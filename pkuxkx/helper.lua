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
    NOT_BUSY = "^[ >]*你现在不忙。$",
    SETTING = "^[ >]*设定环境变量：__SETTING_NAME__ = \"__SETTING_VALUE__\"$",
  }

  helper.settingRegexp = function(name, value)
    return string.gsub(string.gsub(REGEXP.SETTING, "__SETTING_NAME__", name), "__SETTING_VALUE__", value)
  end

  -- 方向简称列表
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

  -- 保证不busy，必须在coroutine中
  helper.assureNotBusy = function()
    while true do
      SendNoEcho("halt")
      -- busy or wait for 3 seconds to resend
      local line = wait.regexp(REGEXP.NOT_BUSY, 3)
      if line then break end
    end
  end

  local jobs = {}
  -- 辅助任务触发
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

  -- 删除所有触发与别名
  helper.removeAllTriggers()
  helper.removeAllAliases()

  return helper
end
return define_helper()
