--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:20
-- To change this template use File | Settings | File Templates.
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

  -- global functions
  inheritMeta = function(Cls)
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


