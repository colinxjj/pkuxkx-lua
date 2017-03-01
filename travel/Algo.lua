--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/1
-- Time: 11:58
-- To change this template use File | Settings | File Templates.
--

local tprint = require "utils.tprint"
local minheap = require "utils.minheap"
local Distance = require "travel.Distance"

local Algo = {}

local defaultHypothesis = function(startid, endid) return 0 end

local finalizePathStack = function(rooms, prev, endid)
    local stack = {}
    local toid = endid
    local fromid = prev[toid]
    while fromid do
        local path = rooms[fromid].paths[toid]
        table.insert(stack, path)
        toid, fromid = fromid, prev[fromid]
    end
    return stack, toid
end

Algo.astar = function(startid, targetid, rooms, hf)
    assert(type(startid) == "number", "startid must be number")
    assert(type(targetid) == "number", "targetid must be number")
    assert(rooms, "rooms must be non-empty")
    local hypo = hf or defaultHypothesis

    local opens = minheap:new()
    local closes = {}
    local prev = {}

    opens:insert(Distance:new {id=startid, real=0, hypo=0})

    while true do
        if opens.size == 0 then break end
        --        print("opens:")
        --        for i, v in opens:pairs() do
        --            print(i, v)
        --        end
        local min = opens:removeMin()
        local minRoom = rooms[min.id]
        local paths = minRoom and minRoom.paths or {}
        for _, path in pairs(paths) do
            local endid = path.endid
            if endid == targetid then
                prev[endid] = min.id
                --          return traceprev(prev, endid)
                return finalizePathStack(rooms, prev, endid)
            end
            if not closes[endid] then
                local newDistance = Distance:new {id=endid, real=min.real + path.weight, hypo=hypo(endid, targetid)}
                if opens:contains(endid) then
                    local currDistance = opens:get(endid)
                    if newDistance < currDistance then
                        --                            print("newDistance < currDistance", newDistance, currDistance)
                        opens:replace(newDistance)
                        prev[endid] = min.id
                    end
                else
                    --                        print("put endid into queue", endid, newDistance)
                    opens:insert(newDistance)
                    prev[endid] = min.id
                end
            end
        end
        closes[min.id] = true
    end
end


return Algo
