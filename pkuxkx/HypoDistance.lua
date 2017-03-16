--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:32
-- To change this template use File | Settings | File Templates.
--

--------------------------------------------------------------
-- HypoDistance.lua
-- data structure of HypoDistance
-- used in A* algorithm
--------------------------------------------------------------
local define_HypoDistance = function()
  local prototype = {
    __eq = function(a, b) return a.real + a.hypo == b.real + b.hypo end,
    __lt = function(a, b) return a.real + a.hypo < b.real + b.hypo end,
    __le = function(a, b) return a.real + a.hypo <= b.real + b.hypo end
  }
  prototype.__index = prototype

  function prototype:new(args)
    assert(args.id, "args of HypoDistance must have valid id field")
    assert(args.real, "args of HypoDistance must have valid real field")
    local obj = {}
    obj.id = args.id
    obj.real = args.real
    obj.hypo = args.hypo or 0
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.id, "id cannot be nil")
    assert(obj.real, "real cannot be nil")
    obj.hypo = obj.hypo or 0
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
return define_HypoDistance()
