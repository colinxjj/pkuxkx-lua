--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:32
-- To change this template use File | Settings | File Templates.
--


--------------------------------------------------------------
-- Distance.lua
-- data structure of Distance
--------------------------------------------------------------
local define_Distance = function()
  local prototype = {
    __eq = function(a, b) return a.weight == b.weight end,
    __lt = function(a, b) return a.weight < b.weight end,
    __le = function(a, b) return a.weight <= b.weight end
  }
  prototype.__index = prototype

  function prototype:new(args)
    assert(args.id, "id cannot be nil")
    assert(args.weight, "weight cannot be nil")
    local obj = {}
    obj.id = args.id
    obj.weight = args.weight
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.id, "id cannot be nil")
    assert(obj.weight, "weight cannot be nil")
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
return define_Distance()

