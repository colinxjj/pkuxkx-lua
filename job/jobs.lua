--
-- jobs.lua
-- User: zhe.jiang
-- Date: 2017/4/7
-- Desc:
-- Change:
-- 2017/4/7 - created

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

local Job = require "job.Job"
local JobDefinition = require "job.JobDefinition"
local songxin = require "job.songxin"

local patterns = {[[
l xiansuo
��ֵ�����(Qiguai xiansuo)
����һ�����Լ����µĵ�ͼ���ƺ�����ʲô��������ͼ����Ѷ���������о�(yanjiu)һ�¡�

yanjiu xiansuo
������Լ����ĵ�ͼ����ϸ�鿴����������λ�ô��˸�����ı�ǡ�
��Ŀͻ��˲�֧��MXP,��ֱ�Ӵ����Ӳ鿴ͼƬ��
��ע�⣬������֤���еĺ�ɫ���֡�
http://pkuxkx.net/antirobot/robot.php?filename=1491612793890973

�������ڵ���(zhao/xunzhao)һ��Ҳ���ܷ���ʲô��

zhao
���������ҵ���һ���书�ĵá�

l xinde
�书�ĵ�(Wugong xinde)
����һ����֪����׫д���书�ĵã�����Է���(kan)һ�¡�

kan xinde
�㿪ʼ��ϸ�Ķ������¸���Ů���������书�ĵá���
�Ķ����书�ĵú�������ڻ��ͨ����ѧ����һ��̨�ף����������ˣ�
�����ʮ����ʵս���飬
�����˵�Ǳ�ܡ�

]]}

