--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:27
-- To change this template use File | Settings | File Templates.
--
--------------------------------------------------------------
-- RoomPath.lua
-- data structure of RoomPath, inherit from Path
-- add concrete fields
--------------------------------------------------------------
require "pkuxkx.predefines"
local Path = require "pkuxkx.Path"

local define_RoomPath = function()
  local prototype = inheritMeta(Path)
  prototype.__index = prototype
  setmetatable(prototype, {__index = Path})

  prototype.Category = {
    normal = 1,
    multiple = 2,
    trigger = 3,
    busy = 4,
    boat = 5
  }

  function prototype:new(args)
    local obj = Path:new(args)
    --    assert(obj.endcode, "endcode cannot be nil")
    assert(args.path, "path can not be nil")
    obj.path = args.path
    obj.endcode = args.endcode
    obj.category = args.category or prototype.Category.normal
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    local obj = Path:decorate(obj)
    --    assert(obj.endcode, "endcode cannot be nil")
    assert(obj.path, "path cannot be nil")
    obj.category = obj.category or prototype.Category.normal
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
return define_RoomPath()

