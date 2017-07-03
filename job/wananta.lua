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
local combat = require "pkuxkx.combat"
local recover = require "pkuxkx.recover"

local define_wananta = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    kill = "kill",
  }
  local Events = {
    STOP = "stop",  -- any status -> stop
    START = "start",  -- stop -> ask
    ENTERED = "entered",  -- ask -> kill
    CAPTCHA = "captcha",  -- ask -> ask
    NEXT = "next",  -- kill -> kill
  }
  local REGEXP = {
    ALIAS_START = "^wananta\\s+start\\s*$",
    ALIAS_STOP = "^wananta\\s+stop\\s*$",
    ALIAS_DEBUG = "^wananta\\s+debug\\s*(on|off)\\s*$",
    ENTERED = "^[ >]*¹�ȿ�΢΢��׵�.*��������$",
    NOBODY_TO_KILL = "^[ >]*����û������ˡ�$",
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

    self.maxFloor = 3
    self:resetOnStop()
    self.precondition = {
      jing = 1,
      qi = 1,
      neili = 1.6,
      jingli = 1
    }
  end

  function prototype:resetOnStop()
    self.allKilled = false
    self.entered = false
    self.floor = 1
  end

  function prototype:disableAllTriggers()

  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
        self:resetOnStop()
      end,
      exit = function() end
    }
    self:addState {
      state = States.ask,
      enter = function()
        helper.enableTriggerGroups("wananta_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("wananta_ask_start", "wananta_ask_done")
      end
    }
    self:addState {
      state = States.kill,
      enter = function()
        combat:start()
        helper.enableTriggerGroups("wananta_kill")
      end,
      exit = function()
        helper.disableTriggerGroups("wananta_kill")
        combat:stop()
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
      newState = States.kill,
      event = Events.ENTERED,
      action = function()
        return self:doKill()
      end
    }
    self:addTransitionToStop(States.ask)
    -- transition from state<kill>
    self:addTransition {
      oldState = States.kill,
      newState = States.kill,
      event = Events.NEXT,
      action = function()
        self.floor = self.floor + 1
        SendNoEcho("up")
        return self:doKill()
      end
    }
    self:addTransitionToStop(States.kill)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("wananta_ask_start", "wananta_ask_done")
    helper.addTriggerSettingsPair {
      group = "wananta",
      start = "ask_start",
      done = "ask_done"
    }
    helper.addTrigger {
      group = "wananta_ask_done",
      regexp = REGEXP.ENTERED,
      response = function()
        self.entered = true
      end
    }
    helper.addTrigger {
      group = "wananta_kill",
      regexp = REGEXP.NOBODY_TO_KILL,
      response = function()
        self.allKilled = true
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("wananta")
    helper.addAlias {
      group = "wananta",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:doStart()
      end
    }
    helper.addAlias {
      group = "wananta",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
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

  function prototype:doAsk()
    helper.checkUntilNotBusy()
    travel:walkto(29)
    travel:waitUntilArrived()

    SendNoEcho("yun powerup")
    SendNoEcho("yun shield")
    self.towerLevel = 1
    self.askSuccess = false
    SendNoEcho("follow none")
    SendNoEcho("set wananta ask_start")
    SendNoEcho("ask luzhang ke about ����")
    SendNoEcho("set wananta ask_done")
    helper.checkUntilNotBusy()
    if not self.entered then
      ColourNote("yellow", "", "�޷�����������ʧ��")
      wait.time(2)
      return self:fire(Events.STOP)
    else
      return self:fire(Events.ENTERED)
    end
  end

  function prototype:doKill()
    self.allKilled = false
    SendNoEcho("kill wu shi")
    while true do
      wait.time(5)
      if self.allKilled then
        break
      else
        SendNoEcho("kill wu shi")
      end
    end
    self:debug("�����ѱ��������ǰ������" .. self.floor)
    if self.floor < self.maxFloor then
      recover:settings {
        jingLowerBound = self.precondition.jing,
        jingUpperBound = self.precondition.jing,
        qiLowerBound = self.precondition.qi,
        qiUpperBound = self.precondition.qi,
        neiliThreshold = self.precondition.neili,
        jingliThreshold = self.precondition.jingli,
      }
      recover:start()
      recover:waitUntilRecovered()
      return self:fire(Events.NEXT)
    else
      SendNoEcho("qiao luo")
      SendNoEcho("kouling С��")
      SendNoEcho("qiao luo")
      wait.time(1)
      helper.checkUntilNotBusy()
      return self:fire(Events.STOP)
    end
  end

  function prototype:doStart()
    return self:fire(Events.START)
  end

  return prototype
end
return define_wananta():FSM()

