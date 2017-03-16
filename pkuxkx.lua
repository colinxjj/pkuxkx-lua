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
  if not _G["world"] then
    require "world"
    require "lsqlite3"
  end
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

-- inheritance over meta table
local inheritMeta = function(Cls)
  local inherited = {
    -- special keys
--    __index = Cls,
--    __newindex = Cls,
--    __mode = Cls.__mode,
--    __call = Cls.__call,
--    __metatable = Cls.__metatable,
--    __tostring = Cls.__tostring,
--    __len = Cls.__len,
--    __gc = Cls.__gc,
    -- equivalence comparison operators
    __eq = Cls.__eq,
    __lt = Cls.__lt,
    __le = Cls.__le,
    -- mathematic operators
    __unm = Cls.__unm,
    __add = Cls.__add,
    __sub = Cls.__sub,
    __mul = Cls.__mul,
    __div = Cls.__div,
    __mod = Cls.__mod,
    __pow = Cls.__pow,
    __concat = Cls.__concat
  }
  inherited.__index = inherited
  setmetatable(inherited, {__index = Cls})
  return inherited
end

-- finite state machine construct for most jobs
local define_FSM = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype.inheritedMeta()
    return inheritMeta(prototype)
  end

  -- every state machine implement should have constructor
  -- calling this method to get a draft to go on
  function prototype:new()
    local obj = {}
    obj.currState = nil
    obj.states = {}
    obj.transitions = {}
    obj.DEBUG = false
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:debug(...)
    if (self.DEBUG) then print(...) end
  end

  function prototype:debugOn()
    print("开启调试模式")
    self.DEBUG = true
  end

  function prototype:debugOff()
    print("关闭调试模式")
    self.DEBUG = false
  end

  function prototype:addState(args)
    local state = assert(args.state, "state cannot be nil")
    local enter = assert(args.enter, "enter function cannot be nil")
    local exit = assert(args.exit, "exit function cannot be nil")
    self.states[state] = {
      enter = enter,
      exit = exit
    }
    if not self.transitions[state] then
      self.transitions[state] = {}
    end
  end

  function prototype:addTransition(args)
    local oldState = assert(args.oldState, "oldState cannot be nil")
    local newState = assert(args.newState, "newState cannot be nil")
    local event = assert(args.event, "event cannot be nil")
    local action = assert(args.action, "action cannot be nil")
    if not self.states[oldState] then
      error("old state does not exist: " .. oldState, 2)
    end
    if not self.states[newState] then
      error("new state does not exist: " .. newState, 2)
    end
    -- by default, action run after new state is entered
    local transition = {
      newState = newState
    }
    if type(action) == "function" then
      transition.afterEnter = action
    elseif type(action) == "table" then
      transition.beforeExit = action.beforeExit
      transition.afterEnter = action.afterEnter
    end
    self.transitions[oldState][event] = transition
  end

  function prototype:setState(state) self.currState = state end

  function prototype:getState() return self.currState end

  function prototype:fire(event)
    local transition = self.transitions[self.currState][event]
    if not transition then
      print(string.format("当前状态[%s]不接受事件[%s]", self.currState or "nil", event or "nil"))
    else
      self:debug("当前状态", self.currState, "事件", event)
      -- using coroutine instead of function so that inside we can
      -- make use of wait functionalities
      local transitioner = coroutine.create(function()
        if transition.beforeExit then
          self:debug("执行退出前转换")
          transition.beforeExit()
        end

        self:debug("退出状态", self.currState)
        self.states[self.currState].exit()
        self.currState = transition.newState

        self:debug("进入状态", self.currState)
        self.states[self.currState].enter()

        if transition.afterEnter then
          self:debug("执行进入后转换")
          return transition.afterEnter()
        end
      end)
      coroutine.resume(transitioner)
    end
  end

  return prototype
end
local FSM = define_FSM()

local define_gb2312 = function()
  local gb2312 = {}
  gb2312.len = function(s)
    if not s or type(s) ~= "string" then error("string required", 2) end
    return string.len(s) / 2
  end

  gb2312.code = function(s, ci)
    local first = ci * 2 - 1
    return string.byte(s, first, first) * 256 + string.byte(s, first + 1, first + 1)
  end

  gb2312.char = function(chrcode)
    local first = math.floor(chrcode / 256)
    local second = chrcode - first * 256
    return string.char(first) .. string.char(second)
  end

  return gb2312
end
local gb2312 = define_gb2312()

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
      check(AddTriggerEx(name, regexp, "-- added by helper", TRIGGER_BASE_FLAG, custom_colour.NoChange, COPY_WILDCARDS_NONE, SOUND_FILE_NONE, name, sendto.script, sequence))
    else
      error("response type is unexpected " .. type(response))
    end
    check(SetTriggerOption(name, "group", group))
  end

  helper.addOneShotTrigger = function(args)
    local regexp = assert(type(args.regexp) == "string" and args.regexp, "regexp in trigger must be string")
    local group = assert(args.group, "group in trigger cannot be empty")
    local response = assert(args.response, "response in trigger cannot be empty")
    local name = args.name or "auto_added_trigger_" .. GetUniqueID()
    local sequence = args.sequence or 10
    if type(response) == "string" then
      check(AddTriggerEx(
        name,
        regexp,
        response, bit.bor (0,
        trigger_flag.Enabled,
        trigger_flag.RegularExpression,
        trigger_flag.Temporary,
        trigger_flag.Replace,
        trigger_flag.OneShot),
        custom_color.NoChange,
        COPY_WILDCARDS_NONE, SOUND_FILE_NONE, "", sendto.world, sequence))
    elseif type(response) == "function" then
      _G.world[name] = response
      _global_trigger_callbacks[name] = true
      check(AddTriggerEx(
        name,
        regexp,
        "-- added by helper", bit.bor (0,
        trigger_flag.Enabled,
        trigger_flag.RegularExpression,
        trigger_flag.Temporary,
        trigger_flag.Replace,
        trigger_flag.OneShot),
        custom_color.NoChange,
        COPY_WILDCARDS_NONE, SOUND_FILE_NONE, name, sendto.script, sequence))
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

  helper.enableTriggerGroups = function(...)
    for _, group in ipairs({...}) do
      EnableTriggerGroup(group, true)
    end
  end

  helper.disableTriggerGroups = function(...)
    for _, group in ipairs({...}) do
      EnableTriggerGroup(group, false)
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
    print("remove alias", name, retCode)
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

  helper.enableAliasGroups = function(...)
    for _, group in ipairs({...}) do
      EnableAliasGroup(group, true)
    end
  end

  helper.disableAliasGroups = function(...)
    for _, group in ipairs({...}) do
      EnableAliasGroup(group, false)
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

  function prototype:executeUpdate(args)
    assert(args.stmt, "stmt cannot be nil")
    local stmt = assert(self.stmts[args.stmt], "stmt is not prepared")
    local params = assert(args.params, "params in update cannot be nil")
    assert(type(args.params) == "table", "params in update must be name table")
    --always reset the statement
    stmt:reset()
    assert(stmt:bind_names(params) == sqlite3.OK, "failed to bind params with nametable")
    assert(stmt:step() == sqlite3.DONE)
  end

  return prototype
end
-- easy to switch to memory db
-- local db = define_db().open_memory_copied("xxx.db")
local db = define_db().open("data/pkuxkx-gb2312.db")

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
-- Path.lua
-- data structure of Path
-- Path is an abstraction of a relationship between two points
-- in mud map
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
    local obj = {}
    obj.startid = args.startid
    obj.endid = args.endid
    obj.weight = args.weight or 1
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.startid, "startid cannot be nil")
    assert(obj.endid, "endid cannot be nil")
    obj.weight = obj.weight or 1
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
local Path = define_Path()

--------------------------------------------------------------
-- RoomPath.lua
-- data structure of RoomPath, inherit from Path
-- add concrete fields
--------------------------------------------------------------
local define_RoomPath = function()
  local prototype = inheritMeta(Path)
  prototype.__index = prototype
  setmetatable(prototype, {__index = Path})

  function prototype:new(args)
    local obj = Path:new(args)
--    assert(obj.endcode, "endcode cannot be nil")
    assert(args.path, "path can not be nil")
    obj.path = args.path
    obj.endcode = args.endcode
    obj.category = args.category or "normal"
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    local obj = Path:decorate(obj)
--    assert(obj.endcode, "endcode cannot be nil")
    assert(obj.path, "path cannot be nil")
    obj.category = obj.category or "normal"
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
local RoomPath = define_RoomPath()

--------------------------------------------------------------
-- ZonePath.lua
-- alias to Path
--------------------------------------------------------------
local ZonePath = Path

--------------------------------------------------------------
-- Room.lua
-- data structure of Room
-- room is an abstraction of a point that player can
-- move from or go to in a mud map
--------------------------------------------------------------
local define_Room = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    assert(args.id, "id can not be nil")
    assert(args.code, "code can not be nil")
    local obj = {}
    obj.id = args.id
    obj.code = args.code
    obj.name = args.name or ""
    obj.description = args.description
    obj.exits = args.exits
    obj.zone = args.zone
    obj.paths = args.paths or {}
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.id, "id can not be nil")
    assert(obj.code, "code cannot be nil")
    obj.name = obj.name or ""
    obj.description = obj.description or ""
    obj.exits = obj.exits or ""
    obj.zone = obj.zone or ""
    obj.paths = obj.paths or {}
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
-- Zone.lua
-- data structure of Zone
-- similar to Room, with no exits, description, mapinfo and list of ZonePath
--------------------------------------------------------------
local define_Zone = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    assert(args.id, "id can not be nil")
    assert(args.code, "code can not be nil")
    assert(args.name, "id can not be nil")
    assert(args.centercode, "code can not be nil")
    local obj = {}
    obj.id = args.id
    obj.code = args.code
    obj.name = args.name
    obj.centercode = args.centercode
    obj.paths = args.paths or {}
    obj.rooms = args.rooms or {}
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.id, "id can not be nil")
    assert(obj.code, "code cannot be nil")
    assert(obj.name, "id can not be nil")
    assert(obj.centercode, "code can not be nil")
    obj.paths = obj.paths or {}
    obj.rooms = obj.rooms or {}
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:addPath(path)
    self.paths[path.endid] = path
  end

  function prototype:addRoom(room)
    self.rooms[room.id] = room
  end

  return prototype
