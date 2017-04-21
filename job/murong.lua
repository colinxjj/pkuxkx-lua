--
-- murong.lua
-- User: zhe.jiang
-- Date: 2017/4/20
-- Desc:
-- Change:
-- 2017/4/20 - created

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
    ALIAS_LOCATION = "^murong\\s+location\\s+(.*?)\\s*$",
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
      regexp = REGEXP.ALIAS_LOCATION,
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
    return self.myId .. "'s jiazei"
  end

  function prototype:jiazeiRegexp()
    return "^\\s*" .. self.myName .. "发现的慕容世家家贼.*$"
  end

  return prototype
end
return define_murong():FSM()

