--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/2/25
-- Time: 12:26
--
-- Remember what Donald Knuth said:
-- Premature optimization is the root of all evil
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

  -- define useful constants here
  trigger_info_flag = {}
  trigger_info_flag.group = 26
  alias_info_flag = {}
  alias_info_flag.group = 16

  -- error code
  eOK = 0; -- No error
  eWorldOpen = 30001; -- The world is already open
  eWorldClosed = 30002; -- The world is closed, this action cannot be performed
  eNoNameSpecified = 30003; -- No name has been specified where one is required
  eCannotPlaySound = 30004; -- The sound file could not be played
  eTriggerNotFound = 30005; -- The specified trigger name does not exist
  eTriggerAlreadyExists = 30006; -- Attempt to add a trigger that already exists
  eTriggerCannotBeEmpty = 30007; -- The trigger "match" string cannot be empty
  eInvalidObjectLabel = 30008; -- The name of this object is invalid
  eScriptNameNotLocated = 30009; -- Script name is not in the script file
  eAliasNotFound = 30010; -- The specified alias name does not exist
  eAliasAlreadyExists = 30011; -- Attempt to add a alias that already exists
  eAliasCannotBeEmpty = 30012; -- The alias "match" string cannot be empty
  eCouldNotOpenFile = 30013; -- Unable to open requested file
  eLogFileNotOpen = 30014; -- Log file was not open
  eLogFileAlreadyOpen = 30015; -- Log file was already open
  eLogFileBadWrite = 30016; -- Bad write to log file
  eTimerNotFound = 30017; -- The specified timer name does not exist
  eTimerAlreadyExists = 30018; -- Attempt to add a timer that already exists
  eVariableNotFound = 30019; -- Attempt to delete a variable that does not exist
  eCommandNotEmpty = 30020; -- Attempt to use SetCommand with a non-empty command window
  eBadRegularExpression = 30021; -- Bad regular expression syntax
  eTimeInvalid = 30022; -- Time given to AddTimer is invalid
  eBadMapItem = 30023; -- Direction given to AddToMapper is invalid
  eNoMapItems = 30024; -- No items in mapper
  eUnknownOption = 30025; -- Option name not found
  eOptionOutOfRange = 30026; -- New value for option is out of range
  eTriggerSequenceOutOfRange = 30027; -- Trigger sequence value invalid
  eTriggerSendToInvalid = 30028; -- Where to send trigger text to is invalid
  eTriggerLabelNotSpecified = 30029; -- Trigger label not specified/invalid for 'send to variable'
  ePluginFileNotFound = 30030; -- File name specified for plugin not found
  eProblemsLoadingPlugin = 30031; -- There was a parsing or other problem loading the plugin
  ePluginCannotSetOption = 30032; -- Plugin is not allowed to set this option
  ePluginCannotGetOption = 30033; -- Plugin is not allowed to get this option
  eNoSuchPlugin = 30034; -- Requested plugin is not installed
  eNotAPlugin = 30035; -- Only a plugin can do this
  eNoSuchRoutine = 30036; -- Plugin does not support that subroutine (subroutine not in script)
  ePluginDoesNotSaveState = 30037; -- Plugin does not support saving state
  ePluginCouldNotSaveState = 30037; -- Plugin could not save state (eg. no state directory)
  ePluginDisabled = 30039; -- Plugin is currently disabled
  eErrorCallingPluginRoutine = 30040; -- Could not call plugin routine
  eCommandsNestedTooDeeply = 30041; -- Calls to "Execute" nested too deeply
  eCannotCreateChatSocket = 30042; -- Unable to create socket for chat connection
  eCannotLookupDomainName = 30043; -- Unable to do DNS (domain name) lookup for chat connection
  eNoChatConnections = 30044; -- No chat connections open
  eChatPersonNotFound = 30045; -- Requested chat person not connected
  eBadParameter = 30046; -- General problem with a parameter to a script call
  eChatAlreadyListening = 30047; -- Already listening for incoming chats
  eChatIDNotFound = 30048; -- Chat session with that ID not found
  eChatAlreadyConnected = 30049; -- Already connected to that server/port
  eClipboardEmpty = 30050; -- Cannot get (text from the) clipboard
  eFileNotFound = 30051; -- Cannot open the specified file
  eAlreadyTransferringFile = 30052; -- Already transferring a file
  eNotTransferringFile = 30053; -- Not transferring a file
  eNoSuchCommand = 30054; -- There is not a command of that name
  eArrayAlreadyExists = 30055;  -- Chat session with that ID not found
  eArrayDoesNotExist = 30056;  -- Already connected to that server/port
  eArrayNotEvenNumberOfValues = 30057;  -- Cannot get (text from the) clipboard
  eImportedWithDuplicates = 30058;  -- Cannot open the specified file
  eBadDelimiter = 30059;  -- Already transferring a file
  eSetReplacingExistingValue = 30060;  -- Not transferring a file
  eKeyDoesNotExist = 30061;  -- There is not a command of that name
  eCannotImport = 30062;  -- There is not a command of that name
  eItemInUse = 30063;   -- Cannot delete trigger/alias/timer because it is executing a script
  eSpellCheckNotActive = 30064;     -- Spell checker is not active
  eSpellCheckNotActive = 30064;    -- Spell checker is not active
  eCannotAddFont = 30065;          -- Cannot create requested font
  ePenStyleNotValid = 30066;       -- Invalid settings for pen parameter
  eUnableToLoadImage = 30067;      -- Bitmap image could not be loaded
  eImageNotInstalled = 30068;      -- Image has not been loaded into window
  eInvalidNumberOfPoints = 30069;  -- Number of points supplied is incorrect
  eInvalidPoint = 30070;           -- Point is not numeric
  eHotspotPluginChanged = 30071;   -- Hotspot processing must all be in same plugin
  eHotspotNotInstalled = 30072;    -- Hotspot has not been defined for this window
  eNoSuchWindow = 30073;           -- Requested miniwindow does not exist
  eBrushStyleNotValid = 30074;     -- Invalid settings for brush parameter
