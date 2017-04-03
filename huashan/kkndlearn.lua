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

local define_fsm = function()
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
  }

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
    self.tunaNum = 0
    self.dazuoCmd = nil
    self.dazuoNum = 0
    self.requireNeili = true
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
      state = States.wait,
      enter = function() end,
      exit = function() end
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
        travel:walkto(1304, function()
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
          return travel:walkto(1304, function()
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
      regexp = "^kkndlearn\\s+(tuna|dazuo)\\s+(\\d+)\\s*$",
      response = function(name, line, wildcards)
        local cmd, num = wildcards[1], wildcards[2]
        if cmd == "tuna" then
          self.tunaCmd = "tuna " .. num
          self.tunaNum = tonumber(num)
          self.dazuoCmd = nil
          self.learnCmd = nil
          self.lianCmd = nil
        elseif cmd == "dazuo" then
          self.dazuoCmd = "dazuo " .. num
          self.dazuoNum = tonumber(num)
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
  function prototype:doWait()
    local cnt = 0
    while self.currState == States.wait do
      cnt = cnt + 1
      wait.time(1)
      status:hpbrief()
      if status.food < 100 or status.drink < 100 then
        return self:fire(Events.HUNGRY)
      end
      if self.tunaCmd then  -- tuna mode
        if status.currJing < self.tunaNum + 10 then
          SendNoEcho("yun regenerate")
          status:hpbrief()
        end
        -- 计算吐纳值
        local tunaNum = status.maxJingli * 2 - status.currJingli
        if tunaNum < self.tunaNum then
          SendNoEcho("tuna " .. math.max(10, tunaNum))
        else
          SendNoEcho(self.tunaCmd)
        end
        wait.regexp(REGEXP.TUNA_FINISH, 6)
      elseif self.dazuoCmd then  -- dazuo mode
        local dazuoNum = status.maxNeili * 2 - status.currNeili
        if dazuoNum < self.dazuoNum then
          SendNoEcho("dazuo " .. math.max(10, dazuoNum))
        else
          SendNoEcho(self.dazuoCmd)
        end
        wait.regexp(REGEXP.DAZUO_FINISH, 6)
      else  -- learn mode
--        if cnt % 10 == 0 and self.lianCmd then
--          SendNoEcho("yun qi")
--        end
        if status.currNeili < 100 then
          self.requireNeili = true
        elseif status.currNeili >= status.maxNeili then
          self.requireNeili = false
        end

        if self.requireNeili then
          SendNoEcho("dazuo 150")
          wait.regexp(REGEXP.DAZUO_FINISH, 6)
        else
          if status.currJing > 50 and self.learnCmd then
            SendNoEcho(self.learnCmd)
          end
          if status.currQi > 50 and self.lianCmd then
            SendNoEcho(self.lianCmd)
          end
        end
      end
    end
  end

  return prototype
end
return define_fsm():new()
