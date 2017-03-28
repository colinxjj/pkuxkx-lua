--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/24
-- Time: 17:55
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"

local define_boat = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    wait = "wait",
    onboard = "onboard",
    arrived = "arrived"
  }
  local Events = {
    STOP = "stop",
    START = "start",
    BOAT_COMING = "boat_coming",
    NOT_ENOUGH_MONEY = "not_enough_money",
    ONBOARD = "onboard",
    BOAT_ARRIVED = "boat_arrived",
  }
  local REGEXP = {
    ONBOARD = "^[ >]*(������̤�Ű�������.*|�����̤�Ű�������.*|С���ں���ź��֮���ˮ·.*|��Ծ��С�ۣ����ͻ���������.*|�����𴬽���������������.*)$",
    BLOCKED_BY_BOATMAN = "^[ >]*����һ����ס�㣬.*",
    BOAT_ARRIVED = "^[> ]*(����˵���������ϰ��ɡ�.*|�������˵����������.*|�㳯������˻���.*|С�����ڻ�������.*|.*����ϰ�ȥ��.*|��֪���˶�ã������ڿ����ˣ����۵���ͷ�󺹡�.*)$",
    -- BOAT_ARRIVED = "^[ >]*(�����������˶��棬�����ʯͷ�������.*|ͻȻ����һ����ƨ��ײ����ʲô���£�.*|������һ���������ڰ�������ͷ.*)$",
    BOAT_COMING = "^[ >]*(һҶ���ۻ�����ʻ�˹�����������һ��̤�Ű�.*|����һֻ�ɴ��ϵ�������˵������������.*)$",
  }

  function prototype:FSM()
    local obj = FSM:new()
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:restart(waitCmd)
    if not waitCmd then
      self.waitCmd = "yell boat"
    else
      self.waitCmd = waitCmd
    end
    self:fire(Events.STOP)
    return self:fire(Events.START)
  end

  function prototype:waitUntilArrived(timer)
    local currCo = assert(coroutine.running(), "Must be in coroutine")
    local waitPattern = helper.settingRegexp("boat", "arrived")
    if timer then
      -- timer means we need to check the status periodically
      local interval = assert(timer.interval, "interval of timer cannot be nil")
      local check = assert(type(timer.check) == "function", "check of timer must be function")
      while true do
        local line = wait.regexp(waitPattern, interval)
        if line then break end
        if check() then break end
      end
    else
      -- no timer, so just schedule a one-shot trigger without timeout
      local resumeCo = function()
        local ok, err = coroutine.resume(currCo)
        if not ok then
          ColourNote ("deeppink", "black", "Error raised in timer function (in wait module).")
          ColourNote ("darkorange", "black", debug.traceback(currCo))
          error (err)
        end -- if
      end
      helper.addOneShotTrigger {
        group = "boat_one_shot",
        regexp = waitPattern,
        response = resumeCo
      }
      return coroutine.yield()
    end
  end

  function prototype:postConstruct()
    self:initStates()
    self:initTransitions()
    self:initTriggers()
    self:initAliases()
    self:setState(States.stop)
    self:resetOnStop()
  end

  function prototype:resetOnStop()
    self.boatComing = false
    self.noMoney = false
    self.waitCmd = "yell boat"
    helper.removeTriggerGroups("boat_one_shot")
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:resetOnStop()
      end,
      exit = function() end
    }
    self:addState {
      state = States.wait,
      enter = function()
        self.boatComing = false
        self.noMoney = false
        helper.enableTriggerGroups(
          "boat_wait_start",
          "boat_enter_start")
      end,
      exit = function()
        helper.disableTriggerGroups(
          "boat_wait_start",
          "boat_wait_done",
          "boat_enter_start",
          "boat_enter_done")
      end
    }
    self:addState {
      state = States.onboard,
      enter = function()
        helper.enableTriggerGroups("boat_onboard")
      end,
      exit = function()
        helper.disableTriggerGroups("boat_onboard")
      end
    }
    self:addState {
      state = States.arrived,
      enter =function() end,
      exit = function() end
    }
  end

  function prototype:initTransitions()
    -- transitions form state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.wait,
      event = Events.START,
      action = function()
        return self:doWait()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transitions from state<wait>
    self:addTransition {
      oldState = States.wait,
      newState = States.wait,
      event = Events.START,
      action = function()
        self:debug("�ȴ�3����к�����")
        wait.time(3)
        return self:doWait()
      end
    }
    self:addTransition {
      oldState = States.wait,
      newState = States.stop,
      event = Events.NOT_ENOUGH_MONEY,
      action = function()
        ColourNote("red", "", "û���㹻��Ǯ���޷��˴�")
      end
    }
    self:addTransition {
      oldState = States.wait,
      newState = States.onboard,
      event = Events.ONBOARD,
      action = function()
        self:debug("�ȴ�ǰ���԰�")
      end
    }
    self:addTransitionToStop(States.wait)
    -- transitions from state<onboard>
    self:addTransition {
      oldState = States.onboard,
      newState = States.arrived,
      event = Events.BOAT_ARRIVED,
      action = function()
        self:doLeave()
      end
    }
    self:addTransitionToStop(States.onboard)
    -- transitions from state<arrived>
    self:addTransitionToStop(States.arrived)
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

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "boat_wait_start",
      "boat_wait_done",
      "boat_enter_start",
      "boat_enter_done",
      "boat_onboard",
      "boat_one_shot"
    )
    helper.addTrigger {
      group = "boat_wait_start",
      regexp = helper.settingRegexp("boat", "wait_start"),
      response = function()
        helper.enableTriggerGroups("boat_wait_done")
      end
    }
    helper.addTrigger {
      group = "boat_wait_done",
      regexp = helper.settingRegexp("boat", "wait_done"),
      response = function()
        self:debug("WAIT_DONE triggered", "boatComing?", self.boatComing)
        helper.disableTriggerGroups("boat_wait_done")
        if self.boatComing then
          return self:doEnter()
        else
          return self:fire(Events.START)
        end
      end
    }
    helper.addTrigger {
      group = "boat_wait_done",
      regexp = REGEXP.BOAT_COMING,
      response = function()
        self:debug("BOAT_COMING triggered")
        self.boatComing = true
      end
    }
    helper.addTrigger {
      group = "boat_enter_start",
      regexp = helper.settingRegexp("boat", "enter_start"),
      response = function()
        helper.enableTriggerGroups("boat_enter_done")
      end
    }
    helper.addTrigger {
      group = "boat_enter_done",
      regexp = helper.settingRegexp("boat", "enter_done"),
      response = function()
        if self.noMoney then
          return self:fire(Events.NOT_ENOUGH_MONEY)
        else
          return self:fire(Events.ONBOARD)
        end
      end
    }
    helper.addTrigger {
      group = "boat_enter_done",
      regexp = REGEXP.BLOCKED_BY_BOATMAN,
      response = function()
        self.noMoney = true
      end
    }
    helper.addTrigger {
      group = "boat_onboard",
      regexp = REGEXP.BOAT_ARRIVED,
      response = function()
        self:debug("BOAT_ARRIVED triggered")
        return self:fire(Events.BOAT_ARRIVED)
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("boat")

    helper.addAlias {
      group = "boat",
      regexp = "^boat\\s+start\\s*(.*)$",
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if not cmd or cmd == "" then
          return self:restart("yell boat")
        else
          return self:restart(cmd)
        end
      end
    }
    helper.addAlias {
      group = "boat",
      regexp = "^boat\\s+stop\\s*",
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "boat",
      regexp = "^boat\\s+debug\\s+(on|off)\\s*$",
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self:debugOn()
        else
          self:debugOff()
        end
      end
    }
  end

  function prototype:doWait()
    SendNoEcho("set boat wait_start")
    SendNoEcho(self.waitCmd)
    SendNoEcho("set boat wait_done")
  end

  function prototype:doEnter()
    helper.assureNotBusy()
    SendNoEcho("set boat enter_start")
    SendNoEcho("enter")
    SendNoEcho("set boat enter_done")
  end

  function prototype:doLeave()
    helper.assureNotBusy()
    SendNoEcho("out")
    SendNoEcho("set boat arrived")
  end

  return prototype
end

return define_boat():FSM()