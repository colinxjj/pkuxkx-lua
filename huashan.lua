--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/7
-- Time: 19:59
-- To change this template use File | Settings | File Templates.
--

require "wait"

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
      check(AddTriggerEx(name, regexp, "", TRIGGER_BASE_FLAG, custom_colour.NoChange, COPY_WILDCARDS_NONE, SOUND_FILE_NONE, response, sendto.world, sequence))
    elseif type(response) == "function" then
      _G[name] = response
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
      _G[name] = nil
    end
    check(DeleteTrigger(name))
  end

  local _global_alias_callbacks = {}
  local ALIAS_BASE_FLAG = alias_flag.Enabled + alias_flag.RegularExpression + alias_flag.Replace
  helper.addAlias = function(args)
    local regexp = assert(args.regexp, "regexp of alias cannot be empty")
    local response = assert(args.response, "response of alias cannot be empty")
    local group = assert(args.group, "group of alias cannot be empty")
    local name = args.name or "auto_added_alias_" .. GetUniqueID()
    if type(response) == "function" then
      _G[name] = response
      _global_alias_callbacks[name] = true
      check(AddAlias(name, regexp, name, ALIAS_BASE_FLAG, ""))
      check(SetAliasOption(name, "send_to", sendto.script))
      check(SetAliasOption(name, "group", group))
    end
  end

  helper.removeAlias = function(name)
    if _global_alias_callbacks[name] then
      _global_alias_callbacks[name] = nil
      _G[name] = nil
    end
    check(DeleteAlias(name))
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

local huashan = {}

huashan.li2yue = {"s", "se", "su", "eu", "su", "eu", "su", "su", "sd", "su", "s", "s" }
huashan.yue2li = {"n", "n", "nd", "nu", "nd", "nd", "wd", "nd", "wd", "nd", "nw", "n"}

