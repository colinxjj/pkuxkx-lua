--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/1
-- Time: 11:49
-- To change this template use File | Settings | File Templates.
--
local memdb = require "utils/db"
memdb:init("data/pkuxkx.db")

local Path = require "travel.Path"
local Room = require "travel.Room"
local Algo = require "travel.Algo"

local travel = {}
local initRoomsAndPaths = function()
    local allRooms = memdb:getAllRooms()
    local rooms = {}
    for i = 1,#allRooms do
        rooms[allRooms[i].id] = Room:new(allRooms[i])
    end
    local allPaths = memdb:getAllPaths()
    for i = 1,#allPaths do
        local path = allPaths[i]
        local startroom = rooms[path.startid]
        if startroom then
            startroom:addPath(Path:new(path))
        end
    end
    travel.rooms = rooms
end
-- do initialization
initRoomsAndPaths()

-- bind search implementation to A* algorithm
-- should enhance with hypothesis functions to reduce search range
function travel:search(startid, endid)
    return Algo.astar(startid, endid, self.rooms)
end

return travel