end
predefines()

local define_helper = function()
  local helper = {}
  -- add trigger but disabled
  local TRIGGER_BASE_FLAG = trigger_flag.RegularExpression
    + trigger_flag.Replace + trigger_flag.KeepEvaluating
  local COPY_WILDCARDS_NONE = 0
  local SOUND_FILE_NONE = ""
  -- make sure the name is unique
  local _global_trigger_callbacks = {}
  helper.addTrigger = function(args)
    local regexp = assert(type(args.regexp) == "string" and args.regexp, "regexp in trigger must be string")
    local group = assert(args.group, "group in trigger cannot be empty")
    local response = assert(args.response, "response in trigger cannot be empty")
    local name = args.name or "auto_added_trigger_" .. GetUniqueID()
    local sequence = args.sequence or 10
    if type(args.response) == "string" then
      check(AddTriggerEx(name, regexp, response, TRIGGER_BASE_FLAG, custom_colour.NoChange, COPY_WILDCARDS_NONE, SOUND_FILE_NONE, "", sendto.world, sequence))
    elseif type(response) == "function" then
      _G.world[name] = response
      _global_trigger_callbacks[name] = true
      check(AddTriggerEx(name, regexp, "", TRIGGER_BASE_FLAG, custom_colour.NoChange, COPY_WILDCARDS_NONE, SOUND_FILE_NONE, name, sendto.script, sequence))
    else
      error("response type is unexpected " .. type(response))
    end
    check(SetTriggerOption(name, "group", group))
  end

  helper.removeTrigger = function(name)
    if _global_trigger_callbacks[name] then
      _global_trigger_callbacks[name] = nil
      _G.world[name] = nil
    end
    local retCode = DeleteTrigger(name)
    print("remove trigger", name, retCode)
    assert(retCode == eOK or retCode == eTriggerNotFound)
  end

  helper.removeTriggerGroups = function(...)
    local groups = {}
    for _, group in ipairs({...}) do
      groups[group] = true
    end
    local triggerList = GetTriggerList()
    if triggerList then
      for i, trigger in ipairs(triggerList) do
        local group = GetTriggerInfo(trigger, trigger_info_flag.group)
        if groups[group] then
          helper.removeTrigger(trigger)
        end
      end
    end
  end

  local _global_alias_callbacks = {}
  local ALIAS_BASE_FLAG = alias_flag.Enabled + alias_flag.RegularExpression + alias_flag.Replace
  helper.addAlias = function(args)
    local regexp = assert(args.regexp, "regexp of alias cannot be empty")
    local response = assert(args.response, "response of alias cannot be empty")
    local group = assert(args.group, "group of alias cannot be empty")
    local name = args.name or "auto_added_alias_" .. GetUniqueID()
    if type(response) == "function" then
      _G.world[name] = response
      _global_alias_callbacks[name] = true
      check(AddAlias(name, regexp, "", ALIAS_BASE_FLAG, name))
      check(SetAliasOption(name, "send_to", sendto.script))
      check(SetAliasOption(name, "group", group))
    end
  end

  helper.removeAlias = function(name)
    if _global_alias_callbacks[name] then
      _global_alias_callbacks[name] = nil
      _G.world[name] = nil
    end
    local retCode = DeleteAlias(name)
    assert(retCode == eOK or retCode == eAliasNotFound)
  end

  helper.removeAliasGroups = function(...)
    local groups = {}
    for _, group in ipairs({...}) do
      groups[group] = true
    end
    local aliasList = GetAliasList()
    if aliasList then
      for i, alias in ipairs(aliasList) do
        local group = GetAliasInfo(alias, alias_info_flag.group)
        if groups[group] then
          helper.removeAlias(alias)
        end
      end
    end
  end

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

  return helper
