--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/1
-- Time: 11:49
-- To change this template use File | Settings | File Templates.
--
require "constants"

require "check"
local memdb = require "utils/db"
memdb:init("data/pkuxkx.db")

local Path = require "travel.Path"
local Room = require "travel.Room"
local Algo = require "travel.Algo"

local travel = {}
travel.roomName = nil
travel.roomDescInline = false
travel.roomDesc = nil
travel.exitsInline = false
travel.exits = nil

local clearRoomInfo = function()
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
-- do initialization
initRoomsAndPaths()

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
end

local initLocateTriggers = function()
  -- start trigger
  local start = function(name, line, wildcards)
    print("trigger "..name.." triggered")
    check(EnableTriggerGroup("travel_locate", true))
    clearRoomInfo()
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

  end
  -- room desc end
  local exitsCaught = function(name, line, wildcards)
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
--    check(DisableTriggerGroup("travel_locate_start", false))
--    check(DisableTriggerGroup("travel_locate", false))
  end
  add_trigger(
    "trigger" .. GetUniqueID(),
    "^\\s*这里(明显|唯一)的出口是(.*)$|^\\s*这里没有任何明显的出路\\w*",
    "travel_locate",
    exitsCaught
  )
  -- stop trigger
  local stop = function(name, line, wildcards)
    print("trigger "..name.." triggered")
    check(EnableTriggerGroup("travel_locate_start", false))
    check(EnableTriggerGroup("travel_locate", false))
  end
end



return travel
