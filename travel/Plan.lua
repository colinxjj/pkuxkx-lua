--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/1
-- Time: 12:17
-- To change this template use File | Settings | File Templates.
--

local Plan = {}
Plan._startid = -1
Plan._paths = {}
Plan._len = 0
Plan._started = false
Plan._finished = false

function Plan:len() end

function Plan:next() end

function Plan:isStarted() end

function Plan:isFinished() end

function Plan:start() end

function Plan:finish() end

function Plan:new(args)
    assert(type(args.startid) == "number", "startid of args must be number")
    assert(args.paths, "paths of args cannot be nil")
    local obj = {}
    obj._startid = args.startid
    obj._paths = args.paths
    setmetatable(obj, self)
    return obj
end

return Plan
