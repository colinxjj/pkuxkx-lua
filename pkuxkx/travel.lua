--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:36
-- To change this template use File | Settings | File Templates.
--

--------------------------------------------------------------
-- travel.lua
-- 提供定位与行走功能，使用travel查看别名使用
-- history:
-- 2017/3/15 创建
-- 2017/3/24 修改，添加busy事件，同时考虑flood事件，配套解决方法可以是
-- 对可能发生map change的路径标记并禁用quick模式；同时，当flood时，比对
-- 当前房间出口直到出口发生变化，再进行后续行走。
-- 2017/5/9 修改，添加遍历方法与获取附近房间列表方法的是否过河参数
-- 2017/5/9 在同一区域仍然可能出现无法从房间A到达房间B的情况，例如无量山后山洞内洞外
-- 2017/5/24 添加全局参数判断，用于对护镖任务提供部分区域的屏蔽支持
-- 2017/5/26 添加specialMode，支持天珠，韩元外
--
-- 该模块采用了FSM设计模式，目标是稳定，易用，容错。
-- FSM状态有：
-- 1. stop 停止状态
-- 2. locating 定位中
-- 3. located 已定位
-- 4. walking 行走中
-- 5. lost 迷路中
-- 6. boat 乘船
-- 7. busy（必须重复相同命令，如西蜀山路等）
-- 8. flood (洪水导致房间出口发生变化)
-- 9. blocked 被阻挡中（目前还没实现）
-- 状态转换：
-- 非stop状态都可通过发送STOP消息，转换为stop状态
-- stop -> locating (event: START)
-- locating -> locating (event: TRY_RELOCATE)
-- locating -> located (event: LOCATION_CONFIRMED, LOCATION_CONFIRMED_ONLY)
-- locating -> stop (event: MAX_RETRIES, ROOM_NO_EXITS)
-- located -> located (event: START)
-- located -> walking (event: WALK_PLAN_GENERATED)
-- located -> stop (event: WALK_PLAN_NOT_EXISTS)
-- walking -> located (event: ARRIVED)
-- walking -> lost (event: GET_LOST)
-- walking -> boat (event: BOAT)
-- walking -> busy (event: BUSY)
-- walking -> flood (event: FLOOD)
-- walking -> blocked (event: BLOCKED)
-- lost -> locating (event: TRY_RELOCATE)
-- boat -> walking (event: LEAVE_BOAT)
-- busy -> walking (event: EASE)
-- busy -> busy (event: BUSY)
-- flood -> walkting (event: EXITS_CHANGE_BACK)
-- blocked -> walking (event: CLEARED)
--
-- 对外API：
-- travel:stop() 初始化状态，行走时会先定位当前房间，适用于大多数场景
-- travel:setMode(mode) 设置行走模式，提供"quick", "normal", "slow"三种模式
-- ~ quick模式：每12步停顿1秒，通过travel:setInterval(steps)修改
--   需要注意，在quick模式下，迷路重定向只在休息间隔时做判断，所以在短距离的行走
--   中迷路，有可能会到达错误地点。
-- ~ normal模式：每步短暂停留
-- ~ slow模式：每步停留1秒，通过travel:setDelay(seconds)修改延迟时间
-- travel:relocate() 重定位，必须在coroutine中调用
-- travel:walkto(roomId, action)
-- 指定目的地(roomId)行走，如果需要，先定位当前房间，action为到达后所执行函数，
-- 可包含协程方法(如wait.lua提供的time, regexp方法)
-- travel:waitUntilArrived() 如果walkto方法中传递callback方法不满足需要，
-- 提供该函数（作用类似wait.regexp），该方法yield直到到达目的地。
-- travel:generateWalkPlan(fromRoomId, toRoomId) 获取指定两地点间的路径栈
--
-- 特殊，提供可编程的接口（无直接别名）
-- travel:setTraverse(args)
-- 指定目标房间与范围（默认每两个相邻房间距离为1），进行遍历（dfs算法），check为
-- 遍历中每一步前执行的检查，必须返回true或false，当检查为true时，walk将直接跳跃其后
-- 所有需要遍历的房间，进入到达状态，并执行action。
-- 注意，当前房间必须被定位为rooms中的房间，否则直接失败，建议walkto到指定房间再调用
-- traverse方法，同时，如果traverse过程中迷路，将重新遍历所有房间，尝试次数同walking
--
-- also provide non-FSM aliases to assist map generation
--
--------------------------------------------------------------

require "pkuxkx.predefines"
local helper = require "pkuxkx.helper"
local gb2312 = require "pkuxkx.gb2312"
local FSM = require "pkuxkx.FSM"
local Algo = require "pkuxkx.Algo"
local dbDef = require "pkuxkx.db"
local db = dbDef.open("data/pkuxkx-utf8.db")
local dalDef = require "pkuxkx.dal"
local dal = dalDef.open(db)
local Room = require "pkuxkx.Room"
local ZonePath = require "pkuxkx.ZonePath"
local RoomPath = require "pkuxkx.RoomPath"
local PathCategory = RoomPath.Category
local Deque = require "pkuxkx.deque"
local boat = require "pkuxkx.boat"

-- inherit global excluded zones
local ExcludedBlockZones = ExcludedBlockZones
local ExcludedZones = ExcludedZones