local define_fsm = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    prepare = "prepare",
    wait = "wait",
    dining = "dining",
    store = "store",
    equip = "equip",
    job = "job",
  }
  local Events = {
    STOP = "stop",  -- any state -> stop
    START = "start",  -- stop -> prepare
    HUNGRY = "hungry",  -- prepare -> dining
    FULL = "full",  -- dining -> wait
    RICH = "rich",  -- prepare -> store
    POOR = "poor",  -- store -> poor
    TO_EQUIP = "to_equip", -- prepare -> equip
    EQUIPPED = "equipped",  -- equip -> prepare
    JOB_READY = "job_ready",  -- prepare -> job
    NO_JOB_AVAILABLE = "no_job_available",  -- prepare -> wait
    JOB_FINISH = "job_finish",  -- job -> wait
    PAUSE_WAIT = "pause_wait",  -- wait -> prepare
  }
  local REGEXP = {
    ALIAS_START = "^jobs\\s+start\\s*$",
    ALIAS_STOP = "^jobs\\s+stop\\s*$",
    ALIAS_DEBUG = "^jobs\\s+debug\\s+(on|off)\\s*$",
    CANNOT_STORE_MONEY = "^[ >]*��Ŀǰ���д��.*���ٴ���ô���Ǯ������С�ſ��ѱ����ˡ�$",
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
    self:initJobs()
    self:setState(States.stop)
    self.weaponId = "sword"
    self.silverThreshold = 300
    self.goldThreshold = 5
  end

  function prototype:disableAllTriggers()

  end

  function prototype:initJobs()
    self.jobs = {}
    self.jobs.songxin = Job:decorate {
      def = JobDefinition.songxin,
      impl = songxin
    }
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
        helper.enableTimerGroups("jobs_stop")
      end,
      exit = function()
        helper.disableTimerGroups("jobs_stop")
      end
    }
    self:addState {
      state = States.prepare,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.wait,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.dining,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.store,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.equip,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.job,
      enter = function() end,
      exit = function() end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.prepare,
      event = Events.START,
      action = function()
        return self:doPrepare()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<prepare>
    self:addTransition {
      oldState = States.prepare,
      newState = States.dining,
      event = Events.HUNGRY,
      action = function()
        return self:doDining()
      end
    }
    self:addTransition {
      oldState = States.prepare,
      newState = States.store,
      event = Events.RICH,
      action = function()
        return self:doStore()
      end
    }
    self:addTransition {
      oldState = States.prepare,
      newState = States.equip,
      event = Events.TO_EQUIP,
      action = function()
        return self:doEquip()
      end
    }
    self:addTransition {
      oldState = States.prepare,
      newState = States.job,
      event = Events.JOB_READY,
      action = function()
        assert(self.currJob, "current job cannot be nil")
        self.currJob.impl:doStart()
        self.currJob.impl:doWaitUntilDone()
        self:fire(Events.JOB_FINISH)
      end
    }
    -- transition from state<dining>
    self:addTransition {
      oldState = States.dining,
      newState = States.prepare,
      event = Events.FULL,
      action = function()
        return self:doPrepare()
      end
    }
    self:addTransitionToStop(States.dining)
    -- transition from state<store>
    self:addTransition {
      oldState = States.store,
      newState = States.prepare,
      event = Events.POOR,
      action = function()
        return self:doPrepare()
      end
    }
    self:addTransitionToStop(States.store)
    -- transition from state<job>
    self:addTransition {
      oldState = States.job,
      newState = States.prepare,
      event = Events.JOB_FINISH,
      action = function()
        helper.assureNotBusy()
        self:doPrepare()
      end
    }
    self:addTransitionToStop(States.job)
  end

  function prototype:initTriggers()

  end

  function prototype:initAliases()
    helper.removeAliasGroups("jobs")
    helper.addAlias {
      group = "jobs",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "jobs",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "jobs",
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

  function prototype:initTimers()
    helper.removeTimerGroups("jobs_stop")

    helper.addTimer {
      group = "jobs_stop",
      interval = 120,
      response = function()
        SendNoEcho("set jobs prevent_idle")
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

  function prototype:doPrepare()
    -- check status
    print("׼������")
    wait.time(1)
    helper.assureNotBusy()
    status:hpbrief()
    if status.food < 120 or status.drink < 120 then
      return self:fire(Events.HUNGRY)
    end
    print("ʳ����ˮ������")
    wait.time(1)
    status:money()
    if status.silvers > self.silverThreshold
      or status.golds > self.goldThreshold then
      self:debug(
        "���Ͻ�Ǯ�����޶",
        "gold:" .. status.golds,
        "silver:" .. status.silvers)
      return self:fire(Events.RICH)
    end

    wait.time(1)
    helper.assureNotBusy()
    self:doCheckWeapons()
    print("����װ�������ϣ������ƣ�")
    wait.time(1)
    helper.assureNotBusy()
    print("������Ϣ�����ϣ������ƣ�")
    -- ȷ������
    self.currJob = self.jobs["songxin"]
    return self:fire(Events.JOB_READY)
  end

  function prototype:doCheckWeapons()
    -- todo refine in future
  end

  function prototype:doCheckJobQuery()
    -- todo refine in future
  end

  --
  function prototype:doDining()
    travel:walkto(3798)
    travel:waitUntilArrived()
    helper.assureNotBusy()
    SendNoEcho("do 2 eat")
    helper.assureNotBusy()
    SendNoEcho("do 2 drink")
    helper.assureNotBusy()
    -- assume is full
    wait.time(1)
    return self:fire(Events.FULL)
  end

  function prototype:doEquip()
    -- todo refine in future
  end

  function prototype:doStore()
    print("׼��ǰ��Ǯׯ��Ǯ")
    wait.time(1)
    helper.assureNotBusy()
    return travel:walkto(91, function()
      wait.time(1)
      status:money()
      if status.silvers > self.silverThreshold then
        helper.assureNotBusy()
        SendNoEcho("convert " .. self.silverThreshold .. " silver to gold")
        wait.time(2)
        status:money()
      end
      if status.golds > self.goldThreshold then
        helper.assureNotBusy()
        SendNoEcho("cun " .. self.goldThreshold .. " gold")
      end
      local line = wait.regexp(REGEXP.CANNOT_STORE_MONEY, 3)
      if line then
        print("Ǯׯ�洢��������")
        return self:fire(Events.STOP)
      else
        return self:fire(Events.POOR)
      end
    end)
  end

  return prototype
end
return define_fsm():FSM()
