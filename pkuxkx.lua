--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/2/25
-- Time: 12:26
-- To change this template use File | Settings | File Templates.
--

--------------------------------------------------------------
-- defines dependencies
--------------------------------------------------------------
local predefines = function()
  if not _G["world"] then require "world" end
  if not _G["world"] then require "socket.core" end
  local sleep = function(n)
    socket.select(nil, nil, n)
  end
  require "tprint"
  require "wait"
end
predefines()

local define_helper = function()
  local helper = {}

  -- convert chinese string to number
  local _nums = {
    ["一"] = 1,
    ["二"] = 2,
    ["三"] = 3,
    ["四"] = 4,
    ["五"] = 5,
    ["六"] = 6,
    ["七"] = 7,
    ["八"] = 8,
    ["九"] = 9
  }
  helper.ch2number = function (str)
    if (#str % 2) == 1 then
      return 0
    end
    local result = 0
    local _10k = 1
    local unit = 1
    for i = #str - 2, 0, -2 do
      local char = string.sub(str, i + 1, i + 2)
      if char == "十" then
        unit = 10 * _10k
        if i == 0 then
          result = result + unit
        elseif _nums[string.sub(str, i - 1, i)] == nil then
          result = result + unit
        end
      elseif char == "百" then
        unit = 100 * _10k
      elseif char == "千" then
        unit = 1000 * _10k
      elseif char == "万" then
        unit = 10000 * _10k
        _10k = 10000
      else
        if _nums[char] ~= nil then
          result = result + _nums[char] * unit
        end
      end
    end
    return result
  end

  -- convert chinese directions
  local _dirs = {
    ["上"] = "up",
    ["下"] = "down",
    ["南"] = "south",
    ["东"] = "east",
    ["西"] = "west",
    ["北"] = "north",
    ["南上"] = "southup",
    ["南下"] = "southdown",
    ["西上"] = "westup",
    ["西下"] = "westdown",
    ["东上"] = "eastup",
    ["东下"] = "eastdown",
    ["北上"] = "northup",
    ["北下"] = "northdown",
    ["西北"] = "northwest",
    ["东北"] = "northeast",
    ["西南"] = "southwest",
    ["东南"] = "southeast",
    ["小道"] = "xiaodao",
    ["小路"] = "xiaolu"
  }
  helper.ch2direction = function (str) return _dirs(str) end

  -- convert chinese areas
  local areas = {
    {
    },
    {
      ["中原"] = true,
      ["曲阜"] = true,
      ["信阳"] = true,
      ["泰山"] = true,
      ["长江"] = true,
      ["嘉兴"] = true,
      ["泉州"] = true,
      ["江州"] = true,
      ["牙山"] = true,
      ["西湖"] = true,
      ["福州"] = true,
      ["南昌"] = true,
      ["镇江"] = true,
      ["苏州"] = true,
      ["昆明"] = true,
      ["桃源"] = true,
      ["岳阳"] = true,
      ["成都"] = true,
      ["北京"] = true,
      ["天坛"] = true,
      ["洛阳"] = true,
      ["灵州"] = true,
      ["晋阳"] = true,
      ["襄阳"] = true,
      ["长安"] = true,
      ["扬州"] = true,
      ["丐帮"] = true,
      ["峨嵋"] = true,
      ["华山"] = true,
      ["全真"] = true,
      ["古墓"] = true,
      ["星宿"] = true,
      ["明教"] = true,
      ["灵鹫"] = true,
      ["兰州"] = true
    },
    {
      ["临安府"] = true,
      ["归云庄"] = true,
      ["小山村"] = true,
      ["张家口"] = true,
      ["麒麟村"] = true,
      ["紫禁城"] = true,
      ["神龙岛"] = true,
      ["杀手帮"] = true,
      ["岳王墓"] = true,
      ["桃花岛"] = true,
      ["天龙寺"] = true,
      ["武当山"] = true,
      ["少林寺"] = true,
      ["白驼山"] = true,
      ["凌霄城"] = true,
      ["大轮寺"] = true,
      ["无量山"] = true,
      ["天地会"] = true
    },
    {
      ["西湖梅庄"] = true,
      ["长江南岸"] = true,
      ["长江北岸"] = true,
      ["黄河南岸"] = true,
      ["黄河北岸"] = true,
      ["大理城中"] = true,
      ["平西王府"] = true,
      ["康亲王府"] = true,
      ["日月神教"] = true,
      ["丝绸之路"] = true,
      ["姑苏慕容"] = true,
      ["峨眉后山"] = true
    },
    {
      ["建康府南城"] = true,
      ["建康府北城"] = true,
      ["杭州提督府"] = true
    }
  }
  helper.ch2place = function(str)
    local place = {}
    for i = 5, 2, -1 do
      if string.len(str) >= i then
        local prefix = string.sub(str, 1, i)
        if areas[i][prefix] then
          place.area = prefix
          place.room = string.sub(str, i + 1, string.len(str))
          break
        end
      end
    end
    return place
  end

  -- convenient way to add trigger
end
local helper = define_helper()

--------------------------------------------------------------
-- db.lua
-- handle db operations
--------------------------------------------------------------
local define_db = function()
  if not _G["world"] then require "lsqlite3" end

  local memdb = {
    SQL_GET_ALL_ROOMS = "select * from rooms",
    SQL_GET_ALL_PATHS = "select * from paths",
    SQL_GET_ROOM_BY_ID = "select * from rooms where id = ?",
    SQL_GET_ROOMS_BY_NAME = "select * from rooms where name = ?",
    SQL_GET_PATHS_BY_STARTID = "select * from paths where startid = ?"
  }

  local getDataFromFile = function(filename, sql)
    local db = sqlite3.open(filename, 0)
    local results = {}
    local stmt = db:prepare(sql)
    while true do
      local result = stmt:step()
      if result == sqlite3.DONE then
        break
      end
      assert(result == sqlite3.ROW, "Row not found")
      local row = stmt:get_named_values()
      table.insert(results, row)
    end
    stmt:finalize()
    db:close()

    return results
  end

  local doLoad = function(db, sql, rows, bindRow)
    local stmt = db:prepare(sql)
    for idx, row in ipairs(rows) do
      bindRow(stmt, row)
      local result = stmt:step()
      if result ~= sqlite3.DONE then error(db:errmsg()) end
      stmt:reset()
    end
    stmt:finalize()
  end

  local loadDataInMem = function(filename, db)
    local rooms = getDataFromFile(filename, "select * from rooms")
    local roomsSql = "insert into rooms (id, code, name, description, exits, zone) values (?,?,?,?,?,?)"
    local bindRoom = function(stmt, row) stmt:bind_values(row.id, row.code, row.name, row.description, row.exits, row.zone) end
    doLoad(db, roomsSql, rooms, bindRoom)
    local paths = getDataFromFile(filename, "select * from paths")
    local pathsSql = "insert into paths (startid, endid, path, endcode, weight) values (?,?,?,?,?)"
    local bindPath = function(stmt, row) stmt:bind_values(row.startid, row.endid, row.path, row.endcode, row.weight) end
    doLoad(db, pathsSql, paths, bindPath)
  end

  function memdb:init(filename)
    self.db = sqlite3.open_memory()
    self.db:exec [[
    drop table if exists rooms;
    create table rooms (
      id integer primary key autoincrement,
      code text,
      name text,
      description text,
      exits text,
      zone text
    );
    drop table if exists paths;
    create table paths (
      startid integer,
      endid integer,
      path text,
      endcode text,
      weight integer default 1
    );
  ]]
    loadDataInMem(filename, self.db)
    self.db:exec [[
    create index if not exists idx_paths_startid_endid on paths (startid, endid);
  ]]
  end

  function memdb:close()
    if self.db then self.db.close() end
  end

  local fetchRowsFromStmt = function(stmt)
    local results = {}
    while true do
      local result = stmt:step()
      if result == sqlite3.DONE then
        break
      end
      assert(result == sqlite3.ROW, "Row not found")
      local row = stmt:get_named_values()
      table.insert(results, row)
    end
    return results
  end

  local fetchRows = function(db, sql, bind, ...)
    if not db then error("mem db already closed", 2) end
    local stmt = db:prepare(sql)
    if bind and arg then bind(stmt, ...) end
    local results = fetchRowsFromStmt(stmt)
    stmt:finalize()
    return results
  end

  function memdb:getAllRooms()
    if not self.db then error("mem db already closed") end
    return fetchRows(self.db, self.SQL_GET_ALL_ROOMS)
  end

  function memdb:getAllPaths()
    if not self.db then error("mem db already closed") end
    return fetchRows(self.db, self.SQL_GET_ALL_PATHS)
  end

  function memdb:getRoomById(id)
    if not self.db then error("mem db already closed") end
    local results = fetchRows(self.db, self.SQL_GET_ROOM_BY_ID, id)
    return results[1]
  end

  function memdb:getRoomsByName(name)
    if not self.db then error("mem db already closed") end
    return fetchRows(self.db, self.SQL_GET_ROOMS_BY_NAME, name)
  end

  return memdb
end
local memdb = define_db()

--------------------------------------------------------------
-- minheap.lua
-- data structure of min-heap
--------------------------------------------------------------
local define_minheap = function()
  local minheap = {}

  -- args:
  function minheap:new()
    local obj = {}
    -- store the actual heap in array
    obj.array = {}
    -- store the position of element, id -> pos
    obj.map = {}
    obj.size = 0
    setmetatable(obj, {__index = self})
    return obj
  end

  function minheap:updatePos(pos)
    self.map[self.array[pos].id] = pos
  end

  function minheap:contains(id)
    return self.map[id] ~= nil
  end

  function minheap:get(id)
    if self.map[id] == nil then return nil end
    return self.array[self.map[id]]
  end

  function minheap:insert(elem)
    local pos = self.size + 1
    self.array[pos] = elem
    self:updatePos(pos)
    local parent = math.ceil(pos / 2)
    while pos > 1 do
      if self.array[pos] < self.array[parent] then
        self.array[pos], self.array[parent] = self.array[parent], self.array[pos]
        -- after the swap, we need to update the position map
        self:updatePos(parent)
        self:updatePos(pos)
        pos, parent = parent, math.ceil(parent / 2)
      else
        break
      end
    end
    self.size = self.size + 1
  end

  function minheap:removeMin()
    if self.size == 0 then error("heap is empty") end
    if self.size == 1 then
      self.size = 0
      return table.remove(self.array)
    end
    local first = self.array[1]
    local last = table.remove(self.array)
    -- move last to position of first and fix the structure
    local pos, c1, c2 = 1, 2, 3
    self.array[pos] = last
    self:updatePos(pos)
    while true do
      -- find the minimum element
      local minPos = pos
      if self.array[c1] and self.array[c1] < self.array[minPos] then
        minPos = c1
      end
      if self.array[c2] and self.array[c2] < self.array[minPos] then
        minPos = c2
      end
      if minPos ~= pos then
        self.array[pos], self.array[minPos] = self.array[minPos], self.array[pos]
        -- update pos map
        self:updatePos(pos)
        self:updatePos(minPos)
        pos, c1, c2 = minPos, minPos * 2, minPos * 2 + 1
      else
        break
      end
    end
    self.size = self.size - 1
    return first
  end

  function minheap:replace(newElem)
    local pos = self.map[newElem.id]
    if pos == nil then error("cannot find element with id" .. newElem.id) end
    local elem = self.array[pos]
    if newElem > elem then error("current version only support replace element with smaller one") end
    self.array[pos] = newElem
    -- we also need to fix the order in heap to make sure it's minimized
    local parent = math.floor(pos / 2)
    while pos > 1 do
      if self.array[pos] < self.array[parent] then
        self.array[pos], self.array[parent] = self.array[parent], self.array[pos]
        -- after the swap, we need to update the position map
        self:updatePos(parent)
        self:updatePos(pos)
        pos, parent = parent, math.ceil(parent / 2)
      else
        break
      end
    end
  end

  return minheap
end
local minheap = define_minheap()

--------------------------------------------------------------
-- Path.lua
-- data structure of Path
--------------------------------------------------------------
local define_PathCategory = function()
  local PathCategory = {}
  PathCategory.Normal = 1
  PathCategory.MultipleCmds = 2
  PathCategory.Trigger = 3

  return PathCategory
end
local PathCategory = define_PathCategory()

--------------------------------------------------------------
-- Path.lua
-- data structure of Path
--------------------------------------------------------------
local define_Path = function()
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
    obj.category = args.category or PathCategory.Normal
    setmetatable(obj, self)
    return obj
  end

  return Path
end
local Path = define_Path()

--------------------------------------------------------------
-- Room.lua
-- data structure of Room
--------------------------------------------------------------
local define_Room = function()
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
end
local Room = define_Room()

--------------------------------------------------------------
-- Distance.lua
-- data structure of Distance
--------------------------------------------------------------
local define_Distance = function()
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
end
local Distance = define_Distance()

local define_PlanMode = function()
  local PlanMode = {}
  PlanMode.Quick = 1
  PlanMode.Delay = 2
  PlanMode.Trigger = 3

  return PlanMode
end
local PlanMode = define_PlanMode()

--------------------------------------------------------------
-- Plan.lua
-- This class handles how to walk in xkx world
-- there are three mode as below
-- Quick
-- Delay
-- Trigger
--
-- Quick mode tries to walk to target place as fast as possible
-- but still wait if needed, e.g. take on a boat,
-- blocked by someone, ...
-- Delay mode tries to walk to target with delay of given amount
-- of time on each step
-- Trigger mode has the most power. We can define actions before,
-- or after each move.
--
--
--------------------------------------------------------------
local define_Plan = function()
  local Plan = {}
  local emptyF = function() end
  Plan._startid = -1
  Plan._paths = {}
  Plan._mode = nil
  Plan._started = false
  Plan._finished = false
  Plan._quickSteps = 10
  Plan._delay = 0.2
  Plan.beforeStart = emptyF
  Plan.afterFinish = emptyF
  Plan.beforeMove = emptyF
  Plan.afterMove = emptyF
  -- OOP
  Plan.__index = Plan

  local pathEval = function(path)
    if path.category == PathCategory.Normal then
      print(path.path)
    elseif path.category == PathCategory.MultipleCmds then
      local cmds = utils.split(path.path, ";")
      for i= 1, #cmds do
        print(cmds[i])
      end
    elseif path.category == PathCategory.Trigger then
      SendNoEcho("set travel trigger")
      wait.regexp("")
    else
      error("unexpected path category " .. path.category)
    end
  end

  function Plan:createCo()
    return coroutine.create(function()
      local steps = self._quickSteps
      local delay = self._delay
      local i = 1
      while #(self._paths) do
        if i >= steps then
          SendNoEcho("set travel rest")
          wait.regexp("")
          i = 0
        end
        i = i + 1
        local next = table.remove(self._paths)
        if self._mode == PlanMode.Delay then
          wait.time(delay)
        elseif self._mode == PlanMode.Trigger then
          SendNoEcho("set travel go")
          wait.regexp("")
        end
        self:beforeMove()
        pathEval(path)
        self:afterMove()
      end
    end)
  end

  function Plan:len()
    return #(self._paths)
  end

  function Plan:isStarted()
    return self._started
  end

  function Plan:isFinished()
    return self._finished
  end

  function Plan:start()
    local walker = self:createCo()
    self:beforeStart()
    coroutine.resume(walker)
    self.afterFinish()
  end

  function Plan:new(args)
    assert(type(args.startid) == "number", "startid of args must be number")
    assert(args.paths, "paths of args cannot be nil")
    assert(args.mode, "mode of args cannot be nil")
    assert(args.beforeStart == nil or type(args.beforeStart) == "function", "beforeStart must be nil or function")
    assert(args.afterFinish == nil or type(args.afterFinish) == "function", "afterFinish must be nil or function")
    assert(args.beforeMove == nil or type(args.beforeMove) == "function", "beforeMove must be nil or function")
    assert(args.afterMove == nil or type(args.afterMove) == "function", "afterMove must be nil or function")
    local obj = {}
    obj._startid = args.startid
    obj._paths = args.paths
    obj._mode = args.mode
    if args.mode == PlanMode.Quick then
      obj._quickSteps = args.quickSteps or Plan._quickSteps
    elseif args.mode == PlanMode.Delay then
      obj._delay = args.delay or Plan._delay
    elseif args.mode == PlanMode.Trigger then

    end
    if (args.beforeStart) then obj.beforeStart = args.beforeStart end
    if (args.afterFinish) then obj.afterFinish = args.afterFinish end
    if (args.beforeMove) then obj.beforeMove = args.beforeMove end
    if (args.afterMove) then obj.afterMove = args.afterMove end
    setmetatable(obj, self)
    return obj
  end
  return Plan
end
local Plan = define_Plan()

--------------------------------------------------------------
-- Algo.lua
-- Implement algorithm of searching path
-- current solution is based on A*
--------------------------------------------------------------
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
      local min = opens:removeMin()
      local minRoom = rooms[min.id]
      local paths = minRoom and minRoom.paths or {}
      for _, path in pairs(paths) do
        local endid = path.endid
        if endid == targetid then
          prev[endid] = min.id
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
end
local Algo = define_Algo()

--------------------------------------------------------------
-- travel.lua
-- Implement the walk, locate, traverse functionalities
-- in xkx world
--------------------------------------------------------------
local define_travel = function()
  local travel = {}
  travel.roomName = nil
  travel.roomDescInline = false
  travel.roomDesc = nil
  travel.exitsInline = false
  travel.exits = nil

  function travel.clearRoomInfo()
    travel.roomName = nil
    travel.roomDescInline = false
    travel.roomDesc = nil
    travel.exitsInline = false
    travel.exits = nil
  end

  local initRoomsAndPaths = function()
    local allRooms = memdb:getAllRooms()
    local rooms = {}
    for i = 1, #allRooms do
      rooms[allRooms[i].id] = Room:new(allRooms[i])
    end
    local allPaths = memdb:getAllPaths()
    for i = 1, #allPaths do
      local path = allPaths[i]
      local startroom = rooms[path.startid]
      if startroom then
        startroom:addPath(Path:new(path))
      end
    end
    travel.rooms = rooms
  end

  -- add trigger but disabled
  local TRIGGER_BASE_FLAG = trigger_flag.RegularExpression
    + trigger_flag.Replace + trigger_flag.KeepEvaluating
  local COPY_WILDCARDS_NONE = 0
  local SOUND_FILE_NONE = ""
  -- make sure the name is unique
  local _global_trigger_functions = {}
  local add_trigger = function(name, regexp, group, response, sequence)
    local sequence = sequence or 10
    if type(response) == "string" then
      check(AddTriggerEx(name, regexp, "", TRIGGER_BASE_FLAG, custom_colour.NoChange, COPY_WILDCARDS_NONE, SOUND_FILE_NONE, response, sendto.world, sequence))
    elseif type(response) == "function" then
      _G[name] = response
      _global_trigger_functions[name] = true
      check(AddTriggerEx(name, regexp, "", TRIGGER_BASE_FLAG, custom_color.NoChange))
    end
    SetTriggerOption(name, "group", group)
  end

  local remove_trigger = function(name)
    if _global_trigger_functions[name] then
      _G[name] = nil
    end
    check(DeleteTrigger(name))
  end

  -- bind search implementation to A* algorithm
  -- should enhance with hypothesis functions to reduce search range
  function travel:search(startid, endid)
    return Algo.astar(startid, endid, self.rooms)
  end

  function travel:locate()
    check(EnableTriggerGroup("travel_locate_start", true))
    check(SendNoEcho("set travel_locate start"))
    check(SendNoEcho("look"))
    check(SendNoEcho("set travel_locate stop"))
    print("roomName:" .. self.roomName)
    print("exits:" .. self.exits)
    print("roomDesc:" .. self.roomDesc)
  end

  local initLocateTriggers = function()
    -- start trigger
    local start = function(name, line, wildcards)
      print("trigger "..name.." triggered")
      check(EnableTriggerGroup("travel_locate", true))
      travel.clearRoomInfo()
    end
    add_trigger(
      "trigger" .. GetUniqueID(),
      "^[ >]*设定环境变量：travel_locate = \"start\"",
      "travel_locate_start",
      start
    )
    -- room name trigger with area
    local roomNameCaught = function(name, line, wildcards)
      print("trigger "..name.." triggered")
      travel.roomName = wildcards[1]
      travel.roomDescInline = true
      travel.roomExitsInline = true
    end
    add_trigger(
      "trigger" .. GetUniqueID(),
      "^[ >]*([^ ]+) \- \[[^ ]+\]$",
      "travel_locate",
      roomNameCaught
    )
    -- room name trigger without area
    local roomNameCaughtNoArea = function(name, line, wildcards)
      print("trigger "..name.." triggered")
      travel.roomName = wildcards[1]
      travel.roomDescInline = true
    end
    add_trigger(
      "trigger" .. GetUniqueID(),
      "^[ >]*([^ ]+) \- $",
      "travel_locate",
      roomNameCaughtNoArea
    )
    -- room desc
    local roomDescCaught = function(name, line, wildcards)
      print("trigger "..name.." triggered")
      if travel.roomDescInline then
        local currDesc = travel.roomDesc or ""
        travel.roomDesc = currDesc .. wildcards[1]
      end
    end
    add_trigger(
      "trigger" .. GetUniqueID(),
      "^ *(.*?) *$",
      "travel_locate",
      roomDescCaught
    )
    -- room desc end
    local seasonCaught = function(name, line, wildcards)
      print("trigger "..name.." triggered")
      if travel.roomDescInline then travel.roomDescInline = false end
      local season = wildcards[1]
      local datetime = wildcards[2]
    end
    add_trigger(
      "trigger" .. GetUniqueID(),
      "^    「([^」]+)」: (.*)$",
      "travel_locate",
      seasonCaught,
      5 -- higher than room desc
    )
    -- room desc end
    local exitsCaught = function(name, line, wildcards)
      print("trigger "..name.." triggered")
      if travel.roomDescInline then travel.roomDescInline = false end
      if travel.exitsInline then
        travel.exitsInline = false
        local exits = wildcards[2] or "look"
        exits = string.gsub(exits,"。","")
        exits = string.gsub(exits," ","")
        exits = string.gsub(exits,"、", ";")
        exits = string.gsub(exits, "和", ";")
        local tb = {}
        for _, str in ipairs(utils.split(exits,";")) do
          local t = Trim(str)
          if t ~= "" then table.insert(tb, t) end
        end
        travel.exits = table.concat(tb, ";") .. ";"
      end

    end
    add_trigger(
      "trigger" .. GetUniqueID(),
      "^\\s*这里(明显|唯一)的出口是(.*)$|^\\s*这里没有任何明显的出路\\w*",
      "travel_locate",
      exitsCaught,
      5 -- higher than room desc
    )
    -- stop trigger
    local stop = function(name, line, wildcards)
      print("trigger "..name.." triggered")
      check(EnableTriggerGroup("travel_locate_start", false))
      check(EnableTriggerGroup("travel_locate", false))
      -- summary
      print("roomName", travel.roomName)
      print("roomDescInline", travel.roomDescInline)
      print("roomDesc", travel.roomDesc)
      print("exitsInline", travel.exitsInline)
      print("exits", travel.exits)
    end
  end

  -- do initialization
  memdb:init("data/pkuxkx.db")
  initRoomsAndPaths()
  if _G["world"] then initLocateTriggers() end

  return travel
end
local travel = define_travel()


for i = 2,1000 do
  local paths, sid, eid = travel:search(1, i)
  if not paths then print(i) end
end
