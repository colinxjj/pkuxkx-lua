--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/4/1
-- Time: 8:33
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"


--------------------------------------------------------------
-- looksnow.lua
-- 看雪涨基本轻功，请自备干粮和酒袋
--------------------------------------------------------------

local define_looksnow = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    looking = "looking",
    blind = "blind",
    walking = "walking"
  }
  local Events = {
    STOP = "stop",
    START = "start",
    BLIND = "blind",
    RECOVERED = "recovered",
    CONTINUE_LOOK = "continue_look",
    FOUND = "found",
    IMPROVED = "improved",
  }
  local REGEXP = {
    BLIND = "^[ >]*突然间，你被积雪闪耀着的刺眼的光芒灼伤，只觉头痛欲裂，眼前什么也看不到了！$",
    RECOVERED = "^[ >]*慢慢的，你发现自己可以睁开眼了，只是眼睛似有砂子，疼痛流泪。$",
    FOUND = "^[ >]*你突然发现在路旁的一片积雪上行走\\(walk\\)似乎可以用来练习轻功。$",
    IMPROVED = "^[ >]*你一路走下来，看着脚印回想方才的步法，轻功水平提高了！$",
    ALIAS_START = "^looksnow\\s+start\\s*$",
    ALIAS_STOP = "^looksnow\\s+stop\\s*$",
    ALIAS_DEBUG = "^looksnow\\s+debug\\s+(on|off)\\s*$",
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
    self.lookCnt = 0
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups("looksnow_looking", "looksnow_blind")
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
      state = States.looking,
      enter = function()
        self.lookFound = false
        helper.enableTriggerGroups("looksnow_looking")
      end,
      exit = function()
        helper.disableTriggerGroups("looksnow_looking")
      end
    }
    self:addState {
      state = States.walking,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.blind,
      enter = function()
        helper.enableTriggerGroups("looksnow_blind")
      end,
      exit = function()
        helper.disableTriggerGroups("looksnow_blind")
      end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.looking,
      event = Events.START,
      action = function()
        self.lookCnt = 0
        return travel:walkto(2003, function()
          helper.assureNotBusy();
          print("准备开始看雪，请自备干粮酒袋，基本轻功需要高于50级")
          return self:fire(Events.CONTINUE_LOOK)
        end)
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<looking>
    self:addTransition {
      oldState = States.looking,
      newState = States.looking,
      event = Events.CONTINUE_LOOK,
      action = function()
        wait.time(1)
        self:doLook()
      end
    }
    self:addTransition {
      oldState = States.looking,
      newState = States.walking,
      event = Events.FOUND,
      action = function()
        wait.time(1)
        self:doWalk()
      end
    }
    self:addTransition {
      oldState = States.looking,
      newState = States.blind,
      event = Events.BLIND,
      action = function()
        print("目盲，等待恢复")
      end
    }
    self:addTransitionToStop(States.looking)
    -- transition from state<walking>
    self:addTransition {
      oldState = States.walking,
      newState = States.looking,
      event = Events.IMPROVED,
      action = function()
        return self:fire(Events.CONTINUE_LOOK)
      end
    }
    self:addTransitionToStop(States.walking)
    -- transition from state<blind>
    self:addTransition {
      oldState = States.blind,
      newState = States.looking,
      event = Events.RECOVERED,
      action = function()
        return self:fire(Events.CONTINUE_LOOK)
      end
    }
    self:addTransitionToStop(States.blind)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("looksnow_looking")

    helper.addTrigger {
      group = "looksnow_looking",
      regexp = REGEXP.BLIND,
      response = function()
        return self:fire(Events.BLIND)
      end
    }
    helper.addTrigger {
      group = "looksnow_looking",
      regexp = REGEXP.FOUND,
      response = function()
        self.lookFound = true
      end
    }
    helper.addTrigger {
      group = "looksnow_blind",
      regexp = REGEXP.RECOVERED,
      response = function()
        return self:fire(Events.RECOVERED)
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("looksnow")
    helper.addAlias {
      group = "looksnow",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "looksnow",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "looksnow",
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

  function prototype:doLook()
    self.lookCnt = self.lookCnt + 1
    if self.lookCnt % 10 == 0 then
      -- 尝试运气
      SendNoEcho("yun qi")
      -- 检查食物饮水
      status:hpbrief()
      if status.food < 200 then
        SendNoEcho("do 5 eat ganliang")
      end
      if status.drink < 200 then
        SendNoEcho("do 5 drink jiudai")
      end
    end
    SendNoEcho("look snow")
    SendNoEcho("set looksnow done")
    local line = wait.regexp(helper.settingRegexp("looksnow", "done"), 3)
    if not line then
--      return self:fire(Events.BLIND)
      self:debug("等待超时，可能目盲了")
    elseif self.lookFound then
      return self:fire(Events.FOUND)
    else
      return self:fire(Events.CONTINUE_LOOK)
    end
  end

  function prototype:doWalk()
    SendNoEcho("walk snow")
    local line = wait.regexp(REGEXP.IMPROVED, 20)
    if line then
      return self:fire(Events.IMPROVED)
    else
      print("等待超时，可能系统繁忙，停止看雪")
      return self:fire(Events.STOP)
    end
  end

  return prototype
end
return define_looksnow():new()

