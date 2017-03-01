--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/1
-- Time: 11:51
-- To change this template use File | Settings | File Templates.
--

local Room = {}
Room.__index = Room

function Room:new(args)
    assert(args.id, "id can not be nil")
    assert(args.code, "code can not be nil")
    assert(args.name, "name can not be nil")
    local obj = {}
    obj.id = args.id
    obj.code = args.code
    obj.name = args.name
    obj.description = args.description
    obj.exits = args.exits
    obj.zone = args.zone
    obj.paths = args.paths or {}
    setmetatable(obj, self)
    return obj
end

function Room:addPath(path)
    self.paths[path.endid] = path
end

return Room