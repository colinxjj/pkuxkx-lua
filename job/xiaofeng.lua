--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/6/5
-- Time: 7:20
-- To change this template use File | Settings | File Templates.
--

local patterns = {[[
7

��������ɱ�ִ����йء�fight������Ϣ��
����ɱ��˵������Ҫ���򣬲��ض��ԣ���

ask xiao about job
������������йء�job������Ϣ��
������˵�ͷ���ã�
��Ŀͻ��˲�֧��MXP,��ֱ�Ӵ����Ӳ鿴ͼƬ��
��ע�⣬������֤���еĺ�ɫ���֡�
http://pkuxkx.net/antirobot/robot.php?filename=1496619389147359

����ɱ����ɫ΢�䣬˵������������������


-- sheng

��սʤ������ɱ��!
����ɱ�������̾�˿�����
������ɱ�����ϵ��˳���һֻ�쾦���
���ˣ���������������ݣ�
> ��������ɱ�ִ����йء����䡻����Ϣ��
����ɱ��˵�����������Ѿ������ˣ��㻹��ʲô����֮��������
> ����ɱ������ԶԶ��ȥ�ˡ�


ͻȻ�������ε�����˲��ƽ�����ɱ�֣����ƽ�����������ɱ�ַ��������������ƣ�

( ����ɱ���ƺ�ʮ��ƣ����������Ҫ�ú���Ϣ�ˡ� )������ɱ��(damage:+1154 wound:+384 ��Ѫ:49%/68%)��
( ����ɱ���Ѿ�һ��ͷ�ؽ����ģ������������֧����������ȥ�� )������ɱ��(damage:+668 ��Ѫ:31%/68%)��

����ɱ�����һ�ݣ��޺޵�˵���������ӱ���ʮ�겻����


��սʤ������ɱ��!
����ɱ�������̾�˿�����
������ɱ�����ϵ��˳���һЩ�ƽ�
���ˣ���������������ݣ�
> ��������ɱ�ִ����йء����䡻����Ϣ��
����ɱ��˵�����������Ѿ������ˣ��㻹��ʲô����֮��������

-- qin
������������йء�job������Ϣ��
������˵�ͷ���ã�
�����������������һƷ���ɳ�����������ɱ�֣�������������и����Ĵ����
          ��������ԭ������Ϊ���ã���ȥ�����ܻ����ｻ���ҡ�������֮����������������ֱ�ӵ���(dian)����
          �����书��ɲ⣬ǧ��С�ģ���
����������ļ磬˵���������ֵܣ��ͽ������ˣ����أ���



��սʤ������ɱ��!
���������䣿�ٺ٣���������ˣ�
> ����һ��ʱ�����������ȫ�ӽ��ŵ�ս����Χ�н��ѳ�����

���߽�����ɱ�֣�ֻ������ɱ�������ϼ���ӬͷС�֣���������ɱ��������

��սʤ�˺�������!
���������䣿�ٺ٣���������ˣ�

������������һ�����ȣ����ڵ���һ��Ҳ�����ˡ�

�㽫�������������������ڱ��ϡ�
>


-- quan
������������йء�job������Ϣ��
������˵�ͷ���ã�
�����������������һƷ���ɳ�����������ɱ�֣�����������һ���������ɽ·��
          ���˼�������һƷ�ò��ã��пɽ̻�����ȥȰȰ(quan)���ɡ�
          �����书��ǿ������׼����ȫ����
����������ļ磬˵���������ֵܣ��ͽ������ˣ����أ���


������ǰȥ����ͼȰ������ɱ�֣�������ɱ�ֲ��ͷ���ת�˸�����Ը����˵��ȥ��
������ѵ��ѵ�������ԣ�����Ч������á�
> ����ɱ���������˼���������ɫ�������ö��ˡ�

��ٺ�һЦ��������ɱ�֣��㶼���������أ����ػ���ִ�Բ��򣿡�
����ɱ�������̾�˿�����
����ɱ������ԶԶ��ȥ�ˡ�

ask xiao about finish
������������йء�finish������Ϣ��
����˵�������ܺá�ߣ�ֵܣ��������ˣ���
�㱻�����ˣ�
        ��ǧ��˵㾭�飻
        һǧ�Űٰ�ʮ����Ǳ�ܣ�
        һ����ʮһ�㽭��������
���Ѿ�������Ĵ�Ȱ��ɱ�ֵĹ�����
����˵��������Ҳ�Ｏ��һЩ�������Ѿ����˴�������ʻ�����
����˵��������Ȼ���࣬�����Ա����⡣��
�������ķݻ�ͭ�����ʡ���ll

ask xiao about finish
������������йء�finish������Ϣ��
����˵�������ܺá�ߣ�ֵܣ��������ˣ���
�㱻�����ˣ�
        һ����������ʮ���㾭�飻
        ��ǧ�İ�������Ǳ�ܣ�
        һǧһ��ʮ���㽭��������
���Ѿ�������Ĵ�սʤɱ�ֵĹ�����
����˵��������Ҳ�Ｏ��һЩ�������Ѿ����˴�������ʻ�����
����˵��������Ȼ���࣬�����Ա����⡣��
�������������������ʡ���

]]}


