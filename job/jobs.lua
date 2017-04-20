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
-- 导入所有任务实现
local songxin = require "job.songxin"
local nanjue = require "job.nanjue"

local patterns = {[[
l xiansuo
奇怪的线索(Qiguai xiansuo)
这是一张你自己画下的地图，似乎藏着什么东西，地图深奥难懂，你可以研究(yanjiu)一下。

yanjiu xiansuo
你打开了自己画的地图，仔细查看……在以下位置打了个宝物的标记。
你的客户端不支持MXP,请直接打开链接查看图片。
请注意，忽略验证码中的红色文字。
http://pkuxkx.net/antirobot/robot.php?filename=1491612793890973

到了所在地找(zhao/xunzhao)一下也许能发现什么。

zhao
你在这里找到了一本武功心得。

l xinde
武功心得(Wugong xinde)
这是一本不知何人撰写的武功心得，你可以翻阅(kan)一下。

kan xinde
你开始仔细阅读大轮寺高手女神所著的武功心得……
阅读了武功心得后，你觉得融会贯通，武学更上一个台阶，从中你获得了：
五百三十三点实战经验，
五百零八点潜能。

]]}

local JobDefinition = require "job.JobDefinition"



local define_Job = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    local obj = {}
    obj.def = assert(args.def, "definition of job cannot be nil")
    local impl = assert(args.impl, "implementation cannot be nil")
    assert(type(impl.doStart) == "function", "doStart() of job implementation must be function")
    assert(type(impl.doCancel) == "function", "doStop() of job implementation must be function")
    assert(type(impl.getLastUpdateTime) == "function", "getLastUpdateTime() of job implementation must be function")
    assert(type(impl.precondition) == "table",
      "precondition of job implementation must be table, containing fields 'jing', 'qi', 'neili', 'jingli'")
    obj.impl = impl
    setmetatable(obj, self or prototype)
    self:postConstruct()
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.def, "definition of job cannot be nil")
    local impl = assert(obj.impl, "implementation cannot be nil")
    assert(type(impl.doStart) == "function", "doStart() of job implementation must be function")
    assert(type(impl.doCancel) == "function", "doStop() of job implementation must be function")
    assert(type(impl.getLastUpdateTime) == "function", "getLastUpdateTime() of job implementation must be function")
    assert(type(impl.precondition) == "table",
      "precondition of job implementation must be table, containing fields 'jing', 'qi', 'neili', 'jingli'")
    setmetatable(obj, self or prototype)
    self:postConstruct()
    return obj
  end

  function prototype:getPrecondition()
    return self.impl.precondition
  end

  function prototype:postConstruct()
    self.waitThread = nil
    self.stopped = true
  end

  function prototype:start()
    assert(self.stopped, "stopped flag must be true before start")
    self.stopped = false
    self.impl:doStart()  -- must be an async call
  end

  function prototype:stop()
    self.impl:doCancel()
    self.stopped = true
    helper.removeTimerGroups("jobs_one_shot")
  end

  function prototype:waitUntilDone()
    local antiIdle

    antiIdle = function()
      return coroutine.wrap(function()
        local currTime = os.time()
        if currTime - self:getLastUpdateTime() >= 300 then
          ColourNote("red", "", "停顿超过5分钟，强制取消任务")
          return self:cancel()
        elseif currTime - self:getLastUpdateTime() >= 180 then
          ColourNote("yellow", "", "停顿超过3分钟，警告")
        else
          print("等待60秒后继续查看状态")
        end
        if not self.stopped then
          local nextCheck = antiIdle()
          helper.addOneShotTimer {
            group = "jobs_one_shot",
            interval = 60,
            response = function()
              nextCheck()
            end
          }
        end
      end)
    end

    local nextCheck = antiIdle()
    helper.addOneShotTimer {
      group = "jobs_one_shot",
      interval = 60,
      response = function()
        nextCheck()
      end
    }

    local currCo = assert(coroutine.running(), "Must be in coroutine")
    helper.addOneShotTrigger {
      group = "jobs_one_shot",
      regexp = helper.settingRegexp("jobs", "job_done"),
      response = helper.resumeCoRunnable(currCo)
    }
    coroutine.yield()  -- this is a long-time yield and before this we need to periodically check status
    self.stopped = true
    helper.removeTimerGroups("jobs_one_shot")
  end

  function prototype:getLastUpdateTime()
    return self.impl:getLastUpdateTime()
  end

  return prototype
end
local Job = define_Job()




