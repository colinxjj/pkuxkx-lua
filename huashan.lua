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
    {path="n",name="���䳡"},
    {path="n",name="��Ů��"},
    {path="e",name="��Ů��"},
    {path="sd",name="��ɽС·"},
    {path="sd",name="��ɽС·"},
    {path="sd",name="СԺ"},
    {path="nu",name="��ɽС·"},
    {path="nu",name="��ɽС·"},
    {path="nu",name="��Ů��"},
    {path="w",name="��Ů��"},
    {path="nd",name="������"},
    {path="eu",name="������"},
    {path="wd",name="������"},
    {path="nu",name="������"},
    {path="wu",name="������"},
    {path="ed",name="������"},
    {path="nd",name="�����"},
    {path="nd",name="�Ͼ���"},
    {path="nu",name="��ɽ��Ժ"},
    {path="sd",name="�Ͼ���"},
    {path="wd",name="�ٳ�Ͽ"},
    {path="nd",name="ǧ�ߴ�"},
    {path="wd",name="���ƺ"},
    {path="nd",name="ɯ��ƺ"},
    {path="nw",name="��ɽ����"},
    {path="n",name="��ȪԺ"}}
  patrol._rooms = {
    ["���䳡"] = 1,
    ["��Ů��"] = 1,
    ["��Ů��"] = 1,
    ["��ɽС·"] = 2,
    ["СԺ"] = 1,
    ["������"] = 1,
    ["������"] = 1,
    ["������"] = 1,
    ["������"] = 1,
    ["�����"] = 1,
    ["�Ͼ���"] = 1,
    ["��ɽ��Ժ"] = 1,
    ["�ٳ�Ͽ"] = 1,
    ["ǧ�ߴ�"] = 1,
    ["���ƺ"] = 1,
    ["ɯ��ƺ"] = 1,
    ["��ɽ����"] = 1,
    ["��ȪԺ"] = 1
  }
  patrol._delay = 1
  patrol.regexp = {
    ASK_JOB="^[ >]*��������ɺ�����йء�job������Ϣ��$",
    GOT_JOB="^[ >]*����ɺ�ó�һ�ŵ�ͼ���ѻ�ɽ��ҪѲ�ߵ������ò�ͬ��ɫ��ע������������˵��һ�顣$",
    PATROLLING="^[ >]*����(\w+)Ѳ߮����δ���ֵ��١�$",
    GO="^[ >]*�趨����������huashan_patrol = \"go\"",
    POTENTIAL_ROOM="^[ >]*([^ ]+)$",
    REJECT_LING="^[ >]*����ɺ����Ҫ���ƣ�����Ը����Űɡ�",
    ACCEPT_LING="^[ >]*�������ɺһ�����ơ�$"
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
          print("Ӧ���ѵ�����ȪԺ����������ɺ��")
          goli2yue()
          -- ��鷿��
          local miss = false
          for room, remainCnt in pairs(P.rooms) do
            if remainCnt ~= 0 then
              print("�з�����©δѲ�ߵ���", room, remainCnt)
              miss = true
            end
          end
          if miss then
            print("��������Ѳ��")
          else
            print("�����ύ����")
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
        print("������ɣ�")
      end,
      group = "huashan_patrol_finish"
    }
    helper.addTrigger {
      regexp = patrol.regexp.REJECT_LING,
      response = function()
        check(EnableTriggerGroup("huashan_patrol_finish", false))
        print("����δ��ɣ����ֶ����")
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
--  local info1 = "^[ >]*����(\w+)Ѳ߮����δ���ֵ��١�$"
--  local answer2 = "�������ɺһ�����ơ�"
--  local answer3 = "����ɺ����Ҫ���ƣ�����Ը����Űɡ�"
--  local info2 = "��Ƥһ����ס�㣺Ҫ��Ӵ˹���������·�ƣ���Ƥһ����ס���㡣"
end
huashan.patrol = define_patrol()
huashan.patrol.init()

return huashan


