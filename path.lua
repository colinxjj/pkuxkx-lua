--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/2/28
-- Time: 10:24
-- To change this template use File | Settings | File Templates.
--

-- this is just metadata
local Path = {
    __eq = function(a, b) return a.weight == b.weight end,
    __lt = function(a, b) return a.weight < b.weight end,
    __le = function(a, b) return a.weight <= b.weight end
}
Path.__index = Path

function Path:new(args)
    assert(args.startid, "startid can not be nil")
    assert(args.endid, "endid can not be nil")
    local obj = {}
    obj.startid = args.startid
    obj.endid = args.endid
    obj.weight = args.weight or 1
    setmetatable(obj, self)
    return obj
end

local Room = {}
Room.__index = Room

function Room:new(args)
    assert(args.id, "id can not be nil")
    local obj = {}
    obj.id = args.id
    obj.paths = args.paths or {}
    setmetatable(obj, self)
    return obj
end

local rooms = {
    Room:new {
        id=1,
        paths={
            Path:new {startid=1, endid=2, weight=3},
            Path:new {startid=1, endid=3, weight=7},
            Path:new {startid=1, endid=4, weight=4}
        }
    },
    Room:new {
        id=2,
        paths={
            Path:new {startid=2, endid=5, weight=5},
            Path:new {startid=2, endid=1, weight=3},
            Path:new {startid=2, endid=4, weight=2}
        }
    },
    Room:new {
        id=3,
        paths={
            Path:new {startid=3, endid=4, weight=1},
            Path:new {startid=3, endid=1, weight=7}
        }
    },
    Room:new {
        id=4,
        paths={
            Path:new {startid=4, endid=5, weight=1},
            Path:new {startid=4, endid=3, weight=1},
            Path:new {startid=4, endid=2, weight=2},
            Path:new {startid=4, endid=1, weight=4}
        }
    },
    Room:new {
        id=5,
        paths={
            Path:new {startid=5, endid=2, weight=5},
            Path:new {startid=5, endid=4, weight=1}
        }
    }
}

local Distance = {
    __eq = function(a, b) return a.real + a.hypo == b.real + b.hypo end,
    __lt = function(a, b) return a.real + a.hypo < b.real + b.hypo end,
    __le = function(a, b) return a.real + a.hypo <= b.real + b.hypo end
}

function Distance:new(args)
    assert(args.real, "args of Distance must have valid real field")
    local obj = {}
    obj.real = args.real
    obj.hypo = args.hypo or 0
    setmetatable(obj, self)
    return obj
end

local IntMap = {}
IntMap.__index = IntMap

function IntMap:put(idx, value)
    if value == nil then error("value of IntMap cannot be nil") end
    if not self._list[idx] then
        self._list[idx] = value
        self:size(self:size() + 1)
    end
end

function IntMap:get(idx) return self._list[idx] end

function IntMap:remove(idx)
    local value = self._list[idx]
    if value ~= nil then
        self._list[idx] = nil
        self:size(self:size() - 1)
    end
    return value
end

function IntMap:contains(idx)
    if self._list[idx] ~= nil then
        return true
    end
    return false
end

function IntMap:size(v)
    if v and type(v) == "number" then
        self._len = v
    else
        return self._len
    end
end

function IntMap:pairs()
    return pairs(self._list)
end

function IntMap:removeMin()
    local minId, minValue
    for idx, value in self:pairs() do
        if (not minValue) or value < minValue then
            minValue = value
            minId = idx
        end
    end
    if minId then
        self:remove(minId)
    end
    return minId, minValue
end

function IntMap:adjust(id, value)
    if not self:contains(id) then error("cannot find id "..id.." in IntMap", 1) end
    self:put(id, value)
    -- fix map if needed
end

function IntMap:new()
    local obj = {}
    obj._len = 0
    obj._list = {}
    setmetatable(obj, self)
    return obj
end

local _hs = {
--    ["1:5"]=6,
--    ["2:5"]=5,
--    ["3:5"]=5,
--    ["4:5"]=1
}
local hypo = function(startid, endid)
    return _hs[startid .. ":" .. endid] or 0
end

local traceprev = function(prev, endid)
    local reversed = {}
    local pivot = endid

    repeat
        table.insert(reversed, pivot)
        pivot = prev[pivot]
    until pivot == nil

    local forward = {}
    for i = #reversed, 1, -1 do
        table.insert(forward, reversed[i])
    end
    return forward
end

-- apply A* algorithm
local shortestpath = function(startid, targetid)
    -- the opens stores the checked nodes with real distance spent,
    -- and the total hypothesis distance to target
    local opens = IntMap:new()
    local closes = {}
    local prev = {}

    opens:put(startid, Distance:new {real=0, hypo=0})

    while true do
        if opens:size() == 0 then break end
--        print("opens:")
--        for i, v in opens:pairs() do
--            print(i, v)
--        end
        local id, dist = opens:removeMin()
        local paths = rooms[id].paths
        if #paths ~= 0 then
            for _, path in ipairs(paths) do
                local endid = path.endid
                if endid == targetid then
                    prev[endid] = id
                    return traceprev(prev, endid)
                end
                if not closes[endid] then
                    local newDistance = Distance:new {real=dist.real + path.weight, hypo=hypo(endid, targetid)}
                    if opens:contains(endid) then
                        local currDistance = opens:get(endid)
                        if newDistance < currDistance then
--                            print("newDistance < currDistance", newDistance, currDistance)
                            opens:adjust(endid, newDistance)
                            prev[endid] = id
                        end
                    else
--                        print("put endid into queue", endid, newDistance)
                        opens:put(endid, newDistance)
                        prev[endid] = id
                    end
                end
            end
        end
        closes[id] = true
    end
end

for k, v in pairs(shortestpath(1, 5)) do
    print(k, v)
end
