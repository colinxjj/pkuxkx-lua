--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/17
-- Time: 19:59
-- To change this template use File | Settings | File Templates.
--
require "wait"
local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

local p2 = [[
> ��������������йء�job������Ϣ��
���������㣬�����þ�û�м�������ת(turnright) ��ͼ(longtu) ����(dddtt) ҹ����(yeqingwu) ��Щ���ˣ����ڽ����У����������Щǰ���е�һ�������������ʸ���(wenhao)�ɣ�������Ʒ��������
������ɺ�ֱ������������ǰ����finish������޷���ɣ�������fail��
�����������һ�����

��ɫ(ywx)�����㣺�������(Grobot)��Ŀǰ�ڡ����ݵĿ͵꡿,��ȥ��������!

���������㱻�����ˣ�

����Ŷ�������һҾ����������������ʺá�

��������������йء�job������Ϣ��
�����ξ�����ʼ������һ���ж���
���������˵���������ɽ����Щ�µ��ӣ����ȥ������ָ��(zhidian)һ�°ɡ�

�����γ��㲻ע�⣬һ���̲�֪���ܵ�����ȥ�ˡ�

�����ε����ðɣ��ðɣ��һ�ȥ��������

�����ε�����Ϣһ���в��а���

������һ��һʽ�а����ۣ�����Ի�ȥ�����������ˡ�
��Դ޾�Ľ���˻��֣��޾�Ľת����ȥ�ˡ�

���������㱻�����ˣ�

��ָ����������У���ӡ֤������ѧ������������һ�㡣

    ˹�����̵��Ļ�ɽ���� �޾�Ľ(Scala's student)

]]



local define_teach = function()
  local prototype = FSM.inheritedMeta()
  local States = {
    stop = "stop",    -- ֹͣ״̬
    ask = "ask",    -- ѯ������
    teaching = "teaching",    -- �̵���
    searching = "searching",    -- ������
    begging = "begging",    -- ����ʦ�ÿ���
    wait_ask = "wait_ask",    -- �ȴ�ѯ������
    submit = "submit",    -- �ύ����
    wenhao = "wenhao",    -- �ʺ�...
    cancel = "cancel"    -- ȡ������
  }
  local Events = {
    STOP = "stop",    -- ֹͣ�ź�
    START = "start",    -- ��ʼ�ź�
    NO_JOB_AVAILABLE = "no_job_available",    -- Ŀǰû��������ɵ�̫�죩
    NEW_TEACH = "new_teach",    -- �õ�һ���µĽ̵�����
    NEW_WENHAO = "new_wenhao",    -- �õ�һ���µ��ʺ�����
    PREV_JOB_NOT_FINISH = "prev_job_not_finish",    -- ֮ǰ������û�����
    START_TEACH = "start_teach",    -- ��ʼ�̵�
    START_WENHAO = "start_wenhao",    -- ��ʼ�ʺ�
    TEACH_DONE = "teach_done",    -- �̵�����
    SUBMIT_DONE = "submit_done",    -- �ύ�ɹ�
    STUDENT_ESCAPED = "student_escaped",    -- ѧ��������
    STUDENT_FOUND = "student_found",    -- �ҵ�ѧ����
    STUDENT_NOT_FOUND = "student_not_found",    -- û�ҵ�ѧ��
    STUDENT_PERSUADED = "studuent_persuaded",    -- ѧ��ͬ�����ѧϰ
    CONTINUE_TEACH = "continue_teach",    -- ������ѧ
    PAUSE_WAIT = "pause_wait",    -- ֹͣ�ȴ�
    GO_BACK_TEACH = "go_back_teach",    -- ��ȥ��
    CONTINUE_BEG = "continue_beg",    -- ������
    WENHAO_DONE = "wenhao_done",    -- �ʺóɹ�
    WENHAO_FAIL = "wenhao_fail",    -- �ʺ�ʧ��
  }
  local REGEXP = {
    NEW_JOB_TEACH = "^[ >]*���������˵���������ɽ����Щ�µ��ӣ����ȥ������ָ��\\(zhidian\\)һ�°ɡ�$",
    NEW_JOB_WENHAO = "^[ >]*���������㣬�����þ�û�м���(.*?) ��Щ���ˣ����ڽ����У����������Щǰ���е�һ�������������ʸ���\\(wenhao\\)�ɣ�������Ʒ��������\\s*$",
    STUDENT_FOLLOWED = "^[ >]*(.*)������ʼ������һ���ж���$",
    PREV_JOB_NOT_FINISH = "^[ >]*������˵���������ϴ�����û������أ���$",
    NEXT_JOB_WAIT = "^[ >]*����ɺ˵����������æ���������Ұɡ���$",
    WORK_TOO_FAST = "^[ >]*������˵��������ո�����������ȥ��Ϣһ��ɡ���$",
    EXP_TOO_HIGH = "^[ >]*������˵��������Ĺ��򲻴��ˣ�������ѧ����ʲô�ˣ�ȥ�����Űɡ���$",
    ASK_START = "^[ >]*�趨����������huashan_teach = \"ask_start\"$",
    ASK_DONE = "^[ >]*�趨����������huashan_teach = \"ask_done\"$",
    -- PATROLLING="^[ >]*����(.+?)Ѳ߮����δ���ֵ��١�$",    -- used in wait.regexp
    STUDENT_ESCAPED = "^[ >]*(.+)���㲻ע�⣬һ���̲�֪���ܵ�����ȥ�ˡ�$",
    STUDENT_IMPROVED = "^[ >]*(.+)һ��һʽ�а����ۣ�����Ի�ȥ�����������ˡ�$",
    STUDENT_PERSUADED = "^[ >]*(.+)�����ðɣ��ðɣ��һ�ȥ��������$",
    -- STUDENT_DESC = "^[ >]*��ɽ.*����(.*)refined$",
    TEACH_START = "^[ >]*�趨����������huashan_teach = \"teach_start\"$",
    TEACH_DONE = "^[ >]*�趨����������huashan_teach = \"teach_done\"$",
    BEG_START = "^[ >]*�趨����������huashan_teach = \"beg_start\"$",
    BEG_DONE = "^[ >]*�趨����������huashan_teach = \"beg_done\"$",
    SUBMIT_START = "^[ >]*�趨����������huashan_teach = \"submit_start\"$",
    SUBMIT_DONE = "^[ >]*�趨����������huashan_teach = \"submit_done\"$",
    SUBMIT_SUCCESS = "^[ >]*���������㱻�����ˣ�$",
    CANCEL_START = "^[ >]*�趨����������huashan_teach = \"cancel_start\"$",
    CANCEL_DONE = "^[ >]*�趨����������huashan_teach = \"cancel_done\"$",
    DZ_FINISH = "^[ >]*�㽫��ת���ζ����������Ϣ�ջص���������˿�����վ��������$",
    DZ_NEILI_ADDED = "^[ >]*������������ˣ���$",
    WENHAO_DESC = "^[ >]*�����(.+)����һҾ������������.*�ʺá�$"
  }
  local teacherId = "luar"
  local teacherName = "ߣ��"

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
    self.studentId = teacherId .. "'s student"
    self:resetOnStop()
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:resetOnStop()
        self:disableAllTriggers()
      end,
      exit = function() end
    }
    self:addState {
      state = States.ask,
      enter = function()
        self.studentName = nil
        self.wenhaoList = nil
        self.jobType = nil
        self.noJobAvailable = false
        helper.enableTriggerGroups("huashan_teach_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_teach_ask_start", "huashan_teach_ask_done")
      end
    }
    self:addState {
      state = States.teaching,
      enter = function()
        self.studentEscaped = false
        self.studentImproved = false
        helper.enableTriggerGroups("huashan_teach_teaching_start")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_teach_teaching_start", "huashan_teach_teaching_done")
      end
    }
    self:addState {
      state = States.wenhao,
      enter = function()
        helper.enableTriggerGroups("huashan_teach_wenhao")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_teach_wenhao")
      end
    }
    self:addState {
      state = States.searching,
      enter = function()
        self.studentCaught = false
        helper.enableTriggerGroups("huashan_teach_searching")
      end,
      exit = function()
        self.studentCaught = false
        helper.disableTriggerGroups("huashan_teach_searching")
      end
    }
    self:addState {
      state = States.begging,
      enter = function()
        self.studentPersuaded = false
        helper.enableTriggerGroups("huashan_teach_beg_start")
      end,
      exit = function()
        self.studentPersuaded = false
        helper.disableTriggerGroups("huashan_teach_beg_start", "huashan_teach_beg_done")
      end
    }
    self:addState {
      state = States.wait_ask,
      enter = function()
        helper.enableTriggerGroups("huashan_teach_wait_ask")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_teach_wait_ask")
      end
    }
    self:addState {
      state = States.submit,
      enter = function()
        self.submitted = false
        helper.enableTriggerGroups("huashan_teach_submit_start")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_teach_submit_start", "huashan_teach_submit_done")
      end
    }
    self:addState {
      state = States.cancel,
      enter = function()
        helper.enableTriggerGroups("huashan_teach_cancel_start")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_teach_cancel_start", "huashan_teach_cancel_done")
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
        travel:stop()
        travel:walkto(66, function()
          self:doAsk()
        end)
      end
    }
    -- transition from state<ask>
    self:addTransition {
      oldState = States.ask,
      newState = States.teaching,
      event = Events.NEW_TEACH,
      action = function()
        travel:walkto(2918, function()
          self:doTeach()
        end)
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.wenhao,
      event = Events.NEW_WENHAO,
      action = function()
        self:doWenhao()
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.wait_ask,
      event = Events.NO_JOB_AVAILABLE,
      action = function()
        travel:walkto(2921, function()
          self:doWaitAsk()
        end)
      end
    }
    self:addTransitionToStop(States.ask)
    -- transition from state<wait_ask>
    self:addTransition {
      oldState = States.wait_ask,
      newState = States.ask,
      event = Events.PAUSE_WAIT,
      action = function()
        travel:walkto(66, function()
          self:doAsk()
        end)
      end
    }
    self:addTransitionToStop(States.wait_ask)
    -- transition from state<teaching>
    self:addTransition {
      oldState = States.teaching,
      newState = States.teaching,
      event = Events.CONTINUE_TEACH,
      action = function()
        helper.assureNotBusy()
        self:doTeach()
      end
    }
    self:addTransition {
      oldState = States.teaching,
      newState = States.searching,
      event = Events.STUDENT_ESCAPED,
      action = function()
        local check = function() return self.studentCaught end
        local action = function()
          if self.studentCaught then
            return self:fire(Events.STUDENT_FOUND)
          else
            return self:fire(Events.STUDENT_NOT_FOUND)
          end
        end
        self:debug("׼������")
        helper.assureNotBusy()
        travel:traverseZone("huashan", check, action)
      end
    }
    self:addTransition {
      oldState = States.teaching,
      newState = States.submit,
      event = Events.TEACH_DONE,
      action = function()
        travel:walkto(66, function()
          self:doSubmit()
        end)
      end
    }
    self:addTransitionToStop(States.teaching)
    -- transition from state<searching>
    self:addTransition {
      oldState = States.searching,
      newState = States.begging,
      event = Events.STUDENT_FOUND,
      action = function()
        self:doBeg()
      end
    }
    self:addTransition {
      oldState = States.searching,
      newState = States.stop,
      event = Events.STUDENT_NOT_FOUND,
      action = function()
        print("�Ҳ���ѧ���ˣ�����ʧ��")
      end
    }
    self:addTransitionToStop(States.searching)
    -- transition from state<begging>
    self:addTransition {
      oldState = States.begging,
      newState = States.teaching,
      event = Events.STUDENT_PERSUADED,
      action = function()
        helper.assureNotBusy()
        travel:walkto(2918, function()
          self:doTeach()
        end)
      end
    }
    self:addTransition {
      oldState = States.begging,
      newState = States.begging,
      event = Events.CONTINUE_BEG,
      action = function()
        helper.assureNotBusy()
        self:doBeg()
      end
    }
    self:addTransitionToStop(States.begging)
    -- transition from state<submit>
    self:addTransition {
      oldState = States.submit,
      newState = States.ask,
      event = Events.SUBMIT_DONE,
      action = function()
        -- �˴�������ж�ʳ����ˮ
        status:hpbrief()
        if status.food < 100 or status.drink < 100 then
          return travel:walkto(3798, function()
            helper.assureNotBusy()
            SendNoEcho("do 2 eat")
            helper.assureNotBusy()
            SendNoEcho("do 2 drink")
            helper.assureNotBusy()
            wait.time(3)
            return travel:walkto(66, function()
              return self:doAsk()
            end)
          end)
        else
          -- ���ڵ�ǰ����
          wait.time(3)
          return self:doAsk()
        end
      end
    }
    self:addTransitionToStop(States.submit)
    -- transition from state<wenhao>
    self:addTransition {
      oldState = States.wenhao,
      newState = States.submit,
      event = Events.WENHAO_DONE,
      action = function()
        travel:walkto(66, function()
          self:doSubmit()
        end)
      end
    }
    self:addTransition {
      oldState = States.wenhao,
      newState = States.cancel,
      event = Events.WENHAO_FAIL,
      action = function()
        travel:walkto(66, function()
          self:doCancel()
        end)
      end
    }
    self:addTransitionToStop(States.wenhao)
    -- transition from state<cancel>
    self:addTransition {
      oldState = States.cancel,
      newState = States.ask,
      event = Events.START,
      action = function()
        self:doAsk()
      end
    }
    self:addTransitionToStop(States.cancel)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "huashan_teach_ask_start", "huashan_teach_ask_done",
      "huashan_teach_wait_ask",
      "huashan_teach_teaching_start", "huashan_teach_teaching_done",
      "huashan_teach_beg_start", "huashan_teach_beg_done",
      "huashan_teach_searching",
      "huashan_teach_submit_start", "huashan_teach_submit_done",
      "huashan_teach_cancel_start", "huashan_teach_cancel_done",
      "huashan_teach_wenhao")
    -- ��ʼѯ��
    helper.addTrigger {
      group = "huashan_teach_ask_start",
      regexp = REGEXP.ASK_START,
      response = function()
        helper.enableTriggerGroups("huashan_teach_ask_done")
      end
    }
    -- ��ȡstudent����
    helper.addTrigger {
      group = "huashan_teach_ask_done",
      regexp = REGEXP.STUDENT_FOLLOWED,
      response = function(name, line, wildcards)
        local name = wildcards[1]
        self.studentName = name
      end
    }
    -- ��ȡ��������
    helper.addTrigger {
      group = "huashan_teach_ask_done",
      regexp = REGEXP.NEW_JOB_TEACH,
      response = function()
        self.jobType = "teach"
      end
    }
    -- �����ʺ�����
    helper.addTrigger {
      group = "huashan_teach_ask_done",
      regexp = REGEXP.NEW_JOB_WENHAO,
      response = function(name, line, wildcards)
        self:debug("�ʺ������", wildcards[1])
        local patterns = utils.split(wildcards[1], " ")
        local players = {}
        for _, pattern in ipairs(patterns) do
          local str = utils.split(pattern, "(") -- the utils.split implementatin is not different
          local name = str[1]
          local id = string.gsub(str[2], "%)", "")
          table.insert(players, {name=name, id=id})
        end
        self.wenhaoList = players
        self.jobType = "wenhao"
      end
    }
    -- ����̫��û����
    helper.addTrigger {
      group = "huashan_teach_ask_done",
      regexp = REGEXP.WORK_TOO_FAST,
      response = function()
        self.noJobAvailable = true
      end
    }
    -- ����������
    helper.addTrigger {
      group = "huashan_teach_ask_done",
      regexp = REGEXP.ASK_DONE,
      response = function()
        if self.jobType == "teach" then
          self:fire(Events.NEW_TEACH)
        elseif self.jobType == "wenhao" then
          self:fire(Events.NEW_WENHAO)
        elseif self.noJobAvailable then
          self:fire(Events.NO_JOB_AVAILABLE)
        else
          print("û�л�ȡ�����񣬳���")
          self:fire(Events.stop)
        end
      end
    }
    -- ��ʼ��
    helper.addTrigger {
      group = "huashan_teach_teaching_start",
      regexp = REGEXP.TEACH_START,
      response = function()
        helper.enableTriggerGroups("huashan_teach_teaching_done")
      end
    }
    -- �жϼ����̣��ѣ��ظ�
    helper.addTrigger {
      group = "huashan_teach_teaching_done",
      regexp = REGEXP.TEACH_DONE,
      response = function()
        if self.studentEscaped then
          self:fire(Events.STUDENT_ESCAPED)
        elseif self.studentImproved then
          self:fire(Events.TEACH_DONE)
        else
          self:fire(Events.CONTINUE_TEACH)
        end
      end
    }
    -- ѧ������
    helper.addTrigger {
      group = "huashan_teach_teaching_done",
      regexp = REGEXP.STUDENT_ESCAPED,
      response = function(name, line, wildcards)
        local name = wildcards[1]
        if name == self.studentName then
          self.studentEscaped = true
        end
      end
    }
    -- ѧ�����������Ը���
    helper.addTrigger {
      group = "huashan_teach_teaching_done",
      regexp = REGEXP.STUDENT_IMPROVED,
      response = function(name, line, wildcards)
        local name = wildcards[1]
        if name == self.studentName then
          self.studentImproved = true
        end
      end
    }
    -- �ȴ�ѯ��
    helper.addTrigger {
      group = "huashan_teach_wait_ask",
      regexp = REGEXP.DZ_FINISH,
      response = function()
        SendNoEcho("dz max")
      end
    }
    -- ֹͣ�ȴ�
    helper.addTrigger {
      group = "huashan_teach_wait_ask",
      regexp = REGEXP.DZ_NEILI_ADDED,
      response = function()
        self:fire(Events.PAUSE_WAIT)
      end
    }
    -- ��ʼ��
    helper.addTrigger {
      group = "huashan_teach_beg_start",
      regexp = REGEXP.BEG_START,
      response = function()
        helper.enableTriggerGroups("huashan_teach_beg_done")
      end
    }
    -- �жϼ������ǻ�ȥ��
    helper.addTrigger {
      group = "huashan_teach_beg_done",
      regexp = REGEXP.BEG_DONE,
      response = function()
        if self.studentPersuaded then
          self:fire(Events.STUDENT_PERSUADED)
        else
          self:fire(Events.CONTINUE_BEG)
        end
      end
    }
    -- �ɹ�Ȱ��
    helper.addTrigger {
      group = "huashan_teach_beg_done",
      regexp = REGEXP.STUDENT_PERSUADED,
      response = function(name, line, wildcards)
        local name = wildcards[1]
        if name == self.studentName then
          self.studentPersuaded = true
        end
      end
    }
    -- ��ʼ�ύ
    helper.addTrigger {
      group = "huashan_teach_submit_start",
      regexp = REGEXP.SUBMIT_START,
      response = function()
        helper.enableTriggerGroups("huashan_teach_submit_done")
      end
    }
    -- �����ύ
    helper.addTrigger {
      group = "huashan_teach_submit_done",
      regexp = REGEXP.SUBMIT_DONE,
      response = function()
        if self.submitted then
          self:fire(Events.SUBMIT_DONE)
        else
          print("ʧ�ܡ������޷��ύ")
          self:fire(Events.STOP)
        end
      end
    }
    -- �ɹ��ύ
    helper.addTrigger {
      group = "huashan_teach_submit_done",
      regexp = REGEXP.SUBMIT_SUCCESS,
      response = function()
        self.submitted = true
      end
    }
    -- ���ҵ���
    helper.addTrigger {
      group = "huashan_teach_searching",
      regexp = "^[ >]*" .. teacherName .. "�̵��Ļ�ɽ���� (.*)\\(.*'s student\\)$",
      response = function(name, line, wildcards)
        local name = wildcards[1]
        if name == self.studentName then
          self:debug("�ҵ��ҵĵ���", name)
          self.studentCaught = true
        else
          self:debug("�ⲻ���ҵĵ���", self.studentName, name)
        end
      end
    }
    -- ȡ������ʼ
    helper.addTrigger {
      group = "huashan_teach_cancel_start",
      regexp = REGEXP.CANCEL_START,
      response = function()
        helper.enableTriggerGroups("huashan_teach_cancel_done")
      end
    }
    -- ȡ���������
    helper.addTrigger {
      group = "huashan_teach_cancel_done",
      regexp = REGEXP.CANCEL_DONE,
      response = function()
        self:fire(Events.START)
      end
    }
    -- �ʺ�
    helper.addTrigger {
      group = "huashan_teach_wenhao",
      regexp = REGEXP.WENHAO_DESC,
      response = function()

      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("huashan_teach")

    helper.addAlias {
      group = "huashan_teach",
      regexp = "^teaching\\s*$",
      response = function()
        print("TEACHING��ɽ���̵ֽ������÷����£�")
        print("teaching start", "��ʼ�̵�")
        print("teaching stop", "��ɵ�ǰ�����ֹͣѲ��")
        print("teaching debug on/off", "����/�ر�Ѳ�ߵ���ģʽ")
      end
    }

    helper.addAlias {
      group = "huashan_teach",
      regexp = "^teaching\\s+start\\s*$",
      response = function()
        self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "huashan_teach",
      regexp = "^teaching\\s+stop\\s*$",
      response = function()
        self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "huashan_teach",
      regexp = "^teaching\\s+debug\\s+(on|off)\\s*$",
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

  function prototype:addTransitionToStop(fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function()
        print("ֹͣ�̵����� - ��ǰ״̬", self.currState)
      end
    }
  end

  function prototype:doAsk()
    SendNoEcho("set huashan_teach ask_start")
    SendNoEcho("ask ning about job")
    SendNoEcho("set huashan_teach ask_done")
  end

  function prototype:doTeach()
    SendNoEcho("set huashan_teach teach_start")
    SendNoEcho("zhidian " .. self.studentId)
    SendNoEcho("set huashan_teach teach_done")
  end

  function prototype:doWenhao()
    print("���ֶ�ִ���ʺ�����")
  end

  function prototype:doBeg()
    SendNoEcho("set huashan_teach beg_start")
    SendNoEcho("ask " .. self.studentId .. " about ָ��")
    SendNoEcho("set huashan_teach beg_done")
  end

  function prototype:doWaitAsk()
    print("�ȴ�10�����ѯ��")
    wait.time(10)
    return self:fire(Events.PAUSE_WAIT)
  end

  function prototype:doSubmit()
    SendNoEcho("set huashan_teach submit_start")
    SendNoEcho("ask ning about finish")
    SendNoEcho("set huashan_teach submit_done")
  end

  function prototype:doCancel()
    SendNoEcho("set huashan_teach cancel_start")
    SendNoEcho("ask ning about fail")
    SendNoEcho("set huashan_teach cancel_done")
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
      "huashan_teach_ask_start", "huashan_teach_ask_done",
      "huashan_teach_wait_ask",
      "huashan_teach_teaching_start", "huashan_teach_teaching_done",
      "huashan_teach_beg_start", "huashan_teach_beg_done",
      "huashan_teach_searching",
      "huashan_teach_submit_start", "huashan_teach_submit_done",
      "huashan_teach_wenhao")
  end

  function prototype:resetOnStop()
    self.studentCaught = false
    self.studentImproved = false
    self.studentEscaped = false
    self.studentPersuaded = false
    self.submitted = false
    self.studentName = nil
    self.wenhaoList = nil
    self.jobType = nil
    self.noJobAvailable = false
  end

  return prototype
end
return define_teach():FSM()


