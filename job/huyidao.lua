--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/5/7
-- Time: 21:40
-- To change this template use File | Settings | File Templates.
--

local patterns = {[[
38

ask hu about job
�����һ�������йء�job������Ϣ��
��һ��˵���������յ���Ϣ����˵�ƺ��ϰ��е�����Ϳ���̲�(ansunk)�ҵ��˴������صĵ�ͼ,��ɷ��æ�һ�������
��һ������˵������ǰ·���У�������أ���

> ����ܿ����㣬��Цһ����������·�㲻�ߣ�������������Ͷ��
�������������ɱ���㣡

    �� �� �� �������������(Phidass)

�����˵������������ȥ���������ֵ������(fonk)��������ұ���ģ���


���ڹ����в��ϻ���ơ�(���ƣ�12%)
κ�˴�˵������������ȥ�ٰ��������ֵܶ�����(ladubk)��������ұ���ģ���



-- ģʽ��

ask sui cong about �ر�ͼ
������������йء��ر�ͼ������Ϣ��
�ҷ��ָ�����С�����������һ������ˣ����������Ͽ��ܻ�������������ʹ����ȥ��
�ּ�С�� -

    һ�������Ĳݵ�С����ǰ���ƺ�ͨ����һƬС���֣�
    �����ġ�: һ�ֻ���Ϧ�����ǻ��������ĵ�ƽ���ϡ�

    ����Ψһ�ĳ����� east��

������ -

    ϡϡ����ó����Ϸ�������������С��ľ��ïʢ��é�ݴ����һ���˶�ߣ�
�����ƺ�Σ���������ҪС���ˡ�
    �����ġ�: һ�ֻ���Ϧ�����ǻ��������ĵ�ƽ���ϡ�

    �������Եĳ����� northeast �� west��
get map from corpse
��ӱ��ܵ�ʬ�������ѳ�һƬ���ص�ͼ��Ƭ��
]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local combat = require "pkuxkx.combat"
local captcha = require "pkuxkx.captcha"

local define_huyidao = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    search = "search",
    kill = "kill",
    submit = "submit",
  }
  local Events = {
    STOP = "stop",  -- any state -> stop
    START = "start",  -- stop -> ask
    SEARCH = "search", -- ask -> search
    KILL = "kill",  -- search -> kill
    KILLED = "killed", -- kill -> search
    FINISHED = "finished",  -- kill -> submit
    FAILED = "failed",  -- search, kill -> submit
  }
  local REGEXP = {
    ALIAS_START = "^huyidao\\s+start\\s*$",
    ALIAS_STOP = "^huyidao\\s+stop\\s*$",
    ALIAS_DEBUG = "^huyidao\\s+debug\\s+(on|off)\\s*$",
    ALIAS_SEARCH = "^huyidao\\s+search\\s+(.*?)\\s+(.*?)\\s*$",
    ALIAS_XUNBAO = "^huyidao\\s+xunbao\\s+(.*?)\\s*$",
    ALIAS_MANUAL = "^^huyidao\\s+manual\\s+(on|off)\s*$",
    JOB_INFO = "^[ >]*��һ��˵���������յ���Ϣ����˵(.*?)�е�����(.*?)\\((.*?)\\)�ҵ��˴������صĵ�ͼ,��ɷ��æ�һ�������$",
    MAP_COUNT = "^\\( *(\\d+)\\) *���ص�ͼ��Ƭ\\(Map piece\\d+\\)$",
    GIVEN = "^[ >]*�����һ��һ.*$",
    CAPTCHA = "^��ù��ڵ����˵���Ϣ��$",
  }

  local JobRoomId = 38
  local ExcludedZones = {
    ["����÷ׯ"] = true,
    ["����ɽ"] = true,
    ["����"] = true,
    ["�Ͻ���"] = true,
  }

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

    self:resetOnStop()
    self.DEBUG = true
  end

  function prototype:resetOnStop()
    self.dbrs = {}
  end

  function prototype:disableAllTriggers()

  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:resetOnStop()
        self:removeTriggerGroups("huyidao_one_shot")
        self:disableAllTriggers()
      end,
      exit = function() end
    }
    self:addState {
      state = States.ask,
      enter = function()
        helper.enableTriggerGroups("huyidao_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("huyidao_ask_start", "huyidao_ask_done")
      end
    }
    self:addState {
      state = States.search,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.kill,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.submit,
      enter = function()
        helper.enableTriggerGroups("huyidao_map_start", "huyidao_give_start")
      end,
      exit = function()
        helper.disableTriggerGroups("huyidao_map_start", "huyidao_map_done",
          "huyidao_give_start", "huyidao_give_done")
      end
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
      newState = States.search,
      event = Events.SEARCH,
      action = function()
        return self:doSearch()
      end
    }
    self:addTransitionToStop(States.ask)
    -- transition from state<search>
    self:addTransition {
      oldState = States.search,
      newState = States.kill,
      event = Events.KILL,
      action = function()
        return self:doKill()
      end
    }
    self:addTransition {
      oldState = States.search,
      newState = States.submit,
      event = Events.FAILED,
      action = function()
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.search)
    -- transition from state<kill>
    self:addTransition {
      oldState = States.kill,
      newState = States.search,
      event = Events.KILLED,
      action = function()
        return self:doSearch()
      end
    }
    self:addTransition {
      oldState = States.kill,
      newState = States.submit,
      event = Events.FINISHED,
      action = function()
        return self:doSubmit()
      end
    }
    self:addTransition {
      oldState = States.kill,
      newState = States.submit,
      event = Events.FAILED,
      action = function()
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.kill)
    -- transition from state<submit>
    self:addTransitionToStop(States.submit)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "huyidao_ask_start", "huyidao_ask_done",
      "huyidao_map_start", "huyidao_map_done",
      "huyidao_give_start", "huyidao_give_done")
    helper.addTriggerSettingsPair {
      group = "huyidao",
      start = "ask_start",
      done = "ask_done",
    }
    helper.addTrigger {
      group = "huyidao_ask_done",
      regexp = REGEXP.JOB_INFO,
      response = function(name, line, wildcards)
        self:debug("JOB_INFO triggered")
        self.searchZoneName = wildcards[1]
        self.npcName = wildcards[2]
        self.npcId = string.lower(wildcards[3])
      end
    }
    helper.addTrigger {
      group = "huyidao_ask_done",
      regexp = REGEXP.CAPTCHA,
      response = function()
        self:debug("CAPTCHA triggered")
        self.needCaptcha = true
      end
    }
    helper.addTriggerSettingsPair {
      group = "huyidao",
      start = "map_start",
      done = "map_done",
    }
    helper.addTrigger {
      group = "huyidao_map_done",
      regexp = REGEXP.MAP_COUNT,
      response = function(name, line, wildcards)
        self:debug("MAP_CNT triggered")
        local cnt = tonumber(wildcards[1])
        if self.mapCnt < cnt then
          self.mapCnt = cnt
        end
      end
    }
    helper.addTriggerSettingsPair {
      group = "huyidao",
      start = "give_start",
      done = "give_done",
    }
    helper.addTrigger {
      group = "huyidao_give_done",
      regexp = REGEXP.GIVEN,
      response = function()
        self.giveSuccess = true
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("huyidao")
    helper.addAlias {
      group = "huyidao",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "huyidao",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "huyidao",
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
    helper.addAlias {
      group = "huyidao",
      regexp = REGEXP.ALIAS_SEARCH,
      response = function(name, line, wildcards)
        self.npcName = wildcards[1]
        self.searchZoneName = wildcards[2]
      end
    }
    helper.addAlias {
      group = "huyidao",
      regexp = REGEXP.ALIAS_XUNBAO,
      response = function(name, line, wildcards)
        travel:walktoFirst {
          fullname = wildcards[1]
        }
        travel:waitUntilArrived()
        wait.time(1)
        SendNoEcho("xunbao")
      end
    }
    helper.addAlias {
      group = "huyidao",
      regexp = REGEXP.ALIAS_MANUAL,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self.manual = true
        else
          self.manual = false
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
    self.searchZoneName = nil
    self.npcName = nil
    self.npcId = nil
    self.workTooFast = false
    self.prevNotFinish = false
    self.needCaptcha = false
    SendNoEcho("set huyidao ask_start")
    SendNoEcho("ask hu about job")
    SendNoEcho("set huyidao ask_done")
    helper.checkUntilNotBusy()
    if self.prevNotFinish then
      ColourNote("yellow", "", "�ϴ�����δ��ɣ�ȡ�����ٽ���ѯ��")
      wait.time(1)
      SendNoEcho("ask hu about fail")
      wait.time(1)
      return self:doGetJob()
    elseif self.workTooFast then
      wait.time(5)
      return self:doGetJob()
    elseif self.needCaptcha then
      ColourNote("yellow", "", "�������֤���ֶ�����huyidao search <����> <�ص�>")
    elseif not self.searchZoneName then
      ColourNote("red", "", "�޷���ȡ��������Ϣ������ʧ��")
      return self:doCancel()
    elseif ExcludedZones[self.searchZoneName] then
      return self:doAskHelp()
    else
      assert(self.npcName, "npc name cannot be nil")
      return self:fire(Events.SEARCH)
    end
  end

  function prototype:doAskHelp()
    self.searchZoneName = nil
    self.npcName = nil
    self.npcId = nil
    SendNoEcho("set huyidao ask_start")
    SendNoEcho("ask hu about help")
    SendNoEcho("set huyidao ask_done")
    helper.checkUntilNotBusy()
    if not self.searchZoneName then
      ColourNote("red", "", "�޷���ȡ��������Ϣ������ʧ��")
      return self:doCancel()
    else
      return self:fire(Events.SEARCH)
    end
  end
  
  function prototype:doSearch()
    assert(self.npcName, "npc name cannot be nil")
    local zone = travel:getMatchedZone(self.searchZoneName)
    if ExcludedZones[self.searchZoneName] or not zone then
      ColourNote("red", "", "�������򲻿ɴ����ʧ��")
      return self:fire(Events.FAILED)
    end
    local centerRoomCode = zone.centercode
    local centerRoom = travel.roomsByCode[centerRoomCode]
    self:debug("���������Ľڵ�������", centerRoom.id)
    travel:walkto(centerRoom.id)
    travel:waitUntilArrived()
    self:debug("����Ѱ������", self.npcName, self.npcId)
    self.npcFound = false

    helper.addOneShotTrigger {
      group = "huyidao_one_shot",
      regexp = "^ *�� �� ��.*?" .. self.npcName .. "\\((.*?)\\)$",
      response = function(name, line, wildcards)
        self:debug("DBR_FOUND triggered")
        -- ��ͬģʽ���ܴ���npcIdδ֪����˸���npcId
        self.npcId = string.lower(wildcards[1])
        self.npcFound = true
      end
    }
    local onStep = function()
      return self.npcFound
    end
    SendNoEcho("yun powerup")
    travel:traverseZone(zone.code, onStep)
    travel:waitUntilArrived()
    if self.npcFound then
      return self:fire(Events.KILL)
    else
      ColourNote("yellow", "", "δ�������ˣ�����ʧ�ܣ�������е�ͼ��Ƭ������")
      return self:fire(Events.FAILED)
    end
  end

  function prototype:doKill()
    self.npcKilled = false
    self.jobFinished = false

    helper.addOneShotTrigger {
      group  = "huyidao_one_shot",
      regexp = "^[ >]*" .. self.npcName .. "˵������������ȥ(.*?)�����ֵ�(.*?)\\((.*?)\\)��������ұ���ģ���$",
      response = function(name, line, wildcards)
        if not self.dbrs then
          self.dbrs = {}
        end
        table.insert(self.dbrs, {
          name = self.npcName,
          id = self.npcId,
          zone = self.searchZoneName
        })
        self.searchZoneName = wildcards[1]
        self.npcName = wildcards[2]
        self.npcId = string.lower(wildcards[3])
        self.npcKilled = true
      end
    }
    helper.addOneShotTrigger {
      group = "huyidao_one_shot",
      regexp = "^[ >]*" .. self.npcName .. "��̾���������㲻�����㣬�벻�����ֵ����˶�����������У���$",
      response = function()
        table.insert(self.dbrs, {
          name = self.npcName,
          id = self.npcId,
          zone = self.searchZoneName
        })
        self.npcKilled = true
        self.jobFinished = true
      end
    }

    combat:start()
    SendNoEcho("halt")
    SendNoEcho("yun recover")
    SendNoEcho("yun powerup")
    SendNoEcho("wield sword")
    SendNoEcho("killall " .. self.npcId)
    SendNoEcho("perform dugu-jiujian.poqi")
    -- �޶�60����ս��
    local waitTime = 0
    while not self.npcKilled and waitTime < 60 do
      self:debug("ս��ʱ����", waitTime)
      wait.time(5)
      waitTime = waitTime + 5
    end
    self:debug("ս��ʱ����", waitTime)
    helper.removeTriggerGroups("huyidao_one_shot")
    if self.jobFinished then
      if self.DEBUG then
        print("�������ѱ�ȫ��ɱ����")
        for i, npc in ipairs(self.dbrs) do
          print("������" .. i, npc.name, npc.id, npc.zone)
        end
      end
      combat:stop()
      return self:fire(Events.FINISHED)
    elseif self.npcKilled then
      combat:stop()
      return self:fire(Events.KILLED)
    else
      combat:stop()
      self:debug("ս��ʱ�����������ʧ��")
      return self:fire(Events.FAILED)
    end
  end

  function prototype:doSubmit()
    self.mapCnt = 0

    helper.checkUntilNotBusy()
    SendNoEcho("halt")
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    wait.time(1)
    SendNoEcho("set huyidao map_start")
    SendNoEcho("i map piece")
    SendNoEcho("set huyidao map_done")
    helper.checkUntilNotBusy()
    if self.mapCnt == 0 then
      self:debug("һ���ͼ��Ƭ��û���ҵ������񳹵�ʧ��")
      SendNoEcho("ask hu about fail")
      helper.checkUntilNotBusy()
      return self:fire(Events.STOP)
    elseif self.mapCnt < 5 then
      self:debug("��������5���ͼ��Ƭ�����񲿷����")
      for i = 1, self.mapCnt do
        while true do
          self.giveSuccess = false
          SendNoEcho("set huyidao give_start")
          SendNoEcho("give map to hu")
          SendNoEcho("set huyidao give_done")
          helper.checkUntilNotBusy()
          if self.giveSuccess then
            break
          else
            wait.time(1)
          end
        end
        wait.time(1)
      end
      return self:fire(Events.STOP)
    else
      self:debug("��ͼ��������룬ֱ�Ӻϲ�")
      SendNoEcho("combine map")
      helper.checkUntilNotBusy()
      while true do
        self.giveSuccess = false
        SendNoEcho("set huyidao give_start")
        SendNoEcho("give cangbao tu to hu")
        SendNoEcho("set huyidao give_done")
        helper.checkUntilNotBusy()
        if self.giveSuccess then
          break
        else
          wait.time(1)
        end
      end
      ColourNote("yellow", "", "ʹ��chakan bao tu��ȡ�ر��ص㣬Ѱ����ʹ��huyidao xunbao <�ص�>")
      return self:fire(Events.STOP)
    end
  end

  -- ����ѯ��ʧ��ʱִ��
  function prototype:doCancel()
    if self.manual then
      ColourNote("red", "", "���ֶ�ȡ������")
    else
      travel:walkto(JobRoomId)
      wait.time(1)
      SendNoEcho("ask hu about fail")
      wait.time(1)
      helper.checkUntilNotBusy()
      return self:fire(Events.STOP)
    end
  end

  return prototype
end
return define_huyidao():FSM()
