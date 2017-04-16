--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/4/16
-- Time: 19:38
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"
local status = require "pkuxkx.status"
--------------------------------------------------------------
-- lingwu.lua
-- 领悟基本武功，请自备干粮和酒袋
--------------------------------------------------------------

local define_learn = function()
  local prototype = {}
  prototype.__index = prototype

  local REGEXP = {
    ALIAS_START = "learning\\s+start\\s*$",
    ALIAS_STOP = "learning\\s+stop\\s*$",
    ALIAS_CMD = "learning\\s+cmd\\s+(.*?)\\s*$",
    DAZUO_FINISH = "^[ >]*你运功完毕，深深吸了口气，站了起来。$",
    NOT_ENOUGH_JING_DAZUO = "^[ >]*你现在精不够，无法控制内息的流动！$",
  }

  function prototype:new()
    local obj = {}
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self:initTriggers()
    self:initAliases()
    self.learnCmd = "xue feng for huashan-neigong 50"
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("learning")
    helper.addTrigger {
      group = "learning",
      regexp = REGEXP.DAZUO_FINISH,
      response = function()
        return self:doLearn()
      end
    }
    helper.addTrigger {
      group = "learning",
      regexp = REGEXP.NOT_ENOUGH_JING_DAZUO,
      response = function()
        wait.time(5)
        return self:doLearn()
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("learning")

    helper.addAlias {
      group = "learning",
      regexp = REGEXP.ALIAS_START,
      response = function()
        helper.enableTriggerGroups("learning")
        self:doLearn()
      end
    }
    helper.addAlias {
      group = "learning",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        helper.disableTriggerGroups("learning")
      end
    }
    helper.addAlias {
      group = "learning",
      regexp = REGEXP.ALIAS_CMD,
      response = function(name, line, wildcards)
        self.learnCmd = wildcards[1]
      end
    }
  end

  function prototype:doLearn()
    while true do
      status:hpbrief()
      if status.food < 150 then
        SendNoEcho("do 3 eat ganliang")
      end
      if status.drink < 150 then
        SendNoEcho("do 3 drink jiudai")
      end
      if status.currNeili > 700 then
        SendNoEcho("yun regenerate")
        SendNoEcho(self.learnCmd)
        wait.time(2)
      else
        SendNoEcho("yun recover")
        SendNoEcho("dazuo max")
        break
      end
    end
  end

  return prototype
end
return define_learn():new()
