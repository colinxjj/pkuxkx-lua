--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:40
-- To change this template use File | Settings | File Templates.
--

--------------------------------------------------------------
-- Algo.lua
-- Implement algorithm of searching path
-- current solution is based on A*
-- changelog:
--------------------------------------------------------------
local minheap = require "pkuxkx.minheap"
local Distance = require "pkuxkx.Distance"
local HypoDistance = require "pkuxkx.HypoDistance"

local define_Algo = function()
  local Algo = {}

  local defaultHypothesis = function(startid, endid) return 0 end

  -- function returns table contianing path in reverse order,
  -- the start point and end point
  local finalizePathStack = function(rooms, prev, endid)
    local stack = {}
    local toid = endid
    local fromid = prev[toid]
    while fromid do
      local path = rooms[fromid].paths[toid]
      table.insert(stack, path)
      toid, fromid = fromid, prev[fromid]
    end
    return stack, toid, endid
  end

  local reverseRoomArrayToPathStack = function(rooms, arr)
    local stack = {}
    if #arr <= 1 then return stack end
    local tgt = table.remove(arr)
    while #arr > 0 do
      local c = table.remove(arr)
      table.insert(stack, rooms[c].paths[tgt])
      tgt = c
    end
    return stack
  end

  Algo.astar = function(args)
    local rooms = assert(args.rooms, "rooms cannot be nil")
    local startid = assert(args.startid, "startid cannot be nil")
    local targetid = assert(args.targetid, "targetid cannot be nil")
    local hypo = args.hf or defaultHypothesis

    if startid == targetid then return {} end

    local opens = minheap:new()
    local closes = {}
    local prev = {}

    opens:insert(HypoDistance:new {id=startid, real=0, hypo=0})

    while true do
      if opens.size == 0 then break end
      local min = opens:removeMin()
      local minRoom = rooms[min.id]
      local paths = minRoom and minRoom.paths or {}
      for _, path in pairs(paths) do
        local endid = path.endid
        if endid == targetid then
          prev[endid] = min.id
          return finalizePathStack(rooms, prev, targetid)
        end
        if not closes[endid] then
          local newDistance = HypoDistance:decorate {
            id=endid,
            real=min.real + path:adjustedWeight(),
            hypo=hypo(endid, targetid)
          }
          if opens:contains(endid) then
            local currDistance = opens:get(endid)
            if newDistance < currDistance then
              opens:replace(newDistance)
              prev[endid] = min.id
            end
          else
            opens:insert(newDistance)
            prev[endid] = min.id
          end
        end
      end
      closes[min.id] = true
    end
  end

  Algo.dijkstra = function(args)
    local rooms = assert(args.rooms, "rooms cannot be nil")
    local startid = assert(args.startid, "startid cannot be nil")
    local targetid = assert(args.targetid, "targetid cannot be nil")

    if startid == targetid then return {} end

    local opens = minheap:new()
    local closes = {}
    local prev = {}

    opens:insert(Distance:decorate {id=startid, weight=0})

    while true do
      if opens.size == 0 then break end
      local min = opens:removeMin()
      local minRoom = rooms[min.id]
      local paths = minRoom and minRoom.paths or {}
      for _, path in pairs(paths) do
        local endid = path.endid
        -- dijkstra algorithm must traverse all nodes
        if not closes[endid] then
          local newDistance = Distance:decorate { id=endid, weight=min.weight + path:adjustedWeight() }
          if opens:contains(endid) then
            local currDistance = opens:get(endid)
            if newDistance < currDistance then
              opens:replace(newDistance)
              prev[endid] = min.id
            end
          else
            opens:insert(newDistance)
            prev[endid] = min.id
          end
        end
      end
      closes[min.id] = true
    end
    if prev[targetid] then return finalizePathStack(rooms, prev, targetid) end
  end

  Algo.dfs = function(args)
    local rooms = assert(args.rooms, "rooms for traveral cannot be nil")
    local startid = args.startid or next(rooms)
    local totalRooms = 0
    for _ in pairs(rooms) do
      totalRooms = totalRooms + 1
    end
    assert(totalRooms > 0, "rooms for traveral cannot be empty")
    if not rooms[startid] then error("cannot find start in rooms", 2) end
    -- depth first search
    local queue = {}
    local reached = {}
    local candidates = {}
    table.insert(candidates, startid)
    while #candidates > 0 and #queue < totalRooms do
      local c = table.remove(candidates)
      if not reached[c] then
        reached[c] = true
        table.insert(queue, c)
        for endid, move in pairs(rooms[c].paths) do
          -- 增加一个判断，path的endid必须也在rooms列表中
          if rooms[endid] and not reached[endid] then
            table.insert(candidates, endid)
          end
        end
      end
    end
    if #queue ~= totalRooms then
      return nil
    else
      return queue
    end
  end

  Algo.traversal = function(args)
    local rooms = assert(args.rooms, "rooms for traveral cannot be nil")
    local fallbackRooms = assert(args.fallbackRooms, "fallback rooms is required for traversal")
    local startid = args.startid or next(rooms)
    local dfs = Algo.dfs {
      rooms = rooms,
      startid = startid
    }
    if not dfs then return nil end
    local fullTraversal = {}
    table.insert(fullTraversal, startid)
    for i = 2, #dfs do
      local roomId = dfs[i]
      local prevRoomId = fullTraversal[#fullTraversal]
      if rooms[prevRoomId].paths[roomId] then
        table.insert(fullTraversal, roomId)
      else
        local astar = Algo.astar {
          rooms = rooms,
          startid = prevRoomId,
          targetid = roomId
        }
        if not astar then
          local roomIds = {}
          for _, room in pairs(rooms) do
            table.insert(roomIds, room.id)
          end
          -- print("rooms: ", table.concat(roomIds, ","))
          -- error("cannot find path from " .. prevRoomId .. " to " .. roomId)
          print("无法从当前房间列表找寻到从" .. prevRoomId .. "到" .. roomId .. "的路径，使用全局搜索")
          astar = Algo.astar {
            rooms = fallbackRooms,
            startid = prevRoomId,
            targetid = roomId
          }
          if not astar then
            error("错误，使用备用全局房间列表仍无法找到从" .. prevRoomId .. "到" .. roomId .. "的可用路径")
          end
        end
        while #astar > 0 do
          local path = table.remove(astar)
          table.insert(fullTraversal, path.endid)
        end
      end
    end
    -- generate path stack
    return reverseRoomArrayToPathStack(rooms, fullTraversal)
  end

  ---- simple test case
  --local solution = Algo.traversal {
  --  startid = 1,
  ----  targetid = 1,
  --  rooms = {
  --    [1] = Room:new {
  --      id=1, code="r1", name="room1",
  --      paths = {
  --        [7] = Path:new {startid=1, endid=7, path="n"},
  --        [2] = Path:new {startid=1, endid=2, path="ne"},
  --        [5] = Path:new {startid=1, endid=5, path="se"}
  --      }
  --    },
  --    [2] = Room:new {
  --      id=2, code="r2", name="room2",
  --      paths = {
  --        [7] = Path:new {startid=2, endid=7, path="w"},
  --        [1] = Path:new {startid=2, endid=1, path="sw"},
  --        [3] = Path:new {startid=2, endid=3, path="e"},
  --        [4] = Path:new {startid=2, endid=4, path="se"}
  --      }
  --    },
  --    [3] = Room:new {
  --      id=3, code="r3", name="room3",
  --      paths = {
  --        [2] = Path:new {startid=3, endid=2, path="w"},
  --        [4] = Path:new {startid=3, endid=4, path="s"},
  --        [6] = Path:new {startid=3, endid=6, path="ne"}
  --      }
  --    },
  --    [4] = Room:new {
  --      id=4, code="r4", name="room4",
  --      paths = {
  --        [2] = Path:new {startid=4, endid=2, path="nw"},
  --        [3] = Path:new {startid=4, endid=3, path="n"},
  --        [5] = Path:new {startid=4, endid=5, path="w"}
  --      }
  --    },
  --    [5] = Room:new {
  --      id=5, code="r5", name="room5",
  --      paths = {
  --        [1] = Path:new {startid=5, endid=1, path="nw"},
  --        [4] = Path:new {startid=5, endid=4, path="e"}
  --      }
  --    },
  --    [6] = Room:new {
  --      id=6, code="r6", name="room6",
  --      paths = {
  --        [3] = Path:new {startid=6, endid=3, path="sw"}
  --      }
  --    },
  --    [7] = Room:new {
  --      id=7, code="r7", name="room7",
  --      paths = {
  --        [1] = Path:new {startid=7, endid=1, path="s"},
  --        [2] = Path:new {startid=7, endid=2, path="e"}
  --      }
  --    }
  --  }
  --}

  return Algo
end
return define_Algo()
