--
-- jobs.lua
-- User: zhe.jiang
-- Date: 2017/4/7
-- Desc:
-- Change:
-- 2017/4/7 - created

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"

local define_fsm = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    wait = "wait",
    dining = "dining",
    store = "store",
    equip = "equip",
    job = "job",
  }
  local Events = {
    STOP = "stop",  -- any state -> stop
    START = "start",  -- stop -> wait
    HUNGRY = "hungry",  -- wait -> dining
    FULL = "full",  -- dining -> wait
    RICH = "rich",  -- wait -> store
    POOR = "poor",  -- store -> poor
    TO_EQUIP = "to_equip", -- wait -> equip
    EQUIPPED = "equipped",  -- equip -> wait
    JOB_BEGIN = "job_begin",  -- wait -> job
    JOB_FINISH = "job_finish",  -- job -> wait
    NO_JOB_AVAILABLE = "no_job_available",  -- wait -> stop
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
  end

  function prototype:disableAllTriggers()

  end

  function prototype:initStates()

    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
        helper.enableTimerGroups("jobs_stop")
      end,
      exit = function()
        helper.disableTimerGroups("jobs_stop")
      end
    }
    self:addState {
      state = States.wait,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.dining,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.store,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.equip,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.job,
      enter = function() end,
      exit = function() end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addState {
      oldState = States.stop,
      newState = States.wait,
      event = Events.START,
      action = function()

      end
    }
  end

  function prototype:initTriggers()

  end

  function prototype:initAliases()

  end

  function prototype:initTimers()
    helper.addTimer {
      group = "jobs_stop",
      interval = 120,
      response = function()
        SendNoEcho("set jobs prevent_idle")
      end
    }
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

  return prototype
end
return define_fsm():FSM()

