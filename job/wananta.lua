--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/4/24
-- Time: 7:58
-- To change this template use File | Settings | File Templates.
--

local patterns = {[[
ask ke about 进塔
你向鹿杖客打听有关『进塔』的消息。
鹿杖客微微颔首道：“请壮士入塔！”
看起来番邦武士想杀死你！
万安塔一层
    番邦武士(Fanbang wushi)

qiao luo
你的客户端不支持MXP,请直接打开链接查看图片。
请注意，忽略验证码中的红色文字。
http://pkuxkx.net/antirobot/robot.php?filename=149300907446041

请用kouling命令回答当日万安塔的口令，如果错误，将受到一定惩罚。

kouling 花园
恭喜你，答对了口令，你可以敲锣离开了，你被允许下次进入万安塔的时间被提前了一分钟。

]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

local define_fsm = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    kill = "kill",
    recover = "recover",
  }
  local Events = {
    STOP = "stop",  -- any status -> stop
    START = "start",  -- stop -> ask
    ENTERED = "entered",  -- ask -> kill
    CAPTCHA = "captcha",  -- ask -> ask
    CLEARED = "cleared",  -- kill -> recover
    PREPARED = "prepared",  -- recover -> kill
    ABANDON = "abandon",  -- recover -> stop
  }
  local REGEXP = {
    ALIAS_START = "^wananta\\s+start\\s*$",
    ALIAS_STOP = "^wananta\\s+stop\\s*$",
    ALIAS_DEBUG = "^wananta\\s+debug\\s*(on|off)\\s*$",
    ENTERED = "^[ >]*鹿杖客微微颔首道：“请壮士入塔！”$",
  }

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
  end

  function prototype:disableAllTriggers()

  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
      end,
      exit = function() end
    }
  end

  function prototype:initTransitions()
    self:addTransition {
      oldState = States.stop,
      newState = States.ask,
      event = Events.START,
      action = function()
        return self:doAsk()
      end
    }
  end

  function prototype:initTriggers()
    helper.removeTriggerGroup("wananta_ask_start", "wananta_ask_done")
    helper.addTriggerSettingsPair {
      group = "wananta",
      start = "ask_start",
      done = "ask_done"
    }
    helper.addTrigger {
      group = "wananta_ask_done",

    }
  end

  function prototype:initAliases()

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

  function prototype:doAsk()
    helper.checkUntilNotBusy()
    travel:walkto(29)
    travel:waitUntilArrived()

    self:doPowerup()
    self.towerLevel = 1
    self.askSuccess = false
    SendNoEcho("set wananta ask_start")
    SendNoEcho("ask luzhang ke about 进塔")
    SendNoEcho("set wananta ask_done")
    helper.checkUntilNotBusy()

   end

  function prototype:doPowerup()

  end

  return prototype
end
return define_fsm():FSM()