local define_travel = function()
  local prototype = FSM.inheritedMeta()
  -- 状态列表
  local States = {
    stop = "stop",  -- 停止状态
    walking = "walking",  -- 行走中
    lost = "lost",  -- 迷路了
    blocked = "blocked", -- 被阻挡
    locating = "locating",  -- 定位中
    located = "located", -- 已定位
    busy = "busy",    -- 行走忙碌中
    boat = "boat",    -- 乘船中
    flood = "flood",    -- 洪水
  }
  -- 事件列表
  local Events = {
    START = "start",    -- 开始信号，从停止状态开始将进入重定位，从已定位状态开始将进入行走
    STOP = "stop",    -- 停止信号，任何状态收到该信号都会转换到stop状态
    LOCATION_CONFIRMED = "location_confirmed",    -- 确定定位信息
    LOCATION_CONFIRMED_ONLY = "location_confirmed_only",    -- 仅确定定位信息
    ARRIVED = "arrived",    -- 到达目的地信号
    GET_LOST = "get_lost",    -- 迷路信号
    MAX_RELOC_RETRIES = "max_reloc_retries",    -- 到达重定位重试最大次数
    MAX_RELOC_MOVES = "max_reloc_moves",    -- 到达重定位移动最大步数（每次）
    ROOM_NO_EXITS = "room_no_exits",    -- 房间没有出口
    WALK_PLAN_NOT_EXISTS = "walk_plan_not_exists",    -- 行走计划无法生成
    WALK_PLAN_GENERATED = "walk_plan_generated",    -- 行走计划生成
    BOAT = "boat",    -- 乘船信号
    LEAVE_BOAT = "leave_boat",    -- 下船信号
    BUSY = "busy",    -- busy信号
    EASE = "ease",    -- 解除busy信号
    BLOCKED = "blocked",    -- 阻塞信号
    CLEARED = "cleared",    -- 阻塞解除信号
    TRY_RELOCATE = "try_relocate",    -- 尝试重定位
    ROOM_INFO_UNKNOWN = "room_info_unknown",    -- 没有获取到房间信息
    WALK_NEXT_STEP = "walk_next_step",    -- 走下一步
    FLOOD = "flood",    -- 洪水引发地图变化
    FLOOD_OVER = "flood_over",    -- 洪水结束，地图恢复原样
    FLOOD_CONTINUED = "flood_continued",    -- 洪水持续
  }
  -- 正则列表
  local REGEXP = {
    -- aliases
    ALIAS_TRAVEL = "^travel\\s*$",
    ALIAS_STOP = "^travel\\s+stop\\s*$",
    ALIAS_DEBUG = "^travel\\s+debug\\s+(on|off)\\s*$",
    ALIAS_RELOC = "^reloc\\s*$",
    ALIAS_WALKTO = "^walkto\\s*$",
    ALIAS_WALKTO_ID = "^walkto\\s+(\\d+)\\s*$",
    ALIAS_WALKTO_CODE = "^walkto\\s+([a-z][a-z0-9]+)\\s*$",
    ALIAS_WALKTO_LIST = "^walkto\\s+listzone\\s+([a-z]+)\\s*$",
    ALIAS_WALKTO_MODE = "^walkto\\s+mode\\s+(quick|normal|slow)$",
    ALIAS_WALKTO_FIRST = "^walkf\\s+(.*?)\\s*$",
    ALIAS_WALKTO_BEFORE_FIRST = "^walkbf\\s+(.*?)\\s*$",
    ALIAS_WALK_NPC = "^walknpc\\s+(.*?)\\s*$",
    ALIAS_TRAVERSE = "^traverse\\s+(\\d+)\\s*([^ ]*)$",
    ALIAS_TRAVERSE_ZONE = "^traverse\\s+([a-z][a-z0-9]+)\\s*([^ ]*)$",
    ALIAS_LOC_HERE = "^loc\\s+here\\s*$",
    ALIAS_LOC_ID = "^loc\\s+(\\d+)$",
    ALIAS_LOC_GUESS = "^loc\\s+guess\\s*$",
    ALIAS_LOC_MATCH_ID = "^loc\\s+match\\s+(\\d+)\\s*$",
    ALIAS_LOC_UPDATE_ID = "^loc\\s+update\\s+(\\d+)\\s*$",
    ALIAS_LOC_MU_ID = "^loc\\s+mu\\s+(\\d+)\\s*$",
    ALIAS_LOC_SHOW = "^loc\\s+show\\s*$",
    ALIAS_LOC_LMU_ID = "^loc\\s+lmu\\s+(\\d+)\\s*$",
    ALIAS_LOC_TASK = "^loctask\\s+(.+?)\\s+(.+?)\\s*$",
    ALIAS_LOC_NPC = "^locnpc\\s+(.+?)\\s*$",
    ALIAS_ADD_NPC = "^addnpc\\s+(.+?)\\s+(.+?)\\s*$",
    -- triggers
    ROOM_NAME_WITH_AREA = "^[ >]*(.{0,14}) {1,2}\\- \\[[^ ]+\\]$",
    ROOM_NAME_WITHOUT_AREA = "^[ >]*(.{0,14}) {1,2}\\- $",
    ROOM_DESC = "^ {0,14}([^ ].*?) *$",
    SEASON_TIME_DESC = "^    「([^\\\\x00-\\\\xff]+?)」: (.*)$",
    EXITS_DESC = "^\\s{0,12}这里(明显|唯一)的出口是(.*)$|^\\s*这里没有任何明显的出路\\w*",
    BUSY_LOOK = "^[> ]*风景要慢慢的看。$",
    NOT_BUSY = "^[ >]*你现在不忙。$",
    WALK_LOST = "^[> ]*(哎哟，你一头撞在墙上，才发现这个方向没有出路。|这个方向没有出路。|你一不小心脚下踏了个空，... 啊...！|你反应迅速，急忙双手抱头，身体蜷曲。眼前昏天黑地，顺着山路直滚了下去。)$",
    WALK_LOST_SPECIAL = "^[ >]*泼皮一把拦住你：要向从此过，留下买路财！泼皮一把拉住了你。$",
    WALK_RESUME =  table.concat({
      "^[ >]*(", -- 匹配开头
      table.concat({
        "你终于来到了对面，心里的石头终于落地",
        "突然间蓬一声，屁股撞上了什么物事，",
        "你终于一步步的终于挨到了桥头",
        "不知过了多久，船终于靠岸了，你累得满头大汗",
        "小舟终于划到近岸，你从船上走了出来",
        "你沿着踏板走了上去",
        "绿衣少女将小船系在树枝之上，你跨上岸去",
        "突然你突然脚下踏了个空，向下一滑，身子登时堕下了去",
        "你朝船夫挥了挥手便跨上岸去",
        "你从上面爬了下来，衣服都烂了，看起来十分狼狈",
        "你从下面爬了上来，衣服都烂了，看起来十分狼狈",
      }, "|"), -- 挡路触发
      ").*$", -- 匹配结束
    }, ""),
    -- 添加武当沼泽busy
    WALK_BUSY =  table.concat({
      "^[ >]*(", -- 匹配开头
      table.concat({
        "你走到门前，轻轻地扣了两下门环",  -- dalunsi
        "吊桥还没有升起来，你就这样走了，可能会给外敌可乘之机的",  -- lingxiao
        "你小心翼翼往前挪动，遇到艰险难行处，只好放慢脚步",  -- chengdu
        "你还在山中跋涉，一时半会恐怕走不出",  -- huizuxiaozhen
        "青海湖畔美不胜收，你不由停下脚步，欣赏起了风景",  -- dalunsi
        "你不小心被什么东西绊了一下",  -- unknown
        "你的动作还没有完成，不能移动",  -- busy
        "沙石地几乎没有路了，你走不了那么快",  -- huangzhong
        "荒路几乎没有路了，你走不了那么快",  -- huangzhong
        "沙漠中几乎没有路了，你走不了那么快",  -- huangzhong
        "你把花盆搬回了原位。洞口被封住了",  -- baituo
      }, "|"), -- 挡路触发
      ").*$", -- 匹配结束
    }, ""),
    WALK_BLOCK = "^[> ]*你的动作还没有完成，不能移动.*$",
    WALK_STEP = helper.settingRegexp("travel", "walk_step"),
    ARRIVED = helper.settingRegexp("travel", "arrived"),
    LOOK_DONE = helper.settingRegexp("travel", "look_done"),
    strange = "你不小心被什么东西绊了一下，差点摔个大跟头。",
    FLOOD_OCCURRED = "^[ >]*(你刚要前行，忽然发现江水决堤，不由暗自庆幸，还好没过去。|你正要前行，有人大喝：黄河决堤啦，快跑啊！)$",
    -- 所有挡路npc触发
    BLOCKED = table.concat({
      "^[ >]*(", -- 匹配开头
      table.concat({
        "江百胜伸手拦住你说道",  -- taishan
        "红花会众说道：“阁下不是红花会弟子",  -- xihu
        "号手首领伸手拦住了你的去路",  -- xingxiu
        "鼓手首领一言不发，闪身拦在你面前",  -- xingxiu
        "守山弟子说: 非我派弟子不许上峨嵋山",  -- emei
        "师太拦住了你的去路",  -- emei
        "官兵拦住了你的去路",  -- kangqinwangfu
        "中年道长拦住你说道：后面是本派重地，你不是武当弟子",  -- wudang
        "小道童拦住你说道：师祖正在静修",  -- wudang
        "土匪把路一挡，狞笑道：怎么，想溜，没那么容易", -- wudang
        "土匪头咧开大嘴狞笑一声：嘿嘿，既然来了这里，就别想走了",  -- wudang
        "保镖向你吼道：小杂种，这也是你来的地方",  -- pingxiwangfu
        "庄丁挡住了你：喂，你总该意思意思",  -- mingjiao(lvliushanzhuang)
        "颜垣说道：“你非我教弟子，不能上山",  -- mingjiao
        "褚万里喝道：闲杂人等，不得入内",  -- dali
        "梅剑伸手拦住你，说道：“非灵鹫宫弟子请回",  -- lingjiu
        "兰剑伸手拦住你，说道：“非灵鹫宫弟子请回",  -- lingjiu
        "清兵说道：赶快滚开，这是你停留的地方吗",  -- tidufu
        "卫士对你大吼一声：站住，干什么的",  -- lingzhou
        "锦衣卫上前挡住你说道：里面没什么好看的，马上离开这里",  -- tiantan
        "神龙教弟子大声喝道：本教重地，外人不得入内",  -- shenlongdao
        "神龙教弟子大喝一声：里面是教主和夫人休息",  -- shenlongdao
        "王兴隆说道：“后面是我家，没事别瞎转悠",  -- tidufu
        "童百熊说道：「你不是我日月神教弟子，来我教干什么",  -- riyue
        "门卫把手一拦：你这种正派人物，老子一看就恶心，快滚",  -- baituo
        "门卫把手一拦：你这种所谓的正派人物不能进去",  -- baituo
      }, "|"), -- 挡路触发
      ").*$", -- 匹配结束
    }, ""),
    -- 马车到达
    BUS_ARRIVED = "^[ >]*大车停稳了下来，你可以下车\\(xia\\)了。$",
  }
  -- 重定位最多重试次数，当进入located或stop状态时重置，当进入locating时减一
  local RELOC_MAX_RETRIES = 4
  -- 每次重定位最大移动步数(每个房间算1步)，当进入locating状态时重置
  local RELOC_MAX_MOVES = 50
  -- 房间描述显示每行字数
  local DESC_DISPLAY_LINE_WIDTH = 30
  -- quick模式下休息间隔步数
  local INTERVAL = 12

  local SpecialRoomDesc = "这里遭受蒙古兵的洗劫后，已经惨不忍睹。尸横遍野，往日的景象已经荡然无存...."

  local SpecialRenamedZones = {
    ["建康府北城"] = "建康府",
    ["建康府南城"] = "建康府",
    ["长江"] = "长江南岸",
    ["大理城中"] = "大理",
    ["武当山"] = "武当",
    ["峨嵋"] = "峨眉",
    ["峨嵋后山"] = "峨眉后山",
  }
  local SpecialRenamedRooms = {
    ["陆家庄大厅"] = "大厅",
    ["岳飞墓"] = "岳  飞  墓",
  }
  local TraverseZoneExcludedRooms = {
    [1479] = true,
    [1480] = true,
    [1481] = true,
    [1482] = true,  -- 提督府后门
  }

  -- room 3185 has 2-line exits descriptions

  -- 区域最短路径搜索算法
  local zonesearch = Algo.dijkstra
  -- 房间最短路径搜索算法
  local roomsearch = Algo.astar
  -- 遍历算法
  local traversal = Algo.traversal

  ---------------- API ----------------
  -- below functions are exposed APIs
  -- for other modules to call
  -------------------------------------

  local SINGLETON
  -- 获取实例（单例，每world仅一个）
  function prototype:FSM()
    if SINGLETON then return SINGLETON end
    SINGLETON = FSM:new()
    setmetatable(SINGLETON, self or prototype)
    SINGLETON:postConstruct()
    return SINGLETON
  end

  -- 设置模式
  function prototype:setMode(mode)
    assert(mode == "quick" or mode == "normal" or mode == "slow",
      "模式仅可以为以下三种：quick, normal, slow")
    self.mode = mode
  end

  -- 设置休息间隔步数
  function prototype:setInterval(interval)
    assert(type(interval) == "number", "quick模式休息间隔步数必须为数字")
  end

  -- 设置延迟时间
  function prototype:setDelay(delay)
    assert(type(delay) == "number", "slow模式每步延迟必须为数字")
    self.delay = delay
  end

  -- 停止自动行走
  function prototype:stop()
    return self:fire(Events.STOP)
  end

  -- 设置遍历参数
  function prototype:setTraverse(args)
    local rooms = assert(type(args.rooms) == "table" and args.rooms, "rooms must be a table")
    local check = assert(type(args.check) == "function" and args.check, "check must be a function or thread")
    -- no defensive copy, user should make sure immutable :)
    self.traverseRooms = rooms
    self.traverseCheck = check
  end

  function prototype:traverseZone(zone, check, action)
    assert(zone, "zone cannot be nil")
    assert(action == nil or type(action) == "function", "action can only nil or function")
    if not self.zonesByCode[zone] then
      print("查找不到区域：", zone)
    else
      local filtered = {}
      local excludedCnt = 0
      for id, room in pairs(self.zonesByCode[zone].rooms) do
        if not TraverseZoneExcludedRooms[id] then
          filtered[id] = room
        else
          excludedCnt = excludedCnt + 1
        end
      end
      if excludedCnt > 0 then
        self:debug("排除遍历难以到达节点：", excludedCnt)
      end
      self:setTraverse {
        rooms = filtered,
        check = check or function() return false end
      }
      self:fire(Events.START)
      if action then
        self:waitUntilArrived()
        action()
      end
    end
  end

  -- 自动行走
  function prototype:walkto(targetRoomId)
    assert(type(targetRoomId) == "number", "target room id must be number")
    self.targetRoomId = targetRoomId
    return self:fire(Events.START)
  end

  function prototype:walktoFirst(args)
    local rooms = self:getMatchedRooms(args)
    if not rooms or #(rooms) == 0 then
      ColourNote("red", "", "查询不到目标房间")
    else
      self.targetRoomId = rooms[1].id
      self.specialMode = "first"
      return self:fire(Events.START)
    end
  end

  function prototype:walktoBeforeFirst(args)
    local rooms = self:getMatchedRooms(args)
    if not rooms or #(rooms) == 0 then
      ColourNote("red", "", "查询不到目标房间")
    else
      self.targetRoomId = rooms[1].id
      self.specialMode = "beforeFirst"
      return self:fire(Events.START)
    end
  end

  -- 等待直到到达目的地，必须在coroutine中使用
  -- 注意，如果调用walkto并传递了action方法，
  -- 有可能产生并发问题，建议不要同时使用该方法和walkto中的action
  function prototype:waitUntilArrived(timer)
    local currCo = assert(coroutine.running(), "Must be in coroutine")
    local waitPattern = REGEXP.ARRIVED
    if timer then
      -- timer means we need to check the status periodically
      local interval = assert(timer.interval, "interval of timer cannot be nil")
      local check = assert(type(timer.check) == "function" and timer.check, "check of timer must be function")
      while true do
        local line = wait.regexp(waitPattern, interval)
        if line then break end
        if check() then break end
      end
    else
      helper.addOneShotTrigger {
        group = "travel_one_shot",
        regexp = waitPattern,
        response = helper.resumeCoRunnable(currCo)
      }
      return coroutine.yield()
    end
  end

  -- 某个区域是否可遍历，修改该方法可以屏蔽某些危险区域
  function prototype:isZoneTraversable(zone)
    if self.zonesByCode[zone] then
      return true
    else
      return false
    end
  end

  -- 获取指定出发地和目的地之间的路径栈
  function prototype:generateWalkPlan(fromRoomId, toRoomId)
    local fromid = fromRoomId or self.currRoomId
    local toid = toRoomId or self.targetRoomId
    self:debug("检验起始房间和目标房间", fromid, toid)
    local startRoom = self.roomsById[fromid]
    local endRoom = self.roomsById[toid]
    if not startRoom then
      self:debug("当前房间不在自动行走列表中")
      return nil
    elseif not endRoom then
      self:debug("目标房间不在自动行走列表中")
      return nil
    else
      local startZone = self.zonesByCode[startRoom.zone]
      local endZone = self.zonesByCode[endRoom.zone]
      if not startZone then
        self:debug("当前区域不在自动行走列表中", startRoom.zone)
        return nil
      elseif not endZone then
        self:debug("目标区域不在自动行走列表中", endRoom.zone)
        return nil
      elseif startZone == endZone then
        if self.DEBUG then
          local roomCnt = 0
          for _, room in pairs(startZone.rooms) do
            roomCnt = roomCnt + 1
          end
          self:debug("出发地与目的地处于同一区域，共" .. roomCnt .. "个房间")
        end
        local plan = roomsearch {
          rooms = startZone.rooms,
          startid = fromid,
          targetid = toid
        }
        self:printPlan(plan, "直达")
        if plan then
          return plan
        end
        -- 修改，当同一区域但无法到达时，使用备用全图搜索！
        ColourNote("yellow", "", "注意，当前区域无法从房间" .. fromid .. "到达房间" .. toid .. "，尝试全局搜索")
        local fallbackPlan = roomsearch {
          rooms = self.roomsById,
          startid = fromid,
          targetid = toid
        }
        self:printPlan(fallbackPlan, "直达")
        return fallbackPlan
      else
        -- zone search for shortest path
        local zoneStack = zonesearch {
          rooms = self.zonesById,
          startid = startZone.id,
          targetid = endZone.id
        }
        if not zoneStack then
          self:debug("计算区域路径失败，区域 " .. startZone.name .. " 至区域 " .. endZone.name .. " 不可达")
          return nil
        else
          table.insert(zoneStack, ZonePath:decorate {startid=startZone.id, endid=startZone.id, weight=0})
          -- only for debug
          if self.DEBUG then
            local zones = {}
            for i=1,#zoneStack do
              table.insert(zones, zoneStack[i].name)
            end
            self:debug("共经过" .. #zoneStack .. "个区域", table.concat(zones, ", "))
          end

          local zoneCnt = #zoneStack
          local zoneNames = {}
          local rooms = {}
          local roomCnt = 0
          while #zoneStack > 0 do
            local zonePath = table.remove(zoneStack)
            table.insert(zoneNames, self.zonesById[zonePath.endid].code)
            for _, room in pairs(self.zonesById[zonePath.endid].rooms) do
              rooms[room.id] = room
              roomCnt = roomCnt + 1
            end
          end
          self:debug("本次路径计算跨" .. zoneCnt .. "个区域" .. table.concat(zoneNames, ",") .. "，共" .. roomCnt .. "个房间")
          local plan = roomsearch {
            rooms = rooms,
            startid = fromid,
            targetid = toid
          }
          self:printPlan(plan, "直达")
          return plan
        end
      end
    end
  end

  -- 获取指定房间周围指定距离内的遍历路径栈
  function prototype:generateNearbyTraversePlan(centerRoomId, depth, skipStart, crossRiver)
    local rooms = self:getNearbyRooms(centerRoomId, depth, crossRiver)
    return self:generateTraversePlan(rooms, centerRoomId, skipStart)
  end

  -- 检查两个房间的出口列表是否一致
  function prototype:checkExitsIdentical(exits1, exits2)
    if exits1 == nil or exits2 == nil then
      return false
    end
    local ls1 = utils.split(exits1, ";")
    local ls2 = utils.split(exits2, ";")
    if #ls1 ~= #ls2 then
      return false
    end
    local map1 = {}
    for i = 1, #ls1 do
      map1[ls1[i]] = true
    end
    for i = 1, #ls2 do
      if not map1[ls2[i]] then
        return false
      end
    end
    return true
  end

  ----------- Alias-only API ----------
  -- below functions are only used
  -- in alias
  -------------------------------------

  -- 别名-匹配
  function prototype:match(roomId, performUpdate)
    local performUpdate = performUpdate or false
    local room = dal:getRoomById(roomId)
    if not room then
      ColourNote("red", "", "查询不到指定编号的房间：" .. roomId)
      return
    end
    -- 比较房间名称
    if not self.currRoomName then
      ColourNote("red", "", "当前房间无可确定的名称，请先使用LOC定位命令捕捉")
      return
    end
    if self.currRoomName == room.name then
      self:debug("名称匹配")
    else
      print("名称不匹配：", "当前", self.currRoomName, "目标", room.name)
    end
    local currRoomDesc = table.concat(self.currRoomDesc)
    if currRoomDesc == room.description then
      self:debug("描述匹配")
    else
      print("描述不匹配：")
      print("当前", currRoomDesc)
      print("目标", room.description)
    end
    local currExits = {}
    local currExitCnt = 0
    if self.currRoomExits and self.currRoomExits ~= "" then
      for _, e in ipairs(utils.split(self.currRoomExits, ";")) do
        currExits[e] = true
        currExitCnt = currExitCnt + 1
      end
    end
    local tgtExits = {}
    local tgtExitCnt = 0
    if room.exits and room.exits ~= "" then
      for _, e in ipairs(utils.split(room.exits, ";")) do
        tgtExits[e] = true
        tgtExitCnt = tgtExitCnt + 1
      end
    end
    local exitsIdentical = true
    if currExitCnt ~= tgtExitCnt then
      exitsIdentical = false
    else
      for curr in pairs(currExits) do
        if not tgtExits[curr] then
          exitsIdentical = false
          break
        end
      end
    end
    -- furthur check on paths
    local pathIdentical = true
    local tgtPaths = dal:getPathsByStartId(roomId)
    local tgtPathCnt = 0
    for _, tgtPath in pairs(tgtPaths) do
      tgtPathCnt = tgtPathCnt + 1
      if not currExits[helper.expandDirection(tgtPath.path)] then
        self:debug("路径" .. tgtPath.path .. "未找到")
        pathIdentical = false
        break
      end
    end
    if tgtPathCnt ~= currExitCnt then
      pathIdentical = false
    end
    local pathDisplay = {}
    for _, tgtPath in pairs(tgtPaths) do
      table.insert(pathDisplay, tgtPath.endid .. " " .. tgtPath.path)
    end
    if exitsIdentical and pathIdentical then
      if performUpdate then
        self:update(roomId)
        print("出口与路径均匹配，数据库记录已更新")
      else
        print("出口与路径均匹配")
      end
    elseif exitsIdentical and not pathIdentical then
      if performUpdate then
        ColourNote("yellow", "", "出口匹配但路径不匹配，不建议更新数据库，如需要请手动update")
      else
        ColourNote("yellow", "", "出口匹配但路径不匹配")
      end
    elseif pathIdentical then
      if performUpdate then
        self:update(roomId)
        print("出口不匹配但路径匹配，数据库记录已更新")
      else
        print("出口不匹配但路径匹配")
      end
    else
      if performUpdate then
        ColourNote("yellow", "", "出口与路径都不匹配，不建议更新数据库，如需要请手动update")
      else
        ColourNote("yellow", "", "出口与路径都不匹配")
      end
    end
    print(table.concat(pathDisplay, ", "))
  end

  -- 别名-更新
  function prototype:update(roomId)
    local room = Room:new {
      id = roomId,
      name = self.currRoomName,
      code = "",
      description = table.concat(self.currRoomDesc, ""),
      exits = self.currRoomExits
    }
    dal:updateRoom(room)
  end

  -- 别名-重定位
  function prototype:reloc()
    self:fire(Events.STOP)
    self:fire(Events.START)
  end

  function prototype:showDesc(roomDesc)
    if type(roomDesc) == "string" then
      for i = 1, string.len(roomDesc), DESC_DISPLAY_LINE_WIDTH do
        print(string.sub(roomDesc, i, i + DESC_DISPLAY_LINE_WIDTH - 1))
      end
    elseif type(roomDesc) == "table" then
      for _, d in ipairs(roomDesc) do
        print(d)
      end
    end
  end

  -- 别名-显示
  function prototype:show(room)
    if room then
      print("目标房间编号：", room.id)
      print("目标房间名称：", room.name)
      print("目标房间代码：", room.code)
      print("目标房间出口：", room.exits)
      if room.description then
        print("目标房间描述：")
        self:showDesc(room.description)
      else
        print("目标房间描述", room.description)
      end
    else
      print("当前房间编号：", self.currRoomId)
      print("当前房间名称：", self.currRoomName)
      print("当前房间出口：", self.currRoomExits)
      print("当前房间描述：")
      self:showDesc(self.currRoomDesc)
      if not self.currRoomName then
        return
      end
      local potentialRooms = dal:getRoomsByName(self.currRoomName)
      if #(potentialRooms) >= 1 then
        local ids = {}
        for _, room in pairs(potentialRooms) do
          table.insert(ids, room.id)
        end
        print("同名房间：", table.concat(ids, ","))
      else
        print("无同名房间")
      end

      self:debug("当前房间名称：", self.currRoomName, "长度：", string.len(self.currRoomName))
      if gb2312.len(self.currRoomName) > 10 then
        print("当前版本仅支持10个汉字长度内的名称查询")
      end
      local pinyins = dal:getPinyinListByWord(self.currRoomName)
      self:debug("尝试拼音列表：", pinyins and table.concat(pinyins, ", "))
      local candidates = {}
      for _, pinyin in ipairs(pinyins) do
        local results = dal:getRoomsLikeCode(pinyin)
        for id, room in pairs(results) do
          table.insert(candidates, room.id)
        end
      end
      if #candidates > 0 then
        print("拼音同名房间：", table.concat(candidates, ","))
      else
        print("无拼音同名房间")
      end
    end
  end

  -- 别名-猜测
  function prototype:guess()
    -- after locate, we can guess which record it
    -- belongs to according to pinyin of its room name
    local roomName = self.currRoomName
    if not roomName then
      print("当前房间名称为空，请先使用LOC定位命令")
      return
    end
    self:debug("当前房间名称：", roomName, "长度：", string.len(roomName))
    if gb2312.len(roomName) > 10 then
      print("当前版本仅支持10个汉字长度内的名称查询")
    end
    local pinyins = dal:getPinyinListByWord(roomName)
    self:debug("尝试拼音列表：", pinyins and table.concat(pinyins, ", "))
    local candidates = {}
    for _, pinyin in ipairs(pinyins) do
      local results = dal:getRoomsLikeCode(pinyin)
      for id, room in pairs(results) do
        candidates[id] = room
      end
    end
    print("通过房间名拼音匹配得到候选列表：")
    print("----------------------------")
    for _, c in pairs(candidates) do
      print("Room Id:", c.id)
      print("Room Code:", c.code)
      print("Room Name:", c.name)
      print("Room exits:", c.exits)
      print("Room Desc:", c.description and string.sub(c.description, 1, 30))
      print("----------------------------")
    end
  end

  function prototype:loctask(args)
    local words = args.words
    local exits = args.exits
    local results = {}
    for _, room in pairs(self.roomsById) do
      local wordsMatched = true
      for _, word in ipairs(words) do
        if not string.find(room.description, word) then
          wordsMatched = false
          break
        end
      end
      if wordsMatched then
        local exitsMatched = true
        local roomExits = {}
        if room.exits and room.exits ~= "" then
          for _, e in ipairs(utils.split(room.exits, ";")) do
            roomExits[e] = true
          end
          for _, e in pairs(exits) do
            if not roomExits[e] then
              exitsMatched = false
              break
            end
          end
        elseif #(exits) > 0 then
          exitsMatched = false
        end
        if exitsMatched then
          table.insert(results, room)
        end
      end
    end
    if #(results) == 0 then
      print("没有找到匹配房间")
    elseif #(results) == 1 then
      print("匹配到唯一房间：", results[1].id, results[1].name, results[1].code)
    else
      print("存在多个房间匹配：")
      for _, room in ipairs(results) do
        print(room.id, room.name, room.code)
      end
    end
  end

  -- 功能受限的自动遍历
  -- 遍历当前房间范围为depth内的所有房间
  function prototype:traverseNearby(depth, check, action, crossRiver)
    if not self.currRoomId then
      print("失败。当前房间未定位，无法进行范围内自动遍历")
    else
      local traverseRooms = self:getNearbyRooms(self.currRoomId, depth, crossRiver)
    -- todo need to consider situation that rooms in maze may not be bi-directional reachable
--      local RoomsInZone = self.zonesByCode[self.roomsById[self.currRoomId].zone].rooms
      if not traverseRooms then
        print("失败。无法获取附近房间列表")
      else
        self:setTraverse {
          rooms = traverseRooms,
          check = check or function() return false end
        }
        self:fire(Events.START)
        if action then
          self:waitUntilArrived()
          action()
        end
      end
    end
  end

  -- 通过给定名称查找房间列表
  -- 1. 通过全名查找
  -- 2. 通过区域名，房间名查找
  function prototype:getMatchedRooms(args)
    if args.fullname then
      -- check if the fullname match pattern <zone>的<room>
      local delimStart, delimEnd = string.find(args.fullname, "的")
      -- bug fix 2017/5/15: 特殊情况 房间名中存在"的"
      if delimStart and args.fullname ~= "扬州正气山庄的大门" then
        local zone = string.sub(args.fullname, 1, delimStart - 1)
        local name = string.sub(args.fullname, delimEnd + 1)
        self:debug("解析后区域名：", zone)
        self:debug("解析后房间名：", name)
        return self:getMatchedRooms {
          zone = zone,
          name = name
        }
      end
      local fullname = args.fullname
      -- 先检查是否为重命名房间
      for roomName, renamed in pairs(SpecialRenamedRooms) do
        local idxStart, idxEnd = string.find(fullname, roomName)
        -- 房间匹配结尾
        if idxEnd == string.len(fullname) then
          self:debug("发现房间为重命名房间", fullname)
          fullname = string.sub(fullname, 1, idxStart - 1) .. renamed
          break
        end
      end

      local results = {}
      for zoneName, zone in pairs(self.zonesByName) do
        local idxStart, idxEnd = string.find(fullname, zoneName)
        -- 首字符匹配
        if idxStart == 1 then
          local roomName = string.sub(fullname, idxEnd + 1)
          for _, room in pairs(zone.rooms) do
            if room.name == roomName then
              table.insert(results, room)
            end
          end
          -- 不用再查其他区域了
          break
        end
      end
      -- 二次查询，查找重命名区域列表
      if #results == 0 then
        -- check renamed zone
        local zoneRenameMatch = false
        for zoneName, renamed in pairs(SpecialRenamedZones) do
          local idxStart, idxEnd = string.find(fullname, zoneName)
          if idxStart == 1 then
            self:debug("重命名区域匹配成功")
            zoneRenameMatch = true
            local zone = self.zonesByName[renamed]
            local roomName = string.sub(fullname, idxEnd + 1)
            for _, room in pairs(zone.rooms) do
              if room.name == roomName then
                table.insert(results, room)
              end
            end
            break
          end
        end
      end
      return results
    else
      assert(args.name, "name cannot be nil")
      assert(args.zone, "zone cannot be nil")
      -- 先检查房间是否为重命名房间
      local name = SpecialRenamedRooms[args.name] or args.name

      local results = {}
      local zoneName = SpecialRenamedZones[args.zone] or args.zone
      local zone = self.zonesByName[zoneName]
      if not zone then
        return results
      end
      for _, room in pairs(zone.rooms) do
        if room.name == name then
          table.insert(results, room)
        end
      end
      return results
    end
  end

  -- 通过给定名称查找区域
  function prototype:getMatchedZone(name)
    local name = SpecialRenamedZones[name] or name
    return self.zonesByName[name]
  end

  -------- Internal Functions ---------
  -- below functions should not be
  -- called outside this module
  -------------------------------------

  -- 实例构造后初始化
  -- 包含状态，转换，区域与房间列表，触发器，别名，内部属性
  function prototype:postConstruct()
    self:initStates()
    self:initTransitions()
    self:initZonesAndRooms()
    self:initTriggers()
    self:initAliases()
    -- this should be the only place to set state
    -- and only once after construct
    -- all state transition should be handled by FSM
    -- built in finctions
    self:setState(States.stop)
    self.blockUsedWeapon = "sword"
    self:resetOnStop()
  end

  -- 初始化状态列表
  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        -- must clean the user defined triggers
        helper.removeTriggerGroups("travel_one_shot")
        self:disableAllTriggers()
        self:resetOnStop()
      end,
      exit = function()
      end
    }
    self:addState {
      state = States.locating,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.located,
      enter = function()
        self.relocMoves = 0
        self.walkLost = false
      end,
      exit = function()

      end
    }
    self:addState {
      state = States.walking,
      enter = function()
        helper.enableTriggerGroups("travel_walk")
      end,
      exit = function()
        helper.disableTriggerGroups("travel_walk")
      end
    }
    self:addState {
      state = States.lost,
      enter = function()

      end,
      exit = function()

      end
    }
    self:addState {
      state = States.blocked,
      enter = function()
        helper.enableTriggerGroups("travel_block_start")
      end,
      exit = function()
        helper.disableTriggerGroups("travel_block_start", "travel_block_done")
      end
    }
    self:addState {
      state = States.busy,
      enter = function()
        self.walkBusy = false
        helper.enableTriggerGroups("travel_walk_busy_start")
      end,
      exit = function()
        helper.disableTriggerGroups(
          "travel_walk_busy_start",
          "travel_walk_busy_done")
      end
    }
    self:addState {
      state = States.boat,
      enter = function()
        assert(self.boatCmd, "boatCmd cannot be nil when entering boat status")
      end,
      exit = function()
        self.boatCmd = nil
      end
    }
    self:addState {
      state = States.flood,
      enter = function()
      end,
      exit = function()
      end
    }
  end

  -- 初始化转换列表
  -- 转换定义了所有事件触发的状态流转
  -- 所有不在列表内的转换均为非法转换
  function prototype:initTransitions()
    -- transtions from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.locating,
      event = Events.START,
      action = function()
        return self:relocate()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transitions from state<locating>
    self:addTransition {
      oldState = States.locating,
      newState = States.locating,
      event = Events.TRY_RELOCATE,
      action = function()
        return self:relocate()
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.located,
      event = Events.LOCATION_CONFIRMED,
      action = function()
        self:prepareWalkPlan()
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.located,
      event = Events.LOCATION_CONFIRMED_ONLY,
      action = function()
        self.relocRetries = 0
        print("完成重新定位。房间名称：", self.currRoomName, "房间编号：", self.currRoomId)
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.MAX_RELOC_RETRIES,
      action = function()
        print("达到重定位重试次数上限", self.currState)
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.MAX_RELOC_MOVES,
      action = function()
        print("达到单次重定位移动步数上限", self.currState)
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.ROOM_NO_EXITS,
      action = function()
        print("房间不存在")
      end
    }
    self:addTransitionToStop(States.locating)
    -- transitions from state<located>
    self:addTransition {
      oldState = States.located,
      newState = States.located,
      event = Events.START,
      action = function()
        self:prepareWalkPlan()
      end
    }
    self:addTransition {
      oldState = States.located,
      newState = States.walking,
      event = Events.WALK_PLAN_GENERATED,
      action = function()
        -- 这是开始行走的唯一入口，初始化prevMove变量，
        -- 该变量保存前一步的路径信息，用于应对洪水事件
        helper.checkUntilNotBusy()
        SendNoEcho("halt")  -- the halt command is required in case in combat
        self.prevMove = nil
        self.prevCheck = false
        return self:walking()
      end
    }
    self:addTransition {
      oldState = States.located,
      newState = States.stop,
      event = Events.WALK_PLAN_NOT_EXISTS,
      action = {
        beforeExit = function()
          if self.traverseCheck then
            ColourNote("red", "", "自动行走失败！无法遍历房间列表")
          else
            ColourNote("red", "", "自动行走失败！房间不可达 " .. self.currRoomId .. " -> " .. self.targetRoomId)
          end
        end,
        afterEnter = function() end
      }
    }
    self:addTransitionToStop(States.located)
    -- transitions from state<walking>
    self:addTransition {
      oldState = States.walking,
      newState = States.walking,
      event = Events.WALK_NEXT_STEP,
      action = function()
        return self:walking()
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.located,
      event = Events.ARRIVED,
      action = function()
        self.specialMode = nil
        self.walkPlan = nil
        self.prevMove = nil
        self.prevCheck = false
        self.relocRetries = 0
        -- 区别直达与遍历
        if self.traverseCheck then
          self.currRoomId = self.traverseRoomId
          self:refreshRoomInfo()
          self:clearTraverseInfo()
        else
          self.currRoomId = self.targetRoomId
          self:refreshRoomInfo()
        end
        SendNoEcho("set travel arrived")  -- this is for other callbacks
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.blocked,
      event = Events.BLOCKED,
      action = function()
        assert(self.blockCmd, "blockCmd cannot be nil when blocked")
        assert(self.blockers, "blockers cannot be nil when blocked")
        return self:clearBlockers()
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.lost,
      event = Events.GET_LOST,
      action = function()
        print("迷路，曾尝试重定位" .. self.relocRetries .. "次", self.currState)
        return self:fire(Events.TRY_RELOCATE)
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.busy,
      event = Events.BUSY,
      action = function()
        assert(self.walkBusyCmd, "进入busy状态walkBusyCmd变量不可为空")
        self:debug("等待2秒执行walkBusyCmd:", self.walkBusyCmd)
        wait.time(2)
        return self:walkingBusy()
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.boat,
      event = Events.BOAT,
      action = function()
        self:debug("等船命令", self.boatCmd)
        boat:restart(self.boatCmd)
        boat:waitUntilArrived {
          interval = 2,
          check = function()
            return self.currState == States.stop
          end
        }
        return self:fire(Events.LEAVE_BOAT)
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.flood,
      event = Events.FLOOD,
      action = function()
        -- 获取当前房间信息
        self:lookUntilNotBusy()
        self.snapshotExits = self.currRoomExits
        return self:fire(Events.FLOOD_CONTINUED)
      end
    }
    self:addTransitionToStop(States.walking)
    -- transitions from state<blocked>
    self:addTransition {
      oldState = States.blocked,
      newState = States.walking,
      event = Events.CLEARED,
      action = function()
        return self:walking()
      end
    }
    self:addTransitionToStop(States.blocked)
    -- transitions from state<lost>
    self:addTransition {
      oldState = States.lost,
      newState = States.locating,
      event = Events.TRY_RELOCATE, -- always try relocate and the retries threshold is checked when locating
      action = function()
        self.relocRetries = self.relocRetries + 1
        return self:relocate()
      end
    }
    self:addTransitionToStop(States.lost)
    -- transitions from state<busy>
    self:addTransition {
      oldState = States.busy,
      newState = States.walking,
      event = Events.EASE,
      action = function()
        if self.walkBusyResumeCmd then
          self:sendPath(self.walkBusyResumeCmd)
        end
        -- 重置busy命令
        self.walkBusyCmd = nil
        self.walkBusyResumeCmd = nil
        return self:walking()
      end
    }
    self:addTransition {
      oldState = States.busy,
      newState = States.busy,
      event = Events.BUSY,
      action = function()
        assert(self.walkBusyCmd, "busy状态walkBusyCmd变量不可为空")
        self:debug("等待2秒执行walkBusyCmd:", self.walkBusyCmd)
        wait.time(2)
        return self:walkingBusy()
      end
    }
    self:addTransitionToStop(States.busy)
    -- transition from state<boat>
    self:addTransition {
      oldState = States.boat,
      newState = States.walking,
      event = Events.LEAVE_BOAT,
      action = function()
        return self:walking()
      end
    }
    self:addTransitionToStop(States.boat)
    -- transition from state<flood>
    self:addTransition {
      oldState = States.flood,
      newState = States.walking,
      event = Events.FLOOD_OVER,
      action = function()
        self.floodOccurred = false
        self.snapshotExits = nil
        self:debug("洪水结束，补足由于洪水少走的一步并继续前进")
        table.insert(self.walkPlan, self.prevMove)
        SendNoEcho("halt")
        return self:walking()
      end
    }
    self:addTransition {
      oldState = States.flood,
      newState = States.flood,
      event = Events.FLOOD_CONTINUED,
      action = function()
        self:debug("等待10秒后重新获取当前房间出口信息并与快照对比")
        wait.time(10)
        self:lookUntilNotBusy()
        if self.currRoomExits == self.snapshotExits then
          self:debug("出口没有变化，表明洪水没有消退，继续等到")
          return self:fire(Events.FLOOD_CONTINUED)
        else
          return self:fire(Events.FLOOD_OVER)
        end
      end
    }
  end

  -- 加载区域列表和房间列表
  function prototype:initZonesAndRooms()
    -- initialize zones
    local zonesById
    if ExcludedZones then
      zonesById = dal:getAllZonesExcludedZones(ExcludedZones)
    else
      zonesById = dal:getAllZones()
    end
