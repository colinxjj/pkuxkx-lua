----------------------------------------
-- 对护镖做重新设计，不参与jobs框架
-- 对行走模块有重要影响，屏蔽特殊区域
-- 设计思路：
-- 因为护镖全过程中也在不断战斗，所以使用战斗模块进行战斗
-- 行走模块也根据护镖需求进行改写
--
----------------------------------------

-- 增加全局屏蔽区域
ExcludedBlockZones = {
  "dali", "emei", "jiaxing",
  "lingjiu", "lingzhou", "mingjiao",
  "pingxiwangfu", "riyue",
  "shaolin", "tiantan",
  "wudang", "xihu",
  "xingxiu"
}
ExcludedZones = {
  "gaibang",
  "miaoling"
}
local travel = require "pkuxkx.travel"

local patterns = {[[
一片浓雾中，什么也看不清。

]]}

local ZonePath = require "pkuxkx.ZonePath"
local RoomPath = require "pkuxkx.RoomPath"
local PathCategory = RoomPath.Category
local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local status = require "pkuxkx.status"
local recover = require "pkuxkx.recover"
local combat = require "pkuxkx.combat"
-- enable combat by default
coroutine.wrap(function() combat:start() end)()
local captcha = require "pkuxkx.captcha"

local define_hubiao = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",  -- 终止状态，与jobs模块整合，提供waitDone触发
    prepare = "prepare",  -- 准备任务，查看任务
    prefetch = "prefetch",  -- 预先前往查找目的地
    transfer = "transfer",  -- 运输中
    lost = "lost",  -- 迷路中（很大可能被强盗推至相邻房间）
    submit = "submit",  -- 提交
    mixin = "mixin",  -- 密信
  }
  local Events = {
    STOP = "stop",  -- 任何状态下停止
    START = "start",  -- stop -> prepare
    NO_JOB_AVAILABLE = "no_job_available",  -- prepare -> stop
    ACCEPT_SUCCESS = "accept_success",  -- prepare -> prefetch
    ACCEPT_FAIL = "accept_fail",  -- prepare -> prepare
    NEXT_PREFETCH = "next_prefetch",  -- prefetch -> prefetch
    PREFETCH_SUCCESS = "prefetch_success",  -- prefetch -> transfer
    TRANSFER_STEP = "transfer_step",  -- transfer -> step
    STEP_SUCCESS = "step_success",  -- 行走一步成功 transfer -> transfer
    STEP_FAIL = "step_fail",  -- 行走一步失败 transfer -> transfer
    GET_LOST = "get_lost",  -- 迷路 transfer -> lost
    RELOCATED = "relocated",  -- 重定位成功 lost -> transfer
    TRANSFER_SUCCESS = "transfer_success",  -- 运输成功 transfer -> submit
    MIXIN_FOUND = "mixin_found",  -- 发现密信 submit -> mixin
    CONTINUE = "continue",  -- submit -> prepare
  }
  local REGEXP = {
    ALIAS_START = "^hubiao\\s+start\\s*$",
    ALIAS_STOP = "^hubiao\\s+stop\\s*$",
    ALIAS_DEBUG = "^hubiao\\s+debug\\s+(on|off)\\s*$",
    ALIAS_MIXIN = "^hubiao\\s+mixin\\s+(.*?)\\s*$",
    JOB_INFO = "^(\\d+)\\s+(.*?)\\s+(\\d+)秒\\s+(.*?)\\s+(.*)$",
    ACCEPT_INFO = "^.*把这批红货送到(.*?)那里，他已经派了个伙计名叫(.*?)到(.*?)附近接你，把镖车送到他那里就行了。$",
    ACCEPT_FAIL = "^[ >]*认领任务失败，请选择其他任务。$",
    TRANSFER_SUCCESS = "^[ >]*你累了个半死，终于把镖运到了地头。$",
    ROBBER_MOVE = "^[ >]*劫匪趁你不注意，推着镖车就跑，你赶紧追了上去。$",
    TRANSFER_BUSY = "^[ >]*(劫匪伸手一拦道：“想跑？没那么容易！”|你还是先把对手解决了再说吧！|你现在正忙着哩。|镖车还没有跟上来呢,走慢点.*)$",
    STEP_SUCCESS = "^[ >]*你赶着镖车驶了过来。$",
    REWARDED = "^[ >]*你一共被奖励了：$",
    MIXIN_DESC = "^[ >]*这是一张.*?给你的密信，需要用特殊的药水才能显形\\(xian\\)。$",
    MIXIN_NPC_DISPLAY = "^[ >]*\\s*卷走.*?财物的伙计 .*?\\((.*?)\\)$",
    MIXIN_NPC_FOUND = "^[ >]*一个伙计挖着鼻屎走了出来，道：你找我啥事？$",
    MIXIN_YAO_SUCCESS = "^[ >]*.*把一包财物砸向你，一转眼不见了。$",
    POWERUP_EXPIRE = "^[ >]*你的(紫霞神功|华山内功)运行完毕，将内力收回丹田。$",
    POWERUP_ENABLE = "^[ >]*(你运起紫霞神功，脸上紫气若隐若现绵如云霞。|你暗运华山内功，提升自己的战斗力。|你已经在运功中了。)$",
    QI_EXPIRE = "^[ >]*你减缓真气运行，让气血运行恢复正常。$",
    QI_ENABLE = "^[ >]*(你运行真气加速自身的气血恢复。|你已经运行内功加速全身气血恢复。)$",
    ROBBER_ESCAPE = "^[ >]*劫匪叫道：点子扎手，扯呼！$",
    ROBBER_APPEAR = "^[ >]*劫匪突然从暗处跳了出来，阴笑道：“红货和人命都留下来吧！。”$",
    ROBBER_ASSIST = "^[ >]*劫匪大喊：点子爪子硬！赶紧来帮忙！$",
    -- ROBBER_ASKED = "^[ >]*你向劫匪打听有关『去死』的消息。$",
    ROBBER_CHECKED = helper.settingRegexp("hubiao", "check_robber"),
    ROBBER_NOT_EXISTS = "^[ >]*这里没有这个人。$",
    WEAPON_REMOVED = "^[ >]*(.*卸除了你的兵器.*|该兵器现在还无法装备。)$",
    WEAPON_WIELDED = "^[ >]*(你已经装备著了。|你从陈旧的剑鞘中拔出一把玄铁剑握在手中。)$",
    WEAPON_ID = "^\\( *(\\d+)\\)(.*?)\\([a-zA-Z0-9_ ]*\\) *可塑性:.*伤害力:.*$",
    WEAPON_DURABILITY = "^ *耐久度:(\\d+)/(\\d+)",
    GARBAGE = "^[ >]*你获得了.*份(石炭|玄冰|陨铁)【.*?】。$",
    GRADUATED = "^[ >]*你已经在新手镖局获得足够经验了，快到大城市去闯荡一番吧。$",
    PFM_NOT_IN_COMBAT = "^[ >]*(.*?只能对战斗中的对手使用。|未有对手或者你和对方未处于战斗中，不能使用.*)$",
    HEAL_IN_COMBAT = "^[ >]* 战斗中运功疗伤？找死吗？$",
    BOAT_ARRIVED = "^[> ]*(艄公说“到啦，上岸吧”.*|船夫对你说道：“到了.*|你朝船夫挥了挥手.*|小舟终于划到近岸.*|.*你跨上岸去。.*|一个番僧用沙哑的声音道：“大轮寺到啦，出来吧。”，.*|藤筐离地面越来越近，终于腾的一声着了地，众人都吁了口长气.*)$",
    BOAT_FORCED_DEPART = "^[ >]*艄公要继续做生意了，所有人被赶下了渡船。$",
    BOAT_OFFSHORE = "^[ >]*(艄公把踏脚板收起来.*|船夫把踏脚板收起来.*|小舟在湖中藕菱之间的水路.*|你跃上小舟，船就划了起来。.*|你拿起船桨用力划了起来。.*|番僧用力一推，将藤筐推离平台，绞盘跟着慢慢放松，藤筐一荡，降了下去。|绳索一紧，藤筐左右摇晃振动了几下，冉冉向上升了起来。)$",
  }

  local SpecialRenameRooms = {
    ["嘉兴钱庄"] = "嘉兴嘉兴钱庄",
    ["泉州当铺"] = "泉州泉州当铺",
    ["建康府车马行"] = "建康府计氏马车分行",
    ["岳阳车马行"] = "岳阳计氏马车分行",
  }
  local ExcludedJobRooms = {
    ["峨嵋毗卢殿"] = true
  }

  local SpecialRelocateRooms = {
    ["嘉兴"] = {
      -- 明州金鸡亭
      ["金鸡亭"] = 785,
      -- 苏州南门
      ["南门"] = 494,
    },
    ["建康府"] = {
      ["长江渡口"] = 864
    },
    ["岳阳"] = {
      ["长江岸边"] = 1095
    }
  }

  -- 福州福威镖局