local define_patrol = function()
  local patrol = {}
  patrol.__index = patrol
  patrol._paths = {
    {path="n",name="练武场"},
    {path="n",name="玉女峰"},
    {path="e",name="玉女祠"},
    {path="sd",name="后山小路"},
    {path="sd",name="后山小路"},
    {path="sd",name="小院"},
    {path="nu",name="后山小路"},
    {path="nu",name="后山小路"},
    {path="nu",name="玉女祠"},
    {path="w",name="玉女峰"},
    {path="nd",name="镇岳宫"},
    {path="eu",name="朝阳峰"},
    {path="wd",name="镇岳宫"},
    {path="nu",name="苍龙岭"},
    {path="wu",name="舍身崖"},
    {path="ed",name="苍龙岭"},
    {path="nd",name="猢狲愁"},
    {path="nd",name="老君沟"},
    {path="nu",name="华山别院"},
    {path="sd",name="老君沟"},
    {path="wd",name="百尺峡"},
    {path="nd",name="千尺幢"},
    {path="wd",name="青柯坪"},
    {path="nd",name="莎萝坪"},
    {path="nw",name="华山脚下"},
    {path="n",name="玉泉院"}}
  patrol._rooms = {
    ["练武场"] = 1,
    ["玉女峰"] = 1,
    ["玉女祠"] = 1,
    ["后山小路"] = 2,
    ["小院"] = 1,
    ["镇岳宫"] = 1,
    ["朝阳峰"] = 1,
    ["苍龙岭"] = 1,
    ["舍身崖"] = 1,
    ["猢狲愁"] = 1,
    ["老君沟"] = 1,
    ["华山别院"] = 1,
    ["百尺峡"] = 1,
    ["千尺幢"] = 1,
    ["青柯坪"] = 1,
    ["莎萝坪"] = 1,
    ["华山脚下"] = 1,
    ["玉泉院"] = 1
  }
  patrol._delay = 1
  patrol.regexp = {
    ASK_JOB="^[ >]*你向岳灵珊打听有关『job』的消息。$",
    GOT_JOB="^[ >]*岳灵珊拿出一张地图，把华山需要巡逻的区域用不同颜色标注出来，并和你说了一遍。$",
    PATROLLING="^[ >]*你在(\w+)巡弋，尚未发现敌踪。$",
    GO="^[ >]*设定环境变量：huashan_patrol = \"go\"",
    POTENTIAL_ROOM="^[ >]*([^ ]+)$",
    REJECT_LING="^[ >]*岳灵珊不想要令牌，你就自个留着吧。",
    ACCEPT_LING="^[ >]*你给岳灵珊一块令牌。$"
  }
  patrol.currRoom = nil

  local goli2yue = function()
    for i = 1,#(huashan.li2yue) do
      check(SendNoEcho(huashan.li2yue[i]))
    end
  end

  local goyue2li = function()
    for i = 1,#(huashan.yue2li) do
      check(SendNoEcho(huashan.yue2li[i]))
    end
  end

  function patrol:new()
    local obj = {}
    setmetatable(obj, self)
    -- copy rooms
    obj.rooms = {}
    for k, v in pairs(patrol.rooms) do
      obj.rooms[k] = v
    end
    -- copy and reverse paths
    obj.paths = {}
    for i = #(patrol._paths),1,-1 do
      table.insert(obj.paths, patrol._paths[i])
    end
    obj.delay = patrol._delay
    return obj
  end

  function patrol.start()
    check(EnableTriggerGroup("huashan_patrol", true))
    SendNoEcho("ask yue about job")
  end

  function patrol.init()
    local triggerList = GetTriggerList()
    if triggerList then
      for i, trigger in ipairs(triggerList) do
        local groupName = GetTriggerInfo(trigger, 26) -- group name
        if groupName == "huashan_patrol"
          or groupName == "huashan_patrol_ask"
          or groupName == "huashan_patrol_move"
          or groupName == "huashan_patrol_finish" then
          check(helper.removeTrigger(trigger))
        end
      end
    end
    helper.addTrigger {
      regexp = patrol.regexp.ASK_JOB,
      response = function() check(EnableTriggerGroup("huashan_patrol_ask", true)) end,
      group = "huashan_patrol"
    }
    helper.addTrigger {
      regexp = patrol.regexp.POTENTIAL_ROOM,
      response = function(name, line, wildcards)
        local potentialRoom = wildcards[1]
        if string.len(potentialRoom) < 14 then
          if patrol._rooms[potentialRoom] then
            patrol.currRoom = potentialRoom
          end
        end
      end,
      group = "huashan_patrol_move"
    }
    helper.addTrigger {
      regexp = patrol.regexp.GOT_JOB,
      response = function()
        check(EnableTriggerGroup("huashan_patrol_ask", false))
        print("start patrol job")
        SendNoEcho("set brief 1")
        local co = coroutine.create(function()
          local P = patrol:new()
          while #(P.paths) > 0 do
            local next = table.remove(P.paths)
            local retries = 0
            repeat
              -- do not busy retry
              if retries > 0 then
                wait.time(1)
              end
              patrol.currRoom = nil
              check(EnableTriggerGroup("huashan_patrol_move", true))
              SendNoEcho(next.path)
              SendNoEcho("set huashan_patrol go")
              wait.regexp(patrol.regexp.GO)
              check(EnableTriggerGroup("huashan_patrol_move", false))
              retries = retries + 1
            until patrol.currRoom ~= nil and patrol.currRoom == next.name

            -- first time reach this room, we need to wait until the notion of patrol occurs
            if P.rooms[next.name] and P.rooms[next.name] > 0 then
              local line, wildcards = wait.regexp(patrol.regexp.PATROLLING, 10)
              local currRoom = wildcards[1]
              if P.rooms[currRoom] and P.rooms[currRoom] > 0 then
                P.rooms[currRoom] = P.rooms[currRoom] - 1
              end
            end
            wait.time(P.delay)
          end
          print("应当已到达玉泉院，返回岳灵珊处")
          goli2yue()
          -- 检查房间
          local miss = false
          for room, remainCnt in pairs(P.rooms) do
            if remainCnt ~= 0 then
              print("有房间遗漏未巡逻到：", room, remainCnt)
              miss = true
            end
          end
          if miss then
            print("尝试重新巡逻")
          else
            print("尝试提交任务")
            check(EnableTriggerGroup("huashan_patrol_finish", true))
            SendNoEcho("give yue ling")
          end
        end)
        coroutine.resume(co)
      end,
      group = "huashan_patrol_ask"
    }
    helper.addTrigger {
      regexp = patrol.regexp.ACCEPT_LING,
      response = function()
        check(EnableTriggerGroup("huashan_patrol_finish", false))
        print("任务完成！")
      end,
      group = "huashan_patrol_finish"
    }
    helper.addTrigger {
      regexp = patrol.regexp.REJECT_LING,
      response = function()
        check(EnableTriggerGroup("huashan_patrol_finish", false))
        print("任务未完成！请手动完成")
      end,
      group = "huashan_patrol_finish"
    }

    local aliasList = GetAliasList()
    if aliasList then
      for i, alias in ipairs(aliasList) do
        local groupName = GetAliasInfo(alias, 16) -- group name
        if groupName == "huashan_patrol" then
          check(helper.removeAlias(alias))
        end
      end
    end
    helper.addAlias {
      regexp = "^startpatrol$",
      response = patrol.start,
      group = "huashan_patrol"
    }
    helper.addAlias {
      regexp = "^li2yue$",
      response = goli2yue,
      group = "huashan_patrol"
    }
    helper.addAlias {
      regexp = "^yue2li$",
      response = goyue2li,
      group = "huashan_patrol"
    }
  end
  return patrol
--  local info1 = "^[ >]*你在(\w+)巡弋，尚未发现敌踪。$"
--  local answer2 = "你给岳灵珊一块令牌。"
--  local answer3 = "岳灵珊不想要令牌，你就自个留着吧。"
--  local info2 = "泼皮一把拦住你：要向从此过，留下买路财！泼皮一把拉住了你。"
end
huashan.patrol = define_patrol()
huashan.patrol.init()

return huashan


