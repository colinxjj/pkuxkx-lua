--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/4/24
-- Time: 7:58
-- To change this template use File | Settings | File Templates.
--

local patterns = {[[
ask ke about ����
����¹�ȿʹ����йء�����������Ϣ��
¹�ȿ�΢΢��׵�������׳ʿ��������
������������ʿ��ɱ���㣡
����һ��
    ������ʿ(Fanbang wushi)

qiao luo
��Ŀͻ��˲�֧��MXP,��ֱ�Ӵ����Ӳ鿴ͼƬ��
��ע�⣬������֤���еĺ�ɫ���֡�
http://pkuxkx.net/antirobot/robot.php?filename=149300907446041

����kouling����ش��������Ŀ��������󣬽��ܵ�һ���ͷ���

kouling ��԰
��ϲ�㣬����˿������������뿪�ˣ��㱻�����´ν���������ʱ�䱻��ǰ��һ���ӡ�

]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

local define_fsm = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    kill = "kill",
    recover = "recover",
  }
  local Events = {
    STOP = "stop",  -- any status -> stop
    START = "start",  -- stop -> ask
    ENTERED = "entered",  -- ask -> kill
    CAPTCHA = "captcha",  -- ask -> ask
    CLEARED = "cleared",  -- kill -> recover
    PREPARED = "prepared",  -- recover -> kill
    ABANDON = "abandon",  -- recover -> stop
  }
  local REGEXP = {
    ALIAS_START = "^wananta\\s+start\\s*$",
    ALIAS_STOP = "^wananta\\s+stop\\s*$",
    ALIAS_DEBUG = "^wananta\\s+debug\\s*(on|off)\\s*$",
    ENTERED = "^[ >]*¹�ȿ�΢΢��׵�������׳ʿ��������$",
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
    self:addTransition {
      oldState = States.stop,
      newState = States.ask,
      event = Events.START,
      action = function()
        return self:doAsk()
      end
    }
  end

  function prototype:initTriggers()
    helper.removeTriggerGroup("wananta_ask_start", "wananta_ask_done")
    helper.addTriggerSettingsPair {
      group = "wananta",
      start = "ask_start",
      done = "ask_done"
    }
    helper.addTrigger {
      group = "wananta_ask_done",

    }
  end

  function prototype:initAliases()

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
    helper.checkUntilNotBusy()
    travel:walkto(29)
    travel:waitUntilArrived()

    self:doPowerup()
    self.towerLevel = 1
    self.askSuccess = false
    SendNoEcho("set wananta ask_start")
    SendNoEcho("ask luzhang ke about ����")
    SendNoEcho("set wananta ask_done")
    helper.checkUntilNotBusy()

   end

  function prototype:doPowerup()

  end

  return prototype
end
return define_fsm():FSM()

