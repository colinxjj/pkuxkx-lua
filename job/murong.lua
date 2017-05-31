--
-- murong.lua
-- User: zhe.jiang
-- Date: 2017/4/20
-- Desc:
-- Change:
-- 2017/4/20 - created

local patterns = {[[
]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local combat = require "pkuxkx.combat"

local define_murong = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    search = "search",
    kill = "kill",
    submit = "submit",
  }
  local Events = {
    STOP = "stop",  -- any status -> stop
    START = "start",  -- stop -> ask
    NEW_JOB = "new_job",  -- ask -> search
    NEW_JOB_CAPTCHA = "new_job_captcha",
    GARBAGE = "^[ >]*������.*��(ʯ̿|����)��.*?����$",
    NEXT_SEARCH = "next_search",  -- search -> search
    JIAZEI_FOUND = "jiazei_found",  -- search -> kill
    JIAZEI_MISS = "jiazei_miss", -- kill -> search
    JIAZEI_KILLED = "jiazei_killed", -- kill -> submit
    PU_BUSY = "pu_busy",  -- submit -> submit
  }
  local REGEXP = {
    ALIAS_START = "^murong\\s+start\\s*$",
    ALIAS_STOP = "^murong\\s+stop\\s*$",
    ALIAS_DEBUG = "^murong\\s+debug\\s+(on|off)\\s*$",
    ALIAS_SEARCH = "^murong\\s+search\\s+(.*?)\\s*$",
    CAPTCHA_LINK = "^(http://pkuxkx.net/antirobot.*)$",
    JOB_INFO = "^[ >]*����̾���������ѷ�������͵������ү���ż����ݴ����ڡ�(.*?)���������֣���ȥ�����һ�����.*$",
    WORK_TOO_FAST = "^[ >]*���˶�����ҡ��ҡͷ˵����(�������������ȥ��Ϣ��Ϣ�ɡ�|������ʧ�ܴ������࣬��ȥ��Ϣ��Ϣ�ɡ�)��$",
    JIAZEI_DESC = "^\\s*(.*?)���ֵ� Ľ�������ڹ�\\((.*)\\).*$",
    JIAZEI_KILLED = "^[ >]*Ľ�������ڹ����ˡ�$",
    JIAZEI_MISSED = "^[ >]*����ɱ˭��$",
    PU_BUSY = "^[ >]*����æ���أ��Ȼ�ɡ�$",
  }

  local JobRoomId = 479

  function prototype:FSM()
    local obj = FSM:new()
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  local SearchDepth = 5

  function prototype:postConstruct()
    self:initStates()
    self:initTransitions()
    self:initTriggers()
    self:initAliases()
    self:initTimers()
    self:setState(States.stop)
    self.precondition = {
      jing = 1,
      qi = 1,
      neili = 1.6,
      jingli = 1
    }

    self.myName = "ߣ��"
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups("murong_ask_start", "murong_ask_done", "murong_search")
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
        SendNoEcho("set jobs job_done")  -- jobs���
      end,
      exit = function() end
    }
    self:addState {
      state = States.ask,
      enter = function()
        helper.enableTriggerGroups("murong_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("murong_ask_start", "murong_ask_done")
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
      exit = function()
        helper.disableTriggerGroups("murong_kill")
        helper.disableTimerGroups("murong_kill")
      end
    }
    self:addState {
      state = States.submit,
      enter = function()
        helper.enableTriggerGroups("murong_submit_start")
      end,
      exit = function()
        helper.disableTriggerGroups("murong_submit_start", "murong_submit_done")
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
        return self:doAsk()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<ask>
    self:addTransition {
      oldState = States.ask,
      newState = States.search,
      event = Events.NEW_JOB,
      action = function()
        return self:doPrepareSearch()
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.search,
      event = Events.NEW_JOB_CAPTCHA,
      action = function()
        ColourNote("yellow", "", "��Ҫʶ����֤�룬���ֶ�����murong search <λ����Ϣ>")
        ColourNote("yellow", "", self.captchaLink)
      end
    }
    self:addTransitionToStop(States.ask)
    -- transition from state<search>
    self:addTransition {
      oldState = States.search,
      newState = States.search,
      event = Events.NEXT_SEARCH,
      action = function()
        return self:doSearch()
      end
    }
    self:addTransition {
      oldState = States.search,
      newState = States.search,
      event = Events.NEW_JOB_CAPTCHA,
      action = function()
        assert(self.searchLocation, "searchLocation cannot be nil")
        return self:doPrepareSearch()
      end
    }
    self:addTransition {
      oldState = States.search,
      newState = States.kill,
      event = Events.JIAZEI_FOUND,
      action = function()
        return self:doKill()
      end
    }
    self:addTransitionToStop(States.search)
    -- transition from state<kill>
    self:addTransition {
      oldState = States.kill,
      newState = States.search,
      event = Events.JIAZEI_MISS,
      action = function()
        local currRoom = travel.roomsById[travel.currRoomId]
        self.searchRooms = { currRoom }
        self.searchedRoomIds = {}  -- this is required as we may skip it because it's previously searched
        return self:doSearch()
      end
    }
    self:addTransition {
      oldState = States.kill,
      newState = States.submit,
      event = Events.JIAZEI_KILLED,
      action = function()
        helper.checkUntilNotBusy()
        SendNoEcho("get xin from corpse")
        SendNoEcho("get gold from corpse")
        SendNoEcho("get silver from corpse")
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.kill)
    -- transition from state<submit>
    self:addTransition {
      oldState = States.submit,
      newState = States.submit,
      event = Events.PU_BUSY,
      action = function()
        wait.time(2)
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.submit)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("murong_ask_start", "murong_ask_done",
      "murong_search", "murong_kill")
    helper.addTriggerSettingsPair {
      group = "murong",
      start = "ask_start",
      done = "ask_done"
    }
    helper.addTrigger {
      group = "murong_ask_done",
      regexp = REGEXP.JOB_INFO,
      response = function(name, line, wildcards)
        self.searchLocation = wildcards[1]
      end
    }
    helper.addTrigger {
      group = "murong_ask_done",
      regexp = REGEXP.CAPTCHA_LINK,
      response = function(name, line, wildcards)
        self.captchaLink = wildcards[1]
      end
    }
    helper.addTrigger {
      group = "murong_ask_done",
      regexp = REGEXP.WORK_TOO_FAST,
      response = function(name, line, wildcards)
        self.workTooFast = true
      end
    }
    -- jiazei���ƹ̶�
    helper.addTrigger {
      group = "murong_search",
      regexp = REGEXP.JIAZEI_DESC,
      response = function(name, line, wildcards)
        local playerName = wildcards[1]
        self:debug("JIAZEI_DESC triggered", playerName)
        if playerName == self.myName then
          --�ҵ�������������Ŀ��ص�Ϊ��ǰ������
          self:debug("���ּ���")
          self.targetRoomId = travel.traverseRoomId
          self.jiazeiId = string.lower(wildcards[2])
        else
          self:debug("���˵ļ���")
        end
      end
    }
    helper.addTrigger {
      group = "murong_kill",
      regexp = REGEXP.JIAZEI_KILLED,
      response = function()
        self:debug("JIAZEI_KILLED triggered")
        self.jiazeiKilled = true
      end
    }
    helper.addTrigger {
      group = "murong_kill",
      regexp = REGEXP.JIAZEI_MISSED,
      response = function()
        self:debug("JIAZEI_MISSED triggered")

      end
    }
    helper.addTriggerSettingsPair {
      group = "murong",
      start = "submit_start",
      done = "submit_done"
    }
    helper.addTrigger {
      group = "murong_submit_done",
      regexp = REGEXP.PU_BUSY,
      response = function()
        self:debug("PU_BUSY triggered")
        self.puBusy = true
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("murong")
    helper.addAlias {
      group = "murong",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "murong",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "murong",
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
      group = "murong",
      regexp = REGEXP.ALIAS_SEARCH,
      response = function(name, line, wildcards)
        self.searchLocation = wildcards[1]
        return self:fire(Events.NEW_JOB_CAPTCHA)
      end
    }
  end

  function prototype:initTimers()
--    helper.removeTimerGroups("murong_kill")
--    helper.addTimer {
--      group = "murong_kill",
--      interval = 2,
--      response = function()
--        if not self.killSeconds then
--          self.killSeconds = 0
--        else
--          self.killSeconds = self.killSeconds + 2
--        end
--        if self.killSeconds % 8 == 0 then
--          SendNoEcho("yun recover")
--        end
--        self:debug("ս��ʱ��", self.killSeconds)
--        if self.killSeconds % 3 == 0 then
----          SendNoEcho("perform dugu-jiujian.poqi")
--          SendNoEcho("wield sword")
--          SendNoEcho("perform kuangfeng-kuaijian.kuangfeng")
--          SendNoEcho("perform huashan-jianfa.jianzhang")
----          SendNoEcho("perform yunushijiu-jian.sanqingfeng")
--          SendNoEcho("perform dugu-jiujian.pobing")
--        end
--      end
--    }
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

  function prototype:doAsk()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    self.searchLocation = nil
    self.captchaLink = nil
    self.workTooFast = false
    SendNoEcho("set murong ask_start")
    SendNoEcho("ask pu about job")
    SendNoEcho("set murong ask_done")
    helper.checkUntilNotBusy()
    if self.workTooFast then
      self:debug("����̫�죬�޷���ȡ���񣬵ȴ�5�������ѯ��")
      wait.time(5)
      return self:doAsk()
    elseif self.captchaLink then
      return self:fire(Events.NEW_JOB_CAPTCHA)
    elseif self.searchLocation then
      return self:fire(Events.NEW_JOB)
    else
      ColourNote("yellow", "", "û�л�ȡ������ص㣬����ʧ��")
      return self:doCancel()
    end
  end

  function prototype:doPrepareSearch()
--    local place = helper.ch2place(self.searchLocation)
--    if place and place.area and ExcludedZones[place.area] then
--      ColourNote("yellow", "", "����ʧ�ܣ��������򲻽������� " .. self.searchLocation)
--      return self:doCancel()
--    end
    local searchRooms = travel:getMatchedRooms {
      fullname = self.searchLocation
    }
    if #(searchRooms) == 0 then
      ColourNote("yellow", "", "����ʧ�ܣ��޷�ƥ�䵽���� " .. self.searchLocation)
      return self:doCancel()
    else
      self.searchRooms = searchRooms
      self.searchedRoomIds = {}
      return self:fire(Events.NEXT_SEARCH)
    end
  end

  function prototype:doSearch()
    if #(self.searchRooms) == 0 then
      ColourNote("yellow", "", "����ʧ�ܣ�û�и���Ŀ���������")
      return self:doCancel()
    else
      local nextRoom = table.remove(self.searchRooms)
      if self.searchedRoomIds[nextRoom.id] then
        return self:doSearch()
      end

      self.targetRoomId = nil
      helper.checkUntilNotBusy()
      self:doPowerup()
      travel:walkto(nextRoom.id)
      travel:waitUntilArrived()
      helper.enableTriggerGroups("murong_search")
      local onStep = function()
        -- ��ÿ�������ĵص㶼�����������б�
        self.searchedRoomIds[travel.traverseRoomId] = true
        return self.targetRoomId ~= nil  -- ֹͣ�������ҵ����
      end
      local onArrive = function()
        helper.disableTriggerGroups("murong_search")
        if self.targetRoomId then
          self:debug("�����������Ѿ����ּ�������ȷ��Ŀ�귿�䣺", self.targetRoomId)
          return self:fire(Events.JIAZEI_FOUND)
        else
          self:debug("û�з��ּ�����������һ���ص�")
          wait.time(1)
          return self:fire(Events.NEXT_SEARCH)
        end
      end
      return travel:traverseNearby(SearchDepth, onStep, onArrive)
    end
  end

  function prototype:doPowerup()
    SendNoEcho("yun powerup")
    SendNoEcho("wield sword")
  end

  function prototype:doSubmit()
    helper.checkUntilNotBusy()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    self.puBusy = false
    SendNoEcho("set murong submit_start")
    SendNoEcho("give xin to pu")
    SendNoEcho("set murong submit_done")
    helper.checkUntilNotBusy()
    SendNoEcho("drop shi tan")
    SendNoEcho("drop xuan bing")
    if self.puBusy then
      return self:fire(Events.PU_BUSY)
    else
      return self:fire(Events.STOP)
    end
  end

  function prototype:doKill()
    SendNoEcho("halt")
    self:doPowerup()
    SendNoEcho("killall " .. self.jiazeiId)
    SendNoEcho("perform dugu-jiujian.poqi")
    self.killSeconds = nil
    self.jiazeiKilled = false
    helper.enableTriggerGroups("murong_kill")
--    helper.enableTimerGroups("murong_kill")
    combat:start()

    while not self.jiazeiKilled do
      wait.time(3)
      self:debug("�������Ƿ��ѱ�ɱ��")
    end

    combat:stop()
    self:debug("�����ѱ�ɱ�����ɹ�����")
    return self:fire(Events.JIAZEI_KILLED)
  end

  -- jobs ���
  function prototype:doStart()
    return self:fire(Events.START)
  end

  function prototype:doCancel()
--    ColourNote("red", "", "����ģʽ�����ֶ�ȡ������")

    helper.assureNotBusy()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    wait.time(1)
    SendNoEcho("ask pu about fail")
    helper.checkUntilNotBusy()
    return self:fire(Events.STOP)
  end

  return prototype
end
return define_murong():FSM()

