--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/5/7
-- Time: 22:37
-- To change this template use File | Settings | File Templates.
--


local patterns = {[[
975

孟之经说道：「这里人多眼杂，你先到江南小道等候，我自会通知你。」

> 孟之经托付都府内常随送给了你一页密码。
孟之经(meng zhijing)告诉你：第一个字在：第八行，第十列。第二个字在：第一行，第十列。第三个字在：第九行，第七列。对照(duizhao)这页，你就知道你要刺杀的人在哪了。

duizhao
你背着众人，悄悄地打开了旧纸。

殺1 2 3 4 5 6 7 8 9 1011
1 疆城襄阜丝府江后明驼帮
2 曲天山平村临西岳寨凉湖
3 湖王手岳真龙山兴府苗山
4 福府曲洛曲襄城丝源中王
5 江中府昆康容嵋嵋目白北
6 北临府山花原阜大安城曲
7 安家河府安谷平临教泉庄
8 城寺清州西武路府丝白麒
9 长山寺州天目山西慕成安

> 你定睛一看，彭晓峦正是你要找的汉奸卖国贼！
东街
    大元 建康府南城路安抚副使 彭晓峦(Peng xiaoluan)

大元 建康府南城路招讨副使 顾杰(Gu jie)

上官年往东落荒而逃了。

恭喜！你完成了都统制府行刺任务！

]]}


local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"

local define_cisha = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    search = "search",
    fight = "fight",
    submit = "submit"
  }
  local Events = {
    STOP = "stop",
    START = "start"
  }
  local REGEXP = {
    ALIAS_START = "^cisha\\s+start\\s*$",
    ALIAS_STOP = "^cisha\\s+stop\\s*$",
    ALIAS_DEBUG = "^cisha\\s+debug\\s+(on|off)\\s*$",
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
    helper.removeAliasGroup("cisha")
    helper.addAlias {
      group = "cisha",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "cisha",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "cisha",
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
return define_cisha():FSM()
