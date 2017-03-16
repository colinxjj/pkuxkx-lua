--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:36
-- To change this template use File | Settings | File Templates.
--

--------------------------------------------------------------
-- travel.lua
-- 提供定位与行走功能，用户命令使用loc
-- 该模块采用了FSM设计模式，目标是稳定易用容错。
-- FSM状态有：
-- 1. stop 停止状态
-- 2. locating 定位中
-- 3. located 已定位
-- 4. walking 行走中
-- 5. lost 迷路中
-- 6. blocked 被阻挡中（busy, boat, etc）
-- 状态转换：
-- 非stop状态都可通过发送STOP消息，转换为stop状态
-- stop -> locating (event: START)
-- locating -> located (event: LOCATION_CONFIRMED, LOCATION_CONFIRMED_ONLY)
-- locating -> stop (event: MAX_RETRIES, ROOM_NO_EXITS)
-- located -> walking (event: WALK_PLAN_GENERATED)
-- located -> stop (event: WALK_PLAN_NOT_EXISTS)
-- walking -> located (event: ARRIVED)
-- walking -> lost (event: GET_LOST)
-- walking -> blocked (event: BOAT, BUSY)
-- lost -> locating (event: START_RELOCATE)
-- blocked -> walking (event: BLOCKING_SOLVED)
--
-- 对外API：
-- travel:reset() 初始化状态，行走时会先定位当前房间，适用于大多数场景
-- travel:setMode(mode) 设置行走模式，提供"quick", "normal", "slow"三种模式
-- ~~ quick模式：每12步停顿1秒，通过travel:setInterval(steps)修改
-- ~~ normal模式：每步短暂停留
-- ~~ slow模式：每步停留1秒，通过travel:setDelay(seconds)修改
-- travel:relocate() 重定位，必须在coroutine中调用
-- travel:walkto(roomId, action)
-- 指定目的地(roomId)行走，如果需要，先定位当前房间，action为到达后所执行函数，
-- 可包含协程方法(如wait.lua提供的time, regexp方法)
-- travel:waitUntilArrived() 如果walkto方法中传递callback方法不满足需要，
-- 提供该函数（作用类似wait.regexp），该方法yield直到到达目的地。
-- todo
-- travel:traverseUntil(roomId, range, untilCheck)
-- 指定目标房间与范围（默认每两个相邻房间距离为1），进行遍历（dfs算法），untilCheck为
-- travel:traverseEach(roomId, range, eachAction)
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
local db = dbDef.open("data/pkuxkx-gb2312.db")
local dalDef = require "pkuxkx.dal"
local dal = dalDef.open(db)
local ZonePath = require "pkuxkx.ZonePath"