--  local StartRoomId = 26
--  local JobNpcId = "lin"
  -- 苏州镖局
  local StartRoomId = 456
  local JobNpcId = "zuo"
  local PrefetchDepth = 5
  local DoubleSearchDepth = 3
  local WeaponFixRoomId = 2167

  function prototype:FSM()
    local obj = FSM:new()
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self:initStates()
    self:initTransitions()
    self:initTriggers()
    self:initAliases()
    self:setState(States.stop)
    self.maxRounds = 10
    self.rounds = 0
    -- special variable
    self.playerName = "撸啊"
    self.playerId = "luar"
    self.robbersPresent = 0
    self.qiPresent = false
    self.powerupPresent = false
    self.jingUpperBound = 1
    self.jingLowerBound = 0.9
    self.qiUpperBound = 1
    self.qiLowerBound = 0.9
    self.neiliUpperBound = 1.8
    self.neiliLowerBound = 1
    self.jingliUpperBound = 1.2
    self.jingliLowerBound = 1
    -- 乱入数
    self.robberMoves = 0
    -- 乘船状态
    self.boatStatus = "yelling"
    -- 武器
    self.weaponName = "百合 追日之剑"
    self.weaponId = nil
    self.needWield = true
    self.wieldCmd = "wield sword"
    self.weaponDurability = 500
    -- 开启调试
    self:debugOn()
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
      "hubiao_info_start", "hubiao_info_done",
      "hubiao_accept_start", "hubiao_accept_done",
      "hubiao_step_start", "hubiao_step_done",
      "hubiao_submit_start", "hubiao_submit_done",
      "hubiao_mixin_start", "hubiao_mixin_done",
      "hubiao_transfer",
      "hubiao_robber",
      "hubiao_force")
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
        helper.removeTriggerGroups("hubiao_prefetch_traverse", "hubiao_transfer_traverse")
        SendNoEcho("set jobs job_done")  -- 为jobs提供结束触发
      end,
      exit = function()
        helper.enableTriggerGroups("hubiao_robber", "hubiao_force")
      end
    }
    self:addState {
      state = States.prepare,
      enter = function()
        helper.enableTriggerGroups(
          "hubiao_info_start", "hubiao_accept_start",
          "hubiao_weapon_id_start", "hubiao_weapon_dura_start")
      end,
      exit = function()
        helper.disableTriggerGroups(
          "hubiao_info_start", "hubiao_info_done",
          "hubiao_accept_start", "hubiao_accept_done",
          "hubiao_weapon_id_start", "hubiao_weapon_id_done",
          "hubiao_weapon_dura_start", "hubiao_weapon_dura_done")
      end
    }
    self:addState {
      state = States.prefetch,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.transfer,
      enter = function()
        helper.enableTriggerGroups(
          "hubiao_step_start",
          "hubiao_transfer")
      end,
      exit = function()
        helper.disableTriggerGroups(
          "hubiao_step_start", "hubiao_step_done",
          "hubiao_transfer")
      end
    }
    self:addState {
      state = States.submit,
      enter = function()
        helper.enableTriggerGroups("hubiao_submit_start", "hubiao_mixin_start")
      end,
      exit = function()
        helper.enableTriggerGroups("hubiao_submit_start", "hubiao_submit_done",
          "hubiao_mixin_start", "hubiao_mixin_done")
      end
    }
    self:addState {
      state = States.lost,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.mixin,
      enter = function() end,
      exit = function() end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.prepare,
      event = Events.START,
      action = function()
        return self:doGetJob()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<prepare>
    self:addTransition {
      oldState = States.prepare,
      newState = States.prepare,
      event = Events.ACCEPT_FAIL,
      action = function()
        self:debug("等待3秒后重新接任务")
        wait.time(3)
        return self:doGetJob()
      end
    }
    self:addTransition {
      oldState = States.prepare,
      newState = States.prefetch,
      event = Events.ACCEPT_SUCCESS,
      action = function()
        self:debug("等待3秒后开始预取")
        wait.time(3)
        self.transferVisitedRoomIds = {}
        return self:doConfirmSearchRooms()
      end
    }
    self:addTransition {
      oldState = States.prepare,
      newState = States.prepare,
      event = Events.NO_JOB_AVAILABLE,
      action = function()
        self:debug("目前无可用任务，等待5秒后继续询问")
        wait.time(5)
        return self:doGetJob()
      end
    }
    self:addTransitionToStop(States.prepare)
    -- transition from state<prefetch>
    self:addTransition {
      oldState = States.prefetch,
      newState = States.prefetch,
      event = Events.NEXT_PREFETCH,
      action = function()
        return self:doPrefetch()
      end
    }
    self:addTransition {
      oldState = States.prefetch,
      newState = States.transfer,
      event = Events.PREFETCH_SUCCESS,
      action = function()
        -- back to start
        travel:walkto(StartRoomId)
        travel:waitUntilArrived()
        self:debug("等待2秒后进行运送")
        wait.time(2)
        return self:doPrepareTransfer()
      end
    }
    self:addTransitionToStop(States.prefetch)
    -- transition from state<transfer>
    self:addTransition {
      oldState = States.transfer,
      newState = States.transfer,
      event = Events.STEP_SUCCESS,
      action = function()
        -- 设置下一步的路径为当前路径
        if #(self.transferPlan) > 0 then
          -- 乘船处理
          if self.currStep and self.currStep.category == PathCategory.boat then
            -- 乘船前
            if self.boatStatus == "yelling" then
              self:debug("登船成功，等待5秒后尝试离船")
              self.boatStatus = "boating"
              wait.time(5)
              return self:doStep()
            -- 乘船中
            elseif self.boatStatus == "boating" then
              self:debug("在boating情况下不应当行走成功，程序存在漏洞")
              wait.time(2)
              return self:doStep()
            elseif self.boatStatus == "leaving" then
              self:debug("离船成功")
              self.boatStatus = "yelling"
              self.currStep = table.remove(self.transferPlan)
              return self:doStep()
            end
          else
            self.currStep = table.remove(self.transferPlan)
            return self:doStep()
          end
        else
          ColourNote("yellow", "", "已走完全部路径")
          wait.time(4)
          helper.checkUntilNotBusy()
          if self.transferSuccess then
            self:debug("镖已送到，返回提交任务")
            return self:doSubmit()
          else
            ColourNote("red", "", "没有找到伙计，任务失败！")
            return self:doCancel()
          end
        end
      end
    }
    self:addTransition {
      oldState = States.transfer,
      newState = States.transfer,
      event = Events.STEP_FAIL,
      action = function()
        -- 失败时不更新当前路径，重试
        return self:doStep()
      end
    }
    self:addTransition {
      oldState = States.transfer,
      newState = States.lost,
      event = Events.GET_LOST,
      action = function()
        return self:doRelocate()
      end
    }
    self:addTransition {
      oldState = States.transfer,
      newState = States.submit,
      event = Events.TRANSFER_SUCCESS,
      action = function()
        local tick = 0 -- 超过12 tick认为无匪了
        while true do
          helper.checkUntilNotBusy()
          if tick <= 12 and self.robbersPresent > 0 then
            tick = tick + 1
            wait.time(3)
          else
            break
          end
        end
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.transfer)
    -- transition from state<lost>
    self:addTransition {
      oldState = States.lost,
      newState = States.transfer,
      event = Events.RELOCATED,
      action = function()
        return self:doPrepareTransfer()
      end
    }
    self:addTransitionToStop(States.lost)
    -- transition from state<submit>
    self:addTransition {
      oldState = States.submit,
      newState = States.mixin,
      event = Events.MIXIN_FOUND,
      action = function()
        ColourNote("yellow", "", "发现密信，请手动输入密信地点hubiao mixin <地点>")
      end
    }
    self:addTransition {
      oldState = States.submit,
      newState = States.prepare,
      event = Events.CONTINUE,
      action = function()
        self:debug("等待3秒后领取新任务")
        wait.time(3)
        return self:doGetJob()
      end
    }
    self:addTransitionToStop(States.submit)
    -- transition from state<mixin>
    self:addTransition {
      oldState = States.mixin,
      newState = States.prepare,
      event = Events.CONTINUE,
      action = function()
        self:debug("等待3秒后领取新任务")
        wait.time(3)
        return self:doGetJob()
      end
    }
    self:addTransitionToStop(States.mixin)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "hubiao_info_start", "hubiao_info_done",
      "hubiao_accept_start", "hubiao_accept_done",
      "hubiao_step_start", "hubiao_step_done",
      "hubiao_submit_start", "hubiao_submit_done",
      "hubiao_mixin_start", "hubiao_mixin_done",
      "hubiao_transfer",
      "hubiao_robber",
      "hubiao_force"
    )
    -- info
    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "info_start",
      done = "info_done"
    }
    helper.addTrigger {
      group = "hubiao_info_done",
      regexp = REGEXP.JOB_INFO,
      response = function(name, line, wildcards)
        self:debug("JOB_INFO triggered")
        local jobId = wildcards[1]
        local jobLocation = wildcards[2]
        local jobRemainedTime = wildcards[3]
        local jobStatus = wildcards[4]
        local jobPlayer = wildcards[5]
        if jobStatus == "待认领" and not ExcludedJobRooms[jobLocation] then
          table.insert(self.jobs, {id = jobId, location = SpecialRenameRooms[jobLocation] or jobLocation})
        end
      end
    }
    -- accept
    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "accept_start",
      done = "accept_done"
    }
    helper.addTrigger {
      group = "hubiao_accept_done",
      regexp = REGEXP.ACCEPT_FAIL,
      response = function()
        self:debug("ACCEPT_FAIL triggered")
      end
    }
    helper.addTrigger {
      group = "hubiao_accept_done",
      regexp = REGEXP.ACCEPT_INFO,
      response = function(name, line, wildcards)
        self.acceptSuccess = true
        self.employer = wildcards[1]
        self.dudeName = wildcards[2]
        self.searchRoomName = wildcards[3]
      end
    }
    -- weapon
    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "weapon_id_start",
      done = "weapon_id_done",
    }
    helper.addTrigger {
      group = "hubiao_weapon_id_done",
      regexp = REGEXP.WEAPON_ID,
      response = function(name, line, wildcards)
        self:debug("WEAPON_ID triggered")
        print(wildcards[1])
        print(wildcards[2])
        local weaponId = tonumber(wildcards[1])
        local weaponName = wildcards[2]
        if string.find(weaponName, self.weaponName) then
          self.weaponId = "sword " .. weaponId
          self.wieldCmd = "wield " .. self.weaponId
          if string.find(weaponName, "(装)") then
            self.needWield = false
          else
            self.needWield = true
          end
        end
      end
    }
    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "weapon_dura_start",
      done = "weapon_dura_done",
    }
    helper.addTrigger {
      group = "hubiao_weapon_dura_done",
      regexp = REGEXP.WEAPON_DURABILITY,
      response = function(name, line, wildcards)
        self.weaponDurability = tonumber(wildcards[1])
      end
    }

    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "weapon_dura_start",
      done = "weapon_dura_done"
    }
    -- step
    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "step_start",
      done = "step_done"
    }
    -- 行走成功
    helper.addTrigger {
      group = "hubiao_step_done",
      regexp = REGEXP.STEP_SUCCESS,
      response = function()
        self.stepSuccess = true
        -- 重置匪徒数为0
        self.robbersPresent = 0
        if self.currStep then
          -- 在触发车子行走时设置运输房间编号
          self.transferRoomId = self.currStep.endid
          self:debug("设置运输房间编号为", self.currStep.endid)
        end
      end
    }
    -- submit
    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "submit_start",
      done = "submit_done"
    }
    helper.addTrigger {
      group = "hubiao_submit_done",
      regexp = REGEXP.REWARDED,
      response = function()
        self.submitSuccess = true
        self:debug("任务完成，获得奖励")
      end
    }
    helper.addTrigger {
      group = "hubiao_submit_done",
      regexp = REGEXP.GARBAGE,
      response = function(name, line, wildcards)
        local item = wildcards[1]
        if item == "石炭" then
          SendNoEcho("drop shi tan")
        elseif item == "玄冰" then
          SendNoEcho("drop xuan bing")
        elseif item == "陨铁" then
          SendNoEcho("drop yun tie")
        end
      end
    }
    -- mixin
    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "mixin_start",
      done = "mixin_done"
    }
    helper.addTrigger {
      group = "hubiao_mixin_done",
      regexp = REGEXP.MIXIN_DESC,
      response = function()
        self.findMixin = true
      end
    }
    -- transfer
    helper.addTrigger {
      group = "hubiao_transfer",
      regexp = REGEXP.TRANSFER_SUCCESS,
      response = function()
        self.transferSuccess = true
      end
    }
    helper.addTrigger {
      group = "hubiao_transfer",
      regexp = REGEXP.ROBBER_MOVE,
      response = function()
--        self.transferLost = true
        self.robberMoves = self.robberMoves + 1
      end
    }
    helper.addTrigger {
      group = "hubiao_transfer",
      regexp = REGEXP.WEAPON_REMOVED,
      response = function()
        self.weaponRemoved = true
      end
    }
    helper.addTrigger {
      group = "hubiao_transfer",
      regexp = REGEXP.WEAPON_WIELDED,
      response = function()
        self.weaponRemoved = false
      end
    }
    helper.addTrigger {
      group = "hubiao_transfer",
      regexp = REGEXP.ROBBER_NOT_EXISTS,
      response = function()
        self.robberExists = false
      end
    }
    helper.addTrigger {
      group = "hubiao_transfer",
      regexp = REGEXP.BOAT_FORCED_DEPART,
      response = function()
        if self.currStep.category == PathCategory.boat and self.boatStatus == "boating" then
          self:debug("乘船中，被赶下船，去除当前步并重置乘船状态")
          self.boatStatus = "yelling"
          self.currStep = table.remove(self.transferPlan)
        end
      end
    }
    helper.addTrigger {
      group = "hubiao_transfer",
      regexp = REGEXP.BOAT_OFFSHORE,
      response = function()
        self:debug("BOAT_OFFSHORE triggered")
        if self.boatStatus == "boating" then
          self:debug("船离岸，尝试离开船")
          self.boatStatus = "leaving"
        end
      end
    }
    -- robber
    helper.addTrigger {
      group = "hubiao_robber",
      regexp = REGEXP.ROBBER_APPEAR,
      response = function()
        self.robbersPresent = self.robbersPresent + 1
        self:debug("当前匪徒数：", self.robbersPresent)
      end
    }
    helper.addTrigger {
      group = "hubiao_robber",
      regexp = REGEXP.ROBBER_ASSIST,
      response = function()
        self.robbersPresent = self.robbersPresent + 1
        self:debug("当前匪徒数：", self.robbersPresent)
      end
    }
    helper.addTrigger {
      group = "hubiao_robber",
      regexp = REGEXP.ROBBER_ESCAPE,
      response = function()
        self.robbersPresent = self.robbersPresent - 1
        self:debug("当前匪徒数：", self.robbersPresent)
      end
    }
    -- force
    helper.addTrigger {
      group = "hubiao_force",
      regexp = REGEXP.POWERUP_EXPIRE,
      response = function()
        self:debug("powerup过期，需要重新运功")
        self.powerupPresent = false
      end
    }
    helper.addTrigger {
      group = "hubiao_force",
      regexp = REGEXP.QI_EXPIRE,
      response = function()
        self:debug("qi过期，需要重新运功")
        self.qiPresent = false
      end
    }
    helper.addTrigger {
      group = "hubiao_force",
      regexp = REGEXP.POWERUP_ENABLE,
      response = function()
        self.powerupPresent = true
      end
    }
    helper.addTrigger {
      group = "hubiao_force",
      regexp = REGEXP.QI_ENABLE,
      response = function()
        self.qiPresent = true
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("hubiao")
    helper.addAlias {
      group = "hubiao",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "hubiao",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "hubiao",
      regexp = REGEXP.ALIAS_DEBUG,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self:debugOn()
        else
          self:debugOff()
        end
      end
    }
    helper.addAlias {
      group = "hubiao",
      regexp = REGEXP.ALIAS_MIXIN,
      response = function(name, line, wildcards)
        local location = wildcards[1]
        local rooms = travel:getMatchedRooms {
          fullname = location
        }
        if #(rooms) == 0 then
          ColourNote("red", "", "房间查询不到或不可达 " .. location)
        else
          self.mixinRoomId = rooms[1].id
          travel:walkto(self.mixinRoomId)
          travel:waitUntilArrived()
          self:debug("等待2秒后开始执行密信任务")
          wait.time(2)
          while true do
            SendNoEcho("zhao")
            local line = wait.regexp(REGEXP.MIXIN_NPC_FOUND, 5)
            if line then break end
          end

          self.mixinNpcId = nil
          helper.addOneShotTrigger {
            group = "hubiao_mixin_one_shot",
            regexp = REGEXP.MIXIN_NPC_DISPLAY,
            response = function(name, line, wildcards)
              self.mixinNpcId = string.lower(wildcards[1])
            end
          }
          travel:lookUntilNotBusy()  --
          helper.removeTriggerGroups("hubiao_mixin_one_shot")
          while true do
            SendNoEcho("ask " .. self.mixinNpcId .. " about yao")
            local line = wait.regexp(REGEXP.MIXIN_YAO_SUCCESS, 5)
            if line then break end
          end
          self:debug("获得财物，返回")
          wait.time(2)
          helper.checkUntilNotBusy()
          return self:doSubmitCaiwu()
        end
      end
    }
  end

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

  function prototype:doStart()
    return self:fire(Events.START)
  end

  function prototype:doSubmitCaiwu()
    travel:stop()
    travel:walkto(StartRoomId)
    travel:waitUntilArrived()
    helper.checkUntilNotBusy()
    SendNoEcho("give cai wu to " .. JobNpcId)
--    return self:fire(Events.STOP)
    return self:fire(Events.CONTINUE)
  end

  function prototype:doGetJob()
    -- 检查武器
    self.weaponId = nil
    self.wieldCmd = nil
    self.needWield = false
    SendNoEcho("set hubiao weapon_id_start")
    SendNoEcho("i sword")
    SendNoEcho("set hubiao weapon_id_done")
    helper.checkUntilNotBusy()
    if not self.weaponId then
      error("武器检查失败")
    end
    if self.needWield then
      SendNoEcho("unwield all")
      SendNoEcho(self.wieldCmd)
    end

    SendNoEcho("set hubiao weapon_dura_start")
    SendNoEcho("look " .. self.weaponId)
    SendNoEcho("set hubiao weapon_dura_done")
    helper.checkUntilNotBusy()
    if self.weaponDurability <= 100 then
      travel:walkto(WeaponFixRoomId)
      travel:waitUntilArrived()
      wait.time(1)
      SendNoEcho("fix " .. self.weaponId)
      wait.time(1)
    end
    travel:walkto(StartRoomId)
    travel:waitUntilArrived()
    self:debug(
      "恢复设置 精" .. self.jingLowerBound .. "/" .. self.jingUpperBound ..
      ", 气" .. self.qiLowerBound .. "/" .. self.qiUpperBound ..
      ", 内力" .. self.neiliLowerBound .. "/" .. self.neiliUpperBound ..
      ", 精力" .. self.jingliLowerBound .. "/" .. self.jingliUpperBound)
    -- 任务前恢复设置，使用恢复上限
    recover:settings {
      jingLowerBound = self.jingUpperBound,
      jingUpperBound = self.jingUpperBound,
      qiLowerBound = self.qiUpperBound,
      qiUpperBound = self.qiUpperBound,
      neiliThreshold = self.neiliUpperBound,
      jingliThreshold = self.jingliUpperBound,
    }
    recover:start()
    recover:waitUntilRecovered()
    -- 任务中恢复设置，使用恢复下限
    recover:settings {
      jingLowerBound = self.jingLowerBound,
      jingUpperBound = self.jingUpperBound,
      qiLowerBound = self.qiLowerBound,
      qiUpperBound = self.qiUpperBound,
      neiliThreshold = self.neiliLowerBound,
      jingliThreshold = self.jingliLowerBound,
    }
    self:debug("等待1秒后查询任务")
    wait.time(1)
    self.jobs = {}
    SendNoEcho("set hubiao info_start")
    SendNoEcho("listesc")
    SendNoEcho("set hubiao info_done")
    -- 等待两秒接任务
    wait.time(2)
    helper.assureNotBusy()
    if #(self.jobs) > 0 then
      return self:doAcceptJob()
    else
      return self:fire(Events.NO_JOB_AVAILABLE)
    end
  end

  function prototype:doAcceptJob()
    -- 设置当前任务
    local _, job = next(self.jobs)
    self.currJob = job
    self.acceptSuccess = false
    self.employer = nil
    self.dudeName = nil
    self.searchRoomName = nil
    SendNoEcho("set hubiao accept_start")
    SendNoEcho("getesc " .. self.currJob.id)
    SendNoEcho("set hubiao accept_done")
    helper.assureNotBusy()
    if self.acceptSuccess then
      return self:fire(Events.ACCEPT_SUCCESS)
    else
      return self:fire(Events.ACCEPT_FAIL)
    end
  end

  function prototype:doConfirmSearchRooms()
    local targets = travel:getMatchedRooms {
      fullname = self.currJob.location
    }
    if #(targets) == 0 then
      self:debug("运镖区域不可达，等待2秒后结束")
      wait.time(2)
      return self:doCancel()
    else
      local zone = targets[1].zone
      local searchRooms = {}
      local rooms = travel.zonesByCode[zone].rooms
      for _, room in pairs(rooms) do
        if room.name == self.searchRoomName then
          table.insert(searchRooms, room)
        end
      end
      if #(searchRooms) == 0 then
        ColourNote("yellow", "", "伙计所在地点不可达", zone, self.searchRoomName, "无法执行预取，等待2秒后结束")
        self:debug("尝试特殊定位房间")
        local zoneName = travel.zonesByCode[zone].name
        local relocZone = SpecialRelocateRooms[zoneName]
        local specialRelocateId
        if relocZone then
          specialRelocateId = relocZone[self.searchRoomName]
        end
        -- local specialRelocateId = SpecialRelocateRooms[self.searchRoomName]
        if not specialRelocateId then
          ColourNote("red", "", "无法执行预取，取消该任务")
          wait.time(2)
          return self:doCancel()
        end
        ColourNote("green", "", "特殊房间匹配，重新定位至房间：" .. specialRelocateId)
        table.insert(searchRooms, travel.roomsById[specialRelocateId])
      elseif #(searchRooms) == 1 then
        self.targetRoomId = searchRooms[1].id
        self:debug("目标房间仅有1个，略过预取，直接运输，房间编号：", self.targetRoomId)
        wait.time(1)
        return self:fire(Events.PREFETCH_SUCCESS)
      end
      self.searchedRoomIds = {}
      self.searchRooms = searchRooms
      return self:fire(Events.NEXT_PREFETCH)
    end
  end

  function prototype:doPrefetch()
    if #(self.searchRooms) > 0 then
      local searchStartRoom = table.remove(self.searchRooms)
      if self.searchedRoomIds[searchStartRoom.id] then
        self:debug("房间已搜索过，跳过", searchStartRoom.id)
        return self:doPrefetch()
      else
        helper.assureNotBusy()
        travel:walkto(searchStartRoom.id)
        travel:waitUntilArrived()
        self:debug("到达搜索起始地点", searchStartRoom.id)
        self:debug("开始遍历，深度为", PrefetchDepth, "寻找伙计名为：", self.dudeName)

        self.targetRoomId = nil
        helper.addTrigger {
          group = "hubiao_prefetch_traverse",
          regexp = self:dudeNameRegexp(),
          response = function()
            --找到伙计，则设置目标地点为当前房间编号
            self:debug("发现伙计", self.dudeName)
            self.targetRoomId = travel.traverseRoomId
          end
        }
        helper.enableTriggerGroups("hubiao_prefetch_traverse")
        local onStep = function()
          return self.targetRoomId ~= nil  -- 停止条件，找到伙计
        end
        local onArrive = function()
          helper.removeTriggerGroups("hubiao_prefetch_traverse")
          if self.targetRoomId then
            self:debug("遍历结束，已经发现伙计，并确定目标房间：", self.targetRoomId)
            return self:fire(Events.PREFETCH_SUCCESS)
          else
            self:debug("没有发现伙计，尝试下一个地点")
            wait.time(1)
            return self:fire(Events.NEXT_PREFETCH)
          end
        end
        return travel:traverseNearby(PrefetchDepth, onStep, onArrive)
      end
    else
      self:debug("没有更多的搜索房间，预取失败，放弃该任务")
      wait.time(2)
      return self:doCancel()
    end
  end

  function prototype:dudeNameRegexp()
    return "^\\s*「店铺伙计」" .. self.dudeName .. "\\(.*?\\)$";
  end

  function prototype:doCancel()
    -- for debug purpose
    ColourNote("red", "", "调试模式不进行任务取消，请手动完成后再重新加载")
--    helper.assureNotBusy()
--    travel:stop()
--    travel:walkto(StartRoomId)
--    travel:waitUntilArrived()
--    helper.assureNotBusy()
--    SendNoEcho("ask " .. JobNpcId .. " about fail")
--    return self:fire(Events.STOP)
  end

  function prototype:doPrepareTransfer()
    local walkPlan = travel:generateWalkPlan(travel.currRoomId, self.targetRoomId)
    if not walkPlan then
      ColourNote("red", "", "计算直达路径失败，放弃该任务")
      return self:doCancel()
    end
    local traversePlan = travel:generateNearbyTraversePlan(self.targetRoomId, DoubleSearchDepth, true)
    if not traversePlan then
      ColourNote("red", "", "计算搜索路径失败，放弃该任务")
      return self:doCancel()
    end
    -- 合并两个行走计划栈，注意顺序
    local transferPlan = {}
    for _, path in ipairs(traversePlan) do
      table.insert(transferPlan, path)
    end
    for _, path in ipairs(walkPlan) do
      table.insert(transferPlan, path)
    end
    self.transferRoomId = travel.currRoomId
    self.transferPlan = transferPlan
    -- self.transferLost = false
    self.robberMoves = 0
    self.findDude = false
    self.transferSuccess = false
    helper.removeTriggerGroups("hubiao_transfer_traverse")
    -- 找到伙计触发
    helper.addTrigger {
      group = "hubiao_transfer_traverse",
      regexp = self:dudeNameRegexp(),
      response = function()
        self:debug("DUDE_NAME triggered")
        self.findDude = true
      end
    }
    helper.enableTriggerGroups("hubiao_transfer_traverse")
    -- 最初时装备和运功
    self.powerupPresent = false
    self.qiPresent = false
    SendNoEcho("wield sword")
    return self:fire(Events.STEP_SUCCESS)
  end

  function prototype:doStep()
    while true do
      self.robberExists = true
      SendNoEcho("ask " .. self.playerId .. "'s robber about 去死")
      SendNoEcho("set hubiao check_robber")
      local line = wait.regexp(REGEXP.ROBBER_CHECKED, 2)
      if not line then
        self:debug("系统超时，重试")
        wait.time(5)
      else
        break
      end
    end
    self:debug("劫匪存在：", self.robberExists)
    if self.robberExists then
      wait.time(3)
      return self:fire(Events.STEP_FAIL)
    else
      helper.checkUntilNotBusy()
      helper.assureNotBusy(6)
      -- 不存在，检查气血并恢复
      recover:start()
      recover:waitUntilRecovered()
      -- 尝试行走
      self:debug("当前行走方向", self.currStep.path)
      self.stepSuccess = false
      if not self.powerupPresent then
        SendNoEcho("yun powerup")
      end

      -- 先判断是否迷路
      if self.robberMoves > 0 then
        return self:fire(Events.GET_LOST)
      end

      SendNoEcho("set hubiao step_start")
      if self.currStep.category == PathCategory.normal then
        local direction, isExpanded = helper.expandDirection(self.currStep.path)
        if isExpanded then
          SendNoEcho("gan che to " .. direction)
        else
          ColourNote("red", "", "护镖不支持特殊路径" .. self.currStep.path)
          return self:doCancel()
        end
      elseif self.currStep.category == PathCategory.multiple then
        -- self:sendPath(move.path)
        local cmds = utils.split(self.currStep.path, ";")
        if #cmds == 2 then
          local direction, isExpanded = helper.expandDirection(cmds[2])
          if isExpanded then
            SendNoEcho(cmds[1])
            SendNoEcho("gan che to " .. direction)
          else
            ColourNote("yellow", "", "护镖不支持多命令路径" .. self.currStep.path)
            return self:doCancel()
          end
        else
          ColourNote("yellow", "", "护镖不支持多命令路径" .. self.currStep.path)
          return self:doCancel()
        end
      elseif self.currStep.category == PathCategory.busy then
        local direction, isExpanded = helper.expandDirection(self.currStep.path)
        if isExpanded then
          SendNoEcho("gan che to " .. direction)
        else
          ColourNote("red", "", "护镖不支持特殊路径" .. self.currStep.path)
          return self:doCancel()
        end
      elseif self.currStep.category == PathCategory.boat then
        self:debug("boatStatus?", self.boatStatus)
        if self.boatStatus == "yelling" then
          -- 叫船
          SendNoEcho(self.currStep.path)
          SendNoEcho("gan che to enter")
        elseif self.boatStatus == "boating" then
          self:debug("尚未开船，等待")
        elseif self.boatStatus == "leaving" then
          SendNoEcho("gan che to out")
        else
          error("Unexpected boat status")
        end
      elseif self.currStep.category == PathCategory.pause then
        ColourNote("red", "", "护镖不支持pause路径")
        return self:doCancel()
      elseif self.currStep.category == PathCategory.block then
        ColourNote("red", "", "护镖不支持block路径")
        return self:doCancel()
      else
        error("current version does not support this path category:" .. self.currStep.category, 2)
      end
      SendNoEcho("set hubiao step_done")
      wait.time(2)
      helper.checkUntilNotBusy()
      self:debug("行走一步，是否成功", self.stepSuccess)
      if self.transferSuccess then
        self:debug("运镖已成功，准备返回")
        wait.time(2)
        helper.checkUntilNotBusy()
        return self:fire(Events.TRANSFER_SUCCESS)
      elseif self.stepSuccess then
        return self:fire(Events.STEP_SUCCESS)
      else
        return self:fire(Events.STEP_FAIL)
      end
    end
  end

  function prototype:doRelocate()
    wait.time(2)
    helper.checkUntilNotBusy()
    self:debug("重定位：获取最近房间并匹配，当前乱入个数：", self.robberMoves)
    -- 获取最近一格房间
    local rooms1 = travel:getNearbyRooms(self.transferRoomId, self.robberMoves)
    if self.DEBUG then
      local roomIds = helper.copyKeys(rooms1)
      print("最近1格房间列表：", table.concat(roomIds, ","))
    end
    self:debug("获取当前房间信息")
    travel:lookUntilNotBusy()
    local currRoomName = travel.currRoomName
    local currRoomDesc = table.concat(travel.currRoomDesc)
    local currRoomExits = travel.currRoomExits
    self:debug(currRoomName)
    self:debug(currRoomDesc)
    self:debug(currRoomExits)
    local matchedRooms = {}
    for _, room in pairs(rooms1) do
      if currRoomName == room.name
        and currRoomDesc == room.description
        and travel:checkExitsIdentical(currRoomExits, room.exits)
        and (self.transferRoomId ~= room.id or self.robberMoves > 1)
      then
        table.insert(matchedRooms, room)
      end
    end
    if #(matchedRooms) > 1 then
      -- 添加对区域信息的匹配，增加匹配的可能
      local zoneCode = travel.roomsById[self.transferRoomId].zone
      self:debug("发现多个房间匹配，尝试增加区域匹配", zoneCode)
      local matchedRoomsWithZone = {}
      for _, room in ipairs(matchedRooms) do
        if room.zone == zoneCode then
          table.insert(matchedRoomsWithZone, room)
        end
      end
      if #matchedRoomsWithZone == 0 then
        ColourNote("red", "", "不存在同区域房间匹配，放弃任务")
        return self:doCancel()
      elseif #matchedRoomsWithZone > 1 then
        ColourNote("red", "", "存在同区域多个房间匹配，放弃任务")
        return self:doCancel()
      else
        ColourNote("yellow", "", "匹配到同区域唯一房间，重新计算")
        travel.currRoomId = matchedRoomsWithZone[1].id
        travel:refreshRoomInfo()
        self.transferRoomId = travel.currRoomId
        return self:fire(Events.RELOCATED)
      end
    elseif #(matchedRooms) == 1 then
      ColourNote("green", "", "已匹配唯一房间，重新计算运输计划")
      travel.currRoomId = matchedRooms[1].id
      travel:refreshRoomInfo()
      self.transferRoomId = travel.currRoomId
      return self:fire(Events.RELOCATED)
    else
      ColourNote("red", "", "无房间可匹配，放弃该任务")
      return self:doCancel()
    end
  end

  function prototype:doSubmit()
    travel:stop()
    travel:walkto(StartRoomId)
    travel:waitUntilArrived()
    self.submitSuccess = false
    SendNoEcho("set hubiao submit_start")
    SendNoEcho("ask " .. JobNpcId .. " about finish")
    SendNoEcho("set hubiao submit_done")
    wait.time(2)
    helper.checkUntilNotBusy()
    if self.submitSuccess then
      self.rounds = self.rounds + 1
      self:debug("已成功完成" .. self.rounds .. "轮护镖")
      if self.rounds > self.maxRounds then
        self:debug("已超过最大运镖轮次上限，重置任务")
        SendNoEcho("ask " .. JobNpcId .. " about 重置任务")
        self.rounds = 0
      end
      self.findMixin = false
      SendNoEcho("set hubiao mixin_start")
      SendNoEcho("look mixin")
      SendNoEcho("set hubiao mixin_done")
      wait.time(2)
      helper.checkUntilNotBusy()
      if self.findMixin then
        return self:fire(Events.MIXIN_FOUND)
      else
        self:debug("成功完成一轮任务")
        return self:fire(Events.CONTINUE)
      end
    else
      self:debug("任务提交不成功，取消之")
      return self:doCancel()
    end
  end

  return prototype
end
return define_hubiao():FSM()

