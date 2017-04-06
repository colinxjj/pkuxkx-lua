--
-- Simulating MushClient world
--
world = {}

trigger_flag = {}
trigger_flag.Enabled = 1
trigger_flag.OmitFromLog = 2
trigger_flag.OmitFromOutput = 4
trigger_flag.KeepEvaluating = 8
trigger_flag.IgnoreCase = 16
trigger_flag.RegularExpression = 32
trigger_flag.ExpandVariables = 512
trigger_flag.Replace = 1024
trigger_flag.Temporary = 16384
trigger_flag.LowercaseWildcard = 2048

custom_colour = {}
custom_colour.NoChange = -1
custom_colour.Custom1 = 0
custom_colour.Custom2 = 1
custom_colour.Custom3 = 2
custom_colour.Custom4 = 3
custom_colour.Custom5 = 4
custom_colour.Custom6 = 5
custom_colour.Custom7 = 6
custom_colour.Custom8 = 7
custom_colour.Custom9 = 8
custom_colour.Custom10 = 9
custom_colour.Custom11 = 10
custom_colour.Custom12 = 11
custom_colour.Custom13 = 12
custom_colour.Custom14 = 13
custom_colour.Custom15 = 14
custom_colour.Custom16 = 15
custom_colour.CustomOther = 16

sendto = {}
sendto.world = 0
sendto.command = 1
sendto.output = 2
sendto.status = 3
sendto.notepad = 4
sendto.notepadappend = 5
sendto.logfile = 6
sendto.notepadreplace = 7
sendto.commandqueue = 8
sendto.variable = 9
sendto.execute = 10
sendto.speedwalk = 11
sendto.script = 12
sendto.immediate = 13
sendto.scriptafteromit = 14

alias_flag = {}
alias_flag.Enabled = 1
alias_flag.KeepEvaluating = 8
alias_flag.IgnoreAliasCase = 32
alias_flag.OmitFromLogFile = 64
alias_flag.RegularExpression = 128
alias_flag.ExpandVariables = 512
alias_flag.Replace = 1024
alias_flag.AliasSpeedWalk = 2048
alias_flag.AliasQueue = 4096
alias_flag.AliasMenu = 8192
alias_flag.Temporary = 16384

timer_flag = {}
timer_flag.Enabled = 1
timer_flag.AtTime = 2
timer_flag.OneShot = 4
timer_flag.TimerSpeedWalk = 8
timer_flag.TimerNote = 16
timer_flag.ActiveWhenClosed = 32
timer_flag.Replace = 1024
timer_flag.Temporary = 16384

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

-- pseudo functions
-- long AddTriggerEx(
--    BSTR TriggerName, BSTR MatchText, BSTR ResponseText,
--    long Flags, short Colour, short Wildcard, BSTR SoundFileName,
--    BSTR ScriptName, short SendTo, short Sequence)
function AddTriggerEx() end

function AddAlias() end

function AddTimer() end

local id = 0
function GetUniqueID()
  id = id + 1
  return id
end

function SetTriggerOption() end

function SetAliasOption() end

function SetTimerOption() end

function SendNoEcho() end

function Trim() end

function ColourNote() end

function GetTriggerList() return {} end

function GetTriggerInfo() end

function GetAliasList() return {} end

function GetAliasInfo() end

function GetTimerList() return {} end

function GetTimerInfo() end

function Note() end

utils = {}

function utils.split(str, delim)
  local results = {}
  local s = 1
  local ss, se = string.find(str, delim, s)
  while ss do
    table.insert(results, string.sub(str, s, ss - 1))
    s = se + 1
    ss, se = string.find(str, delim, s)
  end
  table.insert(results, string.sub(str, s))
  return results
end

bit = {}
bit.bor = function() end