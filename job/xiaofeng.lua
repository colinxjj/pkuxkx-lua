--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/6/5
-- Time: 7:20
-- To change this template use File | Settings | File Templates.
--

local patterns = {[[
7

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
    stop = "stop"
  }
  local Events = {
    STOP = "stop",
    START = "start"
  }
  local REGEXP = {
    ALIAS_START = "^xiaofeng\\s+start\\s*$",
    ALIAS_STOP = "^xiaofeng\\s+stop\\s*$",
    ALIAS_DEBUG = "^xiaofeng\\s+debug\\s+(on|off)\\s*$",
    ALIAS_CAPTURE = "^xiaofeng\\s+capture\\s+(.*)\\s*$",
    ALIAS_PERSUADE = "^xiaofeng\\s+persuade\\s+(.*)\\s*$",
    ALIAS_KILL = "^xiaofeng\\s+kill\\s+(.*)\\s*$",
    ALIAS_WIN = "^xiaofeng\\s+win\\s+(.*)\\s*$",
    JOB_CAPTURE = "^ *��������ԭ������Ϊ���ã���ȥ�����ܻ����ｻ���ҡ�������֮������������.*$",
    JOB_PERSUADE = "^ *���˼�������һƷ�ò��ã��пɽ̻�����ȥȰȰ.*$",
    JOB_KILL = "^ *kill shashou$",
    JOB_WIN = "^ *win shashou$",
    JOB_CAPTCHA = "^��ע�⣬������֤���еĺ�ɫ���֡�$",
    WORK_TOO_FAST = "^work too fast$",
    PREV_NOT_FINISH = "^prev not finish$",
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

    self.mode = nil

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
    self:addTransitionToStop(States.stop)
    self:addTransition {
      oldState = States.stop,

    }
  end

  function prototype:initTriggers()

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

  return prototype
end
return define_xiaofeng():FSM()
