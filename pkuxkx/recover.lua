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
    STOP = "stop",  -- stop
    START = "start",  -- stop -> heal
    RECOVER = "recover",  -- heal -> recover
    ENOUGH = "enough",  -- recover -> heal
    GOOD = "good",  --> heal -> stop
    FORBIDDEN = "forbidden",  --> heal, recover -> stop
  }
  local REGEXP = {
    ALIAS_START = "^recover\\s+start\\s*$",
    ALIAS_STOP = "^recover\\s+stop\\s*$",
    ALIAS_DEBUG = "^recover\\s+debug\\s+(on|off)\\s*$",
    TUNA_FINISH = "^[ >]*你吐纳完毕，睁开双眼，站了起来。$",
    DAZUO_FINISH = "^[ >]*你运功完毕，深深吸了口气，站了起来。$",
    NOT_ENOUGH_JING = "^[ >]*(你现在精不足，无法修行精力.*|你现在精严重不足，无法满足吐纳最小要求。|你现在精不够，无法控制内息的流动！)$",
    NOT_ENOUGH_QI = "^[ >]*(你现在的气太少了，无法产生内息运行全身经脉.*|你现在气血严重不足，无法满足打坐最小要求。|你现在身体状况太差了，无法集中精神！)$",
    JINGLI_MAX = "^[ >]*你现在精力接近圆满状态。$",
    NEILI_MAX = "^[ >]*你现在内力接近圆满状态。$",
    RECOVER_FORBIDDEN = "^[ >]*(中央广场，禁止刷屏|对不起，武庙你只能老实呆着|对不起，比武场中请不要练功).*$",
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

    self.jingUpperBound = 1
    self.jingLowerBound = 0.9
    self.qiUpperBound = 1
    self.qiLowerBound = 0.9
    self.neiliThreshold = 1
    self.jingliThreshold = 1
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
        helper.enableTriggerGroups("recover_heal")
      end,
      exit = function()
        helper.disableTriggerGroups("recover_heal")
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
      event = Events.START,
      action = function()
        return self:doHeal()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<heal>
    self:addTransition {
      oldState = States.heal,
      newState = States.recover,
      event = Events.RECOVER,
      action = function()
        return self:doRecover()
      end
    }
    self:addTransition {
      oldState = States.heal,
      newState = States.stop,
      event = Events.GOOD,
      action = function()
        SendNoEcho("set recover recovered") -- used for callback
      end
    }
    self:addTransition {
      oldState = States.heal,
      newState = States.stop,
      event = Events.FORBIDDEN,
      action = function()
        SendNoEcho("set recover recovered")
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<recover>
    self:addTransition {
      oldState = States.recover,
      newState = States.heal,
      event = Events.ENOUGH,
      action = function()
        return self:doHeal()
      end
    }
    self:addTransition {
      oldState = States.recover,
      newState = States.stop,
      event = Events.FORBIDDEN,
      action = function()
        SendNoEcho("set recover recovered")
      end
    }
    self:addTransitionToStop(States.recover)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("recover_heal", "recover_recover")
    helper.addTrigger {
      group = "recover_recover",
      regexp = REGEXP.TUNA_FINISH,
      response = function()
        return self:doRecover()
      end
    }
    helper.addTrigger {
      group = "recover_recover",
      regexp = REGEXP.DAZUO_FINISH,
      response = function()
        return self:doRecover()
      end
    }
    helper.addTrigger {
      group = "recover_recover",
      regexp = REGEXP.NOT_ENOUGH_JING,
      response = function()
        SendNoEcho("yun regenerate")
        wait.time(1)
        return self:doRecover()
      end
    }
    helper.addTrigger {
      group = "recover_recover",
      regexp = REGEXP.NOT_ENOUGH_QI,
      response = function()
        SendNoEcho("yun recover")
        wait.time(1)
        return self:doRecover()
      end
    }
    helper.addTrigger {
      group = "recover_recover",
      regexp = REGEXP.RECOVER_FORBIDDEN,
      response = function()
        return self:fire(Events.FORBIDDEN)
      end
    }
  end

  function prototype:initAliases()
    helper.removeTriggerGroups("recover")
    helper.addAlias {
      group = "recover",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "recover",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        SendNoEcho("halt")
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "recover",
      regexp = REGEXP.ALIAS_DEBUG,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          return self:debugOn()
        else
          return self:debugOff()
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

  function prototype:doHeal()
    status:hpbrief()
    local useNeili = false
    if status.currQi < status.effQi * 0.8 then
      SendNoEcho("yun recover")
      useNeili = true
    end
    if status.currJing < status.effJing * 0.8 then
      SendNoEcho("yun regenerate")
      useNeili = true
    end
    if status.effQi < status.maxQi * self.qiLowerBound then
      while status.effQi < status.maxQi * self.qiUpperBound do
        SendNoEcho("do 2 yun heal")
        wait.time(1)
        status:hpbrief()
      end
      useNeili = true
    end
    if status.effJing < status.maxJing * self.jingLowerBound then
      while status.effJing < status.maxJing * self.jingUpperBound do
        SendNoEcho("yun inspire")
        wait.time(1)
        helper.checkUntilNotBusy()
        status:hpbrief()
      end
      useNeili = true
    end
    if useNeili then
      status:hpbrief()
    end
    if status.effJing >= status.maxJing * self.jingLowerBound
      and status.effQi >= status.maxQi * self.qiLowerBound
      and status.currNeili >= status.maxNeili * self.neiliThreshold
      and status.currJingli >= status.maxJingli * self.jingliThreshold then
      return self:fire(Events.GOOD)
    else
      return self:fire(Events.RECOVER)
    end
  end

  function prototype:doRecover()
    status:hpbrief()
    local neiliDiff = status.maxNeili * self.neiliThreshold - status.currNeili
    local jingliDiff = status.maxJingli * self.jingliThreshold - status.currJingli
    if neiliDiff > 0 then
      local maxDiff = status.maxNeili * 2 - status.currNeili
      local halfQi = math.floor(status.currQi / 2)
      if halfQi < maxDiff then
        SendNoEcho("dazuo " .. halfQi)
      else
        SendNoEcho("dazuo max")
      end
    elseif jingliDiff > 0 then
      local halfJing = math.floor(status.currJing / 2)
      if halfJing < jingliDiff then
        SendNoEcho("tuna " .. halfJing)
      else
        if jingliDiff < 10 then
          jingliDiff = 10
        end
        SendNoEcho("tuna " .. jingliDiff)
      end
    else
      return self:fire(Events.ENOUGH)
    end
  end

  function prototype:start()
    return self:fire(Events.START)
  end

  function prototype:settings(args)
    assert(args, "args settings cannot be nil")
    if args.jingUpperBound then
      self.jingUpperBound = self:limit(args.jingUpperBound, 0.7, 1)
    end
    if args.jingLowerBound then
      self.jingLowerBound = self:limit(args.jingLowerBound, 0.7, 1)
    end
    if args.qiUpperBound then
      self.qiUpperBound = self:limit(args.qiUpperBound, 0.7, 1)
    end
    if args.qiLowerBound then
      self.qiLowerBound = self:limit(args.qiLowerBound, 0.7, 1)
    end
    if args.neiliThreshold then
      self.neiliThreshold = self:limit(args.neiliThreshold, 0.5, 1.95)
    end
    if args.jingliThreshold then
      self.jingliThreshold = self:limit(args.jingliThreshold, 0.5, 1.95)
    end
  end

  function prototype:limit(input, lowerBound, upperBound)
    if input > upperBound then
      return upperBound
    elseif input < lowerBound then
      return lowerBound
    else
      return input
    end
  end

  function prototype:waitUntilRecovered()
    local currCo = assert(coroutine.running(), "Must be in coroutine")
    helper.addOneShotTrigger {
      group = "recover_one_shot",
      regexp = helper.settingRegexp("recover", "recovered"),
      response = helper.resumeCoRunnable(currCo)
    }
    return coroutine.yield()
  end

  return prototype
end
return define_recover():FSM()

