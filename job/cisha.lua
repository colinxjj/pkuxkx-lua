--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/5/7
-- Time: 22:37
-- To change this template use File | Settings | File Templates.
--

local patterns = {[[
975

��֮��˵�����������˶����ӣ����ȵ�����С���Ⱥ����Ի�֪ͨ�㡣��

> ��֮���и������ڳ����͸�����һҳ���롣
��֮��(meng zhijing)�����㣺��һ�����ڣ��ڰ��У���ʮ�С��ڶ������ڣ���һ�У���ʮ�С����������ڣ��ھ��У������С�����(duizhao)��ҳ�����֪����Ҫ��ɱ���������ˡ�

duizhao
�㱳�����ˣ����ĵش��˾�ֽ��

��1 2 3 4 5 6 7 8 9 1011
1 �����帷˿���������հ�
2 ����ɽƽ��������կ����
3 ������������ɽ�˸���ɽ
4 �������������˿Դ����
5 ���и�����������Ŀ�ױ�
6 ���ٸ�ɽ��ԭ���󰲳���
7 ���ҺӸ�����ƽ�ٽ�Ȫׯ
8 ������������·��˿����
9 ��ɽ������Ŀɽ��Ľ�ɰ�

> �㶨��һ����������������Ҫ�ҵĺ�����������
����
    ��Ԫ �������ϳ�·������ʹ ������(Peng xiaoluan)

��Ԫ �������ϳ�·���ָ�ʹ �˽�(Gu jie)

�Ϲ���������Ķ����ˡ�

��ϲ��������˶�ͳ�Ƹ��д�����

]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local combat = require "pkuxkx.combat"

local define_cisha = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    wait = "wait",
    search = "search",
    kill = "kill",
    submit = "submit"
  }
  local Events = {
    STOP = "stop",
    START = "start",
    WAIT = "wait",
    ZONE_CONFIRMED = "zone_confirmed",
    KILL = "kill",
    KILLED = "killed",
  }
  local REGEXP = {
    ALIAS_START = "^cisha\\s+start\\s*$",
    ALIAS_STOP = "^cisha\\s+stop\\s*$",
    ALIAS_DEBUG = "^cisha\\s+debug\\s+(on|off)\\s*$",
    JOB_WAIT_LOCATION = "^[ >]*��֮��˵�����������˶����ӣ����ȵ�(.*?)�Ⱥ����Ի�֪ͨ�㡣��$",
    HINT = "^[ >]*��֮��\\(meng zhijing\\)�����㣺(.*)����\\(duizhao\\)��ҳ�����֪����Ҫ��ɱ���������ˡ�$",
    DUIZHAO_MAP = "^(\\d+) *(.+)$",
    FOUND = "^[ >]*�㶨��һ����(.*?)������Ҫ�ҵĺ�����������$",
    TITLE_NAME = "^[ >]*��Ԫ.*?(?:����|����)��ʹ *(.*?)\\((.*?)\\)$",
    FINISHED = "^[ >]*��ϲ��������˶�ͳ�Ƹ��д�����$",
  }
  local JobRoomId = 975

  function prototype:FSM()
    local obj = FSM:new()
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self:initStates()
    self:initTransitions()
    self:initTriggers()
    self:initAliases()
    self:setState(States.stop)
  end

  function prototype:disableAllTriggers()

  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
      end,
      exit = function() end
    }
    self:addState {
      state = States.ask,
      enter = function()
        helper.enableTriggerGroups("cisha_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("cisha_ask_start", "cisha_ask_done")
      end
    }
    self:addState {
      state = States.wait,
      enter = function()
        helper.enableTriggerGroups("cisha_wait", "cisha_duizhao_start")
      end,
      exit = function()
        helper.disableTriggerGroups("cisha_wait", "cisha_duizhao_start", "cisha_duizhao_end")
      end
    }
    self:addState {
      state = States.search,
      enter = function()
        helper.enableTriggerGroups("cisha_search")
      end,
      exit = function()
        helper.disableTriggerGroups("cisha_search")
      end
    }
    self:addState {
      state = States.kill,
      enter = function()
        helper.enableTriggerGroups("cisha_kill")
      end,
      exit = function()
        helper.disableTriggerGroups("cisha_kill")
      end
    }
    self:addState {
      state = States.submit,
      enter = function() end,
      exit = function() end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.ask,
      event = Events.START,
      action = function()
        return self:doGetJob()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<ask>
    self:addTransition {
      oldState = States.ask,
      newState = States.wait,
      event = Events.WAIT,
      action = function()
        assert(self.waitRoomId, "wait room id cannot be nil")
        return self:doWait()
      end
    }
    self:addTransitionToStop(States.ask)
    -- transition from state<wait>
    self:addTransition {
      oldState = States.wait,
      newState = States.search,
      event = Events.ZONE_CONFIRMED,
      action = function()
        assert(self.searchZone, "search zone cannot be nil")
        return self:doSearch()
      end
    }
    self:addTransitionToStop(States.wait)
    -- transition from state<search>
    self:addTransition {
      oldState = States.search,
      newState = States.kill,
      event = Events.KILL,
      action = function()
        return self:doKill()
      end
    }
    self:addTransitionToStop(States.search)
    -- transition from state<kill>
    self:addTransition {
      oldState = States.kill,
      newState = States.submit,
      event = Events.KILLED,
      action = function()
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.kill)
    -- transition from state<submit>
    self:addTransitionToStop(States.submit)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("cisha_ask_start", "cisha_ask_done")
    helper.addTriggerSettingsPair {
      group = "cisha",
      start = "ask_start",
      done = "ask_done"
    }
    helper.addTrigger {
      group = "cisha_ask_done",
      regexp = REGEXP.JOB_WAIT_LOCATION,
      response = function(name, line, wildcards)
        local rooms = travel:getMatchedRooms {
          name = wildcards[1],
          zone = "������"
        }
        if rooms and #rooms > 0 then
          self.waitRoomId = rooms[1].id
        end
      end
    }
    local addWordHint = function(name, line, wildcards)
      if not self.hint then
        self.hint = {}
      end
      table.insert(self.hint, {
        row = helper.ch2number(wildcards[1]),
        column = helper.ch2number(wildcards[2])
      })
    end
    helper.addTrigger {
      group = "cisha_wait",
      regexp = REGEXP.HINT,
      response = function(name, line, wildcards)
        self:debug("HINT triggered")
        local rawHint = wildcards[1]
        for _, c in ipairs({"һ", "��", "��", "��", "��"}) do
          local s, e, rowChr, columnChr = string.find(rawHint, "��" .. c .. "�����ڣ���(.-)�У���(.-)�С�")
          if rowChr and columnChr then
            if not self.hint then
              self.hint = {}
            end
            table.insert(self.hint, {
              row = helper.ch2number(rowChr),
              column = helper.ch2number(columnChr)
            })
          end
        end
      end
    }
    helper.addTriggerSettingsPair {
      group = "cisha",
      start = "duizhao_start",
      done = "duizhao_done"
    }
    helper.addTrigger {
      group = "cisha_duizhao_done",
      regexp = REGEXP.DUIZHAO_MAP,
      response = function(name, line, wildcards)
        local rowId = tonumber(wildcards[1])
        local text = wildcards[2]
        if not self.duizhaoMap then
          self.duizhaoMap = {}
        end
        self.duizhaoMap[rowId] = text
      end
    }
    helper.addTrigger {
      group = "cisha_search",
      regexp = REGEXP.FOUND,
      response = function(name, line, wildcards)
        self:debug("FOUND triggered")
        self.npcName = wildcards[1]
      end
    }
    helper.addTrigger {
      group = "cisha_search",
      regexp = REGEXP.TITLE_NAME,
      response = function(name, line, wildcards)
        self:debug("TITLE_NAME triggered")
        if self.npcName then
          if self.npcName == wildcards[1] then
            self.npcId = string.lower(wildcards[2])
            self:debug("����IDΪ��", self.npcId)
          end
        end
      end
    }
    helper.addTrigger {
      group = "cisha_kill",
      regexp = REGEXP.FINISHED,
      response = function()
        self.finished = true
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroup("cisha")
    helper.addAlias {
      group = "cisha",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "cisha",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "cisha",
      regexp = REGEXP.ALIAS_DEBUG,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self:debugOn()
        else
          self:debugOff()
        end
      end
    }
  end

  function prototype:addTransitionToStop(fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function()
        print("ֹͣ - ��ǰ״̬", self.currState)
      end
    }
  end

  function prototype:doGetJob()
    if self.currState ~= States.ask then
      return
    end
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    self:debug("�ȴ�1���ѯ������")
    wait.time(1)
    self.waitRoomId = nil
    self.workTooFast = false
    self.prevNotFinish = false
    SendNoEcho("set cisha ask_start")
    SendNoEcho("ask meng about job")
    SendNoEcho("set cisha ask_done")
    helper.checkUntilNotBusy()
    if self.prevNotFinish then
      ColourNote("yellow", "", "�ϴ�����δ��ɣ�ȡ�����ٽ���ѯ��")
      wait.time(1)
      SendNoEcho("ask meng about finish")
      SendNoEcho("ask meng about fail")
      wait.time(1)
      return self:doGetJob()
    elseif self.workTooFast then
      wait.time(5)
      return self:doGetJob()
    elseif not self.waitRoomId then
      ColourNote("�޷���ȡ���ȴ����䣬����ʧ��")
      return self:doCancel()
    else
      return self:fire(Events.WAIT)
    end
  end

  function prototype:doWait()
    travel:walkto(self.waitRoomId)
    travel:waitUntilArrived()
    SendNoEcho("yun recover")
    SendNoEcho("dazuo max")
    self.hint = nil
    local waitTime = 0
    while not self.hint do
      self:debug("�ȴ�������ʾ", waitTime)
      wait.time(5)
    end
    if self.DEBUG then
      print("�ѻ�ȡ��ʾ��Ϣ��")
      for i, h in ipairs(self.hint) do
        print("��" .. i .. "�֣�", "r" .. h.row, "c" .. h.column)
      end
    end
    wait.time(1)
    self.duizhaoMap = nil
    SendNoEcho("halt")
    SendNoEcho("set cisha duizhao_start")
    SendNoEcho("duizhao")
    SendNoEcho("set cisha duizhao_done")
    helper.checkUntilNotBusy()
    local zoneWords = {}
    for i, h in ipairs(self.hint) do
      local text = self.hint[h.row]
      local word = string.sub(text, h.column * 2 - 1, h.column * 2)
      table.insert(zoneWords, word)
    end
    local searchZoneName = table.concat(zoneWords, "")
    self:debug("������������Ϊ��", searchZoneName)
    self.searchZone = travel.zonesByName[searchZoneName]
    if not self.searchZone then
      ColourNote("red", "", "ָ���������򲻿ɴ����ʧ��")
      return self:doCancel()
    else
      return self:fire(Events.ZONE_CONFIRMED)
    end
  end

  function prototype:doSearch()
    self.npcName = nil
    self.npcId = nil

    -- ���ߵ����Ľڵ�Ȼ�����
    local centerCode = self.searchZone.centercode
    local centerId = travel.roomsByCode[centerCode]
    self:debug("ǰ�����������Ľڵ�������", centerId)
    travel:walkto(centerId)
    travel:waitUntilArrived()
    self:debug("�������Ľڵ�")

    self.npcFound = false
    if self.npcName then
      self:debug("�н�;���Ѿ����������ˣ��޸ı�������", self.npcName, self.npcId)
      helper.addOneShotTrigger {
        group = "cisha_one_shot",
        regexp = "^.*������ʹ " .. self.npcName .. "\\(.*\\)$",
        response = function()
          self.npcFound = true
        end
      }
    else
      self:debug("��δ�������ˣ�����Ѱ��")
      helper.addOneShotTrigger {
        group = "cisha_one_shot",
        regexp = REGEXP.FOUND,
        response = function()
          self.npcFound = true
        end
      }
    end
    local onStep = function()
      return self.npcFound
    end
    travel:traverseZone(self.searchZone.code, onStep)
    travel:waitUntilArrived()

    if self.npcFound then
      self:debug("�������ˣ�ɱ֮")
      return self:fire(Events.KILL)
    else
      self:debug("δ�������ˣ�����ʧ��")
      return self:doCancel()
    end
  end

  function prototype:doKill()
    self.finished = false
    combat:start()
    SendNoEcho("follow " .. self.npcId)
    SendNoEcho("yun powerup")
    SendNoEcho("killall " .. self.npcId)
    local waitTime = 0
    while not self.finished do
      self:debug("�ȴ����", waitTime)
      SendNoEcho("killall " .. self.npcId)
      wait.time(5)
    end
    SendNoEcho("follow none")
    SendNoEcho("halt")
    combat:stop()
    return self:fire(Events.KILLED)
  end

  function prototype:doSubmit()
    travel:stop()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    self:debug("�ȵ�1����ύ")
    wait.time(1)
    SendNoEcho("ask meng about finish")
    helper.checkUntilNotBusy()
    return self:fire(Events.STOP)
  end

  function prototype:doCancel()
--    travel:walkto(JobRoomId)
--    travel:waitUntilArrived()
--    wait.time(1)
--    SendNoEcho("ask meng about fail")
--
    ColourNote("red", "", "�ֶ�����ȡ��")
  end

  return prototype
end
return define_cisha():FSM()
