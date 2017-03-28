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
    ONBOARD = "^[ >]*(艄公把踏脚板收起来.*|船夫把踏脚板收起来.*|小舟在湖中藕菱之间的水路.*|你跃上小舟，船就划了起来。.*|你拿起船桨用力划了起来。.*)$",
    BLOCKED_BY_BOATMAN = "^[ >]*艄公一把拉住你，.*",
    BOAT_ARRIVED = "^[> ]*(艄公说“到啦，上岸吧”.*|船夫对你说道：“到了.*|你朝船夫挥了挥手.*|小舟终于划到近岸.*|.*你跨上岸去。.*|不知过了多久，船终于靠岸了，你累得满头大汗。.*)$",
    -- BOAT_ARRIVED = "^[ >]*(你终于来到了对面，心里的石头终于落地.*|突然间蓬一声，屁股撞上了什么物事，.*|你终于一步步的终于挨到了桥头.*)$",
    BOAT_COMING = "^[ >]*(一叶扁舟缓缓地驶了过来，艄公将一块踏脚板.*|岸边一只渡船上的老艄公说道：正等着你.*)$",
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
        self:debug("等待3秒后招呼船家")
        wait.time(3)
        return self:doWait()
      end
    }
    self:addTransition {
      oldState = States.wait,
      newState = States.stop,
      event = Events.NOT_ENOUGH_MONEY,
      action = function()
        ColourNote("red", "", "没有足够的钱，无法乘船")
      end
    }
    self:addTransition {
      oldState = States.wait,
      newState = States.onboard,
      event = Events.ONBOARD,
      action = function()
        self:debug("等待前往对岸")
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
        print("停止 - 当前状态", self.currState)
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