local define_jobs = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    prepare = "prepare",
    wait = "wait",
    dining = "dining",
    store = "store",
    equip = "equip",
    recover = "recover",
    job = "job",
  }
  local Events = {
    STOP = "stop",  -- any state -> stop
    START = "start",  -- stop -> prepare
    HUNGRY = "hungry",  -- prepare -> dining
    FULL = "full",  -- dining -> prepare
    RICH = "rich",  -- prepare -> store
    POOR = "poor",  -- store -> prepare
    TO_RECOVER = "to_recover",  -- prepare -> recover
    RECOVERED = "recovered",  -- recover -> prepare
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
    CANNOT_STORE_MONEY = "^[ >]*您目前已有存款.*，再存那么多的钱，我们小号可难保管了。$",
    CANNOT_DAZUO = "^[ >]*你正在运行内功加速全身气血恢复，无法静下心来搬运真气。$",
    CANNOT_RECOVER = "^[ >]*你正在运行真气加速气血恢复，无法再分出内力来。$",
    TUNA_BEGIN = "^[ >]*你盘膝坐下，开始吐纳炼精。$",
    DAZUO_BEGIN = "^[ >]*你坐下来运气用功，一股内息开始在体内流动。$",
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
    self:defineAllJobs()
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
    self.jobs.songxin = self.definedJobs.songxin
  end

  function prototype:defineAllJobs()
    self.definedJobs = {}
    self.definedJobs.songxin = Job:decorate {
      def = JobDefinition.songxin,
      impl = songxin
    }
    self.definedJobs.nanjue = Job:decorate {
      def = JobDefinition.nanjue,
      impl = nanjue
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
      state = States.recover,
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
      newState = States.recover,
      event = Events.TO_RECOVER,
      action = function()
        return self:doRecover()
      end
    }
    self:addTransition {
      oldState = States.prepare,
      newState = States.job,
      event = Events.JOB_READY,
      action = function()
        assert(self.currJob, "current job cannot be nil")
        self.currJob:start()
        self.currJob:waitUntilDone()
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
    -- transition from state<recover>
    self:addTransition {
      oldState = States.recover,
      newState = States.prepare,
      event = Events.RECOVERED,
      action = function()
        return self:doPrepare()
      end
    }
    self:addTransitionToStop(States.recover)
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
        print("停止 - 当前状态", self.currState)
      end
    }
  end

  function prototype:doPrepare()
    -- check status
    print("准备任务")
    wait.time(1)
    status:money()
    if status.silvers > self.silverThreshold
      or status.golds > self.goldThreshold then
      self:debug(
        "身上金钱超过限额：",
        "gold:" .. status.golds,
        "silver:" .. status.silvers)
      return self:fire(Events.RICH)
    end
    print("携带金钱检查完毕")
    wait.time(1)
    helper.assureNotBusy()
    self:doCheckWeapons()
    print("武器装备检查完毕（待完善）")
    wait.time(1)
    helper.assureNotBusy()
    print("任务信息检查完毕（待完善）")
    -- 确定任务
    self.currJob = self.jobs["songxin"]
    print("确定当前任务类型：", self.currJob.name)
    wait.time(1)
    helper.assureNotBusy()
    status:hpbrief()
    if status.food < 120 or status.drink < 120 then
      return self:fire(Events.HUNGRY)
    end
    print("食物饮水检查完毕")
    local precondition = self.currJob:getPrecondition()
    if status.effJing < precondition.jingPercent * status.maxJing - 1
      or status.currJingli < precondition.jingPercent * status.maxJingli - 1
      or status.effQi < precondition.qiPercent * status.maxQi - 1
      or status.currNeili < precondition.neiliPercent * status.maxNeili - 1 then
      return self:fire(Events.RECOVER)
    end
    print("身体状态检查完毕")
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
    print("准备前往钱庄存钱")
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
        print("钱庄存储金额到达上限")
        return self:fire(Events.STOP)
      else
        return self:fire(Events.POOR)
      end
    end)
  end

  function prototype:doRecover()
    local pct = self.currJob:getPrecondition()
    status:hpbrief()
    -- 先恢复精
    local neiliUsed = false
    if status.effJing < status.maxJing * pct.jing - 1 then
      SendNoEcho("do 2 yun inspire")
      neiliUsed = true
    end
    -- 再恢复气
    if status.effQi < status.maxQi * pct.qi - 1 then
      SendNoEcho("do 2 yun heal")
      neiliUsed = true
    end
    -- 先恢复内力
    if neiliUsed then status:hpbrief() end
    if status.currNeili < status.maxNeili * pct.neili - 1 then
      local diff = status.maxNeili * pct.neili - status.currNeili
      if diff > status.currQi - status.maxQi * 0.2 then
        SendNoEcho("dazuo max")
        local line = wait.regexp(REGEXP.DAZUO_BEGIN, 4)
        if not line then
          -- todo
          return self:doRecover()
        end
      else
        SendNoEcho("dazuo " .. math.floor(diff))
        local line = wait.regexp(REGEXP.DAZUO_BEGIN, 4)
        if not line then
          -- todo
          return self:doRecover()
        end
      end
      -- 再恢复精力
    elseif status.currJingli < status.maxJingli * pct.jingli - 1 then
      local diff = status.maxJingli * pct.jingli - status.currJingli
      if diff > status.currJing - status.maxJing * 0.2 then
        SendNoEcho("tuna max")
        local line = wait.regexp(REGEXP.TUNA_BEGIN, 4)
        if not line then
          -- todo
          return self:doRecover()
        end
      else
        SendNoEcho("tuna " .. math.floor(diff))
        local line = wait.regexp(REGEXP.TUNA_BEGIN, 4)
        if not line then
          -- todo
          return self:doRecover()
        end
      end
    end
    return self:fire(Events.RECOVERED)
  end

  return prototype
end
return define_jobs():FSM()

