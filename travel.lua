--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/2/26
-- Time: 15:37
-- Desc: this package handles the travel related problem, using A* algorithm
--       data type:
--       room: id, paths
--
require "minheap"
require "db"
memdb:init("pkuxkx.db")
--[[
-- Data structures used in shortestpath algorithm:
-- Path, Room, Distance
--]]

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

travel = {}
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
      table.insert(startroom.paths, Path:new(path))
    end
  end
  travel.rooms = rooms
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

function travel:hypo(startid, endid)
  return 0;
end

function travel:shortestpath(startid, targetid)
  -- the opens stores the checked nodes with real distance spent,
  -- and the total hypothesis distance to target
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
    local paths = self.rooms[min.id].paths
    if #paths ~= 0 then
      for i =1, #paths do
        local path = paths[i]
        local endid = path.endid
        if endid == targetid then
          prev[endid] = min.id
          return traceprev(prev, endid)
        end
        if not closes[endid] then
          local newDistance = Distance:new {id=endid, real=min.real + path.weight, hypo=self:hypo(endid, targetid)}
          if opens:contains(endid) then
            local currDistance = opens:get(endid)
            if newDistance < currDistance then
              --                            print("newDistance < currDistance", newDistance, currDistance)
              opens:adjust(endid, newDistance)
              prev[endid] = min.id
            end
          else
            --                        print("put endid into queue", endid, newDistance)
            opens:put(endid, newDistance)
            prev[endid] = min.id
          end
        end
      end
    end
    closes[min.id] = true
  end

end

-- do initialization
initRoomsAndPaths()

return travel