--    local zonesById = dal:getAllZones()
    local zonePaths = dal:getAllZonePaths()
    for i = 1, #zonePaths do
      local zonePath = zonePaths[i]
      local zone = zonesById[zonePath.startid]
      local toZone = zonesById[zonePath.endid]
      if zone and toZone then
        zone:addPath(zonePath)
      end
    end
    -- create code map
    local zonesByCode = {}
    for _, zone in pairs(zonesById) do
      zonesByCode[zone.code] = zone
    end
    local zonesByName = {}
    for _, zone in pairs(zonesById) do
      zonesByName[zone.name] = zone
    end
    -- initialize rooms
    local roomsById
    if ExcludedBlockZones then
      roomsById = dal:getAllAvailableRoomsExcludedBlockZones(ExcludedBlockZones)
    else
      roomsById = dal:getAllAvailableRooms()
    end
    local roomsByCode = {}
    local paths = dal:getAllAvailablePaths()
    for i = 1, #paths do
      local path = paths[i]
      local room = roomsById[path.startid]
      if room then
        room:addPath(path)
      end
    end
    -- add rooms to zones
    for _, room in pairs(roomsById) do
      roomsByCode[room.code] = room
      local zone = zonesByCode[room.zone]
      if zone then
        zone.rooms[room.id] = room
      end
    end
    -- assign to prototype
    self.zonesById = zonesById
    self.zonesByCode = zonesByCode
    self.zonesByName = zonesByName
    self.roomsById = roomsById
    self.roomsByCode = roomsByCode
    print("地图数据加载完毕，共" .. helper.countElements(self.zonesByCode) .. "个区域，" ..
      helper.countElements(self.roomsByCode) .. "个房间")
    if ExcludedZones then
      print("屏蔽区域：", table.concat(ExcludedZones, ", "))
    end
    if ExcludedBlockZones then
      print("屏蔽部分阻碍区域：", table.concat(ExcludedBlockZones, ", "))
    end
  end

  -- 初始化触发器
  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "travel_look_start",
      "travel_look_name",
      "travel_look_desc",
      "travel_look_season",
      "travel_look_exits",
      "travel_walk",
      "travel_block_start",
      "travel_block_done",
      "travel_walk_busy_start",
      "travel_walk_busy_done"
    )

    -- 初始触发
    helper.addTrigger {
      group = "travel_look_start",
      regexp = helper.settingRegexp("travel", "look_start"),
      response = function()
        self:debug("LOOK_START triggered")
        self:clearRoomInfo()
        helper.enableTriggerGroups("travel_look_name")
      end
    }
    -- 抓取房间名称
    local roomNameCaught = function(name, line, wildcards)
      self:debug("ROOM_NAME triggered")
      local roomName = wildcards[1]
      self:debug("room name:", roomName)
      self.currRoomName = roomName
      -- only get the first name, discard all below possible names
      helper.disableTriggerGroups("travel_look_name")
      helper.enableTriggerGroups("travel_look_desc", "travel_look_season", "travel_look_exits")
      self._roomDescInline = true
      self._roomExitsInline = true
    end
    helper.addTrigger {
      group = "travel_look_name",
      regexp = REGEXP.ROOM_NAME_WITH_AREA,
      response = roomNameCaught,
      sequence = 15 -- lower than desc
    }
    helper.addTrigger {
      group = "travel_look_name",
      regexp = REGEXP.ROOM_NAME_WITHOUT_AREA,
      response = roomNameCaught,
      sequence = 15 -- lower than desc
    }
    -- 当频繁使用look时，系统会给出看风景的提示，此时无法获取到房间名称和描述
    helper.addTrigger {
      group = "travel_look_name",
      regexp = REGEXP.BUSY_LOOK,
      response = function()
        self:debug("BUSY_LOOK triggered")
        self:debug("频繁使用look命令不显示描述了！")
        self.busyLook = true
      end
    }
    -- 抓取房间描述
    helper.addTrigger {
      group = "travel_look_desc",
      regexp = REGEXP.ROOM_DESC,
      response = function(name, line, wildcards)
        self:debug("ROOM_DESC triggered")
        if string.find(line, "travel = \"look_done\"") or string.find(line, "一片浓雾中，什么也看不清。") then
          self._roomDescInline = false
        end
        if self._roomDescInline then
          table.insert(self.currRoomDesc, wildcards[1])
        end
      end
    }
    -- 季节和时间描述
    helper.addTrigger {
      group = "travel_look_season",
      regexp = REGEXP.SEASON_TIME_DESC,
      response = function(name, line, wildcards)
        self:debug("SEASON_TIME_DESC triggered")
        if self._roomDescInline then
          self._roomDescInline = false
          helper.disableTriggerGroups("travel_look_desc")    -- 禁止其后抓取描述
        end
        self.currSeason = wildcards[1]
        self.currDatetime = wildcards[2]
      end,
      sequence = 5 -- higher than room desc
    }
    -- 抓取出口信息
    helper.addTrigger {
      group = "travel_look_exits",
      regexp = REGEXP.EXITS_DESC,
      response = function(name, line, wildcards)
        self:debug("EXITS_DESC triggered")
        if self._roomDescInline then
          self._roomDescInline = false
          helper.disableTriggerGroups("travel_look_desc")    -- 禁止其后抓取描述
        end
        if self._roomExitsInline then
          self._roomExitsInline = false
          self.currRoomExits = self:formatExits(wildcards[2] or "look")
        end
      end,
      sequence = 5 -- higher than room desc
    }
    -- 迷路触发
    local lostWay = function()
      self.walkLost = true
      self:debug("似乎迷路了！")
    end
    helper.addTrigger {
      group = "travel_walk",
      regexp = REGEXP.WALK_LOST,
      response = lostWay
    }
    helper.addTrigger {
      group = "travel_walk",
      regexp = REGEXP.WALK_LOST_SPECIAL,
      response = lostWay
    }
    helper.addTrigger {
      group = "travel_walk",
      regexp = REGEXP.WALK_BLOCK,
      response = lostWay
    }
    helper.addTrigger {
      group = "travel_walk",
      regexp = REGEXP.FLOOD_OCCURRED,
      response = function()
        self.floodOccurred = true
        self.snapshotExits = nil
        self:debug("洪水泛滥，房间出口改变")
      end
    }
    helper.addTrigger {
      group = "travel_walk",
      regexp = REGEXP.BUS_ARRIVED,
      response = function()
        self.busArrived = true
      end
    }
    -- busy触发
    helper.addTrigger {
      group = "travel_walk_busy_start",
      regexp = helper.settingRegexp("travel", "walkbusy_start"),
      response = function()
        helper.enableTriggerGroups("travel_walk_busy_done")
      end
    }
    helper.addTrigger {
      group = "travel_walk_busy_done",
      regexp = helper.settingRegexp("travel", "walkbusy_done"),
      response = function()
        if self.walkBusy then
          return self:fire(Events.BUSY)
        else
          return self:fire(Events.EASE)
        end
      end
    }
    helper.addTrigger {
      group = "travel_walk_busy_done",
      regexp = REGEXP.WALK_BUSY,
      response = function()
        self.walkBusy = true
      end
    }
    -- 阻挡触发
    helper.addTriggerSettingsPair {
      group = "travel",
      start = "block_start",
      done = "block_done"
    }
    helper.addTrigger {
      group = "travel_block_done",
      regexp = REGEXP.BLOCKED,
      response = function()
        self:debug("BLOCKED triggered")
        self.blocked = true
      end
    }
  end

  -- 初始化别名
  function prototype:initAliases()
    helper.removeAliasGroups("travel")
    -- 说明
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_TRAVEL,
      response = function()
        print("TRAVEL自动行走指令，使用方法：")
        print("travel debug on/off", "开启/关闭调试模式，开启时将将显示所有触发器与日志信息")
        print("travel stop", "停止自动行走或重定位")
        print("reloc", "重新定位直到当前房间可唯一确定")
        print("walkto mode quick/normal/slow", "调整自动行走模式，quick：快速行走，每12步休息1秒；normal：每步短暂停顿；slow：每步停顿1秒")
        print("walkto <number>", "根据目标房间编号进行自动行走，如果当前房间未知将先进行重新定位")
        print("walkto <room_code>", "根据目标房间代号进行自动行走，代号如果为区域名，将行走到区域的中心节点")
        print("walkto showzone", "显示自动行走支持的区域列表")
        print("walkto listzone <zone_code>", "显示相应区域所有可达的房间")
        print("同时提供地图录入功能：")
        print("loc here", "尝试定位当前房间，捕捉当前房间信息并显示")
        print("loc <number>", "显示数据库中指定编号房间的信息")
        print("loc match <number>", "将当前房间与目标房间进行对比，输出对比情况")
        print("loc update <number>", "将当前房间的信息更新进数据库，请确保信息的正确性")
        print("loc show", "仅显示当前房间信息，不做look定位")
        print("loc guess", "通过房间名称的拼音查找类似的房间")
        print("loc mu <number>", "将当前房间与目标房间对比，如果信息匹配，则更新")
        print("loc lmu <number>", "查看当前房间，与目标房间对比并进行更新，该操作主要用于为地图添加或更新节点")
        print("提供npc定位，行走以及录入功能：")
        print("locnpc <npc name or id>", "定位同名或同id的npc房间")
        print("walknpc <npc name or id>", "行走至同名或同id的npc房间")
        print("addnpc <npc name> <npc id>", "添加npc到数据库，npc的中文名(不可有空格分隔)为参数1，npc的英文id（可有空格分隔，建议用全名）为参数2")
      end
    }
    -- 调试模式
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_DEBUG,
      response = function(name, line, wildcards)
        local option = wildcards[1]
        if option == "on" then
          self:debugOn()
        elseif option == "off" then
          self:debugOff()
        end
      end
    }
    -- 停止行走
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_STOP,
      response = function ()
        self:stop()
      end
    }
    -- 重定位
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_RELOC,
      response = function()
        self:reloc()
      end
    }
    -- 自动行走(房间编号)
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_WALKTO_ID,
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:walkto(targetRoomId)
        self:waitUntilArrived()
        self:debug("到达目的地")
      end
    }
    -- 自动行走(房间代码)
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_WALKTO_CODE,
      response = function(name, line, wildcards)
        local target = wildcards[1]
        if target == "showzone" then
          print(string.format("%16s%16s%16s", "区域代码", "区域名称", "区域中心"))
          for _, zone in pairs(self.zonesById) do
            print(string.format("%12s%16s%20s", zone.code, zone.name, zone.centercode))
          end
        elseif self.zonesByCode[target] then
          local targetRoomCode = self.zonesByCode[target].centercode
          local targetRoomId = self.roomsByCode[targetRoomCode].id
          self:stop()
          self:walkto(targetRoomId)
          self:waitUntilArrived()
          self:debug("到达目的地")
        elseif self.roomsByCode[target] then
          local targetRoomId = self.roomsByCode[target].id
          self:stop()
          self:walkto(targetRoomId)
          self:waitUntilArrived()
          self:debug("到达目的地")
        else
          print("查询不到相应房间")
          return false
        end
      end
    }
    -- 房间列表
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_WALKTO_LIST,
      response = function(name, line, wildcards)
        local zoneCode = wildcards[1]
        if self.zonesByCode[zoneCode] then
          local zone = self.zonesByCode[zoneCode]
          print(string.format("%s(%s)房间列表：", zone.name, zone.code))
          print(string.format("%4s%20s%40s", "编号", "名称", "代码"))
          for _, room in pairs(zone.rooms) do
            print(string.format("%4d%20s%40s", room.id, room.name, room.code))
          end
        else
          print("查询不到相应区域")
        end
      end
    }
    -- 行走模式
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_WALKTO_MODE,
      response = function(name, line, wildcards)
        local mode = wildcards[1]
        self:setMode(mode)
      end
    }
    -- 遍历周围
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_TRAVERSE,
      response = function(name, line, wildcards)
        local depth = tonumber(wildcards[1])
        local checkName = wildcards[2]
        if checkName ~= "" then
          self:debug("构建临时触发器，匹配", checkName)
          local checked = false
          helper.addOneShotTrigger {
            group = "travel_one_shot",
            regexp = checkName,
            response = function()
              checked = true
            end
          }
          local onStep = function()
            return checked
          end
          local onArrive = function()
            helper.removeTriggerGroups("travel_one_shot")
            if checked then
              ColourNote("green", "", "已发现目标，停止行走")
            else
              ColourNote("yellow", "", "未发现目标，遍历结束")
            end
          end
          return self:traverseNearby(depth, onStep, onArrive)
        end
        return self:traverseNearby(depth)
      end
    }
    -- 遍历区域
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_TRAVERSE_ZONE,
      response = function(name, line, wildcards)
        local zone = wildcards[1]
        local checkName = wildcards[2]
        if checkName ~= "" then
          print("构建临时触发器，匹配", checkName)
          local checked = false
          helper.addOneShotTrigger {
            group = "travel_one_shot",
            regexp = checkName,
            response = function()
              checked = true
            end
          }
          local onStep = function()
            return checked
          end
          local onArrive = function()
            helper.removeTriggerGroups("travel_one_shot")
            if checked then
              ColourNote("green", "", "已发现目标，停止行走")
            else
              ColourNote("yellow", "", "未发现目标，遍历结束")
            end
          end
          return self:traverseZone(zone, onStep, onArrive)
        end
        return self:traverseZone(zone)
      end
    }
    -- 更新地图与查看功能
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_HERE,
      response = function()
        self:lookUntilNotBusy()
        self:show()
      end
    }
    -- 查询房间
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_ID,
      response = function(name, line, wildcards)
        local roomId = tonumber(wildcards[1])
        local room = dal:getRoomById(roomId)
        if room then
          self:show(room)
          local paths = dal:getPathsByStartId(room.id)
          local pathDisplay = {}
          for _, path in pairs(paths) do
            table.insert(pathDisplay, path.endid .. " " .. path.path)
          end
          print("可到达路径：", table.concat(pathDisplay, ", "))
        else
          print("无法查询到相应房间")
        end
      end
    }
    -- 猜测房间
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_GUESS,
      response = function()
        self:guess()
      end
    }
    -- 匹配房间
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_MATCH_ID,
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:match(targetRoomId)
      end
    }
    -- 更新房间
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_UPDATE_ID,
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:update(targetRoomId)
      end
    }
    -- 匹配并更新房间
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_MU_ID,
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:match(targetRoomId, true)
      end
    }
    -- 显示房间
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_SHOW,
      response = function()
        self:show()
      end
    }
    -- 查看匹配并更新房间
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_LMU_ID,
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:lookUntilNotBusy()
        self:show()
        self:match(targetRoomId, true)
      end
    }
    -- task相关查询功能
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_TASK,
      response = function(name, line, wildcards)
        local words = utils.split(wildcards[1], ",")
        local exits = utils.split(wildcards[2], ",")
        return self:loctask {
          words = words,
          exits = exits
        }
      end
    }
    -- 行走到第一个房间
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_WALKTO_FIRST,
      response = function(name, line, wildcards)
        local location = wildcards[1]
        return self:walktoFirst {
          fullname = location
        }
      end
    }
    -- 行走到第一个房间前的一个房间
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_WALKTO_BEFORE_FIRST,
      response = function(name, line, wildcards)
        local location = wildcards[1]
        return self:walktoBeforeFirst {
          fullname = location
        }
      end
    }
    -- 定位npc
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_NPC,
      response = function(name, line, wildcards)
        local searchPattern = wildcards[1]
        local npcs
        npcs = dal:getNpcsByName(searchPattern)
        if not npcs or #npcs == 0 then
          npcs = dal:getNpcsById(searchPattern)
        end

        if not npcs or #npcs == 0 then
          ColourNote("yellow", "", "无法查询到NPC：" .. searchPattern)
        else
          print(string.format("%20s %20s %10s %20s", "名字", "ID", "房间", "区域"))
          for _, npc in ipairs(npcs) do
            print(string.format("%20s %20s %10d %20s", npc.name, npc.id, npc.roomid, npc.zone))
          end
        end
      end
    }
    -- 行走到指定npc
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_WALK_NPC,
      response = function(name, line, wildcards)
        local searchPattern = wildcards[1]
        local npcs
        npcs = dal:getNpcsByName(searchPattern)
        if not npcs or #npcs == 0 then
          npcs = dal:getNpcsById(searchPattern)
        end

        if not npcs or #npcs == 0 then
          ColourNote("yellow", "", "无法查询到NPC: " .. searchPattern)
        else
          if #npcs > 1 then
            print("发现多个同名npc：")
            for _, npc in ipairs(npcs) do
              print(string.format("%20s %20s %10d %20s", npc.name, npc.id, npc.roomid, npc.zone))
            end
          end
          return self:walkto(npcs[1].roomid)
        end
      end
    }
    -- 添加npc
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_ADD_NPC,
      response = function(name, line, wildcards)
        local npcName = wildcards[1]
        local npcId = wildcards[2]
        if self.currState ~= States.located then
          ColourNote("yellow", "", "当前房间未定位，不可添加NPC")
        else
          local roomId = self.currRoomId
          dal:insertNpc {
            id = npcId,
            name = npcName,
            roomid = roomId
          }
          local npcs = dal:getNpcsByName(npcName)
          -- 打印结果
          Note("更新成功，同名npc列表:")
          for _, npc in ipairs(npcs) do
            Note(string.format("%20s %20s %10d %20s", npc.name, npc.id, npc.roomid, npc.zone))
          end
        end
      end
    }
  end

  -- 重置所有属性至初始值
  function prototype:resetOnStop()
    -- locating
    self.currRoomId = nil
    self.currRoomName = nil
    self.targetRoomId = nil -- 当该变量不为空时，为直达任务
    self.busyLook = false  -- 重定位时该变量记录当前look是否被系统判定为频繁
    self.relocMoves = 0  -- 进入located状态时重置
    self.relocRetries = 0  -- STOP, ARRIVED, LOCATION_CONFIRMED_ONLY 时重置
    -- walking
    self.walkPlan = nil
    self.walkLost = false
    self.walkSteps = 0
    self.walkInterval = self.walkInterval or INTERVAL
    self.mode = self.mode or "quick"
    self.delay = self.delay or 1
    -- busy
    self.walkBusyCmd = nil
    self.walkBusyResumeCmd = nil
    self.walkBusy = false
    -- flood
    self.prevMove = nil
    self.prevCheck = false
    self.floodOccurred = false
    self.snapshotExits = nil
    -- traversing
    self.traverseCheck = nil
    self.traverseRoomId = nil    -- 遍历时，每步都执行该方法，为true时停止遍历
    self.traverseRooms = nil    -- 需要遍历的房间列表，LOCATION_CONFIRMED_TRAVERSE时刷新，STOP, ARRIVED重置
    -- block
    self.blockCmd = nil
    self.blockers = nil
    -- special mode
    self.specialMode = nil
  end

  -- 禁用所有触发器
  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
    -- locating
      "travel_look_start",
      "travel_look_name",
      "travel_look_desc",
      "travel_look_season",
      "travel_look_exits",
      "travel_walk"
    )
  end

  -- 添加其他状态到stop状态的转换
  function prototype:addTransitionToStop(fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function()
        print("停止 - 当前状态", self.currState)
      end
    }
  end

  -- 格式化原始出口字符串
  function prototype:formatExits(rawExits)
    local exits = rawExits
    exits = string.gsub(exits,"。","")
    exits = string.gsub(exits," ","")
    exits = string.gsub(exits,"、", ";")
    exits = string.gsub(exits, "和", ";")
    local tb = {}
    for _, str in ipairs(utils.split(exits,";")) do
      local t = Trim(str)
      if t ~= "" then table.insert(tb, t) end
    end
    return table.concat(tb, ";")
  end

  -- 清空当前房间信息
  function prototype:clearRoomInfo()
    self.currRoomId = nil
    self.currRoomName = nil
    self.currRoomDesc = {}    -- use table to store description (avoiding string concat)
    self.currRoomExits = nil
    self.currSeason = nil
    self.currDatetime = nil
    self._roomDescInline = false    -- only use when locating current room
    self._roomExitsInline = false    -- only use when locating current room
  end

  -- 清空遍历信息
  function prototype:clearTraverseInfo()
    self.traverseRoomId = nil
    self.traverseCheck = nil
    self.traverseRooms = nil
  end

  -- 核心函数，捕捉当前房间信息
  function prototype:lookUntilNotBusy()
    while true do
      helper.enableTriggerGroups("travel_look_start")
      self.busyLook = false
      SendNoEcho("set travel look_start")
      SendNoEcho("look")
      SendNoEcho("set travel look_done")
      local line = wait.regexp(REGEXP.LOOK_DONE, 3)
      helper.disableTriggerGroups(
        "travel_look_start",
        "travel_look_name",
        "travel_look_desc",
        "travel_look_season",
        "travel_look_exits")
      if not line then
        print("系统超时，5秒后重试")
        wait.time(5)
      elseif self.busyLook then
        wait.time(2)
      else
        break
      end
    end
  end

  -- 核心函数，执行重定位
  function prototype:relocate()
    if self.relocRetries > RELOC_MAX_RETRIES then
      return self:fire(Events.MAX_RELOC_RETRIES)
    else
      self.relocMoves = self.relocMoves + 1
      if self.relocMoves > RELOC_MAX_MOVES then
        return self:fire(Events.MAX_RELOC_MOVES)
      else
        self:lookUntilNotBusy()
        -- 尝试匹配当前房间
        if not self.currRoomName then
          if not self.currRoomExits then
            return self:fire(Events.ROOM_INFO_UNKNOWN)
          else
            -- 尝试随机游走，重新定位
            wait.time(1.5)
            self:randomGo(self.currRoomExits)
            return self:fire(Events.TRY_RELOCATE)
          end
        else
          local potentialRooms = dal:getRoomsByName(self.currRoomName)
          local matched = self:matchPotentialRooms(table.concat(self.currRoomDesc), self.currRoomExits, potentialRooms)
          if #matched == 1 then
            self:debug("成功匹配唯一房间", matched[1])
            self.currRoomId = matched[1]
            if self.targetRoomId then
              return self:fire(Events.LOCATION_CONFIRMED)
            elseif self.traverseCheck then
              return self:fire(Events.LOCATION_CONFIRMED)
            else
              return self:fire(Events.LOCATION_CONFIRMED_ONLY)
            end
          else
            if #matched == 0 then
              self:debug("没有可匹配的房间，房间名", self.currRoomName)
            else
              self:debug("查找到多个匹配成功的房间", table.concat(matched, ","))
            end
            -- 尝试随机游走，重新定位
            wait.time(1.5)
            self:randomGo(self.currRoomExits)
            return self:fire(Events.TRY_RELOCATE)
          end
        end
      end
    end
  end

  function prototype:sendPath(path)
    local cmds = utils.split(path, ";")
    for i = 1, #cmds do
      SendNoEcho(cmds[i])
    end
  end

  -- 核心函数，执行行走命令
  -- 增加对遍历的支持
  -- 添加对地图改变事件的处理，
  -- 这里需要考虑该步行走前可能已经有别人触发了这个事件（小概率）
  -- 以及当自己行走命令执行后，触发了该事件
  function prototype:walking()
    -- 优先检查前一步是否有可能触发房间出口变化事件（洪水），
    -- 如果发生，转换到对应状态
    if self.prevMove and not self.prevCheck and self.prevMove.mapchange == 1 then
      self:debug("可能发生洪水事件")
      self:assureStepResponsive()
      if self.floodOccurred then
        return self:fire(Events.FLOOD)
      elseif self.walkLost then
        return self:fire(Events.GET_LOST)
      else
        -- 已经检查过上一步，确保下一次不再检查
        self.prevCheck = true
        return self:fire(Events.WALK_NEXT_STEP)
      end
    end
    if #(self.walkPlan) > 0 then
      self.walkSteps = self.walkSteps + 1
      local move = table.remove(self.walkPlan)
      -- 当前步如果可能改变地图，优先检查是否地图已经被改变（他人触发）
      if move.mapchange == 1 then
        self:debug("当前步可能改变房间出口，需要确认地图是否已经被改变")
        local origExits = self.roomsById[move.startid].exits
        self:debug("原始出口信息：", origExits)
        while true do
          self:lookUntilNotBusy()
          if self:checkExitsIdentical(self.currRoomExits, origExits) then
            self:debug("当前出口信息符合原始数据，继续行走")
            break
          else
            self:debug("当前出口信息不符合原始数据，等待10秒后再检查")
            wait.time(10)
          end
        end
      end
      -- 当遍历时，先执行遍历检查函数
      if self.traverseCheck then
        -- 设置遍历房间号为当前房间号
        self.traverseRoomId = move.startid
        local checked, msg = self.traverseCheck()
        self:debug("遍历检测结果", checked, msg)
        if checked then
          return self:fire(Events.ARRIVED)
        else
          -- 当检查不通过时，将遍历房间号设置为下一个房间的编号，以保证路径走完时，遍历房间号等于最终目标房间号
          self.traverseRoomId = move.endid
        end
      end
      -- 执行路径
      self:debug("路径", move.startid, move.endid, move.path, move.category)
      -- 存储当前步，以便于地图变化事件处理
      self.prevMove = move
      self.prevCheck = false
      if move.category == PathCategory.normal then
        SendNoEcho(move.path)
      elseif move.category == PathCategory.multiple then
        self:sendPath(move.path)
      elseif move.category == PathCategory.busy then
        local cmds = utils.split(move.path, ";")
        assert(#cmds <= 2, "busy path can at most have 2 commands(start and stop)")
        self.walkBusyCmd = cmds[1]
        self.walkBusyResumeCmd = cmds[2]
        return self:fire(Events.BUSY)
      elseif move.category == PathCategory.boat then
        self.boatCmd = move.path
        return self:fire(Events.BOAT)
      elseif move.category == PathCategory.pause then
        self:sendPath(move.path)
        self:debug("行走暂停，等待结束信号，超时设置60秒")
        local line = wait.regexp(REGEXP.WALK_RESUME, 60)
        if not line then
          error("行走60秒超时出错")
        end
      elseif move.category == PathCategory.block then
        self.blockCmd = move.path
        self.blockers = move.blockers
        return self:fire(Events.BLOCKED)
      elseif move.category == PathCategory.checkbusy then
        self:sendPath(move.path)
        helper.checkUntilNotBusy()
      elseif move.category == PathCategory.bus then
        self.busArrived = false
        SendNoEcho("gu")
        SendNoEcho(move.path)
        local busTime = 0
        while not self.busArrived do
          wait.time(3)
          busTime = busTime + 3
          self:debug("坐车等待时间：", busTime)
        end
        SendNoEcho("xia")
      else
        error("current version does not support this path category:" .. move.category, 2)
      end
      -- we cannot use quick mode to traverse, because traverse has to use callback check
      -- for each move
      if self.mode == "quick" and not self.traverseCheck then
        if (self.walkSteps % self.walkInterval) == 0 then
          self:assureStepResponsive(1)
          if self.walkLost then
            return self:fire(Events.GET_LOST)
          else
            return self:fire(Events.WALK_NEXT_STEP)
          end
        else
          return self:fire(Events.WALK_NEXT_STEP)
        end
      else
        if self.mode == "slow" then
          wait.time(1)
        elseif self.traverseCheck then
          -- for traverse, we still need to wait some time
          wait.time(0.2)
        end
        self:assureStepResponsive()
        if self.walkLost then
          return self:fire(Events.GET_LOST)
        else
          return self:fire(Events.WALK_NEXT_STEP)
        end
      end
    else
      -- here we also need to put traverse check if traversing
      if self.traverseCheck then
        -- 设置遍历房间号
        local checked, msg = self.traverseCheck()
        self:debug("遍历检测结果", checked, msg)
        if checked then
          -- 将遍历房间号设置回当前房间
          return self:fire(Events.ARRIVED)
        end
      end
      return self:fire(Events.ARRIVED)
    end
  end

  function prototype:assureStepResponsive(extraWaitTime)
    while true do
      SendNoEcho("set travel walk_step")
      local line = wait.regexp(REGEXP.WALK_STEP, 5)
      if not line then
        print("系统反应超时，等待5秒重试")
        wait.time(5)
      elseif self.walkLost then
        SendNoEcho("halt")
        break
      else
        if extraWaitTime and extraWaitTime > 0 then
          wait.time(extraWaitTime)
        end
        SendNoEcho("halt")
        break
      end
    end
  end

  function prototype:walkingBusy()
    SendNoEcho("set travel walkbusy_start")
    SendNoEcho(self.walkBusyCmd)
    SendNoEcho("set travel walkbusy_done")
  end

  -- 随机游走（重定位失败时）
  function prototype:randomGo(currExits)
    if not currExits or currExits == "" then return nil end
    local exits = utils.split(currExits, ";")
    local exit = exits[math.random(#(exits))]
    self:debug("随机选择出口并执行重新定位", exit)
    check(SendNoEcho("halt"))
    check(SendNoEcho(exit))
  end

  -- 匹配潜在房间
  function prototype:matchPotentialRooms(currRoomDesc, currRoomExits, potentialRooms)
    local matched = {}
    -- self:debug(currRoomDesc)
    for i = 1, #potentialRooms do
      local room = potentialRooms[i]
      local exitsMatched = self:checkExitsIdentical(room.exits, currRoomExits)
      local descMatched = room.description == currRoomDesc
      self:debug("房间编号", room.id, "出口匹配：", exitsMatched, "描述匹配：", descMatched)
      if exitsMatched and descMatched then
        table.insert(matched, room.id)
      end
    end
    return matched
  end

  -- 生成遍历计划
  function prototype:generateTraversePlan(traverseRooms, startid, skipStart)
    local plan = traversal {
      rooms = traverseRooms or self.traverseRooms,
      fallbackRooms = self.roomsById,
      startid = startid or self.currRoomId
    }
    local skipStart = skipStart or false
    if plan and #plan > 0 and not skipStart then
      -- 遍历计划需要考虑起始节点，所以在栈顶添加startid -> startid的虚拟path
      table.insert(plan, dal:getPseudoPath(plan[#plan].startid))
    end
    self:printPlan(plan, "遍历")
    return plan
  end

  function prototype:printPlan(plan, type)
    if plan then
      local ls = {}
      for i = #(plan), 1, -1 do
        table.insert(ls, plan[i].path)
      end
      print(type, table.concat(ls, ";"))
    else
      print(type, "无路径")
    end
  end

  -- 准备行走计划（直达，或遍历）
  function prototype:prepareWalkPlan()
    local walkPlan
    if self.traverseCheck then
      self:debug("生成遍历计划，起点：", self.currRoomId)
      walkPlan = self:generateTraversePlan()
    else
      self:debug("生成直达计划")
      walkPlan = self:generateWalkPlan()
    end
    if not walkPlan then
      return self:fire(Events.WALK_PLAN_NOT_EXISTS)
    else
      -- 添加对特殊模式的支持，会根据需要改变目标房间编号
      -- specialMode
      -- first: 同区域同名房间的第一个（天珠任务）
      -- beforeFirst: 同区域同名房间的第一个的前一个（狙击任务）
      if self.specialMode == "first" then
        local targetRoom = self.roomsById[self.targetRoomId]
        local adjustedPlan = {}
        for _, move in ipairs(walkPlan) do
          table.insert(adjustedPlan, move)
          local endRoom = self.roomsById[move.endid]
          if endRoom.id ~= targetRoom.id
            and endRoom.zone == targetRoom.zone
            and endRoom.name == targetRoom.name then
            self:debug("发现直达路径上同名房间，修改目标房间编号：" .. targetRoom.id .. " => " .. endRoom.id)
            self.targetRoomId = endRoom.id
            adjustedPlan = {}
            table.insert(adjustedPlan, move)
          end
        end
        walkPlan = adjustedPlan
      elseif self.specialMode == "beforeFirst" then
        local targetRoom = self.roomsById[self.targetRoomId]
        local adjustedPlan = {}
        for _, move in ipairs(walkPlan) do
          local endRoom = self.roomsById[move.endid]
          if endRoom.zone == targetRoom.zone
            and endRoom.name == targetRoom.name then
            self:debug("发现直达路径同名房间，修改目标房间为前一个房间：" .. targetRoom.id .. " => " .. move.startid)
            self.targetRoomId = move.startid
            adjustedPlan = {}
          else
            table.insert(adjustedPlan, move)
          end
        end
        walkPlan = adjustedPlan
      end
      self:debug("本次自动行走共" .. #walkPlan .. "步")
      self:debug("曾有" .. self.relocRetries .. "次定位重试")
      -- this is the only place to store walk plan
      self.walkPlan = walkPlan
      return self:fire(Events.WALK_PLAN_GENERATED)
    end
  end

  -- 获取附近房间列表
  function prototype:getNearbyRooms(centerRoomId, maxDepth, crossRiver)
    if maxDepth < 1 then return nil end
    local startroom = self.roomsById[centerRoomId]
    if not startroom then return nil end

    local visited = {}
    local deque = Deque:new()
    deque:addLast({room=startroom, depth=0})

    while deque:size() > 0 do
      local elem = deque:removeFirst()    -- bfs
      local room = elem.room
      local depth = elem.depth
      if not visited[room.id] then
        visited[room.id] = room
        if depth < maxDepth then
          for _, exit in pairs(room.paths) do
            local nextRoom = self.roomsById[exit.endid]
            if nextRoom then
              -- 添加对过河的判断
              if crossRiver or not string.find(exit.path, "boat") then
                deque:addLast({room=nextRoom, depth=depth+1})
              end
            end
          end
        end
      end
    end
    return visited
  end

  -- 通过id更新房间信息
  function prototype:refreshRoomInfo()
    -- 更新房间信息
    local currRoom = self.roomsById[self.currRoomId]
    self.currRoomName = currRoom and currRoom.name
    self.currRoomExits = currRoom and currRoom.exits
    self.currRoomDesc = currRoom and {currRoom.description}
  end

  -- 清除阻挡者
  function prototype:clearBlockers()
    while true do
      self.blocked = false
      SendNoEcho("halt")
      SendNoEcho("set travel block_start")
      self:sendPath(self.blockCmd)
      SendNoEcho("set travel block_done")
      helper.checkUntilNotBusy()
      if self.blocked then
        if self.blockUsedWeapon then
          SendNoEcho("wield " .. self.blockUsedWeapon)
        end
        for _, blocker in ipairs(utils.split(self.blockers, ",")) do
          SendNoEcho("killall " .. blocker)
        end
      else
        return self:fire(Events.CLEARED)
      end
      wait.time(5)
    end
  end

  return prototype
end

return define_travel():FSM()

--local travel = define_travel():FSM()
--local rooms = travel.zonesByCode["beijing"].rooms
--print(helper.countElements(rooms))
--travel:debugOn()
--travel.currRoomId = 147
--travel.targetRoomId = 38
--local plan = travel:generateWalkPlan()
--print(#plan)
--travel.traverseRooms = rooms
--travel.currRoomId = 110
--local plan = travel:generateTraversePlan()
--print(#plan)
