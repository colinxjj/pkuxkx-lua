--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/5/7
-- Time: 21:40
-- To change this template use File | Settings | File Templates.
--

local patterns = {[[
ask hu about job
你向胡一刀打听有关『job』的消息。
胡一刀说道：『我收到消息，听说黄河南岸有盗宝人涂钦筇才(ansunk)找到了闯王宝藏的地图,你可否帮忙找回来！』
胡一刀朗声说道：「前路难行，多多珍重！」

> 倪五杰看见你，阴笑一声：天堂有路你不走，地狱无门你来投！
看起来倪五杰想杀死你！

    盗 宝 人 「狂暴龙」倪五杰(Phidass)

倪五杰说道：“你有种去洛阳找我兄弟仲孙可(fonk)，他会给我报仇的！”

]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

local define_huyidao = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop"
  }
  local Events = {
    STOP = "stop",  -- any state -> stop
    START = "start",  -- stop -> ask

  }
  local REGEXP = {
    ALIAS_START = "^huyidao\\s+start\\s*$",
    ALIAS_STOP = "^huyidao\\s+stop\\s*$",
    ALIAS_DEBUG = "^huyidao\\s+debug\\s+(on|off)\\s*$",
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
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransitionToStop(States.STOP)

  end

  function prototype:initTriggers()

  end

  function prototype:initAliases()
    helper.removeAliasGroup("huyidao")
    helper.addAlias {
      group = "huyidao",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "huyidao",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "huyidao",
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

  return prototype
end
return define_huyidao():FSM()
