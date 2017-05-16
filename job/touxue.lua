--
-- touxue.lua
-- User: zhe.jiang
-- Date: 2017/5/8
-- Desc:
-- Change:
-- 2017/5/8 - created

local patterns = {[[
ask murong about job
你向慕容复打听有关『job』的消息。
慕容复说道：「撸啊，我近来习武遇到障碍，听说有人擅长少林醉棍。」
慕容复说道：「你去把下面几招学(touxue)下来。」
慕容复在你的耳边悄声说道：「韩湘子棍铁，提胸醉拔萧」棍大英雄横提钢杖棍，端划了个半圈棍击向盖世豪杰的头部
慕容复在你的耳边悄声说道：「蓝采和，提篮劝酒醉朦胧」，大英雄手中钢杖半提，缓缓向划盖世豪杰的头部
慕容复在你的耳边悄声说道：「汉钟离疾跌步翻身醉盘龙」疾大英雄手中棍花团团疾，风般向卷向盖世豪杰
慕容复在你的耳边悄声说道：「曹国舅千，杯不醉金倒盅」千大英雄金竖钢杖千指天打地千向盖世豪杰的头部劈去
慕容复在你的耳边悄声说道：「何仙姑右拦腰敬酒醉仙步」右大英雄左掌护胸右，臂挟棍猛地扫向盖世豪杰的腰间
慕容复在你的耳边悄声说道：其人名曰郭叶，正在西湖一带活动。
慕容复说道：「具体招式我是多年前所见，记得不怎么清晰了。」

你从郭叶身上偷学到了一招！

你恐怕没有偷学机会了。


ask murong about job
你向慕容复打听有关『job』的消息。
慕容复说道：「撸啊，我近来习武遇到障碍，听说有人擅长赤炼神掌。」
慕容复说道：「你去把下面几招学(touxue)下来。」
慕容复在你的耳边悄声说道：大英雄左掌结印，右掌轻轻拍向世盖豪杰
慕容复在你的耳边悄声说道：大英雄手双一合，平平推向盖世豪杰
慕容复在你的耳边悄声说道：大英雄拳打脚踢，看似毫章无法，其实已将盖世豪杰逼入绝境
慕容复在你的耳边悄声说道：处英雄轻巧地攻向盖世杰豪胸前诸大处穴
慕容复在你的耳边悄声说道：大英雄手上如传花蝴蝶，并不停歇，印向盖世豪杰必救处之
慕容复在你的耳边悄声说道：其人名曰赵丽姣，正在福州一带活动。
慕容复说道：「具体招式我是多年前所见，记得不怎么清晰了。」

]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"

local define_touxue = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop"
  }
  local Events = {
    STOP = "stop"
  }
  local REGEXP = {
    ALIAS_START = "^touxue\\s+start\\s*$",
    ALIAS_STOP = "^touxue\\s+stop\\s*$",
    ALIAS_DEBUG = "^touxue\\s+debug\\s+(on|off)\\s*$",
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

  end

  function prototype:initTriggers()

  end

  function prototype:initAliases()
    helper.removeAliasGroups("touxue")
    helper.addAlias {
      group = "touxue",
      regexp = REGEXP.ALIAS_START,
      response = function()

      end
    }
    helper.addAlias {
      group = "touxue",
      regexp = REGEXP.ALIAS_STOP,
      response = function() end
    }
    helper.addAlias {
      group = "touxue",
      regexp = REGEXP.ALIAS_DEBUG,
      response = function()

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
return define_touxue():FSM()

