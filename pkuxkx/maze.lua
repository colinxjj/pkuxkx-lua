----
-- Handle the maze
-- Assumptions:
-- 1. there is one unique start room can be identified,
-- 2. all paths in the maze are reversble
----

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local idgen = require "pkuxkx.idgen"
local deque = require "pkuxkx.deque"

local ReversePath = {
  ["east"] = "west",
  ["south"] = "north",
  ["west"] = "east",
  ["north"] = "south",
  ["northeast"] = "southwest",
  ["southeast"] = "northwest",
  ["southwest"] = "northwest",
  ['northwest'] = "southeast",
  ["eastup"] = "westdown",
  ["eastdown"] = "westup",
  ["southup"] = "northdown",
  ["southdown"] = "northup",
  ["westup"] = "eastdown",
  ["westdown"] = "eastup",
  ["northup"] = "southdown",
  ["northdown"] = "southup",
  ["up"] = "down",
  ["down"] = "up",
  ["enter"] = "out",
  ["out"] = "enter",
}


local define_Room = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    local obj = {}
    obj.id = args.id
    obj.name = args.name
    obj.description = obj.description
    obj.exits = obj.exits
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
local Room = define_Room()

local define_Path = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    local obj = {}
    obj.startid = args.startid
    obj.endid = args.endid
    obj.path = args.path
    -- obj.origpath = args.origpath
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:rootPaths()

  end

  return prototype
end
local Path = define_Path()

local define_maze = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    explore = "explore",
    identify = "identify",
    search = "search",
  }
  local Events = {
    STOP = "stop",
    START = "start",
    EXPLORE = "explore",
    IDENTIFY = "identify",
    EXPLORED = "explored",
    MOVE = "move",
    MOVED = "moved",
  }
  local REGEXP = {
    ALIAS_START = "^maze\\s+start\\s*$",
    ALIAS_STOP = "^maze\\s+stop\\s*$",
    ALIAS_DEBUG = "^maze\\s+debug\\s+(on|off)\\s*$",
  }

  function prototype:FSM()
    local obj = FSM:new()
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self:initStates()
    self:initTransitions()
    self:initTriggers()
    self:initAliases()
    self:setState(States.stop)

    self.waitThread = nil
    self.idgen = idgen:new()
    self.root = nil
    self.roomsById = {}
    self.paths = {}
    self.pathsToExplore = {}
    self.pathsExplored = {}
  end

  function prototype:disableAllTriggers()

  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
      end,
      exit = function() end
    }
    self:addState {
      state = States.explore,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.identify,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.search,
      enter = function() end,
      exit = function() end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.explore,
      event = Events.START,
      action = function()
        return self:doStart()
      end
    }
    self:addTransitionToStop(States.stop)

  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("maze_move")

    helper.addTrigger {
      group = "maze_move",
      regexp = helper.settingRegexp("maze", "moving"),
      response = function()
        return self:fire(Events.MOVE)
      end
    }
    helper.addTrigger {
      group = "maze_move",
      regexp = helper.settingRegexp("maze", "moved"),
      response = function()
        if self.waitThread then
          local co = self.waitThread
          self.waitThread = nil
          local ok, err = coroutine.resume(co)
          if not ok then
            error(err)
          end
        end
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("maze")
    helper.addAlias {
      group = "maze",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "maze",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "maze",
      regexp = REGEXP.ALIAS_DEBUG,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self:debugOn()
        else
          self:debugOff()
        end
      end
    }
  end

  function prototype:addTransitionToStop(fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function()
        print("停止 - 当前状态", self.currState)
      end
    }
  end

  function prototype:doStart()
    travel:lookUntilNotBusy()
    local room = Room:new {
      id = self.idgen:next(),
      name = travel.currRoomName,
      description = table.concat(self.currRoomDesc, ""),
      exits = self.currRoomExits
    }
    local moves = utils.split(room.exits, ";")
    local pathsToExplore = {}
    for _, move in ipairs(moves) do
      local path = Path:new {
        startid = room.id,
        -- currently do not know endid
        path = move,
      }
      table.insert(pathsToExplore, path)
    end
    self.pathsToExplore = pathsToExplore
    self.root = room
    self.roomsById[room.id] = room
    return self:fire(Events.EXPLORE)
  end

  function prototype:doExplore()
    if #(self.pathsToExplore) > 0 then
      local move = table.remove(self.pathsToExplore)
      if self:isPathExplored(move) then
        self:debug("Path is already explored:", move.startid, move.path)
        return self:fire(Events.EXPLORE)
      else
        self:setPathExplored(move)
        -- check whether the current room id is same as move.startid
        if self.currRoomId == move.startid then
          self:moveTo(move.startid)
        end
      end
    else
      return self:fire(Events.EXPLORED)
    end
  end

  function prototype:isPathExplored(move)
    local key = move.startid .. ":" .. move.path
    return self.pathsExplored[key]
  end

  function prototype:setPathExplored(move)
    local key = move.startid .. ":" .. move.path
    self.pathExplored[key] = true
  end

  function prototype:moveUntilArrived(roomId)
    local pathStack = self:dfs(self.currRoomId, roomId)
    if not pathStack then
      error("无法从当前地点前进到" .. roomId)
    end
    self.waitThread = assert(coroutine.running(), "Must be in coroutine")
    self.moveStack = pathStack
    self:fire(Events.MOVE)

    return coroutine.yield()
  end

  function prototype:doMove()
    if #(self.moveStack) > 0 then
      local move = table.remove(self.moveStack)
      helper.checkUntilNotBusy()
      SendNoEcho(move.path)
      SendNoEcho("set maze moving")
    else
      SendNoEcho("set maze moved")
    end
  end

  function prototype:bfs(startid, endid)
    local ids = deque:new()
    local traversed = {}
    local prev = {}
    table.insert(ids, startid)
    while ids:size() > 0 do
      local roomId = ids:removeFirst()
      if not traversed[roomId] then
        traversed[roomId] = true
        if roomId == endid then
          break
        end
        local room = self.roomsById[roomId]
        if room.paths then
          for _, path in pairs(room.paths) do
            if not traversed[path.endid] then
              prev[path.endid] = path.startid
              ids:addLast(path.endid)
            end
          end
        end
      end
    end
    local eid = endid
    local pathStack = {}
    while prev[eid] do
      local sid = prev[eid]
      local room = self.roomsById[sid]
      table.insert(pathStack, room.paths[eid])
      -- 当追溯至起点时中止
      if sid == startid then
        break
      else
        eid = sid
      end
    end
    return nil
  end

  return prototype
end
return define_maze():FSM()

