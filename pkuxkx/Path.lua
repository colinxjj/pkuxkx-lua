--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:26
-- To change this template use File | Settings | File Templates.
--
--------------------------------------------------------------
-- Path.lua
-- data structure of Path
-- Path is an abstraction of a relationship between two points
-- in mud map
--------------------------------------------------------------
local define_Path = function()
  local prototype = {
    __eq = function(a, b) return a.weight == b.weight end,
    __lt = function(a, b) return a.weight < b.weight end,
    __le = function(a, b) return a.weight <= b.weight end
  }
  prototype.__index = prototype

  function prototype:new(args)
    assert(args.startid, "startid can not be nil")
    assert(args.endid, "endid can not be nil")
    local obj = {}
    obj.startid = args.startid
    obj.endid = args.endid
    obj.weight = args.weight or 1
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.startid, "startid cannot be nil")
    assert(obj.endid, "endid cannot be nil")
    obj.weight = obj.weight or 1
    setmetatable(obj, self or prototype)
    return obj
  end

  -- subclass can override this method to introduce different weight algorithm
  function prototype:adjustedWeight()
    return self.weight
  end

  return prototype
end
return define_Path()

