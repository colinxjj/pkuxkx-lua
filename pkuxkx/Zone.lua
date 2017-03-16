--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:31
-- To change this template use File | Settings | File Templates.
--

--------------------------------------------------------------
-- Zone.lua
-- data structure of Zone
-- similar to Room, with no exits, description, mapinfo and list of ZonePath
--------------------------------------------------------------
local define_Zone = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    assert(args.id, "id can not be nil")
    assert(args.code, "code can not be nil")
    assert(args.name, "id can not be nil")
    assert(args.centercode, "code can not be nil")
    local obj = {}
    obj.id = args.id
    obj.code = args.code
    obj.name = args.name
    obj.centercode = args.centercode
    obj.paths = args.paths or {}
    obj.rooms = args.rooms or {}
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.id, "id can not be nil")
    assert(obj.code, "code cannot be nil")
    assert(obj.name, "id can not be nil")
    assert(obj.centercode, "code can not be nil")
    obj.paths = obj.paths or {}
    obj.rooms = obj.rooms or {}
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:addPath(path)
    self.paths[path.endid] = path
  end

  function prototype:addRoom(room)
    self.rooms[room.id] = room
  end

  return prototype
end
return define_Zone()

