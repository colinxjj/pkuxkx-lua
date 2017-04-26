--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/30
-- Time: 10:28
-- To change this template use File | Settings | File Templates.
--
-- learn with help from kknd music recovery

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local status = require "pkuxkx.status"
local travel = require "pkuxkx.travel"

local define_kkndlearn = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    wait = "wait",
    dining = "dining"
  }
  local Events = {
    STOP = "stop",
    START = "start",
    HUNGRY = "hungry",
    FULL = "full"
  }
  local REGEXP = {
    TUNA_FINISH = "^[ >]*你吐纳完毕，睁开双眼，站了起来。$",
    DAZUO_FINISH = "^[ >]*你运功完毕，深深吸了口气，站了起来。$",
    NOT_ENOUGH_JING = "^[ >]*你现在精不足，无法修行精力.*$",
    NOT_ENOUGH_JING_DAZUO = "^[ >]*你现在精不够，无法控制内息的流动！$",
    JINGLI_MAX = "^[ >]*你现在精力接近圆满状态。$",
    NOT_ENOUGH_QI = "^[ >]*(你现在的气太少了，无法产生内息运行全身经脉.*|你现在气血严重不足，无法满足打坐最小要求。)$",
    NEILI_MAX = "^[ >]*你现在内力接近圆满状态。$",
  }
  
  local KkndRoomId = 1305

  function prototype:new()
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
    self.learnCmd = nil
    self.lianCmd = nil
    self.tunaCmd = nil
    self.dazuoCmd = nil
    self.requireNeili = false
    self.notEnoughJing = false
    self.notEnoughQi = false
    self.jingliMax = false
    self.neiliMax = false
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups("kkndlearn_wait")
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
      state = States.wait,
      enter = function()
        helper.enableTriggerGroups("kkndlearn_wait")
      end,
      exit = function()
        helper.disableTriggerGroups("kkndlearn_wait")
      end
    }
    self:addState {
      state = States.dining,
      enter = function() end,
      exit = function() end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.wait,
      event = Events.START,
      action = function()
        travel:walkto(KkndRoomId, function()
          helper.assureNotBusy()
          SendNoEcho("follow kknd")
          self:doWait()
        end)
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<wait>
    self:addTransition {
      oldState = States.wait,
      newState = States.dining,
      event = Events.HUNGRY,
      action = function()
        travel:walkto(3797, function()
          helper.assureNotBusy()
          SendNoEcho("do 2 eat")
          SendNoEcho("do 2 drink")
          helper.assureNotBusy()
          return travel:walkto(KkndRoomId, function()
            return self:fire(Events.FULL)
          end)
        end)
      end
    }
    self:addTransitionToStop(States.wait)
    -- transition from state<dining>
    self:addTransition {
      oldState = States.dining,
      newState = States.wait,
      event = Events.FULL,
      action = function()
        return self:doWait()
      end
    }
    self:addTransitionToStop(States.dining)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("kkndlearn_wait")

    helper.addTrigger {
      group = "kkndlearn_wait",
      regexp = REGEXP.NOT_ENOUGH_JING,
      response = function(name, line, wildcards)
        self.notEnoughJing = true
        wait.time(5)
        return self:doWait()
      end
    }
    helper.addTrigger {
      group = "kkndlearn_wait",
      regexp = REGEXP.TUNA_FINISH,
      response = function()
        self.notEnoughJing = false
        return self:doWait()
      end
    }
    helper.addTrigger {
      group = "kkndlearn_wait",
      regexp = REGEXP.JINGLI_MAX,
      response = function()
        SendNoEcho("tuna 10")
      end
    }
    helper.addTrigger {
      group = "kkndlearn_wait",
      regexp = REGEXP.NOT_ENOUGH_QI,
      response = function(name, line, wildcards)
        self.notEnoughQi = true
        wait.time(5)
        return self:doWait()
      end
    }
    helper.addTrigger {
      group = "kkndlearn_wait",
      regexp = REGEXP.NOT_ENOUGH_JING_DAZUO,
      response = function(name, line, wildcards)
        wait.time(5)
        return self:doWait()
      end
    }
    helper.addTrigger {
      group = "kkndlearn_wait",
      regexp = REGEXP.DAZUO_FINISH,
      response = function()
        self.notEnoughQi = false
        return self:doWait()
      end
    }
    helper.addTrigger {
      group = "kkndlearn_wait",
      regexp = REGEXP.NEILI_MAX,
      response = function()
        SendNoEcho("dazuo 10")
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("kkndlearn")
    helper.addAlias {
      group = "kkndlearn",
      regexp = "^kkndlearn\\s+start\\s*$",
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "kkndlearn",
      regexp = "^kkndlearn\\s+stop\\s*$",
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "kkndlearn",
      regexp = "^kkndlearn\\s+learn\\s+(.*?)\\s*$",
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        self:debug("set learn command to:", cmd)
        self.learnCmd = cmd
        self.tunaCmd = nil
        self.dazuoCmd = nil
      end
    }
    helper.addAlias {
      group = "kkndlearn",
      regexp = "^kkndlearn\\s+lian\\s+(.*?)\\s*$",
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        self:debug("set lian command to:", cmd)
        self.lianCmd = cmd
        self.tunaCmd = nil
        self.dazuoCmd = nil
      end
    }
    helper.addAlias {
      group = "kkndlearn",
      regexp = "^kkndlearn\\s+debug\\s+(on|off)\\s*$",
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
      group = "kkndlearn",
      regexp = "^kkndlearn\\s+(tuna|dazuo)\\s*$",
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "tuna" then
          self.tunaCmd = "tuna max"
          self.dazuoCmd = nil
          self.learnCmd = nil
          self.lianCmd = nil
        elseif cmd == "dazuo" then
          self.dazuoCmd = "dazuo max"
          self.tunaCmd = nil
          self.learnCmd = nil
          self.lianCmd = nil
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

  -- learn/tuna/dazuo
  -- tuna,dazuo do not need loop, will recurisvely called via trigger
  function prototype:doWait()
    local cnt = 0
    while self.currState == States.wait do
      cnt = cnt + 1
      status:hpbrief()
      if status.food < 100 or status.drink < 100 then
        return self:fire(Events.HUNGRY)
      end
      if self.tunaCmd then  -- tuna mode
        SendNoEcho(self.tunaCmd)
        return
      elseif self.dazuoCmd then  -- dazuo mode
        SendNoEcho(self.dazuoCmd)
        return
      else  -- learn mode
        if status.currNeili < 100 and status.maxNeili > 2000 then
          self.requireNeili = true
        elseif status.currNeili >= 1000 then
          self.requireNeili = false
        end
        wait.time(1)
        if status.currJing == status.maxJing then
          SendNoEcho(self.learnCmd)
          status:hpbrief()
        elseif self.requireNeili then
          SendNoEcho("dazuo 300")
          return
--          wait.regexp(REGEXP.DAZUO_FINISH, 6)
        end
        if status.currJing > 200 and self.learnCmd then
          SendNoEcho(self.learnCmd)
        end
        --          if status.currQi > 50 and self.lianCmd then
        --            SendNoEcho(self.lianCmd)
        --          end
        if status.currQi > 200 then
          SendNoEcho("lian dodge 5")
--          SendNoEcho("wield jian")
          SendNoEcho("jifa sword kuangfeng-kuaijian")
          SendNoEcho("lian sword 5")
          SendNoEcho("jifa sword huashan-jianfa")
          SendNoEcho("lian sword 5")
--          SendNoEcho("unwield jian")
          SendNoEcho("jifa sword yangwu-jian")
          SendNoEcho("lian sword 5")
        end
      end
    end
  end

  return prototype
end
return define_kkndlearn():new()
