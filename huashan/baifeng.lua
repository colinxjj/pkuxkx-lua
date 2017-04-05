--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/4/5
-- Time: 16:59
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"
local travel = require "pkuxkx.travel"

local define_module = function()
  local prototype = {}
  prototype.__index = prototype

  local REGEXP = {
    ALIAS_START = "^baifeng\\s+start\\s*$",
    ALIAS_DEBUG = "^baifeng\\s+stop\\s*$",
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
  end

  function prototype:initTriggers()

  end

  function prototype:initAliases()
    helper.removeAliasGroups("baifeng")
    helper.addAlias {
      group = "baifeng",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return travel:walkto(2916, function()
          SendNoEcho("ask yue about ¡Ó∫¸≥Â")
          SendNoEcho("ask yue about Àºπ˝—¬")
          SendNoEcho("n")
          SendNoEcho("northwest")
          SendNoEcho("w")
          SendNoEcho("wu")
          SendNoEcho("sd")
          SendNoEcho("eu")
          self:keepTryingBaiFeng()
        end)
      end
    }
    helper.addAlias {
      group = "baifeng",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        helper.removeTimerGroups("baifeng")
      end
    }
  end

  function prototype:keepTryingBaiFeng()
    print("√ø10√Î≥¢ ‘1¥Œ")
    helper.addTimer {
      group = "baifeng",
      interval = 10,
      response = function()
        SendNoEcho("ask linghu about ‘¿¡È…∫")
        SendNoEcho("ask linghu about ∑ÁÃ´ ¶ Â")
        SendNoEcho("enter dong")
        SendNoEcho("south")
        SendNoEcho("bai feng")
        SendNoEcho("n")
        SendNoEcho("out")
      end
    }
  end

  return prototype
end
return define_module():new()
