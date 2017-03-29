--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:30
-- To change this template use File | Settings | File Templates.
--

local Path = require "pkuxkx.Path"

local define_ZonePath = function()
  local prototype = inheritMeta(Path)
  prototype.__index = prototype
  local BUSY_WEIGHT = 5
  local BOAT_WEIGHT = 100

  setmetatable(prototype, {__index = Path})

  function prototype:new(args)
    local obj = Path:new(args)
    obj.busy = args.busy or 0
    obj.boat = args.boat or 0
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    local obj = Path:decorate(obj)
    obj.busy = obj.busy or 0
    obj.boat = obj.boat or 0
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:adjustedWeight()
    return self.weight + self.boat * BOAT_WEIGHT + self.busy * BUSY_WEIGHT
  end

  -- the global setting
  function prototype.setBoatWeight(weight)
    BOAT_WEIGHT = weight
  end

  function prototype.setBusyWeight(weight)
    BUSY_WEIGHT = weight
  end

  return prototype
end
return define_ZonePath()