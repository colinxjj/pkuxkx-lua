--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/4/1
-- Time: 18:03
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local status = require "pkuxkx.status"

local define_recover = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    heal = "heal",
    recover = "recover"
  }
  local Events = {
    STOP = "stop",
    HEAL = "heal",
    RECOVER = "recover",
  }
  local REGEXP = {}

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
    self.neiliThreshold = 0
    self.jingliThreshold = 0
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
    self:addState {
      state = States.heal,
      enter = function()
        helper.enableTriggerGroup("recover_heal")
      end,
      exit = function()
        helper.disableTriggerGroup("recover_heal")
      end
    }
    self:addState {
      state = States.recover,
      enter = function()
        helper.enableTriggerGroups("recover_recover")
      end,
      exit = function()
        helper.disableTriggerGroups("recover_recover")
      end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.heal,
      event = Events.HEAL,
      action = function()
        return self:doHeal()
      end
    }
  end

  function prototype:initTriggers()

  end

  function prototype:initAliases()

  end

  function prototype:addTransitionToStop(fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function()
        print("ֹͣ - ��ǰ״̬", self.currState)
      end
    }
  end

  function prototype:doHeal()
--    status:hpbrief()
--    if status.effQi < status.maxQi then
--      if status.currNeili > 100 then
--        SendNoEcho("do 2 yun heal")
--        wait.time(1)
--        return self:fire(Events.HEAL)
--      else
--        -- try find a room to sleep
--        wait.time(10)
  end

  return prototype
end
return define_recover():FSM()

