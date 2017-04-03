--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/19
-- Time: 17:33
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

local define_learn = function()
  local prototype = FSM.inheritedMeta()
  prototype.__index = prototype

  local States = {
    stop = "stop",
    learn = "learn",
    sleep = "sleep",
    exercise = "exercise",
    dining = "dining",
  }
  local Events = {
    STOP = "stop",
    START = "start",
    HUNGRY = "hungry",
    FULL = "full",
    BAD_STATUS = "bad_status",
    WAKE_UP = "wake_up",
    PAUSE_EXERCISE = "pause_exercise",
    NO_MASTER = "no_master",
  }

  local REGEXP = {
    ALIAS_LEARN = "^learning\\s*$",
    ALIAS_LEARN_DEBUG = "^learning\\s+debug\\s*$",
    ALIAS_LEARN_START = "^learning\\s+start\\s*$",
    ALIAS_LEARN_STOP = "^learning\\s+stop\\s*$",
    AWAKE = "^[ >]*��һ�������������ӵػ�˼����ֽš�$",
    SLEEPED = "^[ >]*��������һ�ɣ���ʼ˯����$",
    SLEEP_TOO_MUCH = "^[ >]*�������������˯��һ��, ��˯�������к�����!\\s*$",
    NO_MASTER = "^[ >]*�㸽��û�� (.*) ����ˣ����� id here ָ�����Χ���� id ��$",
    DZ_BEGIN = "^[ >]*����ϥ���£�Ĭ�˻�ɽ�ڹ���һ����Ϣ�Ե�����������$",
    DZ_FINISH = "^[ >]*�㽫��ת���ζ����������Ϣ�ջص���������˿�����վ��������$",
    DZ_NEILI_ADDED = "^[ >]*������������ˣ���$",
    NOT_ENOUGH_QI = "^[ >]*�����ڵ���̫���ˣ��޷�������Ϣ����ȫ������$"
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
    self.masterExists = true
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.learn,
      enter = function()
        helper.enableTriggerGroups("learn_learn")
        self.masterExists = true
      end,
      exit = function()
        helper.disableTriggerGroups("learn_learn")
        self.masterExists = true
      end
    }
    self:addState {
      state = States.sleep,
      enter = function()
        helper.enableTriggerGroups("learn_sleep")
      end,
      exit = function()
        helper.disableTriggerGroups("learn_sleep")
      end
    }
    self:addState {
      state = States.exercise,
      enter = function()
        helper.enableTriggerGroups("learn_exercise")
      end,
      exit = function()
        helper.disableTriggerGroups("learn_exercise")
      end
    }
    self:addState {
      state = States.dining,
      enter = function() end,
      exit = function() end
    }
  end

  function prototype:initTransitions()
    -- transitions from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.learn,
      event = Events.START,
      action = function()
        travel:walkto(2920, function()
          self:doLearnUntilBadStatus()
        end)
      end
    }
    self:addTransitionToStop(States.stop)
    -- transitions from state<learn>
    self:addTransition {
      oldState = States.learn,
      newState = States.sleep,
      event = Events.BAD_STATUS,
      action = function()
        travel:walkto(2921, function()
          self:doSleepUntilFallAsleep()
        end)
      end
    }
    self:addTransition {
      oldState = States.learn,
      newState = States.exercise,
      event = Events.NO_MASTER,
      action = function()
        travel:walkto(2921, function()
          self:doExerciseUntilSatisfied()
        end)
      end
    }
    self:addTransitionToStop(States.learn)
    -- transitions from state<sleep>
    self:addTransition {
      oldState = States.sleep,
      newState = States.dining,
      event = Events.HUNGRY,
      action = function()
        self:doEatUntilFull()
      end
    }
    self:addTransition {
      oldState = States.sleep,
      newState = States.exercise,
      event = Events.WAKE_UP,
      action = function()
        local run = coroutine.wrap(function()
          self:doExerciseUntilSatisfied()
        end)
        run()
      end
    }
    self:addTransitionToStop(States.sleep)
    -- transitions from state<dining>
    self:addTransition {
      oldState = States.dining,
      newState = States.learn,
      event = Events.FULL,
      action = function()
        travel:walkto(2920, function()
          self:doLearnUntilBadStatus()
        end)
      end
    }
    self:addTransitionToStop(States.dining)
    -- transitions from state<exercise>
    self:addTransition {
      oldState = States.exercise,
      newState = States.learn,
      event = Events.PAUSE_EXERCISE,
      action = function()
        travel:walkto(2920, function()
          self:doLearnUntilBadStatus()
        end)
      end
    }
    self:addTransitionToStop(States.exercise)
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

  function prototype:initTriggers()
    helper.removeTriggerGroups("learn_sleep", "learn_exercise")
    helper.addTrigger {
      group = "learn_sleep",
      regexp = REGEXP.AWAKE,
      response = function()
        status:hpbrief()
        if status.food < 50 or status.drink < 50 then
          return self:fire(Events.HUNGRY)
        else
          return self:fire(Events.WAKE_UP)
        end
      end
    }
    helper.addTrigger {
      group = "learn_learn",
      regexp = REGEXP.NO_MASTER,
      response = function()
        self.masterExists = false
      end
    }
    helper.addTrigger {
      group = "learn_exercise",
      regexp = REGEXP.DZ_NEILI_ADDED,
      response = function()
        return self:fire(Events.PAUSE_EXERCISE)
      end
    }
    helper.addTrigger {
      group = "learn_exercise",
      regexp = REGEXP.DZ_FINISH,
      response = function()
        self:dzOrDazuoIfEnoughQi()
      end
    }
    helper.addTrigger {
      group = "learn_exercise",
      regexp = REGEXP.NOT_ENOUGH_QI,
      response = function()
        DoAfter(5, "dz max")
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("learn")
    helper.addAlias {
      group = "learn",
      regexp = REGEXP.ALIAS_LEARN,
      response = function()
        print("LEARNѧϰָ���÷����£�")
        print("learn start", "��ʼѧϰ")
        print("learn stop", "����ѧϰ")
        print("learn debug (on|off)", "����/�رյ���ģʽ")
      end
    }
    helper.addAlias {
      group = "learn",
      regexp = REGEXP.ALIAS_LEARN_START,
      response = function()
        self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "learn",
      regexp = REGEXP.ALIAS_LEARN_STOP,
      response = function()
        self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "learn",
      regexp = REGEXP.ALIAS_LEARN_DEBUG,
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

  function prototype:doLearnUntilBadStatus()
    while self.masterExists do
      status:hpbrief()
      status:show()
      --print("currNeili", status.currNeili)
      if status.currNeili > 80 then
        SendNoEcho("yun regenerate")
        SendNoEcho("xue yue for " .. self.skill .. " 50")
        SendNoEcho()
      elseif status.currJing > 100 then
        SendNoEcho("xue yue for " .. self.skill .. " 10")
      else
        return self:fire(Events.BAD_STATUS)
      end
      wait.time(1)
    end
    --error("Master not exists")
    return self:fire(Events.NO_MASTER)
  end

  function prototype:doSleepUntilFallAsleep()
    while true do
      SendNoEcho("sleep")
      local line = wait.regexp(REGEXP.SLEEPED, 5)
      if line then break end
    end
  end

  function prototype:doEatUntilFull()
    travel:walkto(3798, function()
      helper.assureNotBusy()
      SendNoEcho("do 2 eat")
      helper.assureNotBusy()
      SendNoEcho("do 2 drink")
      helper.assureNotBusy()
      wait.time(3)
      return self:fire(Events.FULL)
    end)
  end

  function prototype:doExerciseUntilSatisfied()
    while true do
      SendNoEcho("dz max")
      local line = wait.regexp(REGEXP.DZ_BEGIN, 5)
      if line then break end
    end
  end

  function prototype:dzOrDazuoIfEnoughQi()
    status:hpbrief()
    local diff = status.maxNeili * 2 - status.currNeili + 1
    print("����Ҫ" .. diff .. "��������ǰ��" .. status.currQi)
    if diff < status.currQi + 50 then
      SendNoEcho("dazuo " .. diff)
    else
      SendNoEcho("dz max")
    end
--    SendNoEcho("dz max")
  end

  return prototype
end

return define_learn():FSM()