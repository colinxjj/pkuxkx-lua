--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:31
-- To change this template use File | Settings | File Templates.
--

--------------------------------------------------------------
-- Room.lua
-- data structure of Room
-- room is an abstraction of a point that player can
-- move from or go to in a mud map
--------------------------------------------------------------
local define_Room = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    assert(args.id, "id can not be nil")
    assert(args.code, "code can not be nil")
    local obj = {}
    obj.id = args.id
    obj.code = args.code
    obj.name = args.name or ""
    obj.description = args.description
    obj.exits = args.exits
    obj.zone = args.zone
    obj.paths = args.paths or {}
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.id, "id can not be nil")
    assert(obj.code, "code cannot be nil")
    obj.name = obj.name or ""
    obj.description = obj.description or ""
    obj.exits = obj.exits or ""
    obj.zone = obj.zone or ""
    obj.paths = obj.paths or {}
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:addPath(path)
    self.paths[path.endid] = path
  end

  return prototype
end
return define_Room()