local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local captcha = require "pkuxkx.captcha"

local XiaofengMode = {
  KILL = 1,  -- ɱ
  CAPTURE = 2,  -- ��
  PERSUADE = 3,  -- Ȱ
  WIN = 4,  -- ʤ
}

local define_xiaofeng = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    search = "search",
    kill = "kill",
    persuade = "persuade",
    win = "win",
    capture = "capture",
    submit = "submit",
  }
  local Events = {
    STOP = "stop",  -- any state -> stop
    START = "start",  -- stop -> ask
    SEARCH = "search",
  }
  local REGEXP = {
    ALIAS_START = "^xiaofeng\\s+start\\s*$",
    ALIAS_STOP = "^xiaofeng\\s+stop\\s*$",
    ALIAS_DEBUG = "^xiaofeng\\s+debug\\s+(on|off)\\s*$",
--    ALIAS_CAPTURE = "^xiaofeng\\s+capture\\s+(.*)\\s*$",
--    ALIAS_PERSUADE = "^xiaofeng\\s+persuade\\s+(.*)\\s*$",
--    ALIAS_KILL = "^xiaofeng\\s+kill\\s+(.*)\\s*$",
--    ALIAS_WIN = "^xiaofeng\\s+win\\s+(.*)\\s*$",
    ALIAS_DO = "^xiaofeng\\s+(��|ɱ|Ȱ|��)\\s+(.*?)\\s*$",
    JOB_CAPTURE = "^ *��������ԭ������Ϊ���ã���ȥ�����ܻ����ｻ���ҡ�������֮������������.*$",
    JOB_PERSUADE = "^ *���˼�������һƷ�ò��ã��пɽ̻�����ȥȰȰ.*$",
    JOB_KILL = "^ *kill shashou$",
    JOB_WIN = "^ *win shashou$",
    JOB_CAPTCHA = "^��ע�⣬������֤���еĺ�ɫ���֡�$",
    WORK_TOO_FAST = "^work too fast$",
    PREV_NOT_FINISH = "^prev not finish$",
    MR_RIGHT = "^[ >]*����ɱ��˵������Ҫ���򣬲��ض��ԣ���$",
  }

  local JobRoomId = 7

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
    self.mode = nil
    self.DEBUG = true
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
    self:addTransition {

    }
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("xiaofeng_ask_start", "xiaofeng_ask_done")
    helper.addTriggerSettingsPair {
      group = "xiaofeng",
      start = "ask_start",
      done = "ask_done"
    }
    helper.addTrigger {
      group = "xiaofeng_ask_done",
      regexp = REGEXP.JOB_KILL,
      response = function()
        self.mode = XiaofengMode.KILL
      end
    }
    helper.addTrigger {
      group = "xiaofeng_ask_done",
      regexp = REGEXP.JOB_CAPTURE,
      response = function()
        self.mode = XiaofengMode.CAPTURE
      end
    }
    helper.addTrigger {
      group = "xiaofeng_ask_done",
      regexp = REGEXP.JOB_PERSUADE,
      response = function()
        self.mode = XiaofengMode.PERSUADE
      end
    }
    helper.addTrigger {
      group = "xiaofeng_ask_done",
      regexp = REGEXP.JOB_WIN,
      response = function()
        self.mode = XiaofengMode.WIN
      end
    }
    helper.addTriggerSettingsPair {
      group = "xiaofeng",
      start = "identify_start",
      done = "identify_done"
    }
    helper.addTrigger {
      group = "xiaofeng_identify_done",
      regexp = REGEXP.MR_RIGHT,
      response = function()
        self.identified = true
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("xiaofeng")
    helper.addAlias {
      group = "xiaofeng",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "xiaofeng",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "xiaofeng",
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
    helper.checkUntilNotBusy()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    wait.time(1)
    self.needCaptcha = false
    self.workTooFast = false
    self.prevNotFinish = false
    self.location = nil
    self.mode = nil
    SendNoEcho("set xiaofeng ask_start")
    SendNoEcho("ask xiaofeng about job")
    SendNoEcho("set xiaofeng ask_done")
    helper.checkUntilNotBusy()
    if self.needCaptcha then
      ColourNote("yellow", "", "���ֶ�������֤�룬xiaofeng Ȱ/��/��/ɱ �ص�")
      return
    elseif self.workTooFast then
      self:debug("�ȴ�8����ٴ�ѯ��")
      wait.time(8)
      return self:doGetJob()
    elseif self.prevNotFinish then
      self:debug("ǰ������û����ɣ�ȡ��֮")
      wait.time(1)
      SendNoEcho("ask xiao about fail")
      return self:doGetJob()
    end

    return self:fire(Events.SEARCH)
  end

  function prototype:doStart()
    return self:fire(Events.START)
  end

  return prototype
end
return define_xiaofeng():FSM()
