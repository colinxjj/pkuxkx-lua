--
-- murong.lua
-- User: zhe.jiang
-- Date: 2017/4/20
-- Desc:
-- Change:
-- 2017/4/20 - created

local patterns = {[[

ask pu about job
你向仆人打听有关『job』的消息。
仆人说道：「壮士能为慕容世家出力，真是太好了。」
仆人叹道：家贼难防，有人偷走了少爷的信件，据传曾在以下地点附近出现，你去把它找回来吧！
你的客户端不支持MXP,请直接打开链接查看图片。
请注意，忽略验证码中的红色文字。
http://pkuxkx.net/antirobot/robot.php?filename=1492781942600002


]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

local define_murong = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    search = "search",
    kill = "kill",
    submit = "submit",
  }
  local Events = {
    STOP = "stop",  -- any status -> stop
    START = "start",  -- stop -> ask

  }
  local REGEXP = {
    ALIAS_START = "^murong\\s+start\\s*$",
    ALIAS_STOP = "^murong\\s+stop\\s*$",
    ALIAS_DEBUG = "^murong\\s+debug\\s+(on|off)\\s*$",
    ALIAS_SEARCH = "^murong\\s+search\\s+(.*?)\\s*$",
    CAPTCHA_LINK = "^(http://pkuxkx.net/antirobot.*)$",
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

    self.myId = "luar"
    self.myName = "撸啊"

    self.precondition = {
      jing = 1,
      qi = 1,
      neili = 1.5,
      jingli = 1
    }
  end

  function prototype:disableAllTriggers()

  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
        SendNoEcho("set jobs job_done")  -- jobs框架
      end,
      exit = function() end
    }
    self:addState {
      state = States.ask,
      enter = function()
        helper.enableTriggerGroups("murong_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("murong_ask_start", "murong_ask_done")
      end
    }
    self:addState {
      state = States.search,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.kill,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.submit,
      enter = function() end,
      exit = function() end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.ask,
      event = Events.START,
      action = function()
        return self:doAsk()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<ask>
    self:addTransition {
      oldState = States.ask,
      newState = States.search,
      event = Events.NEW_JOB,
      action = function()
        return self:doSearch()
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.search,
      event = Events.NEW_JOB_CAPTCHA,
      action = function()
        ColourNote("yellow", "", "需要识别验证码，请手动输入murong search <位置信息>")
        ColourNote("yellow", "", self.captchaLink)
      end
    }
  end

  function prototype:initTriggers()
    helper.removeTriggerGroup("murong_ask_start", "murong_ask_done")
    helper.addTriggerSettingsPair {
      group = "murong",
      start = "ask_start",
      done = "ask_done"
    }
    helper. addTrigger {
      group = "murong_ask_done",
      regexp = REGEXP.JOB_INFO,
      -- todo
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("murong")
    helper.addAlias {
      group = "murong",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "murong",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "murong",
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
      group = "murong",
      regexp = REGEXP.ALIAS_SEARCH,
      response = function(name, line, wildcards)
        local location = wildcards[1]
        -- todo
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

  function prototype:jiazeiId()
    return self.myId .. "'s murong jiazei"
  end

  function prototype:jiazeiRegexp()
    return "^\\s*" .. self.myName .. "发现的 慕容世家家贼.*$"
  end

  -- jobs 框架
  function prototype:doStart()
    return self:fire(Events.START)
  end

  function prototype:doCancel()
    helper.assureNotBusy()
    travel:walkto(479)
    travel:waitUntilArrived()
    wait.time(1)
    SendNoEcho("ask pu about fail")
    helper.checkUntilNotBusy()
    return self:fire(Events.STOP)
  end

  return prototype
end
return define_murong():FSM()

