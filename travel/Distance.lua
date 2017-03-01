--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/1
-- Time: 11:52
-- To change this template use File | Settings | File Templates.
--

local Distance = {
    __eq = function(a, b) return a.real + a.hypo == b.real + b.hypo end,
    __lt = function(a, b) return a.real + a.hypo < b.real + b.hypo end,
    __le = function(a, b) return a.real + a.hypo <= b.real + b.hypo end
}

function Distance:new(args)
    assert(args.id, "args of Distance must have valid id field")
    assert(args.real, "args of Distance must have valid real field")
    local obj = {}
    obj.id = args.id
    obj.real = args.real
    obj.hypo = args.hypo or 0
    setmetatable(obj, self)
    return obj
end

return Distance
