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
    ["һ"] = 1,
    ["��"] = 2,
    ["��"] = 3,
    ["��"] = 4,
    ["��"] = 5,
    ["��"] = 6,
    ["��"] = 7,
    ["��"] = 8,
    ["��"] = 9
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
      if char == "ʮ" then
        unit = 10 * _10k
        if i == 0 then
          result = result + unit
        elseif _nums[string.sub(str, i - 1, i)] == nil then
          result = result + unit
        end
      elseif char == "��" then
        unit = 100 * _10k
      elseif char == "ǧ" then
        unit = 1000 * _10k
      elseif char == "��" then
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
    ["��"] = "up",
    ["��"] = "down",
    ["��"] = "south",
    ["��"] = "east",
    ["��"] = "west",
    ["��"] = "north",
    ["����"] = "southup",
    ["����"] = "southdown",
    ["����"] = "westup",
    ["����"] = "westdown",
    ["����"] = "eastup",
    ["����"] = "eastdown",
    ["����"] = "northup",
    ["����"] = "northdown",
    ["����"] = "northwest",
    ["����"] = "northeast",
    ["����"] = "southwest",
    ["����"] = "southeast",
    ["С��"] = "xiaodao",
    ["С·"] = "xiaolu"
  }
  helper.ch2direction = function (str) return _dirs(str) end

  -- convert chinese areas
  local areas = {
    {
    },
    {
      ["��ԭ"] = true,
      ["����"] = true,
      ["����"] = true,
      ["̩ɽ"] = true,
      ["����"] = true,
      ["����"] = true,
      ["Ȫ��"] = true,
      ["����"] = true,
      ["��ɽ"] = true,
      ["����"] = true,
      ["����"] = true,
      ["�ϲ�"] = true,
      ["��"] = true,
      ["����"] = true,
      ["����"] = true,
      ["��Դ"] = true,
      ["����"] = true,
      ["�ɶ�"] = true,
      ["����"] = true,
      ["��̳"] = true,
      ["����"] = true,
      ["����"] = true,
      ["����"] = true,
      ["����"] = true,
      ["����"] = true,
      ["����"] = true,
      ["ؤ��"] = true,
      ["����"] = true,
      ["��ɽ"] = true,
      ["ȫ��"] = true,
      ["��Ĺ"] = true,
      ["����"] = true,
      ["����"] = true,
      ["����"] = true,
      ["����"] = true
    },
    {
      ["�ٰ���"] = true,
      ["����ׯ"] = true,
      ["Сɽ��"] = true,
      ["�żҿ�"] = true,
      ["�����"] = true,
      ["�Ͻ���"] = true,
      ["������"] = true,
      ["ɱ�ְ�"] = true,
      ["����Ĺ"] = true,
      ["�һ���"] = true,
      ["������"] = true,
      ["�䵱ɽ"] = true,
      ["������"] = true,
      ["����ɽ"] = true,
      ["������"] = true,
      ["������"] = true,
      ["����ɽ"] = true,
      ["��ػ�"] = true
    },
    {
      ["����÷ׯ"] = true,
      ["�����ϰ�"] = true,
      ["��������"] = true,
      ["�ƺ��ϰ�"] = true,
      ["�ƺӱ���"] = true,
      ["��������"] = true,
      ["ƽ������"] = true,
      ["��������"] = true,
      ["�������"] = true,
      ["˿��֮·"] = true,
      ["����Ľ��"] = true,
      ["��ü��ɽ"] = true
    },
    {
      ["�������ϳ�"] = true,
      ["����������"] = true,
      ["�����ᶽ��"] = true
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