end
local Zone = define_Zone()

--------------------------------------------------------------
-- Distance.lua
-- data structure of Distance
--------------------------------------------------------------
local define_Distance = function()
  local prototype = {
    __eq = function(a, b) return a.weight == b.weight end,
    __lt = function(a, b) return a.weight < b.weight end,
    __le = function(a, b) return a.weight <= b.weight end
  }
  prototype.__index = prototype

  function prototype:new(args)
    assert(args.id, "id cannot be nil")
    assert(args.weight, "weight cannot be nil")
    local obj = {}
    obj.id = args.id
    obj.weight = args.weight
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.id, "id cannot be nil")
    assert(obj.weight, "weight cannot be nil")
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
local Distance = define_Distance()

--------------------------------------------------------------
-- HypoDistance.lua
-- data structure of HypoDistance
-- used in A* algorithm
--------------------------------------------------------------
local define_HypoDistance = function()
  local prototype = {
    __eq = function(a, b) return a.real + a.hypo == b.real + b.hypo end,
    __lt = function(a, b) return a.real + a.hypo < b.real + b.hypo end,
    __le = function(a, b) return a.real + a.hypo <= b.real + b.hypo end
  }
  prototype.__index = prototype

  function prototype:new(args)
    assert(args.id, "args of HypoDistance must have valid id field")
    assert(args.real, "args of HypoDistance must have valid real field")
    local obj = {}
    obj.id = args.id
    obj.real = args.real
    obj.hypo = args.hypo or 0
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.id, "id cannot be nil")
    assert(obj.real, "real cannot be nil")
    obj.hypo = obj.hypo or 0
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
local HypoDistance = define_HypoDistance()

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
    GET_ROOMS_LIKE_CODE = "select * from rooms where code like ?",
    GET_PATHS_BY_STARTID = "select * from paths where startid = ?",
