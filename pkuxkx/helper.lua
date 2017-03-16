--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:24
-- To change this template use File | Settings | File Templates.
--
require "pkuxkx.predefines"

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
return define_helper()
