--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/17
-- Time: 19:58
-- To change this template use File | Settings | File Templates.
--

require "wait"
local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"

local define_patrol = function()
  local prototype = FSM.inheritedMeta()
  -- define own states and events
  local States = {
    stop = "stop",    -- ֹͣ״̬
    ask = "ask",    -- ��������
    work = "work",    -- ִ��Ѳ��
    submit = "submit",    -- �ύ����
    wait_ask = "wait_ask",    -- �ȴ��ٴ�ѯ��
    wait_submit = "wait_submit"    -- �ȴ��ٴ��ύ
  }
  local Events = {
    START = "start",    -- ��ʼ�ź�
    NO_JOB_AVAILABLE = "no_job_available",    -- Ŀǰû��������ɵ�̫�죩
    NEW_JOB = "new_job",    -- �õ�һ���µ�����
    PREV_JOB_NOT_FINISH = "prev_job_not_finish",    -- ֮ǰ������û�����
    WORK_DONE = "work_done",    -- Ѳ�����
    SUBMIT_ACCEPT = "submit_ok",    -- �ύ����ɹ�
    WORK_MISS = "work_miss",    -- �з�����©û��Ѳ�ߵ�
    WORK_TOO_FAST = "work_too_fast",    -- Ѳ��̫���޷��ύ
    PAUSE_WAIT = "pause_wait",    -- ֹͣ�ȴ�
    STOP = "stop"    -- ֹͣ������
  }
  local Paths = {
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
  local Rooms = {
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
  local REGEXP = {
    --ASK_YUE = "^[ >]*��������ɺ�����йء�job������Ϣ��$",
    NEW_JOB="^[ >]*����ɺ�ó�һ�ŵ�ͼ���ѻ�ɽ��ҪѲ�ߵ������ò�ͬ��ɫ��ע������������˵��һ�顣$",
    PREV_JOB_NOT_FINISH = "^[ >]*����ɺ˵���������ϴ�����û������أ���$",
    NEXT_JOB_WAIT = "^[ >]*����ɺ˵����������æ���������Ұɡ���$",
    NEXT_JOB_TOO_FAST = "^[ >]*����ɺ˵����������æ���������Ұɡ���$",
    NO_JOB_AVAILABLE = "^[ >]*����ɺ˵��������ո�����������ȥ��Ϣһ��ɡ���$",
    EXP_TOO_HIGH = "^[ >]*����ɺ˵��������Ĺ��򲻴��ˣ������￴����ʲô���񽻸��㡣��$",
    ASK_START = "^[ >]*�趨����������huashan_patrol = \"ask_start\"$",
    ASK_DONE = "^[ >]*�趨����������huashan_patrol = \"ask_done\"$",
    PATROLLING="^[ >]*����(.+?)Ѳ߮����δ���ֵ��١�$",    -- used in wait.regexp
    WORK_DONE="^[ >]*�趨����������huashan_patrol = \"work_done\"$",
    REJECT_LING="^[ >]*����ɺ����Ҫ���ƣ�����Ը����Űɡ�$",
    ACCEPT_LING="^[ >]*�������ɺһ�����ơ�$",
    SUBMIT_START = "^[ >]*�趨����������huashan_patrol = \"submit_start\"$",
    SUBMIT_DONE = "^[ >]*�趨����������huashan_patrol = \"submit_done\"$",
    DZ_FINISH = "^[ >]*�㽫��ת���ζ����������Ϣ�ջص���������˿�����վ��������$",
    DZ_NEILI_ADDED = "^[ >]*������������ˣ���$"
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
    -- set state to stop by default
    self:setState(States.stop)
    self.eventToSend = nil
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        -- disable all triggers
        helper.disableTriggerGroups(
          "huashan_patrol_ask_start",
          "huashan_patrol_ask_done",
          "huashan_patrol_work",
          "huashan_patrol_submit_start",
          "huashan_patrol_submit_done",
          "huashan_patrol_wait_ask",
          "huashan_patrol_wait_submit")
      end,
      exit = function() end
    }
    self:addState {
      state = States.ask,
      enter = function()
        helper.disableTriggerGroups("huashan_patrol_ask_done")
        helper.enableTriggerGroups("huashan_patrol_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups(
          "huashan_patrol_ask_start",
          "huashan_patrol_ask_done")
      end
    }
    self:addState {
      state = States.work,
      enter = function()
        helper.enableTriggerGroups("huashan_patrol_work")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_patrol_work")
      end
    }
    self:addState {
      state = States.submit,
      enter = function()
        helper.disableTriggerGroups("huashan_patrol_submit_done")
        helper.enableTriggerGroups("huashan_patrol_submit_start")
      end,
      exit = function()
        helper.disableTriggerGroups(
          "huashan_patrol_submit_start",
          "huashan_patrol_submit_done")
      end
    }
    self:addState {
      state = States.wait_ask,
      enter = function()
        helper.enableTriggerGroups("huashan_patrol_wait_ask")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_patrol_wait_ask")
      end
    }
    self:addState {
      state = States.wait_submit,
      enter = function()
        helper.enableTriggerGroups("huashan_patrol_wait_submit")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_patrol_wait_submit")
      end
    }
  end

  function prototype:addTransitionToStop(fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function()
        print("ֹͣѲ������ - ��ǰ״̬", self.currState)
      end
    }
  end

  function prototype:initTransitions()
    -- transitions from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.ask,
      event = Events.START,
      action = function()
        travel:stop()
        -- ����ɺ�ڻ�ɽ����2916
        travel:walkto(2916, function()
          self:doAsk()
        end)
      end
    }
    -- transitions from state<ask>
    self:addTransition {
      oldState = States.ask,
      newState = States.work,
      event = Events.NEW_JOB,
      action = function()
        -- ���ڻ��������ʱ�����ط����б�
        self:reloadRooms()
        self:doWork()
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.wait_ask,
      event = Events.NO_JOB_AVAILABLE,
      action = function()
        helper.assureNotBusy()
        travel:stop()
        -- ��������2921�����ȴ�ask
        travel:walkto(2921, function()
          SendNoEcho("dz max")
        end)
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.work,
      event = Events.PREV_JOB_NOT_FINISH,
      action = function() self:doWork() end
    }
    self:addTransitionToStop(States.ask)
    -- transitions from state<work>
    self:addTransition {
      oldState = States.work,
      newState = States.submit,
      event = Events.WORK_DONE,
      action = function()
        travel:stop()
        -- ǰ������������ --��2910�п���busy
        travel:walkto(2910, function()
          helper.assureNotBusy()
          travel:walkto(2916, function()
            self:doSubmit()
          end)
        end)
      end
    }
    self:addTransitionToStop(States.work)
    -- transitions from state<submit>
    self:addTransition {
      oldState = States.submit,
      newState = States.ask,
      event = Events.SUBMIT_ACCEPT,
      action = function()
        -- ���ڵ�ǰ����
        self:doAsk()
      end
    }
    self:addTransition {
      oldState = States.submit,
      newState = States.work,
      event = Events.WORK_MISS,
      action = function()
        self:doWork()
      end
    }
    self:addTransition {
      oldState = States.submit,
      newState = States.wait_submit,
      event = Events.WORK_TOO_FAST,
      action = function()
        -- ��������2921�����ȴ�submit
        travel:walkto(2921, function()
          SendNoEcho("dz max")
        end)
      end
    }
    self:addTransitionToStop(States.submit)
    -- transitions from state<wait_ask>
    self:addTransition {
      oldState = States.wait_ask,
      newState = States.ask,
      event = Events.PAUSE_WAIT,
      action = function()
        -- �����ٴ�ѯ��
        travel:walkto(2916, function()
          self:doAsk()
        end)
      end
    }
    self:addTransitionToStop(States.wait_ask)
    -- transitions from state<wait_submit>
    self:addTransition {
      oldState = States.wait_submit,
      newState = States.submit,
      event = Events.PAUSE_WAIT,
      action = function()
        -- �����ٴ��ύ
        travel:walkto(2916, function()
          self:doSubmit()
        end)
      end
    }
    self:addTransitionToStop(States.wait_submit)
  end

  function prototype:doAsk()
    SendNoEcho("set huashan_patrol ask_start")
    SendNoEcho("ask yue about job")
    SendNoEcho("set huashan_patrol ask_done")
  end

  function prototype:doSubmit()
    SendNoEcho("set huashan_patrol submit_start")
    SendNoEcho("give yue ling")
    SendNoEcho("set huashan_patrol submit_done")
  end

  function prototype:doWork()
    self:debug("����Ѳ��·��")
    self:reloadPaths()
    self:debug("��ʼѲ��")
    while #(self.paths) > 0 do
      local next = table.remove(self.paths)
      -- ������һ�����䣬�˴���ǿ���裬������һ�����䲻��ʧ��
      helper.assureNotBusy()
      SendNoEcho(next.path)
      if self.rooms[next.name] and self.rooms[next.name] > 0 then
        self:debug("�״ν���Ѳ�߷��䣬�ȴ�Ѳ������")
        -- wait at most 10 seconds for the notion
        local _, wildcards = wait.regexp(REGEXP.PATROLLING, 8)
        if wildcards and wildcards[1] then
          local currRoom = wildcards[1]
          if self.rooms[currRoom] and self.rooms[currRoom] > 0 then
            self.rooms[currRoom] = self.rooms[currRoom] - 1
          end
        else
          print("�õ���Ӧ����ʾѲ����ʾ��û����ʾ��")
        end
      end
    end
    self:debug("Ѳ�߱������")
    wait.time(1)
    SendNoEcho("set huashan_patrol work_done")
  end

  function prototype:reloadRooms()
    self.rooms = {}
    for k, v in pairs(Rooms) do
      self.rooms[k] = v
    end
  end

  function prototype:reloadPaths()
    -- copy and reverse paths
    self.paths = {}
    for i = #(Paths),1,-1 do
      table.insert(self.paths, Paths[i])
    end
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "huashan_patrol_ask_start", "huashan_patrol_ask_done",
      "huashan_patrol_work",
      "huashan_patrol_submit_start", "huashan_patrol_submit_done",
      "huashan_patrol_wait_ask", "huashan_patrol_wait_submit"
    )

    helper.addTrigger {
      group = "huashan_patrol_ask_start",
      regexp = REGEXP.ASK_START,
      response = function()
        self:debug("ASK_START triggered")
        helper.enableTriggerGroups("huashan_patrol_ask_done")
      end
    }
    -- ask result can be 4 types, so store the
    helper.addTrigger {
      group = "huashan_patrol_ask_done",
      regexp = REGEXP.NEW_JOB,
      response = function()
        self:debug("NEW_JOB triggered")
        self.eventToSend = Events.NEW_JOB
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_ask_done",
      regexp = REGEXP.PREV_JOB_NOT_FINISH,
      response = function()
        self:debug("PREV_JOB_NOT_FINISH triggered")
        self.eventToSend = Events.PREV_JOB_NOT_FINISH
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_ask_done",
      regexp = REGEXP.NEXT_JOB_WAIT,
      response = function()
        self:debug("NEXT_JOB_WAIT triggered")
        self.eventToSend = Events.NO_JOB_AVAILABLE
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_ask_done",
      regexp = REGEXP.NO_JOB_AVAILABLE,
      response = function()
      self:debug("NO_JOB_AVAILABLE triggered")
        self.eventToSend = Events.NO_JOB_AVAILABLE
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_ask_done",
      regexp = REGEXP.EXP_TOO_HIGH,
      response = function()
        self:debug("EXP_TOO_HIGH triggered")
        self.eventToSend = Events.STOP
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_ask_done",
      regexp = REGEXP.ASK_DONE,
      response = function()
        self:debug("ASK_DONE triggered")
        if not self.eventToSend then
          print("����û�л�ȡ������ѯ�ʽ��")
          self.eventToSend = nil
        else
          local event = self.eventToSend
          self.eventToSend = nil
          self:fire(event)
        end
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_work",
      regexp = REGEXP.WORK_DONE,
      response = function()
        self:debug("WORK_DONE triggered")
        self:fire(Events.WORK_DONE)
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_submit_start",
      regexp = REGEXP.SUBMIT_START,
      response = function()
        self:debug("SUBMIT_START triggered")
        helper.enableTriggerGroups("huashan_patrol_submit_done")
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_submit_done",
      regexp = REGEXP.REJECT_LING,
      response = function()
        local allPatrolled = true
        for room, cnt in pairs(self.rooms) do
          if cnt > 0 then
            print("�����з���δѲ�ߵ�", room)
            allPatrolled = false
            break
          end
        end
        if not allPatrolled then
          print("�в�������û��Ѳ�ߵ�������Ѳ��")
          self:fire(Events.WORK_MISS)
        else
          print("Ѳ��ʱ��̫�죬���Դ����ȴ�")
          self:fire(Events.WORK_TOO_FAST)
        end
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_submit_done",
      regexp = REGEXP.ACCEPT_LING,
      response = function()
        self:fire(Events.SUBMIT_ACCEPT)
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_submit_done",
      regexp = REGEXP.SUBMIT_DONE,
      response = function()
        if not self.eventToSend then
          print("����û�л�ȡ�������ύ���")
          self.eventToSend = nil
        else
          local event = self.eventToSend
          self.eventToSend = nil
          self:fire(self.eventToSend)
        end
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_wait_ask",
      regexp = REGEXP.DZ_FINISH,
      response = function()
        SendNoEcho("dz max")
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_wait_ask",
      regexp = REGEXP.DZ_NEILI_ADDED,
      response = function()
        self:fire(Events.PAUSE_WAIT)
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_wait_submit",
      regexp = REGEXP.DZ_FINISH,
      response = function()
        SendNoEcho("dz max")
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_wait_submit",
      regexp = REGEXP.DZ_NEILI_ADDED,
      response = function()
        self:fire(Events.PAUSE_WAIT)
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("huashan_patrol")

    helper.addAlias {
      group = "huashan_patrol",
      regexp = "^patrol$",
      response = function()
        print("PATROL��ɽ����Ѳ�������÷����£�")
        print("patrol start", "��ʼѲ��")
        print("patrol stop", "��ɵ�ǰ�����ֹͣѲ��")
        print("patrol debug on/off", "����/�ر�Ѳ�ߵ���ģʽ")
      end
    }

    helper.addAlias {
      group = "huashan_patrol",
      regexp = "^patrol\\s+start\\s*",
      response = function()
        -- �ֶ���ʼʱ���������¼��ط���
        self:reloadRooms()
        self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "huashan_patrol",
      regexp = "^patrol\\s+stop\\s*$",
      response = function()
        self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "huashan_patrol",
      regexp = "^patrol\\s+debug\\s+(on|off)\\s*$",
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self:debugOn()
        elseif cmd == "off" then
          self:debugOff()
        end
      end
    }
  end

  return prototype
end
return define_patrol():FSM()