local define_travel = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",  -- 停止状态
    walking = "walking",  -- 行走中
    lost = "lost",  -- 迷路了
    blocked = "blocked", -- 被阻挡
    locating = "locating",  -- 定位中
    located = "located" -- 已定位
  }

  local Events = {
    START = "start",    -- 开始信号，从停止状态开始将进入重定位，从已定位状态开始将进入行走
    STOP = "stop",    -- 停止信号，任何状态收到该信号都会转换到stop状态
    LOCATION_CONFIRMED = "location_confirmed",    -- 确定定位信息
    LOCATION_CONFIRMED_ONLY = "location_confirmed_only",    -- 仅确定定位信息
    ARRIVED = "arrived",    -- 到达目的地信号
    GET_LOST = "get_lost",    -- 迷路信号
    START_RELOCATE = "start_relocate",    -- 重新定位信号
    -- FAIL_RELOCATE = "fail_relocate",    -- 重新定位失败
    MAX_RELOC_RETRIES = "max_reloc_retries",    -- 到达重定位重试最大次数
    MAX_RELOC_MOVES = "max_reloc_moves",    -- 到达重定位移动最大步数（每次）
    ROOM_NO_EXITS = "room_no_exits",    -- 房间没有出口
    WALK_PLAN_NOT_EXISTS = "walk_plan_not_exists",    -- 行走计划无法生成
    WALK_PLAN_GENERATED = "walk_plan_generated",    -- 行走计划生成
    BOAT = "boat",    -- 乘船信号
    BUSY = "busy",    -- busy信号
    BLOCKING_SOLVED = "blocking_solved",    -- 阻塞解除信号
    TRY_RELOCATE = "try_relocate",    -- 尝试重定位
    ROOM_INFO_UNKNOWN = "room_info_unknown",    -- 没有获取到房间信息
  }
  local RELOC_MAX_RETRIES = 4    -- 重定位最多重试次数，当进入located或stop状态时重置，当进入locating时减一
  local RELOC_MAX_MOVES = 50    -- 每次重定位最大移动步数(每个房间算1步)，当进入locating状态时重置


  prototype.regexp = {
    --SET_LOCATE_START = "^[ >]*设定环境变量：locate = \"start\"$",
    --SET_LOCATE_STOP = "^[ >]*设定环境变量：locate = \"stop\"$",
    ROOM_NAME_WITH_AREA = "^[ >]{0,12}([^ ]+) \\- \\[[^ ]+\\]$",
    ROOM_NAME_WITHOUT_AREA = "^[ >]{0,12}([^ ]+) \\- $",
    ROOM_DESC = "^ {0,12}([^ ].*?) *$",
    SEASON_TIME_DESC = "^    「([^\\\\x00-\\\\xff]+?)」: (.*)$",
    EXITS_DESC = "^\\s{0,12}这里(明显|唯一)的出口是(.*)$|^\\s*这里没有任何明显的出路\\w*",
    BUSY_LOOK = "^[> ]*风景要慢慢的看。$",
    NOT_BUSY = "^[ >]*你现在不忙。$",
    LOOK_START = "^[ >]*设定环境变量：travel_look = \"start\"$",
    LOOK_DONE = "^[ >]*设定环境变量：travel_look = \"done\"$",
    ARRIVED = "^[ >]*设定环境变量：travel_walk = \"arrived\"$",
    WALK_LOST = "^[> ]*(这个方向没有出路。|你一不小心脚下踏了个空，... 啊...！|你小心翼翼往前挪动，遇到艰险难行处，只好放慢脚步。|你还在山中跋涉，一时半会恐怕走不出.*|青海湖畔美不胜收，你不由停下脚步，欣赏起了风景。|你不小心被什么东西绊了一下.*)$",
    WALK_LOST_SPECIAL = "^[ >]*泼皮一把拦住你：要向从此过，留下买路财！泼皮一把拉住了你。$",
    WALK_BLOCK = "^[> ]*你的动作还没有完成，不能移动.*$",
    WALK_BREAK = "^[ >]*设定环境变量：travel_walk = \"break\"$",
    WALK_STEP = "^[ >]*设定环境变量：travel_walk = \"step\"$",
  }
  prototype.zonesearch = Algo.dijkstra
  prototype.roomsearch = Algo.astar
  prototype.traverse = Algo.traversal

  function prototype:FSM()
    local obj = FSM:new()
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:setMode(mode)
    self.mode = mode
  end

  function prototype:setDelay(delay)
    self.delay = delay
  end

  function prototype:reset()
    -- locating
    self.currRoomId = nil
    self.currRoomName = nil
    self.targetRoomId = nil -- if target room id is nil, means locating only
    self.targetAction = nil
    self.relocMaxRetries = RELOC_MAX_RETRIES
    self.relocMaxMoves = RELOC_MAX_MOVES
    self.busyLook = false  -- used when relocating, system might tell you too busy to look around
    -- walking
    self.walkPlan = nil
    self.walkLost = false
  end

  function prototype:walkto(targetRoomId, action)
    assert(type(targetRoomId) == "number", "target room id must be number")
    assert(not action or type(action) == "function", "action must be function or nil")
    self.targetRoomId = targetRoomId
    self.targetAction = action
    self:fire(Events.START)
  end

  function prototype:reloc()
    -- 强制重定位
    self:reset()
    self:fire(Events.START)
  end

  function prototype:postConstruct()
    self:initStates()
    self:initTransitions()
    self:initZonesAndRooms()
    self:initTriggers()
    self:initAliases()
    self:setState(States.stop)
    self:reset()
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
    -- locating
      "travel_look_start",
      "travel_look_name",
      "travel_look_desc",
      "travel_look_season",
      "travel_look_exits"
    )
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        -- must clean the user defined triggers
        helper.removeTriggerGroups("travel_one_shot")
        self:disableAllTriggers()
      end,
      exit = function()

      end
    }
    self:addState {
      state = States.locating,
      enter = function()

      end,
      exit = function()
        helper.disableTriggerGroups(
          "travel_look_start",
          "travel_look_name",
          "travel_look_desc",
          "travel_look_season",
          "travel_look_exits",
          "travel_walk"
        )
      end
    }
    self:addState {
      state = States.located,
      enter = function()
        self.relocMaxRetries = RELOC_MAX_RETRIES
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

      end,
      exit = function()

      end
    }
  end

  local addTransitionToStop = function(self, fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function()
        print("停止 - 当前状态", self.currState)
      end
    }
  end

  function prototype:generateWalkPlan()
    local fromid = self.currRoomId
    local toid = self.targetRoomId
    self:debug("检验起始房间和目标房间", fromid, toid)
    local startRoom = self.roomsById[fromid]
    local endRoom = self.roomsById[toid]
    if not startRoom then
      print("当前房间不在自动行走列表中")
      return nil
    elseif not endRoom then
      print("目标房间不在自动行走列表中")
      return nil
    else
      local startZone = self.zonesByCode[startRoom.zone]
      local endZone = self.zonesByCode[endRoom.zone]
      if not startZone then
        print("当前区域不在自动行走列表中", startRoom.zone)
        return nil
      elseif not endZone then
        print("目标区域不在自动行走列表中", endRoom.zone)
        return nil
      elseif startZone == endZone then
        if self.DEBUG then
          local roomCnt = 0
          for _, room in pairs(startZone.rooms) do
            roomCnt = roomCnt + 1
          end
          print("出发地与目的地处于同一区域，共" .. roomCnt .. "个房间")
        end
        return self.roomsearch(startZone.rooms, fromid, toid)
      else
        -- zone search for shortest path
        local zoneStack = self.zonesearch {
          rooms = self.zonesById,
          startid = startZone.id,
          targetid = endZone.id
        }
        if not zoneStack then
          print("计算区域路径失败，区域 " .. startZone.name .. " 至区域 " .. endZone.name .. " 不可达")
          return false
        else
          table.insert(zoneStack, ZonePath:decorate {startid=startZone.id, endid=startZone.id, weight=0})
          local zoneCnt = #zoneStack
          local rooms = {}
          local roomCnt = 0
          while #zoneStack > 0 do
            local zonePath = table.remove(zoneStack)
            for _, room in pairs(self.zonesById[zonePath.endid].rooms) do
              rooms[room.id] = room
              roomCnt = roomCnt + 1
            end
          end
          self:debug("本次路径计算跨" .. zoneCnt .. "个区域，共" .. roomCnt .. "个房间")
          return self.roomsearch(startZone.rooms, fromid, toid)
        end
      end
    end
  end

  function prototype:initTransitions()
    -- transtions from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.locating,
      event = Events.START,
      action = function()
        self:relocate()
      end
    }
    -- transitions from state<locating>
    self:addTransition {
      oldState = States.locating,
      newState = States.located,
      event = Events.LOCATION_CONFIRMED,
      action = function()
        local walkPlan = self:generateWalkPlan()
        if not walkPlan then
          return self:fire(Events.WALK_PLAN_NOT_EXISTS)
        else
          self:debug("本次自动行走共" .. #walkPlan .. "步")
          -- this is the only place to store walk plan
          self.walkPlan = walkPlan
          return self:fire(Events.WALK_PLAN_GENERATED)
        end
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.located,
      event = Events.LOCATION_CONFIRMED_ONLY,
      action = function()
        print("完成重新定位。房间名称：", self.currRoomName, "房间编号：", self.currRoomId)
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.MAX_RELOC_RETRIES,
      action = function()

      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.MAX_RELOC_MOVES,
      action = function()

      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.ROOM_NO_EXITS,
      action = function()

      end
    }
    addTransitionToStop(self, States.locating)
    -- transitions from state<located>
    self:addTransition {
      oldState = States.located,
      newState = States.walking,
      event = Events.WALK_PLAN_GENERATED,
      action = function()
        self:walking()
      end
    }
    self:addTransition {
      oldState = States.located,
      newState = States.stop,
      event = Events.WALK_PLAN_NOT_EXISTS,
      action = function()
        print("自动行走失败！无法获取从房间" .. self.currRoomId .. "到达房间" .. self.targetRoomId .. "的行走计划")
      end
    }
    addTransitionToStop(self, States.located)
    -- transitions from state<walking>
    self:addTransition {
      oldState = States.walking,
      newState = States.located,
      event = Events.ARRIVED,
      action = function()
        self.walkPlan = nil
        self.currRoomId = self.targetRoomId
        SendNoEcho("set travel_walk arrived")  -- this is for
        if self.targetAction then
          self.targetAction()
        end
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.blocked,
      event = Events.BOAT,
      action = function()

      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.blocked,
      event = Events.BUSY,
      action = function()

      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.lost,
      event = Events.GET_LOST,
      action = function()

      end
    }
    addTransitionToStop(self, States.walking)
    -- transitions from state<blocked>
    self:addTransition {
      oldState = States.blocked,
      newState = States.walking,
      event = Events.BLOCKING_SOLVED,
      action = function()

      end
    }
    addTransitionToStop(self, States.blocked)
    -- transitions from state<lost>
    self:addTransition {
      oldState = States.lost,
      newState = States.locating,
      event = Events.TRY_RELOCATE, -- always try relocate and the retries threshold is checked when locating
      action = function()

      end
    }
    addTransitionToStop(self, States.lost)
  end

  -- 加载区域列表和房间列表
  function prototype:initZonesAndRooms()
    -- initialize zones
    local zonesById = dal:getAllZones()
    local zonePaths = dal:getAllZonePaths()
    for i = 1, #zonePaths do
      local zonePath = zonePaths[i]
      local zone = zonesById[zonePath.startid]
      if zone then
        zone:addPath(zonePath)
      end
    end
    -- create code map
    local zonesByCode = {}
    for _, zone in pairs(zonesById) do
      zonesByCode[zone.code] = zone
    end
    -- initialize rooms
    local roomsById = dal:getAllAvailableRooms()
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
    self.roomsById = roomsById
    self.roomsByCode = roomsByCode
  end

  local formatExits = function(raw)
    local exits = raw
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

  function prototype:initTriggers()

    helper.removeTriggerGroups(
      "travel_look_start",
      "travel_look_name",
      "travel_look_desc",
      "travel_look_season",
      "travel_look_exits",
      "travel_walk"
    )

    -- 初始触发
    helper.addTrigger {
      group = "travel_look_start",
      regexp = self.regexp.LOOK_START,
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
      regexp = self.regexp.ROOM_NAME_WITH_AREA,
      response = roomNameCaught,
      sequence = 15 -- lower than desc
    }
    helper.addTrigger {
      group = "travel_look_name",
      regexp = self.regexp.ROOM_NAME_WITHOUT_AREA,
      response = roomNameCaught,
      sequence = 15 -- lower than desc
    }
    -- 当频繁使用look时，系统会给出看风景的提示，此时无法获取到房间名称和描述
    helper.addTrigger {
      group = "travel_look_name",
      regexp = self.regexp.BUSY_LOOK,
      response = function()
        self:debug("BUSY_LOOK triggered")
        self:debug("频繁使用look命令不显示描述了！")
        self.busyLook = true
      end
    }
    -- 抓取房间描述
    helper.addTrigger {
      group = "travel_look_desc",
      regexp = self.regexp.ROOM_DESC,
      response = function(name, line, wildcards)
        self:debug("ROOM_DESC triggered")
        if self._roomDescInline then
          table.insert(self.currRoomDesc, wildcards[1])
        end
      end
    }
    -- 季节和时间描述
    helper.addTrigger {
      group = "travel_look_season",
      regexp = self.regexp.SEASON_TIME_DESC,
      response = function(name, line, wildcards)
        self:debug("SEASON_TIME_DESC triggered")
        if self._roomDescInline then
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
      regexp = self.regexp.EXITS_DESC,
      response = function(name, line, wildcards)
        self:debug("EXITS_DESC triggered")
        if self._roomDescInline then
          self._roomDescInline = false
          helper.disableTriggerGroups("travel_look_desc")    -- 禁止其后抓取描述
        end
        if self._roomExitsInline then
          self._roomExitsInline = false
          self.currRoomExits = formatExits(wildcards[2] or "look")
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
      regexp = self.regexp.WALK_LOST,
      response = lostWay
    }
    helper.addTrigger {
      group = "travel_walk",
      regexp = self.regexp.WALK_LOST_SPECIAL,
      response = lostWay
    }
    helper.addTrigger {
      group = "travel_walk",
      regexp = self.regexp.WALK_BLOCK,
      response = lostWay
    }
  end

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

  function prototype:initAliases()
    helper.removeAliasGroups("travel")

    helper.addAlias {
      group = "travel",
      regexp = "^loc\\s*$",
      response = function()
        print("TRAVEL自动行走指令，使用方法：")
        print("travel debug on/off", "开启/关闭调试模式，开启时将将显示所有触发器与日志信息")
        print("reloc", "重新定位直到当前房间可唯一确定")



        print("同时提供地图录入功能：")
        print("loc here", "尝试定位当前房间，捕捉当前房间信息并显示")
        print("loc <number>", "显示数据库中指定编号房间的信息")
        print("loc match <number>", "将当前房间与目标房间进行对比，输出对比情况")
        print("loc update <number>", "将当前房间的信息更新进数据库，请确保信息的正确性")
        print("loc show", "仅显示当前房间信息，不做look定位")
        print("loc guess", "通过房间名称的拼音查找类似的房间")
        print("loc mu <number>", "将当前房间与目标房间对比，如果信息匹配，则更新")
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc here$",
      response = function()
        local co = coroutine.create(function()
          self:lookUntilNotBusy()
          self:show()
        end)
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+(\\d+)$",
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
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+debug\\s+(on|off)$",
      response = function(name, line, wildcards)
        local option = wildcards[1]
        if option == "on" then
          self:debugOn()
          print("打开定位调试模式")
        elseif option == "off" then
          self:debugOff()
          print("关闭定位调试模式")
        end
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+guess\\s*$",
      response = function()
        self:guess()
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+match\\s+(\\d+)\\s*$",
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:match(targetRoomId)
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+update\\s+(\\d+)\\s*$",
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:update(targetRoomId)
      end
    }
    -- match and update
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+mu\\s+(\\d+)\\s*$",
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:match(targetRoomId, true)
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^reloc\\s*$",
      response = function()
        self:reloc()
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+show\\s*$",
      response = function()
        self:show()
      end
    }
  end

  function prototype:waitUntilArrived()
    local currCo = assert(coroutine.running(), "Must be in coroutine")
    local resumeCo = function()
      local ok, err = coroutine.resume(currCo)
      if not ok then
        ColourNote ("deeppink", "black", "Error raised in timer function (in wait module).")
        ColourNote ("darkorange", "black", debug.traceback(currCo))
        error (err)
      end -- if
    end

    helper.addOneShotTrigger {
      group = "travel_one_shot",
      regexp = self.regexp.ARRIVED,
      response = resumeCo
    }
    return coroutine.yield()
  end

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
      local potentialRooms = dal:getRoomsByName(self.currRoomName)
      if #(potentialRooms) > 1 then
        local ids = {}
        for _, room in pairs(potentialRooms) do table.insert(ids, room) end
        print("同名房间：", table.concat(room.id, ","))
      else
        print("无同名房间")
      end
    end
  end

  function prototype:showDesc(roomDesc)
    if type(roomDesc) == "string" then
      for i = 1, string.len(roomDesc), self.DESC_DISPLAY_LINE_WIDTH do
        print(string.sub(roomDesc, i, i + self.DESC_DISPLAY_LINE_WIDTH - 1))
      end
    elseif type(roomDesc) == "table" then
      for _, d in ipairs(roomDesc) do
        print(d)
      end
    end
  end

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

  local directions = {
    s="south",
    n="north",
    w="west",
    e="east",
    ne="northeast",
    se="southeast",
    sw="southwest",
    nw="northwest",
    su="southup",
    nu="northup",
    eu="eastup",
    wu="westup",
    sd="southdown",
    nd="northdown",
    wd="westdown",
    ed="eastdown",
    u="up",
    d="down"
  }
  local expandDirection = function(path)
    return directions[path] or path
  end


  function prototype:match(roomId, performUpdate)
    local performUpdate = performUpdate or false
    local room = dal:getRoomById(roomId)
    if not room then
      print("查询不到指定编号的房间：" .. roomId)
      return
    end
    -- 比较房间名称
    if not self.currRoomName then
      print("当前房间无可确定的名称，请先使用LOC定位命令捕捉")
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
      if not currExits[expandDirection(tgtPath.path)] then
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
        print("出口匹配但路径不匹配，不建议更新数据库，如需要请手动update")
      else
        print("出口匹配但路径不匹配")
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
        print("出口与路径都不匹配，不建议更新数据库，如需要请手动update")
      else
        print("出口与路径都不匹配")
      end
    end
    print(table.concat(pathDisplay, ", "))
  end

  function prototype:update(roomId)
    local room = Room:new {
      id = roomId,
      name = self.currRoomName,
      code = "",
      description = table.concat(self.currRoomDesc),
      exits = self.currRoomExits
    }
    dal:updateRoom(room)
  end


  function prototype:relocate()
    local moves = 0
    repeat
      self:lookUntilNotBusy()
      -- 尝试匹配当前房间
      if not self.currRoomName then
        if not self.currRoomExits then
          return self:fire(Events.ROOM_INFO_UNKNOWN)
        else
          -- 尝试随机游走，重新定位
          self:randomGo(self.currRoomExits)
        end
      else
        local potentialRooms = dal:getRoomsByName(self.currRoomName)
        local matched = self:matchPotentialRooms(table.concat(self.currRoomDesc), self.currRoomExits, self._potentialRooms)
        if #matched == 1 then
          self:debug("成功匹配唯一房间", matched[1])
          self.currRoomId = matched[1]
          if self.targetRoomId then
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
          self:randomGo(self.currRoomExits)
        end
      end
      wait.time(1)
      moves = moves + 1
      if self.currState == States.stop then return end
    until moves > RELOC_MAX_MOVES
    -- 重试多次仍无法定位当前房间
    return self:fire(Events.MAX_RELOC_MOVES)
  end

  function prototype:walking()
    local interval = self.interval or 12
    local restTime = self.restTime or 1
    local mode = self:getMode() or "quick"    -- the default walkto mode
    self:debug("行走模式", mode)
    local delay = self.delay or 1    -- the default walkto delay in slow mode

    local steps = 0
    while #(self.walkPlan) > 0 do
      local move = table.remove(self.walkPlan)
      -- here should be refined, the state may change
      -- due to the path
      -- evaluate the move and may be transit to other state
      if mode ~= "quick" then
        SendNoEcho("halt")
      end
      if move.category == "busy" then
        SendNoEcho(move.path)
        return self:fire(Events.BUSY)
      elseif move.category == "boat" then
        SendNoEcho(move.path)
        return self:fire(Events.BOAT)
      else
        SendNoEcho(move.path)
      end

      steps = steps + 1
      if mode == "quick" and steps >= interval then
        steps = 0
        while true do
          SendNoEcho("set travel_walk break")
          local line = wait.regexp(self.regexp.WALK_BREAK, 5)
          if not line then
            print("系统反应超时，等待5秒重试")
            wait.time(5)
          elseif self.walkLost then
            return self:fire(Events.GET_LOST)
          else
            wait.time(1)
            SendNoEcho("halt")
            break
          end
        end
      end
      if mode == "normal" then
        while true do
          SendNoEcho("set travel_walk step")
          local line = wait.regexp(self.regexp.WALK_STEP, 5)
          if not line then
            print("系统反应超时，等待5秒重试")
            wait.time(5)
          elseif self.walkLost then
            return self:fire(Events.GET_LOST)
          else
            SendNoEcho("halt")
            break
          end
        end
      elseif mode == "slow" then
        while true do
          SendNoEcho("set travel_walk step")
          local line = wait.regexp(self.regexp.WALK_STEP, 5)
          if not line then
            print("系统反应超时，等待5秒重试")
            wait.time(5)
          elseif self.walkLost then
            return self:fire(Events.GET_LOST)
          else
            wait.time(1)
            SendNoEcho("halt")
            break
          end
        end
      end
      if self.currState == States.stop then return end
    end
    return self:fire(Events.ARRIVED)
  end

  ---------------------------------------------------

  function prototype:lookUntilNotBusy()
    while true do
      helper.enableTriggerGroups("travel_look_start")
      self.busyLook = false
      SendNoEcho("set travel_look start")
      SendNoEcho("look")
      SendNoEcho("set travel_look done")
      local line = wait.regexp(self.regexp.LOOK_DONE, 3)
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

  function prototype:randomGo(currExits)
    if not currExits or currExits == "" then return nil end
    local exits = utils.split(currExits, ";")
    local exit = exits[math.random(#(exits))]
    self:debug("随机选择出口并执行重新定位", exit)
    check(SendNoEcho("halt"))
    check(SendNoEcho(exit))
  end

  function prototype:matchPotentialRooms(currRoomDesc, currRoomExits, potentialRooms)
    local matched = {}
    for i = 1, #potentialRooms do
      local room = potentialRooms[i]
      if room.exits == currRoomExits and room.description == currRoomDesc then
        table.insert(matched, room.id)
      end
    end
    return matched
  end

  return prototype
end
-- 这个功能需要等到地图完善后再开放
local travel = define_travel().FSM()
