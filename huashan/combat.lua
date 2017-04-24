--
-- combat.lua
-- User: zhe.jiang
-- Date: 2017/4/24
-- Desc:
-- Change:
-- 2017/4/24 - created

local helper = require "pkuxkx.helper"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

----
-- combat.lua
----
local define_module = function()
  local prototype = {}
  prototype.__index = prototype

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
    helper.removeTriggerGroups("combat")

  end

  function prototype:initAliases()
    helper.removeAliasGroups("combat")

  end

  return prototype
end
return define_module():new()

