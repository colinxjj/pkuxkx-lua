--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:24
-- To change this template use File | Settings | File Templates.
--
require "pkuxkx.predefines"
require "check"

local define_helper = function()
  local helper = {}

  local REGEXP = {
    NOT_BUSY = "^[ >]*�����ڲ�æ��$",
    SETTING = "^[ >]*�趨����������__SETTING_NAME__ = \"__SETTING_VALUE__\"$",
  }

  helper.settingRegexp = function(name, value)
    return string.gsub(string.gsub(REGEXP.SETTING, "__SETTING_NAME__", name), "__SETTING_VALUE__", value)
  end

  -- �������б�
  local DIRECTIONS = {
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

  helper.expandDirection = function(path)
    return DIRECTIONS[path] or path
  end

  -- the global namespace to store the functions used in trigger, alias and timer
  local _global_trigger_callbacks = {}
  local _global_alias_callbacks = {}
  local _global_timer_callbacks = {}

  helper.repeatedRunnableWithCo = function(func, oneshot)
    local func = func
    if oneshot then
      -- oneshot we must clean up the global name space after the action is called
      local oneshotFunc = function(name, line, wildcards)
        func(name, line, wildcards)
        _global_trigger_callbacks = nil
        _global_alias_callbacks = nil
        _global_timer_callbacks = nil
        _G.world[name] = nil
      end
      return function(name, line, wildcards)
        return coroutine.wrap(oneshotFunc)(name, line, wildcards)
      end
    else
      return function(name, line, wildcards)
        return coroutine.wrap(func)(name, line, wildcards)
      end
    end
  end

  local COPY_WILDCARDS_NONE = 0
  local SOUND_FILE_NONE = ""

  -- make sure name is unique

  helper.addTrigger = function(args)
    local regexp = assert(type(args.regexp) == "string" and args.regexp, "regexp in trigger must be string")
    local group = assert(args.group, "group in trigger cannot be empty")
    local response = assert(type(args.response) == "function" and args.response, "response must be function")
    local name = args.name or (group .. "_" .. GetUniqueID())
    local sequence = args.sequence or 10
    local stopEvaluation = args.stopEvaluation or false

    -- wrap function into coroutine and stored in world for trigger to call
    _G.world[name] = helper.repeatedRunnableWithCo(response)
    _global_trigger_callbacks[name] = true
    check(AddTriggerEx(name, regexp, "-- added by helper",
      -- add trigger but disabled
      bit.bor(
        trigger_flag.RegularExpression,
        trigger_flag.Replace,
        trigger_flag.KeepEvaluating),
      custom_colour.NoChange, COPY_WILDCARDS_NONE, SOUND_FILE_NONE, name, sendto.script, sequence))
    check(SetTriggerOption(name, "group", group))
    if stopEvaluation then
      check(SetTriggerOption(name, "keep_evaluating", false))
    end
  end

  helper.addOneShotTrigger = function(args)
    local regexp = assert(type(args.regexp) == "string" and args.regexp, "regexp in trigger must be string")
    local group = assert(args.group, "group in trigger cannot be empty")
    local response = assert(type(args.response) == "function" and args.response, "response in trigger must be function")
    local name = args.name or "auto_added_trigger_" .. GetUniqueID()
    local sequence = args.sequence or 10
    if type(response) == "function" then
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
        custom_colour.NoChange,
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
    -- print("remove trigger", name, retCode)
    assert(retCode == eOK or retCode == eTriggerNotFound)
  end

  helper.removeAllTriggers = function()
    local triggerList = GetTriggerList()
    if triggerList then
      for _, trigger in ipairs(triggerList) do
        helper.removeTrigger(trigger)
      end
    end
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

  local ALIAS_BASE_FLAG = alias_flag.Enabled + alias_flag.RegularExpression + alias_flag.Replace
  helper.addAlias = function(args)
    local regexp = assert(args.regexp, "regexp of alias cannot be empty")
    local response = assert(type(args.response) == "function" and args.response, "response of alias must be function")
    local group = assert(args.group, "group of alias cannot be empty")
    local name = args.name or "auto_added_alias_" .. GetUniqueID()

    _G.world[name] = helper.repeatedRunnableWithCo(response)
    _global_alias_callbacks[name] = true
    check(AddAlias(name, regexp, "", ALIAS_BASE_FLAG, name))
    check(SetAliasOption(name, "send_to", sendto.script))
    check(SetAliasOption(name, "group", group))
  end

  helper.removeAlias = function(name)
    if _global_alias_callbacks[name] then
      _global_alias_callbacks[name] = nil
      _G.world[name] = nil
    end
    local retCode = DeleteAlias(name)
    -- print("remove alias", name, retCode)
    assert(retCode == eOK or retCode == eAliasNotFound)
  end

  helper.removeAllAliases = function()
    local aliasList = GetAliasList()
    if aliasList then
      for i, alias in ipairs(aliasList) do
        helper.removeAlias(alias)
      end
    end
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

  helper.addTimer = function(args)
    local interval = assert(args.interval, "interval of timer cannot be nil")
    local response = assert(type(args.response) == "function" and args.response, "response of timer must be function")
    local group = assert(args.group, "group of timer cannot be nil")
    local name = args.name or "auto_added_timer_" .. GetUniqueID()
    _G.world[name] = helper.repeatedRunnableWithCo(response)
    _global_timer_callbacks[name] = true
    local hours = math.floor(interval / 3600)
    local minutes = math.floor((interval - hours * 3600) / 60)
    local seconds = interval - hours * 3600 - minutes * 60
    check(AddTimer(name, hours, minutes, seconds, "-- added by helper", 0, name))
    check(SetTimerOption(name, "send_to", "12"))
    check(SetTimerOption(name, "group", group))
  end

  helper.removeTimer = function(name)
    if _global_timer_callbacks[name] then
      _global_timer_callbacks[name] = nil
      _G.world[name] = nil
    end
    local retCode = DeleteTimer(name)
    assert(retCode == eOK or retCode == eTimerNotFound)
  end

  helper.removeTimerGroups = function(...)
    local groups = {}
    for _, group in ipairs({...}) do
      groups[group] = true
    end
    local timerList = GetTimerList()
    if timerList then
      for i, timer in ipairs(timerList) do
        local group = GetTimerInfo(timer, timer_info_flag.group)
        if groups[group] then
          helper.removeTimer(timer)
        end
      end
    end
  end

  helper.addOneShotTimer = function(args)
    local interval = assert(args.interval, "interval in timer cannot be nil")
    local group = assert(args.group, "group in timer cannot be empty")
    local response = assert(type(args.response) == "function" and args.response, "response in timer must be function")
    local name = args.name or "auto_added_timer_" .. GetUniqueID()
    _G.world[name] = helper.repeatedRunnableWithCo(response)
    _global_timer_callbacks[name] = true
    local hours = math.floor(interval / 3600)
    local minutes = math.floor((interval - hours * 3600) / 60)
    local seconds = interval - hours * 3600 - minutes * 60
    check(AddTimer(name, hours, minutes, seconds, "-- added by helper", bit.bor (0,
      timer_flag.Enabled,
      timer_flag.OneShot,
      trigger_flag.Temporary,
      timer_flag.Replace,
      timer_flag.Temporary), name))
    check(SetTimerOption(name, "send_to", "12"))
    check(SetTimerOption(name, "group", group))
  end

  helper.enableTimerGroups = function(...)
    for _, group in ipairs({...}) do
      EnableTimerGroup(group, true)
    end
  end

  helper.disableTimerGroups = function(...)
    for _, group in ipairs({...}) do
      EnableTimerGroup(group, false)
    end
  end

  helper.resumeCoRunnable = function(co)
    local co = co
    return function()
      local ok, err = coroutine.resume(co)
      if not ok then
        ColourNote ("deeppink", "black", "Error raised in timer function (in wait module).")
        ColourNote ("darkorange", "black", debug.traceback(co))
        error (err)
      end -- if
    end
  end

  helper.countElements = function(tb)
    local cnt = 0
    for _ in pairs(tb) do
      cnt = cnt + 1
    end
    return cnt
  end

  helper.convertAbbrNumber = function(abbr)
    local unit = string.sub(abbr, -1)
    if unit == "K" then
      local base = tonumber(string.sub(abbr, 1, -2))
      return base * 1000
    elseif unit == "M" then
      local base = tonumber(string.sub(abbr, 1, -2))
      return base * 1000000
    elseif unit == "B" then
      local base = tonumber(string.sub(abbr, 1, -2))
      return base * 1000000000
    else
      return tonumber(abbr)
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
      ["�������"] = true,
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

  -- ��֤��busy��������coroutine��
  helper.assureNotBusy = function()
    while true do
      SendNoEcho("halt")
      -- busy or wait for 3 seconds to resend
      local line = wait.regexp(REGEXP.NOT_BUSY, 3)
      if line then break end
    end
  end

  local jobs = {}
  -- �������񴥷�
  helper.initJobTriggers = function(args)
    local prefix = assert(type(args.prefix) == "string" and args.prefix, "prefix must be string")
    local acquire = assert(type(args.acquire) == "string" and args.acquire, "acquire must be function")
    local afterAcquire = assert(type(args.afterAcquire) == "function" and args.afterAcquire, "afterAcquire must be function")
    local submit = assert(type(args.submit) == "string" and args.submit, "submit must be string")
    local afterSubmit = assert(type(args.afterSubmit) == "function" and args.afterSubmit, "afterSubmit must be function")
    assert(jobs[prefix], "Cannot re-initialize job triggers")
    jobs[prefix] = {}
    local setAcquireStart = "set " .. prefix .. " acquire_start"
    local setAcquireDone = "set " .. prefix .. " acquire_done"
    local acquireAction = function()
      SendNoEcho(setAcquireStart)
      SendNoEcho(acquire)
      SendNoEcho(setAcquireDone)
    end
    jobs[prefix].acquire = acquireAction
    local setSubmitStart = "set " .. prefix .. " submit_start"
    local setSubmitDone = "set " .. prefix .. " submit_done"
    local submitAction = function()
      SendNoEcho(setSubmitStart)
      SendNoEcho(submit)
      SendNoEcho(setSubmitDone)
    end
    jobs[prefix].submit = submitAction
    local trigger_acq_start = prefix .. "_acquire_start"
    local trigger_acq_done = prefix .. "_acquire_done"
    local trigger_sub_start = prefix .. "_submit_start"
    local trigger_sub_done = prefix .. "_submit_done"
    helper.removeTriggerGroups(trigger_acq_start, trigger_acq_done, trigger_sub_start, trigger_sub_done)
    helper.addTrigger {
      group = trigger_acq_start,
      regexp = helper.settingRegexp(prefix, "acquire_start"),
      response = function()
        helper.enableTriggerGroups(trigger_acq_done)
      end
    }
    helper.addTrigger {
      group = trigger_acq_done,
      regexp = helper.settingRegexp(prefix, "acquire_done"),
      response = afterAcquire
    }
    helper.addTrigger {
      group = trigger_sub_start,
      regexp = helper.settingRegexp(prefix, "submit_start"),
      response = function()
        helper.enableTriggerGroups(trigger_sub_done)
      end
    }
    helper.addTrigger {
      group = trigger_sub_done,
      regexp = helper.settingRegexp(prefix, "submit_done"),
      response = afterSubmit
    }
  end

  helper.acquireJob = function(prefix)
    assert(jobs[prefix], "job trigger is not initialized by helper: " .. prefix)
    jobs[prefix].acquire()
  end

  helper.submitJob = function(prefix)
    assert(jobs[prefix], "job trigger is not initialized by helper: " .. prefix)
    job[prefix].submit()
  end

  -- ɾ�����д��������
  helper.removeAllTriggers()
  helper.removeAllAliases()

  return helper
end
return define_helper()
