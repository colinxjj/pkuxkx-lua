--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/1
-- Time: 11:49
-- To change this template use File | Settings | File Templates.
--
local Path = {
    __eq = function(a, b) return a.weight == b.weight end,
    __lt = function(a, b) return a.weight < b.weight end,
    __le = function(a, b) return a.weight <= b.weight end
}
Path.__index = Path

function Path:new(args)
    assert(args.startid, "startid can not be nil")
    assert(args.endid, "endid can not be nil")
    assert(args.path, "path can not be nil")
    local obj = {}
    obj.startid = args.startid
    obj.endid = args.endid
    obj.path = args.path
    obj.endcode = args.endcode
    obj.weight = args.weight or 1
    setmetatable(obj, self)
    return obj
end

return Path
