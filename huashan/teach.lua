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

local p1 = "һ��һʽ�а����ۣ�����Ի�ȥ�����������ˡ�"

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

���������㱻�����ˣ�

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
  }
  local REGEXP = {
    NEW_JOB_TEACH = "^[ >]*���������˵���������ɽ����Щ�µ��ӣ����ȥ������ָ��\\(zhidian\\)һ�°ɡ�$",
    NEW_JOB_WENHAO = "^[ >]*���������㣬�����þ�û�м���(.*?) ��Щ���ˣ����ڽ����У����������Щǰ���е�һ�������������ʸ���\\(wenhao\\)�ɣ�������Ʒ��������\\s*$",
    STUDENT_FOLLOWED = "^[ >]*(.*)������ʼ������һ���ж���$",
    PREV_JOB_NOT_FINISH = "^[ >]*����ɺ˵���������ϴ�����û������أ���$",
    NEXT_JOB_WAIT = "^[ >]*����ɺ˵����������æ���������Ұɡ���$",
    NEXT_JOB_TOO_FAST = "^[ >]*����ɺ˵����������æ���������Ұɡ���$",
    -- EXP_TOO_HIGH = "^[ >]*����ɺ˵��������Ĺ��򲻴��ˣ������￴����ʲô���񽻸��㡣��$",
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
    SUBMIT_START = "^[ >]*�趨����������huashan_patrol = \"submit_start\"$",
    SUBMIT_DONE = "^[ >]*�趨����������huashan_patrol = \"submit_done\"$",
    SUBMIT_SUCCESS = "^[ >]*���������㱻�����ˣ�$",
    NOT_BUSY = "^[ >]*�����ڲ�æ��$",
    DZ_FINISH = "^[ >]*�㽫��ת���ζ����������Ϣ�ջص���������˿�����վ��������$",
    DZ_NEILI_ADDED = "^[ >]*������������ˣ���$"
  }
  local teacherId = "scala"
  local teacherName = "˹����"

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

      end,
      exit = function()

      end
    }
    self:addState {
      state = States.searching,
      enter = function()
        self.studentCaught = false
      end,
      exit = function()
        self.studentCaught = false
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
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.ask,
      event = Events.START,
      action = function()
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
        travel:walto(2921, function()
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
    -- transition from state<teaching>
    self:addTransition {
      oldState = States.teaching,
      newState = States.teaching,
      event = Events.CONTINUE_TEACH,
      action = function()
        -- ÿ�ν̵����2��
        wait.time(2)
        self:doTeach()
      end
    }
    self:addTransition {
      oldState = States.teaching,
      newState = States.searching,
      event = Events.STUDENT_ESCAPED,
      action = function()
        travel:traverse {
          rooms = travel:getNearbyRooms(8),
          check = function()
            return self:catchStudent()
          end,
          action = function()
            if self.studentCaught then
              return self:fire(Events.STUDENT_FOUND)
            else
              return self:fire(Events.STUDENT_NOT_FOUND)
            end
          end
        }
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
        time.wait(1)
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
        wait.time(3)
        self:doAsk()
      end
    }
    self:addTransitionToStop(States.submit)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "huashan_teach_ask_start", "huashan_teach_ask_done",
      "huashan_teach_wait_ask",
      "huashan_teach_teaching_start", "huashan_teach_teaching_done",
      "huashan_teach_beg_start", "huashan_teach_beg_done",
      "huashan_teach_submit_start", "huashan_teach_submit_done",
      "huashan_teach_wenhao_start", "huashan_teach_wenhao_done")
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
        local patterns = utils.split(wildcards[1], " ")
        local players = {}
        for _, pattern in ipairs(patterns) do
          local str = utils.split(pattern, "(")
          local name = str[1]
          local id = string.gsub(str[2], ")", "")
          table.insert(players, {name=name, id=id})
        end
        self.wenhaoList = players
        self.jobType = "wenhao"
      end
    }
    -- ����������
    helper.addTrigger {
      group = "huashan_teach_ask_done",
      regexp = REGEXP.ASK_DONE,
      response = function()
        if self.jobType == "teach" then
          self:fire(Events.NEW_TEACH)
        else
          self:fire(Events.NEW_WENHAO)
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
          self:fire(Events.STUDENT_IMPROVED)
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
      response = function()
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
  end

  function prototype:initAliases() end

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

  end

  function prototype:doWaitAsk()
    SendNoEcho("dz max")
  end

  function prototype:doSubmit()
    SendNoEcho("set huashan_teach submit_start")
    SendNoEcho("ask ning about finish")
    SendNoEcho("set huashan_teach submit_done")
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
      "huashan_teach_ask_start", "huashan_teach_ask_done",
      "huashan_teach_teaching_start", "huashan_teach_teaching_done",
      "huashan_teach_beg_start", "huashan_teach_beg_done",
      "huashan_teach_submit_start", "huashan_teach_submit_done",
      "huashan_teach_wenhao_start", "huashan_teach_wenhao_done",
      "huashan_teach_wait_ask")
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
  end

  return prototype
end
return define_teach().FSM()