end
local helper = define_helper()

--------------------------------------------------------------
-- db.lua
-- handle db operations
--------------------------------------------------------------
local define_db = function()
  if not _G["world"] then require "lsqlite3" end

  local prototype = {}
  prototype.__index = prototype

  -- Deprecated, use file db
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

  -- Deprecated, use file db
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

  -- Deprecated, use file db
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

  function prototype.open(filename)
    assert(filename, "filename cannot be empty")
    local obj = {}
    obj.db = sqlite3.open(filename)
    setmetatable(obj, prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self.stmts = {}
  end

  function prototype:close()
    if not self.db then error("db already closed") end
    for name, stmt in pairs(self.stmts) do
      stmt:finalize()
      self.stmts[name] = nil
    end
    self.db.close()
    self.db = nil
  end

  function prototype:prepare(args)
    assert(args, "args in prepare cannot be nil")
    for name, sql in pairs(args) do
      if self.stmts[name] then error("SQL " .. name .. " is already prepared", 2) end
      self.stmts[name] = self.db:prepare(sql)
    end
  end

  function prototype:fetchRowAs(args)
    assert(args.stmt, "stmt cannot be nil")
    local stmt = assert(self.stmts[args.stmt], "stmt is not prepared")
    local constructor = assert(args.constructor, "constructor cannot be nil")
    local params = args.params
    -- always reset the statement
    stmt:reset()
    if params then
      if type(params) == "table" then
        assert(stmt:bind_values(unpack(params)) == sqlite3.OK, "failed to bind values")
      else
        assert(stmt:bind_values(params) == sqlite3.OK, "failed to bind values")
      end
    end
    --assert(stmt:step() == sqlite3.ROW, "Row not found")
    if stmt:step() ~= sqlite3.ROW then
      return nil
    end
    return constructor(nil, stmt:get_named_values())
  end

  function prototype:fetchRowsAs(args)
    assert(args.stmt, "stmt cannot be nil")
    local stmt = assert(self.stmts[args.stmt], "stmt is not prepared")
    local constructor = assert(args.constructor, "constructor cannot be nil")
    local key = args.key
    if key and type(key) ~= "function" then
      error("key must be a function to generate dict", 2)
    end
    local params = args.params
    -- always reset the statement
    stmt:reset()
    if params then
      if type(params) == "table" then
        assert(stmt:bind_values(unpack(params)) == sqlite3.OK, "failed to bind values")
      else
        assert(stmt:bind_values(params) == sqlite3.OK, "failed to bind values")
      end
    end
    local results = {}
    while true do
      local result = stmt:step()
      if result == sqlite3.DONE then
        break
      end
      assert(result == sqlite3.ROW, "Row not found")
      local row = stmt:get_named_values()
      local obj = constructor(nil, row)
      if key then
        results[key(obj)] = obj
      else
        table.insert(results, obj)
      end
    end
    return results
  end

  return prototype
end
-- easy to switch to memory db
-- local db = define_db().open_memory_copied("xxx.db")
local db = define_db().open("data/pkuxkx.db")

--------------------------------------------------------------
-- minheap.lua
-- data structure of min-heap
--------------------------------------------------------------
local define_minheap = function()
  local prototype = {}
  prototype.__index = prototype

  -- args:
  function prototype:new()
    local obj = {}
    -- store the actual heap in array
    obj.array = {}
    -- store the position of element, id -> pos
    obj.map = {}
    obj.size = 0
    setmetatable(obj, {__index = self or prototype})
    return obj
  end

  function prototype:updatePos(pos)
    self.map[self.array[pos].id] = pos
  end

  function prototype:contains(id)
    return self.map[id] ~= nil
  end

  function prototype:get(id)
    if self.map[id] == nil then return nil end
    return self.array[self.map[id]]
  end

  function prototype:insert(elem)
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

  function prototype:removeMin()
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

  function prototype:replace(newElem)
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

  return prototype
end
local minheap = define_minheap()

--------------------------------------------------------------
-- PathCategory.lua
-- define PathCategory
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
  local prototype = {
    __eq = function(a, b) return a.weight == b.weight end,
    __lt = function(a, b) return a.weight < b.weight end,
    __le = function(a, b) return a.weight <= b.weight end
  }
  prototype.__index = prototype

  function prototype:new(args)
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
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
local Path = define_Path()

--------------------------------------------------------------
-- Room.lua
-- data structure of Room
--------------------------------------------------------------
local define_Room = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
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
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:addPath(path)
    self.paths[path.endid] = path
  end

  return prototype
end
local Room = define_Room()

--------------------------------------------------------------
-- Distance.lua
-- data structure of Distance
--------------------------------------------------------------
local define_Distance = function()
  local prototype = {
    __eq = function(a, b) return a.real + a.hypo == b.real + b.hypo end,
    __lt = function(a, b) return a.real + a.hypo < b.real + b.hypo end,
    __le = function(a, b) return a.real + a.hypo <= b.real + b.hypo end
  }
  prototype.__index = prototype

  function prototype:new(args)
    assert(args.id, "args of Distance must have valid id field")
    assert(args.real, "args of Distance must have valid real field")
    local obj = {}
    obj.id = args.id
    obj.real = args.real
    obj.hypo = args.hypo or 0
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
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
--local define_Plan = function()
--  local emptyF = function() end
--  local prototype = {}
--  prototype.__index = prototype
--  prototype.regexp = {
--    WRONG_WAY = "^[ >]*这个方向没有路。"
--  }
--  -- always be overwrite by instance variable
--  prototype.startid = -1
--  prototype.paths = {}
--  prototype.mode = nil
--
--  -- this module may offen requires debug enabled to track errors
--  prototype._DEBUG = false
--  prototype._started = false
--  prototype._finished = false
--  prototype._quickSteps = 10
--  prototype._delay = 0.2
--  prototype._mayBeLost = false
--  prototype._retries = 1
--
--  prototype.beforeStart = emptyF
--  prototype.afterFinish = emptyF
--  prototype.beforeMove = emptyF
--  prototype.afterMove = emptyF
--
--  local pathEval = function(path)
--    if path.category == PathCategory.Normal then
--      print(path.path)
--    elseif path.category == PathCategory.MultipleCmds then
--      local cmds = utils.split(path.path, ";")
--      for i= 1, #cmds do
--        print(cmds[i])
--      end
--    elseif path.category == PathCategory.Trigger then
--      SendNoEcho("set travel trigger")
--      wait.regexp("")
--    else
--      error("unexpected path category " .. path.category)
--    end
--  end
--
--  function prototype:debug(...)
--    if self._DEBUG then Note(...) end
--  end
--
--  function prototype:createWalker()
--    return coroutine.create(function()
--      local steps = self._quickSteps
--      local delay = self._delay
--      local i = 1
--      while #(self._paths) do
--        if i >= steps then
--          SendNoEcho("set travel rest")
--          wait.regexp("")
--          i = 0
--        end
--        i = i + 1
--        local next = table.remove(self._paths)
--        if self._mode == PlanMode.Delay then
--          wait.time(delay)
--        elseif self._mode == PlanMode.Trigger then
--          SendNoEcho("set travel go")
--          wait.regexp("")
--        end
--        self:beforeMove()
--        pathEval(path)
--        self:afterMove()
--      end
--    end)
--  end
--
--  function prototype:len()
--    return #(self._paths)
--  end
--
--  function prototype:isStarted()
--    return self._started
--  end
--
--  function prototype:isFinished()
--    return self._finished
--  end
--
--  function prototype:prepare()
--    -- re-initialize travel triggers
--    local triggerList = GetTriggerList()
--    for i, trigger in ipairs(triggerList) do
--      local group = GetTriggerInfo(trigger, trigger_info_flag.group)
--      if group == "travel_assist" then
--        helper.removeTrigger(trigger)
--      end
--    end
--
--    -- if the direction is wrong
--    helper.addTrigger {
--      regexp = prototype.regexp.WRONG_WAY,
--      response = function(name, line, wildcards)
--        self._mayBeLost = true
--        if self._DEBUG then Note("行走路径出现错误") end
--      end,
--      group = "travel_assist"
--    }
--  end
--
--  function prototype:start()
--    self:prepare()
--    local walker = self:createWalker()
--    self:beforeStart()
--    coroutine.resume(walker)
--    self.afterFinish()
--  end
--
--  function prototype:new(args)
--    assert(type(args.startid) == "number", "startid of args must be number")
--    assert(args.paths, "paths of args cannot be nil")
--    assert(args.mode, "mode of args cannot be nil")
--    assert(args.beforeStart == nil or type(args.beforeStart) == "function", "beforeStart must be nil or function")
--    assert(args.afterFinish == nil or type(args.afterFinish) == "function", "afterFinish must be nil or function")
--    assert(args.beforeMove == nil or type(args.beforeMove) == "function", "beforeMove must be nil or function")
--    assert(args.afterMove == nil or type(args.afterMove) == "function", "afterMove must be nil or function")
--    local obj = {}
--    obj.startid = args.startid
--    obj.paths = args.paths
--    obj.mode = args.mode
--    if args.mode == PlanMode.Quick then
--      obj._quickSteps = args.quickSteps or Plan._quickSteps
--    elseif args.mode == PlanMode.Delay then
--      obj._delay = args.delay or Plan._delay
--    elseif args.mode == PlanMode.Trigger then
--
--    end
--    if (args.beforeStart) then obj.beforeStart = args.beforeStart end
--    if (args.afterFinish) then obj.afterFinish = args.afterFinish end
--    if (args.beforeMove) then obj.beforeMove = args.beforeMove end
--    if (args.afterMove) then obj.afterMove = args.afterMove end
--    setmetatable(obj, self or prototype)
--    return obj
--  end
--  return prototype
--end
--local Plan = define_Plan()

--------------------------------------------------------------
-- dal.lua
-- data access layer based on db module
-- it also depends on the value classes
-- includes query rooms, paths, etc.
--------------------------------------------------------------
local define_dal = function()
  local prototype = {}
  prototype.__index = prototype
  local sql_to_prepare = {
    GET_ALL_ROOMS = "select * from rooms",
    GET_ALL_PATHS = "select * from paths",
    GET_ROOM_BY_ID = "select * from rooms where id = ?",
    GET_ROOMS_BY_NAME = "select * from rooms where name = ?",
    GET_PATHS_BY_STARTID = "select * from paths where startid = ?",
    GET_PINYIN_BY_CHR = "select * from pinyin2chr where pinyin = ?",
    GET_CHR_BY_PINYIN = "select * from chr2pinyin where chr = ?"
  }
  local NoChangeConstructor = function(self, obj) return obj end

  function prototype.open(db)
    local obj = {}
    obj.db = db
    obj.stmts = {}
    setmetatable(obj, prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self.db:prepare(sql_to_prepare)
  end

  function prototype:dispose()
    if self.db then
      for name, stmt in self.stmts do
        stmt:finalize()
        self.stmts[name] = nil
      end
      self.db = nil
    end
  end

  -- return dict of rooms
  function prototype:getAllRooms()
    return self.db:fetchRowsAs {
      stmt = "GET_ALL_ROOMS",
      constructor = Room.new,
      key = function(room) return room.id end
    }
  end

  -- return array of paths
  function prototype:getAllPaths()
    return self.db:fetchRowsAs {
      stmt = "GET_ALL_PATHS",
      constructor = Path.new
    }
  end

  -- return single room if found
  function prototype:getRoomById(id)
    return self.db:fetchRowAs {
      stmt = "GET_ROOM_BY_ID",
      constructor = Room.new,
      params = id
    }
  end

  -- return array of rooms if name matched
  function prototype:getRoomsByName(name)
    return self.db:fetchRowsAs {
      stmt = "GET_ROOMS_BY_NAME",
      constructor = Room.new,
      params = name
    }
  end

  -- return dict of paths(key = endid) by start id
  function prototype:getPathsByStartId(startid)
    return self.db:fetchRowsAs {
      stmt = "GET_PATHS_BY_STARTID",
      constructor = Path.new,
      params = startid,
      key = function(path) return path.endid end
    }
  end

  -- return raw record, {chr=?,pinyin}
  -- note single char may have multiple pinyin, delimited by comma
  function prototype:getPinyinByChar(chr)
    return self.db:fetchRowAs {
      stmt = "GET_PINYIN_BY_CHR",
      constructor = NoChangeConstructor,
      params = chr
    }
  end

  function prototype:getCharByPinyin(pinyin)
    return self.db:fetchRowAs {
      stmt = "GET_CHR_BY_PINYIN",
      constructor = NoChangeConstructor,
      params = pinyin
    }
  end

  return prototype
end
local dal = define_dal().open(db)

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

  Algo.dfs = function(args)
    local rooms = assert(args.rooms, "rooms for traveral cannot be nil")
    local startid = args.startid or next(rooms)
    local totalRooms = 0
    for _ in pairs(rooms) do
      totalRooms = totalRooms + 1
    end
    assert(totalRooms > 0, "rooms for traveral cannot be empty")
    if not rooms[startid] then error("cannot find start in rooms") end
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
        for endid, path in pairs(rooms[c].paths) do
          if not reached[endid] then
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
--      print(prevRoomId, roomId)
      if rooms[prevRoomId].paths[roomId] then
--        print("direct path")
        table.insert(fullTraversal, roomId)
      else
--        print("indirect, need search using A*")
        local astar = Algo.astar {
          rooms = rooms,
          startid = prevRoomId,
          targetid = roomId
        }
--        print("A* solution:")
--        tprint(astar)
        if not astar then error("cannot find path from " .. prevRoomId .. " to " .. roomId) end
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
local Algo = define_Algo()

--------------------------------------------------------------
-- locate.lua
-- identify the room in world
-- should not be singleton
--------------------------------------------------------------
local define_locate = function()
  local prototype = {}
  prototype.__index = prototype
  prototype.regexp = {
    SET_LOCATE_START = "^[ >]*设定环境变量：locate = \"start\"",
    SET_LOCATE_STOP = "^[ >]*设定环境变量：locate = \"stop\"",
    ROOM_NAME_WITH_AREA = "^[ >]{,8}([^ ]+) \- \[[^ ]+\]$",
    ROOM_NAME_WITHOUT_AREA = "^[ >]{,8}([^ ]+) \- $",
    -- a very short line also might be the room name line
    ROOM_NAME_SINGLE = "^[ >]{,8}([^ ]{1,8}) *$",
    ROOM_DESC = "^ {,8}(.*?) *$",
    SEASON_TIME_DESC = "^    「([^」]+)」: (.*)$",
    EXITS_DESC = "^\\s*这里(明显|唯一)的出口是(.*)$|^\\s*这里没有任何明显的出路\\w*"
  }

  function prototype.newInstance()
    local obj = {}
    setmetatable(obj, prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self:clearRoomInfo()
    self:initTriggers()
    self:initAliases()
  end

  function prototype:clearRoomInfo()
    self.currRoomId = nil
    self.currRoomName = nil
    self.currRoomDesc = nil
    self.currExits = nil
    -- used when identify the current room
    self._roomDescInline = false
    self._exitsInline = false
    self._potentialRoomIds = {}
    self._locateInProcess = false
  end

  function prototype:initTriggers()
    -- re-initialize travel triggers
    helper.removeTriggerGroups("locate", "locate_start")

    -- start trigger
    local start = function(name, line, wildcards)
      print("locate start triggered")
      EnableTriggerGroup("locate", true)
      self:clearRoomInfo()
    end
    helper.addTrigger {
      group = "locate_start",
      regexp = self.regexp.SET_LOCATE_START,
      response = start
    }
    -- room name trigger
    local roomNameCaught = function(name, line, wildcards)
      print("locate room name triggered")
      local roomName = wildcards[1]
      self._potentialRoomIds = dal:getRoomsByName(roomName)
      if #(self._potentialRoomIds) == 1 then
        self.currRoomId = self._potentialRoomIds[1]
        self.currRoomName = roomName
        self._locateInProcess = false
      end
      self._roomDescInline = true
      self._roomExitsInline = true
    end
    helper.addTrigger {
      group = "locate",
      regexp = self.regexp.ROOM_NAME_WITH_AREA,
      response = roomNameCaught
    }
    helper.addTrigger {
      group = "locate",
      regexp = self.regexp.ROOM_NAME_WITHOUT_AREA,
      response = roomNameCaught
    }
    -- there is also case that the mini-map is missing and no slash at end of the name line
    helper.addTrigger {
      group = "locate",
      regexp = self.regexp.ROOM_NAME_SINGLE,
      response = roomNameCaught
    }
    -- room desc trigger
    local roomDescCaught = function(name, line, wildcards)
      print("locate room desc triggered")
      if self._roomDescInline then
        local currDesc = self.roomDesc or ""
        self.roomDesc = currDesc .. wildcards[1]
      end
    end
    helper.addTrigger {
      group = "locate",
      regexp = self.regexp.ROOM_DESC,
      response = roomDescCaught
    }
    -- season/time trigger
    local seasonCaught = function(name, line, wildcards)
      print("locate season/time triggered")
      if self._roomDescInline then self._roomDescInline = false end
      local season = wildcards[1]
      local datetime = wildcards[2]
    end
    helper.addTrigger {
      group = "locate",
      regexp = self.regexp.SEASON_TIME_DESC,
      response = seasonCaught,
      sequence = 5 -- higher than room desc
    }
    -- exits trigger
    local exitsCaught = function(name, line, wildcards)
      print("locate exits triggered")
      if self._roomDescInline then self._roomDescInline = false end
      if self._exitsInline then
        self._exitsInline = false
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
        self.currExits = table.concat(tb, ";") .. ";"
      end
    end
    helper.addTrigger {
      group = "locate",
      regexp = self.regexp.EXITS_DESC,
      response = exitsCaught,
      sequence = 5 -- higher than room desc
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("locate")

    helper.addAlias {
      regexp = "^locatehere$",
      response = function() self:locate() end,
      group = "locate"
    }
  end

  function prototype:show()
    print("Current Room Id:", self.currRoomId)
    print("Current Room Name:", self.currRoomName)
    print("Current Room Exits:", self.currExits)
    print("Current Room Desc:", self.currRoomDesc and string.sub(self.currRoomDesc, 1, 60))
  end

  function prototype:locate()
    local locater = coroutine.create(function()
      self._locateInProcess = true
      EnableTriggerGroup("locate_start", true)
      check(SendNoEcho("set locate start"))
      check(SendNoEcho("look"))
      check(SendNoEcho("set locate stop"))
      wait.regexp(self.regexp.SET_LOCATE_STOP)
      EnableTriggerGroup("locate_start", false)
      EnableTriggerGroup("locate", false)
      self._locateInProcess = false
      self:show()
    end)
    return coroutine.resume(locater)
  end

  return prototype
end
local locate = define_locate().newInstance()

--
----------------------------------------------------------------
---- travel.lua
---- Implement the walk, locate, traverse functionalities
---- in xkx world
----------------------------------------------------------------
--local define_travel = function()
--  local prototype = {}
--  prototype.__index = prototype
--
--  prototype.roomName = nil
--  prototype.roomDescInline = false
--  prototype.roomDesc = nil
--  prototype.exitsInline = false
--  prototype.exits = nil
--
--  function prototype.clearRoomInfo()
--    travel.roomName = nil
--    travel.roomDescInline = false
--    travel.roomDesc = nil
--    travel.exitsInline = false
--    travel.exits = nil
--  end
--
--  local initRoomsAndPaths = function()
--    local rooms = dal:getAllRooms()
--    local allPaths = dal:getAllPaths()
--    for i = 1, #allPaths do
--      local path = allPaths[i]
--      local startroom = rooms[path.startid]
--      if startroom then
--        startroom:addPath(path)
--      end
--    end
--    prototype.rooms = rooms
--  end
--
--  -- bind search implementation to A* algorithm
--  -- should enhance with hypothesis functions to reduce search range
--  function prototype:search(startid, endid)
--    return Algo.astar {
--      rooms = self.rooms,
--      startid = startid,
--      targetid = endid
--    }
--  end
--
--  function prototype:locate()
--    EnableTriggerGroup("travel_locate_start", true)
--    check(SendNoEcho("set travel_locate start"))
--    check(SendNoEcho("look"))
--    check(SendNoEcho("set travel_locate stop"))
--    print("roomName:" .. self.roomName)
--    print("exits:" .. self.exits)
--    print("roomDesc:" .. self.roomDesc)
--  end
--
--  local initLocateTriggers = function()
--    -- start trigger
--    helper.addTrigger {
--      group = "travel_locate_start",
--      regexp = "^[ >]*设定环境变量：travel_locate = \"start\"",
--      response = function(name, line, wildcards)
--        print("trigger "..name.." triggered")
--        EnableTriggerGroup("travel_locate", true)
--        travel.clearRoomInfo()
--      end
--    }
--    -- room name trigger with area
--    helper.addTrigger {
--      group = "travel_locate",
--      regexp = "^[ >]*([^ ]+) \- \[[^ ]+\]$",
--      response = function(name, line, wildcards)
--        print("trigger "..name.." triggered")
--        travel.roomName = wildcards[1]
--        travel.roomDescInline = true
--        travel.roomExitsInline = true
--      end
--    }
--    -- room name trigger without area
--    helper.addTrigger {
--      group = "travel_locate",
--      regexp = "^[ >]*([^ ]+) \- $",
--      response = function(name, line, wildcards)
--        print("trigger "..name.." triggered")
--        travel.roomName = wildcards[1]
--        travel.roomDescInline = true
--      end
--    }
--
--    -- room desc
--    local roomDescCaught = function(name, line, wildcards)
--      print("trigger "..name.." triggered")
--      if travel.roomDescInline then
--        local currDesc = travel.roomDesc or ""
--        travel.roomDesc = currDesc .. wildcards[1]
--      end
--    end
--    helper.addTrigger(
--      "trigger" .. GetUniqueID(),
--      "^ *(.*?) *$",
--      "travel_locate",
--      roomDescCaught
--    )
--    -- room desc end
--    local seasonCaught = function(name, line, wildcards)
--      print("trigger "..name.." triggered")
--      if travel.roomDescInline then travel.roomDescInline = false end
--      local season = wildcards[1]
--      local datetime = wildcards[2]
--    end
--    helper.addTrigger(
--      "trigger" .. GetUniqueID(),
--      "^    「([^」]+)」: (.*)$",
--      "travel_locate",
--      seasonCaught,
--      5 -- higher than room desc
--    )
--    -- room desc end
--    local exitsCaught = function(name, line, wildcards)
--      print("trigger "..name.." triggered")
--      if travel.roomDescInline then travel.roomDescInline = false end
--      if travel.exitsInline then
--        travel.exitsInline = false
--        local exits = wildcards[2] or "look"
--        exits = string.gsub(exits,"。","")
--        exits = string.gsub(exits," ","")
--        exits = string.gsub(exits,"、", ";")
--        exits = string.gsub(exits, "和", ";")
--        local tb = {}
--        for _, str in ipairs(utils.split(exits,";")) do
--          local t = Trim(str)
--          if t ~= "" then table.insert(tb, t) end
--        end
--        travel.exits = table.concat(tb, ";") .. ";"
--      end
--
--    end
--    helper.addTrigger(
--      "trigger" .. GetUniqueID(),
--      "^\\s*这里(明显|唯一)的出口是(.*)$|^\\s*这里没有任何明显的出路\\w*",
--      "travel_locate",
--      exitsCaught,
--      5 -- higher than room desc
--    )
--    -- stop trigger
--    local stop = function(name, line, wildcards)
--      print("trigger "..name.." triggered")
--      EnableTriggerGroup("travel_locate_start", false)
--      EnableTriggerGroup("travel_locate", false)
--      -- summary
--      print("roomName", travel.roomName)
--      print("roomDescInline", travel.roomDescInline)
--      print("roomDesc", travel.roomDesc)
--      print("exitsInline", travel.exitsInline)
--      print("exits", travel.exits)
--    end
--  end
--
--  initRoomsAndPaths()
--  if _G["world"] then initLocateTriggers() end
--
--  return prototype
--end
--local travel = define_travel()
