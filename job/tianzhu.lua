--
-- tianzhu.lua
-- User: zhe.jiang
-- Date: 2017/4/23
-- Desc:
-- Change:
-- 2017/4/23 - created


local patterns = {[[

��������ʿ(lianhuasheng dashi)�����㣺���Ʋ�������ܼ����ڸ��ݵ����ҷ����������㲻��ȥ��һ����

��������֮�����ȡ�˳��������飬���԰���������������ʿ�����ˡ�

give dashi tian zhu
��������ʿĬĬ�ӹ������е����飬���ḧ���š�
> ��������ʿ������һö���飬�����������ڶ��������(pei)��������������ԡ�������Ϊ�����á�
��������ʿ��Ц����Ȼ��һ��ɽ�������������������棬��Ҳһ����ȥ�ɡ�
��������ʿ˵�����������������������оɣ������ȥ����������������еĹ��򡣡�

]]}


local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local captcha = require "pkuxkx.captcha"

local define_tianzhu = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    fight = "fight",
    submit = "submit",
  }
  local Events = {
    STOP = "stop",  -- any state -> stop
    START = "start",  -- stop -> ask
    GO = "go",  -- ask -> fight
    CAPTCHA = "captcha",  --> ask -> ask
    CANNOT_GO = "cannot_go",  -- ask -> stop
    BACK = "back",  -- fight -> submit
  }
  local REGEXP = {
    ALIAS_START = "^tianzhu\\s+start\\s*$",
    ALIAS_STOP = "^tianzhu\\s+stop\\s*$",
    ALIAS_DEBUG = "^tianzhu\\s+debug\\s+(on|off)\\s*$",
    ALIAS_SEARCH = "^tianzhu\\s+search\\s+(.+)$",
    ALIAS_BACK = "^tianzhu\\s+back\\s*$",
    JOB_INFO = "^[ >]*��������ʿ\\(lianhuasheng dashi\\)�����㣺���Ʋ�������ܼ�����(.*?)�������㲻��ȥ��һ����$",
    CAPTCHA = "^[ >]*��ע�⣬������֤���еĺ�ɫ���֡�$",
    REWARDED = "^[ >]*��������ʿ������һö���飬��������.*$",
    OBTAINED = "^[ >]*��������֮�����ȡ�˳��������飬���԰���������������ʿ�����ˡ�$",
    ZHENQI = "^[ >]*��������ʿ˵�����������������������оɣ������ȥ����������������еĹ��򡣡�$",
  }

  local JobRoomId = 1842

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

  function prototype:resetOnStop()
    self.needCaptcha = false
    self.targetLocation = nil
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
        helper.enableTriggerGroups("tianzhu_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("tianzhu_ask_start", "tianzhu_ask_done")
      end
    }
    self:addState {
      state = States.fight,
      enter = function()
        helper.enableTriggerGroups("tianzhu_fight")
      end,
      exit = function()
        helper.disableTriggerGroups("tianzhu_fight")
      end
    }
    self:addState {
      state = States.submit,
      enter = function() 
        helper.enableTriggerGroups("tianzhu_submit")
      end,
      exit = function() 
        helper.disableTriggerGroups("tianzhu_submit")
      end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransitionToStop(States.stop)
    self:addTransition {
      oldState = States.stop,
      newState = States.ask,
      event = Events.START,
      action = function()
        return self:doGetJob()
      end
    }
    -- transition from state<ask>
    self:addTransition {
      oldState = States.ask,
      newState = States.stop,
      event = Events.CANNOT_GO,
      action = function()
        return self:doCancel()
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.fight,
      event = Events.GO,
      action = function()
        assert(self.targetLocation, "target location cannot be nil")
        return self:doGo()
      end
    }
    self:addTransitionToStop(States.ask)
    -- transition from state<fight>
    self:addTransition {
      oldState = States.fight,
      newState = States.submit,
      event = Events.BACK,
      action = function()
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.fight)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("tianzhu_ask_start", "tianzhu_ask_done", "tianzhu_submit")
    helper.addTriggerSettingsPair {
      group = "tianzhu",
      start = "ask_start",
      done = "ask_done",
    }
    helper.addTrigger {
      group = "tianzhu_ask_done",
      regexp = REGEXP.JOB_INFO,
      response = function(name, line, wildcards)
        self:debug("JOB_INFO triggered")
        self.targetLocation = wildcards[1]
      end
    }
    helper.addTrigger {
      group = "tianzhu_ask_done",
      regexp = REGEXP.CAPTCHA,
      response = function()
        self.needCaptcha = true
      end
    }

    helper.addTrigger {
      group = "tianzhu_fight",
      regexp = REGEXP.OBTAINED,
      response = function()
        SendNoEcho("get silver from corpse")
        SendNoEcho("get silver from corpse 2")
        SendNoEcho("get silver from corpse 3")
        SendNoEcho("get silver from corpse 4")
        SendNoEcho("get silver from corpse 5")
        ColourNote("green", "", "�ѻ�ȡ���飬����������tianzhu back")
      end
    }

    helper.addTrigger {
      group = "tianzhu_submit",
      regexp = REGEXP.REWARDED,
      response = function()
        ColourNote("green", "", "������ɣ����(pei)������(break)����")
        wait.time(1)
        return self:fire(Events.STOP)
      end
    }
    helper.addTrigger {
      group = "tianzhu_submit",
      regexp = REGEXP.ZHENQI,
      response = function()
        ColourNote("lime", "", "��ȥѯ������")
        ColourNote("lime", "", "��ȥѯ������")
        ColourNote("lime", "", "��ȥѯ������")
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("tianzhu")
    helper.addAlias {
      group = "tianzhu",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "tianzhu",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "tianzhu",
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
      group = "tianzhu",
      regexp = REGEXP.ALIAS_SEARCH,
      response = function(name, line, wildcards)
        self.targetLocation = wildcards[1]
        return self:fire(Events.GO)
      end
    }
    helper.addAlias {
      group = "tianzhu",
      regexp = REGEXP.ALIAS_BACK,
      response = function()
        return self:doSubmit()
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
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    wait.time(1)
    self.targetLocation = nil
    self.needCaptcha = false
    SendNoEcho("set tianzhu ask_start")
    SendNoEcho("ask dashi about job")
    SendNoEcho("set tianzhu ask_done")
    helper.checkUntilNotBusy()
    if self.targetLocation then
      return self:fire(Events.GO)
    elseif self.needCaptcha then
      ColourNote("yellow", "", "���ֶ�������֤�룬��ʽΪ��tianzhu search <�ص�>")
    else
      print("δ��ȡ��������Ϣ���ȴ�8������ѯ��")
      wait.time(8)
      return self:doGetJob()
    end
  end

  function prototype:doCancel()
    ColourNote("red", "", "���ֶ�ȡ������")
  end

  function prototype:doGo()
    travel:walktoFirst {
      fullname = self.targetLocation
    }
    travel:waitUntilArrived()
    print("����Ŀ�ĵ�")
  end

  function prototype:doSubmit()
    travel:stop()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    wait.time(1)
    SendNoEcho("give dashi tian zhu")
    wait.time(1)
    helper.checkUntilNotBusy()
    return self:fire(Events.STOP)
  end

  return prototype
end
return define_tianzhu():FSM()