--    GET_PINYIN_BY_CHR = "select * from pinyin2chr where pinyin = ?",
--    GET_CHR_BY_PINYIN = "select * from chr2pinyin where chr = ?",
    -- current version ignores code, zone, mapinfo columns
    UPD_ROOM = [[update rooms
    set name = :name, description = :description, exits = :exits
    where id = :id]],
    GET_ALL_ZONES = "select * from zones",
    GET_ALL_ZONE_PATHS = [[select sz.id as startid, ez.id as endid, zc.weight as weight
    from zone_connectivity zc, zones sz, zones ez
    where zc.startcode = sz.code
    and zc.endcode = ez.code]],
    GET_ALL_AVAILABLE_ROOMS = "select * from rooms where name <> '' and zone <> ''",
    GET_ALL_AVAILABLE_PATHS = "select * from paths where enabled = 1"
  }

  local nameGetPinyinByCharCode = function(n)
    return  "SQL_GET_PINYIN_BY_CHR_" .. n
  end
  local SQL_GET_PINYIN_BY_CHR = "select * from chr2pinyin where chrcode in (__REPLACEMENT__)"
  local char2pinyinSqlGenerator = function(n)
    local queries = {}
    for i = 1, n do
      local name = nameGetPinyinByCharCode(i)
      local holders = string.rep("?,", i)
      local sql = string.gsub(SQL_GET_PINYIN_BY_CHR, "__REPLACEMENT__", string.sub(holders, 1, string.len(holders) - 1))
      queries[name] = sql
    end
    return queries
  end

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
    -- support at most 10-char word pinyin mapping query
    local pinyinStmts = char2pinyinSqlGenerator(10)
    self.db:prepare(pinyinStmts)
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
      constructor = Room.decorate,
      key = function(room) return room.id end
    }
  end

  function prototype:getAllAvailableRooms()
    return self.db:fetchRowsAs {
      stmt = "GET_ALL_AVAILABLE_ROOMS",
      constructor = Room.decorate,
      key = function(room) return room.id end
    }
  end

  -- return array of paths
  function prototype:getAllPaths()
    return self.db:fetchRowsAs {
      stmt = "GET_ALL_PATHS",
      constructor = RoomPath.decorate
    }
  end

  function prototype:getAllAvailablePaths()
    return self.db:fetchRowsAs {
      stmt = "GET_ALL_AVAILABLE_PATHS",
      constructor = RoomPath.decorate
    }
  end

  -- return single room if found
  function prototype:getRoomById(id)
    return self.db:fetchRowAs {
      stmt = "GET_ROOM_BY_ID",
      constructor = Room.decorate,
      params = id
    }
  end

  -- return array of rooms if name matched
  function prototype:getRoomsByName(name)
    return self.db:fetchRowsAs {
      stmt = "GET_ROOMS_BY_NAME",
      constructor = Room.decorate,
      params = name
    }
  end

  function prototype:getRoomsLikeCode(code)
    return self.db:fetchRowsAs {
      stmt = "GET_ROOMS_LIKE_CODE",
      constructor = Room.decorate,
      params =  "%" .. code .. "%"
    }
  end

  -- return dict of paths(key = endid) by start id
  function prototype:getPathsByStartId(startid)
    return self.db:fetchRowsAs {
      stmt = "GET_PATHS_BY_STARTID",
      constructor = RoomPath.decorate,
      params = startid,
      key = function(path) return path.endid end
    }
  end

  -- generate pinyinList
  local pinyinPerm
  pinyinPerm = function(seq, dict, n)

    if n == 0 then
      coroutine.yield(dict) -- the order in elements are switched back and forth
    else
      local chr = seq[n]
      local pys = dict[chr]
      if not pys then error("cannot find pinyin of char:" .. chr, 2) end
      for i = 1, #pys do
        pys[1], pys[i] = pys[i], pys[1]
        pinyinPerm(seq, dict, n - 1)
        pys[1], pys[i] = pys[i], pys[1]
      end
    end
  end

  local pinyinIter = function(seq, dict)
    local n = #seq
    local co = coroutine.create(function() pinyinPerm(seq, dict, n) end)
    return function()
      local retCode, result = coroutine.resume(co)
      if not retCode then -- error
        error(result)
      end
      return result
    end
  end

  -- input must be a gb2312 encoded string (chinese words)
  function prototype:getPinyinListByWord(word)
    local nChars = gb2312.len(word)
    local seq = {}
    for i = 1, nChars do
      local code = gb2312.code(word, i)
      table.insert(seq, code)
    end
    local dict = self.db:fetchRowsAs {
      stmt = nameGetPinyinByCharCode(nChars),
      constructor = function(self, row)
        return {
          chrcode = row.chrcode,
          unpack(utils.split(row.pinyin, ","))
        }
      end,
      key = function(row) return row.chrcode end,
      params = seq
    }
    local results = {}
    for pyDict in pinyinIter(seq, dict) do
      -- generate result
      local result = {}
      for i = 1, #seq do
        -- always get the first element in pinyin list,
        -- because permuation already switch them inside.
        table.insert(result, pyDict[seq[i]][1])
      end
      table.insert(results, table.concat(result))
    end
    return results
  end

  function prototype:updateRoom(room)
    return self.db:executeUpdate {
      stmt = "UPD_ROOM",
      params = room
    }
  end

  -- return zone table
  function prototype:getAllZones()
    return self.db:fetchRowsAs {
      stmt = "GET_ALL_ZONES",
      constructor = Zone.decorate,
      key = function(zone) return zone.id end
    }
  end

  -- return array of zone path
  function prototype:getAllZonePaths()
    return self.db:fetchRowsAs {
      stmt = "GET_ALL_ZONE_PATHS",
      constructor = ZonePath.decorate
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
            real=min.real + path.weight,
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
          local newDistance = Distance:decorate { id=endid, weight=min.weight + path.weight }
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
      if rooms[prevRoomId].paths[roomId] then
        table.insert(fullTraversal, roomId)
      else
        local astar = Algo.astar {
          rooms = rooms,
          startid = prevRoomId,
          targetid = roomId
        }
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
-- travel.lua
-- 提供定位与行走功能，用户命令使用loc
-- 该模块采用了FSM设计模式，目标是稳定易用容错。
-- FSM状态有：
-- 1. stop 停止状态
-- 2. locating 定位中
-- 3. located 已定位
-- 4. walking 行走中
-- 5. lost 迷路中
-- 6. blocked 被阻挡中（busy, boat, etc）
-- 状态转换：
-- 非stop状态都可通过发送STOP消息，转换为stop状态
-- stop -> locating (event: START)
-- locating -> located (event: LOCATION_CONFIRMED, LOCATION_CONFIRMED_ONLY)
-- locating -> stop (event: MAX_RETRIES, ROOM_NO_EXITS)
-- located -> walking (event: WALK_PLAN_GENERATED)
-- located -> stop (event: WALK_PLAN_NOT_EXISTS)
-- walking -> located (event: ARRIVED)
-- walking -> lost (event: GET_LOST)
-- walking -> blocked (event: BOAT, BUSY)
-- lost -> locating (event: START_RELOCATE)
-- blocked -> walking (event: BLOCKING_SOLVED)
--
-- 对外API：
-- travel:reset() 初始化状态，行走时会先定位当前房间，适用于大多数场景
-- travel:setMode(mode) 设置行走模式，提供"quick", "normal", "slow"三种模式
-- ~~ quick模式：每12步停顿1秒，通过travel:setInterval(steps)修改
-- ~~ normal模式：每步短暂停留
-- ~~ slow模式：每步停留1秒，通过travel:setDelay(seconds)修改
-- travel:relocate() 重定位，必须在coroutine中调用
-- travel:walkto(roomId, action)
-- 指定目的地(roomId)行走，如果需要，先定位当前房间，action为到达后所执行函数，
-- 可包含协程方法(如wait.lua提供的time, regexp方法)
-- travel:waitUntilArrived() 如果walkto方法中传递callback方法不满足需要，
-- 提供该函数（作用类似wait.regexp），该方法yield直到到达目的地。
-- todo
-- travel:traverseUntil(roomId, range, untilCheck)
-- 指定目标房间与范围（默认每两个相邻房间距离为1），进行遍历（dfs算法），untilCheck为
-- travel:traverseEach(roomId, range, eachAction)
--
-- also provide non-FSM aliases to assist map generation
--
--------------------------------------------------------------
local define_travel = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",  -- 停止状态
    walking = "walking",  -- 行走中
    lost = "lost",  -- 迷路了
    blocked = "blocked", -- 被阻挡
    locating = "locating",  -- 定位中
    located = "located" -- 已定位
  }

  local Events = {
    START = "start",    -- 开始信号，从停止状态开始将进入重定位，从已定位状态开始将进入行走
    LOCATION_CONFIRMED = "location_confirmed",    -- 确定定位信息
    LOCATION_CONFIRMED_ONLY = "location_confirmed_only",    -- 仅确定定位信息
    ARRIVED = "arrived",    -- 到达目的地信号
    GET_LOST = "get_lost",    -- 迷路信号
    START_RELOCATE = "start_relocate",    -- 重新定位信号
    -- FAIL_RELOCATE = "fail_relocate",    -- 重新定位失败
    MAX_RELOC_RETRIES = "max_reloc_retries",    -- 到达重定位重试最大次数
    MAX_RELOC_MOVES = "max_reloc_moves",    -- 到达重定位移动最大步数（每次）
    ROOM_NO_EXITS = "room_no_exits",    -- 房间没有出口
    WALK_PLAN_NOT_EXISTS = "walk_plan_not_exists",    -- 行走计划无法生成
    WALK_PLAN_GENERATED = "walk_plan_generated",    -- 行走计划生成
    BOAT = "boat",    -- 乘船信号
    BUSY = "busy",    -- busy信号
    BLOCKING_SOLVED = "blocking_solved",    -- 阻塞解除信号
    TRY_RELOCATE = "try_relocate",    -- 尝试重定位
    ROOM_INFO_UNKNOWN = "room_info_unknown",    -- 没有获取到房间信息
  }
  local RELOC_MAX_RETRIES = 4    -- 重定位最多重试次数，当进入located或stop状态时重置，当进入locating时减一
  local RELOC_MAX_MOVES = 50    -- 每次重定位最大移动步数(每个房间算1步)，当进入locating状态时重置


  prototype.regexp = {
    --SET_LOCATE_START = "^[ >]*设定环境变量：locate = \"start\"$",
    --SET_LOCATE_STOP = "^[ >]*设定环境变量：locate = \"stop\"$",
    ROOM_NAME_WITH_AREA = "^[ >]{0,12}([^ ]+) \\- \\[[^ ]+\\]$",
    ROOM_NAME_WITHOUT_AREA = "^[ >]{0,12}([^ ]+) \\- $",
    ROOM_DESC = "^ {0,12}([^ ].*?) *$",
    SEASON_TIME_DESC = "^    「([^\\\\x00-\\\\xff]+?)」: (.*)$",
    EXITS_DESC = "^\\s{0,12}这里(明显|唯一)的出口是(.*)$|^\\s*这里没有任何明显的出路\\w*",
    BUSY_LOOK = "^[> ]*风景要慢慢的看。$",
    NOT_BUSY = "^[ >]*你现在不忙。$",
    LOOK_START = "^[ >]*设定环境变量：travel_look = \"start\"$",
    LOOK_DONE = "^[ >]*设定环境变量：travel_look = \"done\"$",
    ARRIVED = "^[ >]*设定环境变量：travel_walk = \"arrived\"$",
    WALK_LOST = "^[> ]*(这个方向没有出路。|你一不小心脚下踏了个空，... 啊...！|你小心翼翼往前挪动，遇到艰险难行处，只好放慢脚步。|你还在山中跋涉，一时半会恐怕走不出.*|青海湖畔美不胜收，你不由停下脚步，欣赏起了风景。|你不小心被什么东西绊了一下.*)$",
    WALK_LOST_SPECIAL = "^[ >]*泼皮一把拦住你：要向从此过，留下买路财！泼皮一把拉住了你。$",
    WALK_BLOCK = "^[> ]*你的动作还没有完成，不能移动.*$",
    WALK_BREAK = "^[ >]*设定环境变量：travel_walk = \"break\"$",
    WALK_STEP = "^[ >]*设定环境变量：travel_walk = \"step\"$",
  }
  prototype.zonesearch = Algo.dijkstra
  prototype.roomsearch = Algo.astar
  prototype.traverse = Algo.traversal

  function prototype:FSM()
    local obj = FSM:new()
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:setMode(mode)
    self.mode = mode
  end

  function prototype:setDelay(delay)
    self.delay = delay
  end

  function prototype:reset()
    -- locating
    self.currRoomId = nil
    self.currRoomName = nil
    self.targetRoomId = nil -- if target room id is nil, means locating only
    self.targetAction = nil
    self.relocMaxRetries = RELOC_MAX_RETRIES
    self.relocMaxMoves = RELOC_MAX_MOVES
    self.busyLook = false  -- used when relocating, system might tell you too busy to look around
    -- walking
    self.walkPlan = nil
    self.walkLost = false
  end

  function prototype:walkto(targetRoomId, action)
    assert(type(targetRoomId) == "number", "target room id must be number")
    assert(not action or type(action) == "function", "action must be function or nil")
    self.targetRoomId = targetRoomId
    self.targetAction = action
    self:fire(Events.START)
  end

  function prototype:postConstruct()
    self:initStates()
    self:initTransitions()
    self:initZonesAndRooms()
    self:initTriggers()
    self:initAliases()
    self:setState(States.stop)
    self:reset()
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
      -- locating
      "travel_look_start",
      "travel_look_name",
      "travel_look_desc",
      "travel_look_season",
      "travel_look_exits"
    )
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        -- must clean the user defined triggers
        helper.removeTriggerGroups("travel_one_shot")
        self:disableAllTriggers()
      end,
      exit = function()

      end
    }
    self:addState {
      state = States.locating,
      enter = function()

      end,
      exit = function()
        helper.disableTriggerGroups(
          "travel_look_start",
          "travel_look_name",
          "travel_look_desc",
          "travel_look_season",
          "travel_look_exits",
          "travel_walk"
        )
      end
    }
    self:addState {
      state = States.located,
      enter = function()
        self.relocMaxRetries = RELOC_MAX_RETRIES
      end,
      exit = function()

      end
    }
    self:addState {
      state = States.walking,
      enter = function()
        helper.enableTriggerGroups("travel_walk")
      end,
      exit = function()
        helper.disableTriggerGroups("travel_walk")
      end
    }
    self:addState {
      state = States.lost,
      enter = function()

      end,
      exit = function()

      end
    }
    self:addState {
      state = States.blocked,
      enter = function()

      end,
      exit = function()

      end
    }
  end

  local addTransitionToStop = function(self, fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function()
        print("停止 - 当前状态", self.currState)
      end
    }
  end

  function prototype:generateWalkPlan()
    local fromid = self.currRoomId
    local toid = self.targetRoomId
    self:debug("检验起始房间和目标房间", fromid, toid)
    local startRoom = self.roomsById[fromid]
    local endRoom = self.roomsById[toid]
    if not startRoom then
      print("当前房间不在自动行走列表中")
      return nil
    elseif not endRoom then
      print("目标房间不在自动行走列表中")
      return nil
    else
      local startZone = self.zonesByCode[startRoom.zone]
      local endZone = self.zonesByCode[endRoom.zone]
      if not startZone then
        print("当前区域不在自动行走列表中", startRoom.zone)
        return nil
      elseif not endZone then
        print("目标区域不在自动行走列表中", endRoom.zone)
        return nil
      elseif startZone == endZone then
        if self.DEBUG then
          local roomCnt = 0
          for _, room in pairs(startZone.rooms) do
            roomCnt = roomCnt + 1
          end
          print("出发地与目的地处于同一区域，共" .. roomCnt .. "个房间")
        end
        return self.roomsearch(startZone.rooms, fromid, toid)
      else
        -- zone search for shortest path
        local zoneStack = self.zonesearch {
          rooms = self.zonesById,
          startid = startZone.id,
          targetid = endZone.id
        }
        if not zoneStack then
          print("计算区域路径失败，区域 " .. startZone.name .. " 至区域 " .. endZone.name .. " 不可达")
          return false
        else
          table.insert(zoneStack, ZonePath:decorate {startid=startZone.id, endid=startZone.id, weight=0})
          local zoneCnt = #zoneStack
          local rooms = {}
          local roomCnt = 0
          while #zoneStack > 0 do
            local zonePath = table.remove(zoneStack)
            for _, room in pairs(self.zonesById[zonePath.endid].rooms) do
              rooms[room.id] = room
              roomCnt = roomCnt + 1
            end
          end
          self:debug("本次路径计算跨" .. zoneCnt .. "个区域，共" .. roomCnt .. "个房间")
          return self.roomsearch(startZone.rooms, fromid, toid)
        end
      end
    end
  end

  function prototype:initTransitions()
    -- transtions from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.locating,
      event = Events.START,
      action = function()
        self:relocate()
      end
    }
    -- transitions from state<locating>
    self:addTransition {
      oldState = States.locating,
      newState = States.located,
      event = Events.LOCATION_CONFIRMED,
      action = function()
        local walkPlan = self:generateWalkPlan()
        if not walkPlan then
          return self:fire(Events.WALK_PLAN_NOT_EXISTS)
        else
          self:debug("本次自动行走共" .. #walkPlan .. "步")
          -- this is the only place to store walk plan
          self.walkPlan = walkPlan
          return self:fire(Events.WALK_PLAN_GENERATED)
        end
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.located,
      event = Events.LOCATION_CONFIRMED_ONLY,
      action = function()
        print("完成重新定位。房间名称：", self.currRoomName, "房间编号：", self.currRoomId)
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.MAX_RELOC_RETRIES,
      action = function()

      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.MAX_RELOC_MOVES,
      action = function()

      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.ROOM_NO_EXITS,
      action = function()

      end
    }
    addTransitionToStop(self, States.locating)
    -- transitions from state<located>
    self:addTransition {
      oldState = States.located,
      newState = States.walking,
      event = Events.WALK_PLAN_GENERATED,
      action = function()
        self:walking()
      end
    }
    self:addTransition {
      oldState = States.located,
      newState = States.stop,
      event = Events.WALK_PLAN_NOT_EXISTS,
      action = function()
        print("自动行走失败！无法获取从房间" .. self.currRoomId .. "到达房间" .. self.targetRoomId .. "的行走计划")
      end
    }
    addTransitionToStop(self, States.located)
    -- transitions from state<walking>
    self:addTransition {
      oldState = States.walking,
      newState = States.located,
      event = Events.ARRIVED,
      action = function()
        self.walkPlan = nil
        self.currRoomId = self.targetRoomId
        SendNoEcho("set travel_walk arrived")  -- this is for
        if self.targetAction then
          self.targetAction()
        end
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.blocked,
      event = Events.BOAT,
      action = function()

      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.blocked,
      event = Events.BUSY,
      action = function()

      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.lost,
      event = Events.GET_LOST,
      action = function()

      end
    }
    addTransitionToStop(self, States.walking)
    -- transitions from state<blocked>
    self:addTransition {
      oldState = States.blocked,
      newState = States.walking,
      event = Events.BLOCKING_SOLVED,
      action = function()

      end
    }
    addTransitionToStop(self, States.blocked)
    -- transitions from state<lost>
    self:addTransition {
      oldState = States.lost,
      newState = States.locating,
      event = Events.TRY_RELOCATE, -- always try relocate and the retries threshold is checked when locating
      action = function()

      end
    }
    addTransitionToStop(self, States.lost)
  end

  -- 加载区域列表和房间列表
  function prototype:initZonesAndRooms()
    -- initialize zones
    local zonesById = dal:getAllZones()
    local zonePaths = dal:getAllZonePaths()
    for i = 1, #zonePaths do
      local zonePath = zonePaths[i]
      local zone = zonesById[zonePath.startid]
      if zone then
        zone:addPath(zonePath)
      end
    end
    -- create code map
    local zonesByCode = {}
    for _, zone in pairs(zonesById) do
      zonesByCode[zone.code] = zone
    end
    -- initialize rooms
    local roomsById = dal:getAllAvailableRooms()
    local roomsByCode = {}
    local paths = dal:getAllAvailablePaths()
    for i = 1, #paths do
      local path = paths[i]
      local room = roomsById[path.startid]
      if room then
        room:addPath(path)
      end
    end
    -- add rooms to zones
    for _, room in pairs(roomsById) do
      roomsByCode[room.code] = room
      local zone = zonesByCode[room.zone]
      if zone then
        zone.rooms[room.id] = room
      end
    end
    -- assign to prototype
    self.zonesById = zonesById
    self.zonesByCode = zonesByCode
    self.roomsById = roomsById
    self.roomsByCode = roomsByCode
  end

  local formatExits = function(raw)
    local exits = raw
    exits = string.gsub(exits,"。","")
    exits = string.gsub(exits," ","")
    exits = string.gsub(exits,"、", ";")
    exits = string.gsub(exits, "和", ";")
    local tb = {}
    for _, str in ipairs(utils.split(exits,";")) do
      local t = Trim(str)
      if t ~= "" then table.insert(tb, t) end
    end
    return table.concat(tb, ";")
  end

  function prototype:initTriggers()

    helper.removeTriggerGroups(
      "travel_look_start",
      "travel_look_name",
      "travel_look_desc",
      "travel_look_season",
      "travel_look_exits",
      "travel_walk"
    )

    -- 初始触发
    helper.addTrigger {
      group = "travel_look_start",
      regexp = self.regexp.LOOK_START,
      response = function()
        self:debug("LOOK_START triggered")
        self:clearRoomInfo()
        helper.enableTriggerGroups("travel_look_name")
      end
    }
    -- 抓取房间名称
    local roomNameCaught = function(name, line, wildcards)
      self:debug("ROOM_NAME triggered")
      local roomName = wildcards[1]
      self:debug("room name:", roomName)
      self.currRoomName = roomName
      -- only get the first name, discard all below possible names
      helper.disableTriggerGroups("travel_look_name")
      helper.enableTriggerGroups("travel_look_desc", "travel_look_season", "travel_look_exits")
      self._roomDescInline = true
      self._roomExitsInline = true
    end
    helper.addTrigger {
      group = "travel_look_name",
      regexp = self.regexp.ROOM_NAME_WITH_AREA,
      response = roomNameCaught,
      sequence = 15 -- lower than desc
    }
    helper.addTrigger {
      group = "travel_look_name",
      regexp = self.regexp.ROOM_NAME_WITHOUT_AREA,
      response = roomNameCaught,
      sequence = 15 -- lower than desc
    }
    -- 当频繁使用look时，系统会给出看风景的提示，此时无法获取到房间名称和描述
    helper.addTrigger {
      group = "travel_look_name",
      regexp = self.regexp.BUSY_LOOK,
      response = function()
        self:debug("BUSY_LOOK triggered")
        self:debug("频繁使用look命令不显示描述了！")
        self.busyLook = true
      end
    }
    -- 抓取房间描述
    helper.addTrigger {
      group = "travel_look_desc",
      regexp = self.regexp.ROOM_DESC,
      response = function(name, line, wildcards)
        self:debug("ROOM_DESC triggered")
        if self._roomDescInline then
          table.insert(self.currRoomDesc, wildcards[1])
        end
      end
    }
    -- 季节和时间描述
    helper.addTrigger {
      group = "travel_look_season",
      regexp = self.regexp.SEASON_TIME_DESC,
      response = function(name, line, wildcards)
        self:debug("SEASON_TIME_DESC triggered")
        if self._roomDescInline then
          helper.disableTriggerGroups("travel_look_desc")    -- 禁止其后抓取描述
        end
        self.currSeason = wildcards[1]
        self.currDatetime = wildcards[2]
      end,
      sequence = 5 -- higher than room desc
    }
    -- 抓取出口信息
    helper.addTrigger {
      group = "travel_look_exits",
      regexp = self.regexp.EXITS_DESC,
      response = function(name, line, wildcards)
        self:debug("EXITS_DESC triggered")
        if self._roomDescInline then
          self._roomDescInline = false
          helper.disableTriggerGroups("travel_look_desc")    -- 禁止其后抓取描述
        end
        if self._roomExitsInline then
          self._roomExitsInline = false
          self.currRoomExits = formatExits(wildcards[2] or "look")
        end
      end,
      sequence = 5 -- higher than room desc
    }
    -- 迷路触发
    local lostWay = function()
      self.walkLost = true
      self:debug("似乎迷路了！")
    end
    helper.addTrigger {
      group = "travel_walk",
      regexp = self.regexp.WALK_LOST,
      response = lostWay
    }
    helper.addTrigger {
      group = "travel_walk",
      regexp = self.regexp.WALK_LOST_SPECIAL,
      response = lostWay
    }
    helper.addTrigger {
      group = "travel_walk",
      regexp = self.regexp.WALK_BLOCK,
      response = lostWay
    }
  end

  function prototype:clearRoomInfo()
    self.currRoomId = nil
    self.currRoomName = nil
    self.currRoomDesc = {}    -- use table to store description (avoiding string concat)
    self.currRoomExits = nil
    self.currSeason = nil
    self.currDatetime = nil
    self._roomDescInline = false    -- only use when locating current room
    self._roomExitsInline = false    -- only use when locating current room
  end

  function prototype:initAliases()

  end

  function prototype:waitUntilArrived()
    local currCo = assert(coroutine.running(), "Must be in coroutine")
    local resumeCo = function()
      local ok, err = coroutine.resume(currCo)
      if not ok then
        ColourNote ("deeppink", "black", "Error raised in timer function (in wait module).")
        ColourNote ("darkorange", "black", debug.traceback(currCo))
        error (err)
      end -- if
    end

    helper.addOneShotTrigger {
      group = "travel_one_shot",
      regexp = self.regexp.ARRIVED,
      response = resumeCo
    }
    return coroutine.yield()
  end

  function prototype:relocate()
    local moves = 0
    repeat
      self:lookUntilNotBusy()
      -- 尝试匹配当前房间
      if not self.currRoomName then
        if not self.currRoomExits then
          return self:fire(Events.ROOM_INFO_UNKNOWN)
        else
          -- 尝试随机游走，重新定位
          self:randomGo(self.currRoomExits)
        end
      else
        local potentialRooms = dal:getRoomsByName(self.currRoomName)
        local matched = self:matchPotentialRooms(table.concat(self.currRoomDesc), self.currExits, self._potentialRooms)
        if #matched == 1 then
          self:debug("成功匹配唯一房间", matched[1])
          self.currRoomId = matched[1]
          if self.targetRoomId then
            return self:fire(Events.LOCATION_CONFIRMED)
          else
            return self:fire(Events.LOCATION_CONFIRMED_ONLY)
          end
        else
          if #matched == 0 then
            self:debug("没有可匹配的房间，房间名", self.currRoomName)
          else
            self:debug("查找到多个匹配成功的房间", table.concat(matched, ","))
          end
          -- 尝试随机游走，重新定位
          self:randomGo(self.currRoomExits)
        end
      end
      wait.time(1)
      moves = moves + 1
      if self.currState == States.stop then return end
    until moves > RELOC_MAX_MOVES
    -- 重试多次仍无法定位当前房间
    return self:fire(Events.MAX_RELOC_MOVES)
  end

  function prototype:walking()
    local interval = self.interval or 12
    local restTime = self.restTime or 1
    local mode = self:getMode() or "quick"    -- the default walkto mode
    self:debug("行走模式", mode)
    local delay = self.delay or 1    -- the default walkto delay in slow mode

    local steps = 0
    while #(self.walkPlan) > 0 do
      local move = table.remove(self.walkPlan)
      -- here should be refined, the state may change
      -- due to the path
      -- evaluate the move and may be transit to other state
      if mode ~= "quick" then
        SendNoEcho("halt")
      end
      if move.category == "busy" then
        SendNoEcho(move.path)
        return self:fire(Events.BUSY)
      elseif move.category == "boat" then
        SendNoEcho(move.path)
        return self:fire(Events.BOAT)
      else
        SendNoEcho(move.path)
      end

      steps = steps + 1
      if mode == "quick" and steps >= interval then
        steps = 0
        while true do
          SendNoEcho("set travel_walk break")
          local line = wait.regexp(self.regexp.WALK_BREAK, 5)
          if not line then
            print("系统反应超时，等待5秒重试")
            wait.time(5)
          elseif self.walkLost then
            return self:fire(Events.GET_LOST)
          else
            wait.time(1)
            SendNoEcho("halt")
            break
          end
        end
      end
      if mode == "normal" then
        while true do
          SendNoEcho("set travel_walk step")
          local line = wait.regexp(self.regexp.WALK_STEP, 5)
          if not line then
            print("系统反应超时，等待5秒重试")
            wait.time(5)
          elseif self.walkLost then
            return self:fire(Events.GET_LOST)
          else
            SendNoEcho("halt")
            break
          end
        end
      elseif mode == "slow" then
        while true do
          SendNoEcho("set travel_walk step")
          local line = wait.regexp(self.regexp.WALK_STEP, 5)
          if not line then
            print("系统反应超时，等待5秒重试")
            wait.time(5)
          elseif self.walkLost then
            return self:fire(Events.GET_LOST)
          else
            wait.time(1)
            SendNoEcho("halt")
            break
          end
        end
      end
      if self.currState == States.stop then return end
    end
    return self:fire(Events.ARRIVED)
  end

  ---------------------------------------------------

  function prototype:lookUntilNotBusy()
    while true do
      helper.enableTriggerGroups("travel_look_start")
      self.busyLook = false
      SendNoEcho("set travel_look start")
      SendNoEcho("look")
      SendNoEcho("set travel_look done")
      local line = wait.regexp(self.regexp.LOOK_DONE, 3)
      helper.disableTriggerGroups(
        "travel_look_start",
        "travel_look_name",
        "travel_look_desc",
        "travel_look_season",
        "travel_look_exits")
      if not line then
        print("系统超时，5秒后重试")
        wait.time(5)
      elseif self.busyLook then
        wait.time(2)
      else
        break
      end
    end
  end

  function prototype:randomGo(currExits)
    if not currExits or currExits == "" then return nil end
    local exits = utils.split(currExits, ";")
    local exit = exits[math.random(#(exits))]
    self:debug("随机选择出口并执行重新定位", exit)
    check(SendNoEcho("halt"))
    check(SendNoEcho(exit))
  end

  function prototype:matchPotentialRooms(currRoomDesc, currRoomExits, potentialRooms)
    local matched = {}
    for i = 1, #potentialRooms do
      local room = potentialRooms[i]
      if room.exits == currRoomExits and room.description == currRoomDesc then
        table.insert(matched, room.id)
      end
    end
    return matched
  end

  return prototype
end
-- 这个功能需要等到地图完善后再开放
-- local travel = define_travel().FSM()



--------------------------------------------------------------
-- locate.lua
-- identify the room in world
-- should not be singleton
--------------------------------------------------------------
local define_locate = function()
  local prototype = {}
  prototype.__index = prototype
  prototype.regexp = {
    SET_LOCATE_START = "^[ >]*设定环境变量：locate = \"start\"$",
    SET_LOCATE_STOP = "^[ >]*设定环境变量：locate = \"stop\"$",
    ROOM_NAME_WITH_AREA = "^[ >]{0,12}([^ ]+) \\- \\[[^ ]+\\]$",
    ROOM_NAME_WITHOUT_AREA = "^[ >]{0,12}([^ ]+) \\- $",
    -- a very short line also might be the room name line
    -- ROOM_NAME_SINGLE = "^[ >]{0,12}([^ ]{1,8}) *$",
    ROOM_DESC = "^ {0,12}([^ ].*?) *$",
    SEASON_TIME_DESC = "^    「([^\\\\x00-\\\\xff]+?)」: (.*)$",
    EXITS_DESC = "^\\s{0,12}这里(明显|唯一)的出口是(.*)$|^\\s*这里没有任何明显的出路\\w*",
    BUSY_LOOK = "^[> ]*风景要慢慢的看。$"
  }

  function prototype.newInstance()
    local obj = {}
    setmetatable(obj, prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    -- by default disable debug
    self.DEBUG = false
    self.DESC_DISPLAY_LINE_WIDTH = 30
    self:clearRoomInfo()
    self:initTriggers()
    self:initAliases()
  end

  function prototype:debug(...)
    if self.DEBUG then print(...) end
  end

  function prototype:clearRoomInfo()
    self.currRoomId = nil
    self.currRoomName = nil
    self.currRoomDesc = {}
    self.currExits = nil
    -- used when identify the current room
    self._roomDescInline = false
    self._roomExitsInline = false
    self._potentialRoomName = nil
    self._potentialRooms = {}
    self._locateInProcess = false
    self._busyLook = false
  end

  function prototype:matchPotentialRooms(currRoomDesc, currRoomExits, potentialRooms)
    local matched = {}
    for i = 1, #potentialRooms do
      local room = potentialRooms[i]
      if room.exits == currRoomExits and room.description == currRoomDesc then
        print("room.id", room.id)
        table.insert(matched, room.id)
      end
    end
    return matched
  end

  function prototype:initTriggers()
    -- re-initialize travel triggers
    helper.removeTriggerGroups("locate", "locate_start", "locate_desc", "locate_name", "locate_other")

    -- start trigger
    local start = function(name, line, wildcards)
      self:debug("locate start triggered")
      helper.enableTriggerGroups("locate_name")
      self:clearRoomInfo()
    end
    helper.addTrigger {
      group = "locate_start",
      regexp = self.regexp.SET_LOCATE_START,
      response = start
    }
    -- room name trigger
    local roomNameCaught = function(name, line, wildcards)
      self:debug("locate room name triggered")
      local roomName = wildcards[1]
      print("room name:", roomName, string.len(roomName))
      self._potentialRoomName = roomName
      self:debug("可能的房间名称：", self._potentialRoomName)
      self._potentialRooms = dal:getRoomsByName(roomName)
      -- it is right if and only if the map is complete
      if #(self._potentialRooms) == 1 then
        self.currRoomId = self._potentialRooms[1].id
        self.currRoomName = roomName
        self._locateInProcess = false
      end
      helper.disableTriggerGroups("locate_name")
      helper.enableTriggerGroups("locate_desc")
      helper.enableTriggerGroups("locate_other")
      self._roomDescInline = true
      self._roomExitsInline = true
    end
    helper.addTrigger {
      group = "locate_name",
      regexp = self.regexp.ROOM_NAME_WITH_AREA,
      response = roomNameCaught,
      sequence = 15 -- lower than desc
    }
    helper.addTrigger {
      group = "locate_name",
      regexp = self.regexp.ROOM_NAME_WITHOUT_AREA,
      response = roomNameCaught,
      sequence = 15 -- lower than desc
    }
    -- room name trigger when busy look
    local busyLook = function()
      self:debug("系统禁止频繁使用look命令")
      self._busyLook = true
    end
    helper.addTrigger {
      group = "locate_name",
      regexp = self.regexp.BUSY_LOOK,
      response = busyLook
    }
    -- room desc trigger
    local roomDescCaught = function(name, line, wildcards)
      self:debug("locate room desc triggered")
      if self._roomDescInline then
        table.insert(self.currRoomDesc, wildcards[1])
      end
    end
    helper.addTrigger {
      group = "locate_desc",
      regexp = self.regexp.ROOM_DESC,
      response = roomDescCaught
    }
    -- season/time trigger
    local seasonCaught = function(name, line, wildcards)
      self:debug("locate season/time triggered")
      if self._roomDescInline then
        self._roomDescInline = false
        EnableTriggerGroup("locate_desc", false)
      end
      local season = wildcards[1]
      local datetime = wildcards[2]
    end
    helper.addTrigger {
      group = "locate_other",
      regexp = self.regexp.SEASON_TIME_DESC,
      response = seasonCaught,
      sequence = 5 -- higher than room desc
    }
    -- exits trigger
    local exitsCaught = function(name, line, wildcards)
      self:debug("locate exits triggered")
      if self._roomDescInline then
        self._roomDescInline = false
        EnableTriggerGroup("locate_desc", false)
      end
      if self._roomExitsInline then
        self._roomExitsInline = false
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
        self.currExits = table.concat(tb, ";")
      end
    end
    helper.addTrigger {
      group = "locate_other",
      regexp = self.regexp.EXITS_DESC,
      response = exitsCaught,
      sequence = 5 -- higher than room desc
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("locate")

    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s*$",
      response = function()
        print("LOC定位指令，使用方法：")
        print("loc debug on/off", "开启/关闭调试模式，开启时将将显示所有触发器与日志信息")
        print("loc here", "定位当前房间")
        print("loc <number>", "显示数据库中指定编号房间的信息")
        print("loc match <number>", "将当前房间与目标房间进行对比，输出对比情况")
        print("loc update <number>", "将当前房间的信息更新进数据库，请确保信息的正确性")
        print("loc show", "仅显示当前房间信息，不做look定位")
        print("reloc", "重新定位直到当前房间可唯一确定")
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc here$",
      response = function()
        local locator = self:locator(function() self:show() end)
        coroutine.resume(locator)
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+(\\d+)$",
      response = function(name, line, wildcards)
        local roomId = tonumber(wildcards[1])
        local room = dal:getRoomById(roomId)
        if room then
          self:show(room)
          local paths = dal:getPathsByStartId(room.id)
          local pathDisplay = {}
          for _, path in pairs(paths) do
            table.insert(pathDisplay, path.endid .. " " .. path.path)
          end
          print("可到达路径：", table.concat(pathDisplay, ", "))
        else
          print("无法查询到相应房间")
        end
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+debug\\s+(on|off)$",
      response = function(name, line, wildcards)
        local option = wildcards[1]
        if option == "on" then
          self.DEBUG = true
          print("打开定位调试模式")
        elseif option == "off" then
          self.DEBUG = false
          print("关闭定位调试模式")
        end
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+guess\\s*$",
      response = function()
        self:guess()
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+match\\s+(\\d+)\\s*$",
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:match(targetRoomId)
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+update\\s+(\\d+)\\s*$",
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:update(targetRoomId)
      end
    }
    -- match and update
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+mu\\s+(\\d+)\\s*$",
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:match(targetRoomId, true)
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^reloc\\s*$",
      response = function()
        local relocator = self:relocator(function()
          print("重新定位成功：", self.currRoomId, self.currRoomName)
        end)
        coroutine.resume(relocator)
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+show\\s*$",
      response = function()
        self:show()
      end
    }
  end

  function prototype:showDesc(roomDesc)
    if type(roomDesc) == "string" then
      for i = 1, string.len(roomDesc), self.DESC_DISPLAY_LINE_WIDTH do
        print(string.sub(roomDesc, i, i + self.DESC_DISPLAY_LINE_WIDTH - 1))
      end
    elseif type(roomDesc) == "table" then
      for _, d in ipairs(roomDesc) do
        print(d)
      end
    end
  end

  function prototype:show(room)
    if room then
      print("Target Room Id:", room.id)
      print("Target Room Name:", room.name)
      print("Target Room Code:", room.code)
      print("Target Room Exits:", room.exits)
      if room.description then
        print("Target Room desc:")
        self:showDesc(room.description)
      else
        print("Target Room desc:", room.description)
      end
    else
      print("Current Room Id:", self.currRoomId)
      print("Current Room Name:", self.currRoomName)
      print("Current Room Exits:", self.currExits)
      print("Current Room desc:")
      self:showDesc(self.currRoomDesc)
      if #(self._potentialRooms) > 0 then
        local ids = {}
        for _, room in pairs(self._potentialRooms) do table.insert(ids, room.id) end
        print("Potential Room Ids:", table.concat(ids, ","))
      end
    end
  end

  -- used for other module to update the current room
  function prototype:notify(roomId)
    self.currRoomId = roomId
  end

  function prototype:locator(action)
    local action = action or function() end
    return coroutine.create(function()
      local additionalInfo
      local retries = 5
      repeat
        self._locateInProcess = true
        helper.enableTriggerGroups("locate_start")
        check(SendNoEcho("set locate start"))
        check(SendNoEcho("look"))
        check(SendNoEcho("set locate stop"))
        local line = wait.regexp(self.regexp.SET_LOCATE_STOP, 5)
        helper.disableTriggerGroups("locate_start", "locate_desc", "locate_name", "locate_other")
        self._locateInProcess = false
        -- if timeout line is not matched and line will be nil
        if not line then
          self:debug("Timeout on locate!")
          break
        elseif self._busyLook then
          --retry with 1 second delay
          wait.time(1)
        else
          if self.currRoomId then
            local room = dal:getRoomById(self.currRoomId)
            if room.description ~= table.concat(self.currRoomDesc) then
              additionalInfo = "注意：房间描述与数据库中不符，存在错配的可能！"
            end
            break
          end
        end
      until not self._busyLook
      action(self.currRoomId)
      if additionalInfo then
        print(additionalInfo)
      end
    end)
  end

  local randomPickExits = function(currExits)
    if not currExits or currExits == "" then return nil end
    local exits = utils.split(currExits, ";")
    return exits[math.random(#(exits))]
  end

  -- relocate current room, when action associated after the relocating
  -- action callback can receive the current room id as its input
  function prototype:relocator(action)
    local action = action or function() end
    return coroutine.create(function()
      local retries = 15
      repeat
        self._locateInprocess = true
        helper.enableTriggerGroups("locate_start")
        check(SendNoEcho("set locate start"))
        check(SendNoEcho("look"))
        check(SendNoEcho("set locate stop"))
        local line = wait.regexp(self.regexp.SET_LOCATE_STOP, 5)
        helper.disableTriggerGroups("locate_start", "locate_desc", "locate_name", "locate_other")
        self._locateInProcess = false
        if not line then
          print("重新定位超时失败！")
          -- no action performed
          return false
        elseif self._busyLook then
          self:debug("系统禁止频繁look请求，1秒后重试")
          wait.time(1)
        elseif self.currRoomId then
          self:debug("获取到当前房间编号", self.currRoomId)
          break
        elseif #(self._potentialRooms) > 0 then
          local matched = self:matchPotentialRooms(table.concat(self.currRoomDesc), self.currExits, self._potentialRooms)
          if #matched == 1 then
            self:debug("成功匹配仅1个房间", matched[1])
            self.currRoomId = matched[1]
            self.currRoomName = self._potentialRoomName
            break
          elseif #matched == 0 then
            self:debug("没有可匹配的房间", self._potentialRoomName)
          elseif #matched > 1 then
            self:debug("查找到多个匹配成功的房间", table.concat(matched, ","))
          end
          local exit = randomPickExits(self.currExits)
          if exit then
            self:debug("随机选择出口并执行重新定位", exit)
            check(SendNoEcho("halt"))
            check(SendNoEcho(exit))
          else
            print("没有出口可供选择，重新定位失败")
            return false
          end
        else
          print("没有可供匹配的同名房间")
          local exit = randomPickExits(self.currExits)
          if exit then
            self:debug("随机选择出口并重新定位", exit)
            check(SendNoEcho("halt"))
            check(SendNoEcho(exit))
          else
            print("没有出口可供选择，重新定位失败")
            return false
          end
        end
        wait.time(0.3)
        retries = retries - 1
      until self.currRoomId ~= nil or retries <= 0
      -- 执行后续行动
      if self.currRoomId then
        action(self.currRoomId)
      else
        print("重新定位失败，到达重试最大次数")
      end
    end)
  end

  function prototype:guess()
    -- after locate, we can guess which record it
    -- belongs to according to pinyin of its room name
    local roomName = self._potentialRoomName
    print(roomName, string.len(roomName))
    if not roomName then
      print("当前房间名称为空，请先使用LOC定位命令")
      return
    end
    self:debug("当前房间名称：", roomName, "长度：", string.len(roomName))
    if gb2312.len(roomName) > 10 then
      print("当前版本仅支持10个汉字长度内的名称查询")
    end
    local pinyins = dal:getPinyinListByWord(roomName)
    self:debug("尝试拼音列表：", pinyins and table.concat(pinyins, ", "))
    local candidates = {}
    for _, pinyin in ipairs(pinyins) do
      local results = dal:getRoomsLikeCode(pinyin)
      for id, room in pairs(results) do
        candidates[id] = room
      end
    end
    print("通过房间名拼音匹配得到候选列表：")
    print("----------------------------")
    for _, c in pairs(candidates) do
      print("Room Id:", c.id)
      print("Room Code:", c.code)
      print("Room Name:", c.name)
      print("Room exits:", c.exits)
      print("Room Desc:", c.description and string.sub(c.description, 1, 30))
      print("----------------------------")
    end
  end

  local directions = {
    s="south",
    n="north",
    w="west",
    e="east",
    ne="northeast",
    se="southeast",
    sw="southwest",
    nw="northwest",
    su="southup",
    nu="northup",
    eu="eastup",
    wu="westup",
    sd="southdown",
    nd="northdown",
    wd="westdown",
    ed="eastdown",
    u="up",
    d="down"
  }
  local expandDirection = function(path)
    return directions[path] or path
  end

  function prototype:match(roomId, performUpdate)
    local performUpdate = performUpdate or false
    local room = dal:getRoomById(roomId)
    if not room then
      print("查询不到指定编号的房间：" .. roomId)
      return
    end
    -- 比较房间名称
    if not self._potentialRoomName then
      print("当前房间无可确定的名称，请先使用LOC定位命令捕捉")
      return
    end
    if self._potentialRoomName == room.name then
      self:debug("名称匹配")
    else
      print("名称不匹配：", "当前", self._potentialRoomName, "目标", room.name)
    end
    local currRoomDesc = table.concat(self.currRoomDesc)
    if currRoomDesc == room.description then
      self:debug("描述匹配")
    else
      print("描述不匹配：")
      print("当前", currRoomDesc)
      print("目标", room.description)
    end
    local currExits = {}
    local currExitCnt = 0
    if self.currExits and self.currExits ~= "" then
      for _, e in ipairs(utils.split(self.currExits, ";")) do
        currExits[e] = true
        currExitCnt = currExitCnt + 1
      end
    end
    local tgtExits = {}
    local tgtExitCnt = 0
    if room.exits and room.exits ~= "" then
      for _, e in ipairs(utils.split(room.exits, ";")) do
        tgtExits[e] = true
        tgtExitCnt = tgtExitCnt + 1
      end
    end
    local exitsIdentical = true
    if currExitCnt ~= tgtExitCnt then
      exitsIdentical = false
    else
      for curr in pairs(currExits) do
        if not tgtExits[curr] then
          exitsIdentical = false
          break
        end
      end
    end
    -- furthur check on paths
    local pathIdentical = true
    local tgtPaths = dal:getPathsByStartId(roomId)
    local tgtPathCnt = 0
    for _, tgtPath in pairs(tgtPaths) do
      tgtPathCnt = tgtPathCnt + 1
      if not currExits[expandDirection(tgtPath.path)] then
        pathIdentical = false
        break
      end
    end
    if tgtPathCnt ~= currExitCnt then
      pathIdentical = false
    end
    local pathDisplay = {}
    for _, tgtPath in pairs(tgtPaths) do
      table.insert(pathDisplay, tgtPath.endid .. " " .. tgtPath.path)
    end
    if exitsIdentical and pathIdentical then
      if performUpdate then
        self:update(roomId)
        print("出口与路径均匹配，数据库记录已更新")
      else
        print("出口与路径均匹配")
      end
    elseif exitsIdentical and not pathIdentical then
      if performUpdate then
        print("出口匹配但路径不匹配，不建议更新数据库，如需要请手动update")
      else
        print("出口匹配但路径不匹配")
      end
    elseif pathIdentical then
      if performUpdate then
        self:update(roomId)
        print("出口不匹配但路径匹配，数据库记录已更新")
      else
        print("出口不匹配但路径匹配")
      end
    else
      if performUpdate then
        print("出口与路径都不匹配，不建议更新数据库，如需要请手动update")
      else
        print("出口与路径都不匹配")
      end
    end
    print(table.concat(pathDisplay, ", "))
  end

  function prototype:update(roomId)
    local room = Room:new {
      id = roomId,
      name = self._potentialRoomName,
      code = "",
      description = table.concat(self.currRoomDesc),
      exits = self.currExits
    }
    dal:updateRoom(room)
  end

  return prototype
end
local locate = define_locate().newInstance()

--------------------------------------------------------------
-- walkto.lua
-- walk from one room to another room
-- depends on locate
--------------------------------------------------------------
local define_walkto = function()
  local prototype = {}
  prototype.__index = prototype
  prototype.regexp = {
    TRIGGER_WALKTO_REST = "^[ >]*设定环境变量：walkto = \"rest\"",
    TRIGGER_WALKTO_STEP = "^[ >]*设定环境变量：walkto = \"step\"",
    TRIGGER_WALKTO_FINISH = "^[ >]*设定环境变量：walkto = \"finish\"",
    TRIGGER_WALKTO_LOST_WAY = "^[> ]*(这个方向没有出路。|你一不小心脚下踏了个空，... 啊...！|你小心翼翼往前挪动，遇到艰险难行处，只好放慢脚步。|你还在山中跋涉，一时半会恐怕走不出.*|青海湖畔美不胜收，你不由停下脚步，欣赏起了风景。|你不小心被什么东西绊了一下.*)$",
    TRIGGER_WALKTO_LOST_WAY_SPECIAL = "^[ >]*泼皮一把拦住你：要向从此过，留下买路财！泼皮一把拉住了你。$",
    TRIGGER_WALKTO_BLOCK = "^[> ]*你的动作还没有完成，不能移动.*$",
    TRIGGER_WALKTO_PAUSE_START = "^[ >]*(你踩上铁索，向山涧的对面飘然而去.*|你一咬牙，扳住崖上的岩石.*|你扶着铁索，踏上桥板.*)",
    TRIGGER_WALKTO_PAUSE_END = "^[> ]*(你整了整衣服，走了进去。|你定了定神，走了出来。|你从下面爬了上来，衣服都烂了，看起来十分狼狈。|你从上面爬了下来，衣服都烂了，看起来十分狼狈。|六名雪山弟子一齐转动机关，吊桥便又升了起来。|大车停稳了下来，你可以下车\\(xia\\)了。|你身在半空，双手乱挥，只盼能抓到什么东西，这么乱挥一阵，又下堕下百馀丈。|你终于一步步的终于挨到了桥头.*|你终于来到了对面，心里的石头终于落地。|你听到声音的来源好象是从左侧\\(left\\)的墙壁\\(wall\\)中发出的。|你在左侧墙上的一块石缝中摸到了一处开关\\(button\\)。)$",
    TRIGGER_WALKTO_BOAT_START = "^[ >]*一叶扁舟缓缓地驶了过来，艄公将一块踏脚板.*|岸边一只渡船上的老艄公说道：正等着你.*)$",
    TRIGGER_WALKTO_BOAT_END = "^[ >]*(艄公说“到啦，上岸吧”.*|船夫对你说道：“到了.*|你朝船夫挥了挥手.*|小舟终于划到近岸.*|.*你跨上岸去。.*|不知过了多久，船终于靠岸了，你累得满头大汗。.*)$",
    TRIGGER_WALKTO_BOAT_YELL = "^[ >]*(你吸了口气，一声“船家”.*|你使出吃奶的力气.*|你没事不要乱往别人船上钻!.*)$",
    TRIGGER_WALKTO_BOAT_IN = "^[ >]*(艄公把踏脚板收起来.*|船夫把踏脚板收起来.*|小舟在湖中藕菱之间的水路.*|你跃上小舟，船就划了起来。.*|你拿起船桨用力划了起来。.*)",
    --TRIGGER_WALKTO_IN_COMBAT = "^[ >]*你身行向后一跃，跳出战圈不打了。$",
    ALIAS_WALKTO = "^walkto\\s*$",
    ALIAS_WALKTO_DEBUG = "^walkto\\s+debug\\s+(on|off)\\s*$",
    ALIAS_WALKTO_ID = "^walkto\\s+(\\d+)\\s*$",
    ALIAS_WALKTO_CODE = "^walkto\\s+([a-z][a-z0-9]+)\\s*$",
    ALIAS_WALKTO_LIST = "^walkto\\s+listzone\\s+([a-z]+)\\s*$",
    ALIAS_WALKTO_MODE = "^walkto\\s+mode\\s+(quick|normal|slow)$"
  }
  prototype.DEBUG = true
  prototype.zonesearch = Algo.dijkstra
  prototype.roomsearch = Algo.astar
  prototype.traverse = Algo.traversal

  function prototype:newInstance(args)
    assert(args.locate, "locate cannot be nil")
    local obj = {}
    obj.locate = args.locate
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self.lostWay = false
    self:initZonesAndRooms()
    self:initTriggers()
    self:initAliases()
  end

  function prototype:prepareWalk()
    EnableTriggerGroup("walkto", true)
    self.lostWay = false
    self.locate:clearRoomInfo()
  end

  function prototype:stopWalk()
    EnableTriggerGroup("walkto", false)
  end

  function prototype:initZonesAndRooms()
    -- initialize zones
    local zonesById = dal:getAllZones()
    local zonePaths = dal:getAllZonePaths()
    for i = 1, #zonePaths do
      local zonePath = zonePaths[i]
      local zone = zonesById[zonePath.startid]
      if zone then
        zone:addPath(zonePath)
      end
    end
    -- create code map
    local zonesByCode = {}
    for _, zone in pairs(zonesById) do
      zonesByCode[zone.code] = zone
    end
    -- initialize rooms
    local roomsById = dal:getAllAvailableRooms()
    local roomsByCode = {}
    local paths = dal:getAllAvailablePaths()
    for i = 1, #paths do
      local path = paths[i]
      local room = roomsById[path.startid]
      if room then
        room:addPath(path)
      end
    end
    -- add rooms to zones
    for _, room in pairs(roomsById) do
      roomsByCode[room.code] = room
      local zone = zonesByCode[room.zone]
      if zone then
        zone.rooms[room.id] = room
      end
    end
    -- assign to prototype
    self.zonesById = zonesById
    self.zonesByCode = zonesByCode
    self.roomsById = roomsById
    self.roomsByCode = roomsByCode
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("walkto")
    local lostWay = function()
      if not self.lostWay then
        self.lostWay = true
        print("行走路径出错！")
      end
    end
    helper.addTrigger {
      group = "walkto",
      regexp = self.regexp.TRIGGER_WALKTO_LOST_WAY,
      response = lostWay
    }
    helper.addTrigger {
      group = "walkto",
      regexp = self.regexp.TRIGGER_WALKTO_LOST_WAY_SPECIAL,
      response = lostWay
    }
    helper.addTrigger {
      group = "walkto",
      regexp = self.regexp.TRIGGER_WALKTO_BLOCK,
      response = lostWay
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("walkto")

    helper.addAlias {
      group = "walkto",
      regexp = self.regexp.ALIAS_WALKTO,
      response = function()
        print("WALK自动行走指令，使用方法：")
        print("walkto debug on/off", "开启/关闭调试模式，开启时将将显示所有触发器与日志信息")
        print("walkto mode quick/normal/slow", "调整自动行走模式，quick：快速行走，每12步休息1秒；normal：每步短暂停顿；slow：每步停顿1秒")
        print("walkto <number>", "根据目标房间编号进行自动行走，如果当前房间未知将先进行重新定位")
        print("walkto <room_code>", "根据目标房间代号进行自动行走，代号如果为区域名，将行走到区域的中心节点")
        print("walkto showzone", "显示自动行走支持的区域列表")
        print("walkto listzone <zone_code>", "显示相应区域所有可达的房间")
      end
    }
    helper.addAlias {
      group = "walkto",
      regexp = self.regexp.ALIAS_WALKTO_DEBUG,
      response = function(name, line, wildcards)
        local option = wildcards[1]
        if option == "on" then
          self.DEBUG = true
          print("开启自动行走调试模式")
        elseif option == "off" then
          self.DEBUG = false
          print("关闭自动行走调试模式")
        end
      end
    }
    helper.addAlias {
      group = "walkto",
      regexp = self.regexp.ALIAS_WALKTO_ID,
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:walkto(targetRoomId, function() self:debug("到达目的地") end)
      end
    }
    helper.addAlias {
      group = "walkto",
      regexp = self.regexp.ALIAS_WALKTO_CODE,
      response = function(name, line, wildcards)
        local target = wildcards[1]
        if target == "showzone" then
          print(string.format("%16s%16s%16s", "区域代码", "区域名称", "区域中心"))
          for _, zone in pairs(self.zonesById) do
            print(string.format("%16s%16s%16s", zone.code, zone.name, zone.centercode))
          end
        elseif self.zonesByCode[target] then
          local targetRoomCode = self.zonesByCode[target].centercode
          local targetRoomId = self.roomsByCode[targetRoomCode]
          self:walkto(targetRoomId, function() self:debug("到达目的地") end)
        elseif self.roomsByCode[target] then
          local targetRoomId = self.roomsByCode[target].id
          self:walkto(targetRoomId, function() self:debug("到达目的地") end)
        else
          print("查询不到相应房间")
          return false
        end
      end
    }
    helper.addAlias {
      group = "walkto",
      regexp = self.regexp.ALIAS_WALKTO_LIST,
      response = function(name, line, wildcards)
        local zoneCode = wildcards[1]
        if self.zonesByCode[zoneCode] then
          local zone = self.zonesByCode[zoneCode]
          print(string.format("%s(%s)房间列表：", zone.name, zone.code))
          print(string.format("%4s%20s%40s", "编号", "名称", "代码"))
          for _, room in pairs(zone.rooms) do
            print(string.format("%4d%20s%40s", room.id, room.name, room.code))
          end
        else
          print("查询不到相应区域")
        end
      end
    }
    helper.addAlias {
      group = "walkto",
      regexp = self.regexp.ALIAS_WALKTO_MODE,
      response = function(name, line, wildcards)
        local mode = wildcards[1]
        self:mode(mode)
      end
    }
  end

  function prototype:mode(mode)
    if mode then
      self._mode = mode
    else
      return self._mode
    end
  end

  -- this function is very important and should be refined
  function prototype:evaluateEachMove(move, mode)
    if mode == "quick" then
      SendNoEcho(move.path)
    else
      SendNoEcho("halt")
      SendNoEcho(move.path)
    end
  end

  function prototype:debug(...)
    if (self.DEBUG) then print(...) end
  end

  function prototype:walker(pathStack, action)
    local interval = self.interval or 12
    local restTime = self.restTime or 1
    local mode = self:mode() or "quick"    -- the default walkto mode
    print("mode", mode)
    local delay = self.delay or 1    -- the default walkto delay in slow mode
    local action = action or function() end
    return coroutine.create(function()
      -- before move, clear room info
      self:prepareWalk()
      local targetRoomId
      local steps = 0
      repeat
        local move = table.remove(pathStack)
        --always update target room id
        targetRoomId = move.endid
        self:evaluateEachMove(move, mode)
        steps = steps + 1
        if mode == "quick" and steps >= interval then
          steps = 0
          SendNoEcho("set walkto rest")
          local line = wait.regexp(self.regexp.TRIGGER_WALKTO_REST, 5)
          -- in quick mode, we can only check if lost way when rest
          if self.lostWay then
            print("路线出现错误，自动行走失败")
            self:stopWalk()
            return false
          elseif not line then
            print("系统反应超时，自动行走失败")
            self:stopWalk()
            return false
          else
            wait.time(1)
            SendNoEcho("halt")
          end
        end
        -- for normal
        if mode == "normal" then
          SendNoEcho("set walkto step")
          local line = wait.regexp(self.regexp.TRIGGER_WALKTO_STEP, 5)
          if self.lostWay then
            print("路线出现错误，自动行走失败")
            self:stopWalk()
            return false
          elseif not line then
            print("系统反应超时，自动行走失败")
            self:stopWalk()
            return false
          else
            SendNoEcho("halt")
          end
        elseif mode == "slow" then
          SendNoEcho("set walkto step")
          local line = wait.regexp(self.regexp.TRIGGER_WALKTO_STEP, 5)
          if self.lostWay then
            print("路线出现错误，自动行走失败")
            self:stopWalk()
            return false
          elseif not line then
            print("系统反应超时，自动行走失败")
            self:stopWalk()
            return false
          else
            wait.time(self.delay)
            SendNoEcho("halt")
          end
        end
      until #pathStack == 0
      SendNoEcho("set walkto finish")
      wait.regexp(self.regexp.TRIGGER_WALKTO_FINISH, 5)
      self.locate:notify(targetRoomId)
      self:stopWalk()
      self:debug("更新房间编号为", targetRoomId)
      action()
    end)
  end

  function prototype:walkWithinRooms(rooms, startid, targetid, action)
    local pathStack = self.roomsearch {
      rooms = rooms,
      startid = startid,
      targetid = targetid
    }
    self:debug("行走路径共经过" .. #pathStack .. "个房间")
    if not pathStack then
      print("计算路径失败，房间" .. startid .. "至房间" .. targetid .. "不可达")
    elseif #pathStack == 0 then
      print("正在当前房间")
      if action then action() end
    else
      local walker = self:walker(pathStack, action)
      coroutine.resume(walker)
    end
  end

  function prototype:walkFromTo(fromid, toid, action)
    self:debug("检验起始房间和目标房间", fromid, toid)
    local startRoom = self.roomsById[fromid]
    local endRoom = self.roomsById[toid]
    if not startRoom then
      print("当前房间不在自动行走列表中")
      return false
    elseif not endRoom then
      print("目标房间不在自动行走列表中")
      return false
    else
      local startZone = self.zonesByCode[startRoom.zone]
      local endZone = self.zonesByCode[endRoom.zone]
      if not startZone then
        print("当前区域不在自动行走列表中", startRoom.zone)
        return false
      elseif not endZone then
        print("目标区域不在自动行走列表中", endRoom.zone)
        return false
      elseif startZone == endZone then
        if self.DEBUG then
          local roomCnt = 0
          for _, room in pairs(startZone.rooms) do
            roomCnt = roomCnt + 1
          end
          print("出发地与目的地处于同一区域，共" .. roomCnt .. "个房间")
        end
        self:walkWithinRooms(startZone.rooms, fromid, toid, action)
      else
        -- zone search for shortest path
        local zoneStack = self.zonesearch {
          rooms = self.zonesById,
          startid = startZone.id,
          targetid = endZone.id
        }
        if not zoneStack then
          print("计算区域路径失败，区域 " .. startZone.name .. " 至区域 " .. endZone.name .. " 不可达")
          return false
        else
          table.insert(zoneStack, ZonePath:decorate {startid=startZone.id, endid=startZone.id, weight=0})
          local zoneCnt = #zoneStack
          local rooms = {}
          local roomCnt = 0
          while #zoneStack > 0 do
            local zonePath = table.remove(zoneStack)
            for _, room in pairs(self.zonesById[zonePath.endid].rooms) do
              rooms[room.id] = room
              roomCnt = roomCnt + 1
            end
          end
          self:debug("本次路径计算跨" .. zoneCnt .. "个区域，共" .. roomCnt .. "个房间")
          self:walkWithinRooms(rooms, fromid, toid, action)
        end
      end
    end
  end

  function prototype:walkto(toid, action)
    if not self.locate.currRoomId then
      local walker = self.locate:relocator(function(roomId)
        self:walkFromTo(roomId, toid, action)
      end)
      coroutine.resume(walker)
    else
      self:walkFromTo(self.locate.currRoomId, toid, action)
    end
  end

  return prototype
end
local walkto = define_walkto():newInstance {locate = locate}

local define_traverse = function()
  local prototype = {}
  prototype.__index = prototype



  return prototype
end
local traverse = define_traverse

--
--local define_simple = function()
--  local prototype = FSM.inheritedMeta()
--
--  function prototype:new()
--    local obj = FSM:new()
--    setmetatable(obj, self or prototype)
--    obj:postConstruct()
--    return obj
--  end
--
--  function prototype:postConstruct()
--    self:addState {
--      state = "on",
--      enter = function()
--        print("enter on")
--      end,
--      exit = function()
--        print("exit on")
--      end
--    }
--    self:addState {
--      state = "off",
--      enter = function()
--        print("enter off")
--      end,
--      exit = function()
--        print("exit off")
--      end
--    }
--    self:addTransition {
--      oldState = "on",
--      newState = "off",
--      event = "switch",
--      action = function()
--        print("switched")
--      end
--    }
--    self:addTransition {
--      oldState = "off",
--      newState = "on",
--      event = "switch",
--      action = function()
--        print("switched")
--      end
--    }
--    self:setState("on")
--  end
--
--  return prototype
--end
--local simple = define_simple():new()
--
--simple:debugOn()
--
--print(simple:getState())
--print(simple:fire("switch"))
--print(simple:fire("switch"))



-- expose modules
return {
  FSM = FSM,
  helper = helper,
  locate = locate,
  walkto = walkto
}


