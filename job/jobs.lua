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
local murong = require "job.murong"
local touxue = require "job.touxue"
local tianzhu = require "job.tianzhu"
local cisha = require "job.cisha"
local huyidao = require "job.huyidao"
local wananta = require "job.wananta"

-- 帮会任务
local banghui = require "common.banghui"
local captcha = require "pkuxkx.captcha"

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

│[01][门]门忠任务                未接受任务。                                                  │
│[02][门]门派任务                未接受任务。                                                  │
│[03][新]送信                    未接受任务。                                                  │
│[04][新]唱戏任务                未接受任务。                                                  │
│[05][新]灵柩护卫                未接受任务。                                                  │
│[06][主]慕容任务(0)             现在即可接到下个任务。                                        │
│[07][主]韩员外复仇(0)           现在即可接到下个任务。                                        │
│[08][主]都统制府刺杀(0)         现在即可接到下个任务。                                        │
│[09][主]运镖任务(0)             现在即可接到下个新手镖局的任务。                              │
│[10][主]胡一刀任务(0)           现在即可接到下个任务。                                        │
│[11][主]萧峰任务(0)             现在即可接到下个任务。                                        │
│[12][主]韩世忠任务(0)           现在即可接到下个任务。                                        │
│[13][主]公孙止任务(0)           现在即可接到下个任务。                                        │
│[14][主]万安塔任务(0) ↑        现在即可接到下个任务。                                        │
│[15][主]破阵任务(0)             现在即可接到下个任务。                                        │
│[16][主]天珠任务(0)             现在即可接到下个任务。                                        │
│[17][主]偷学任务(0)             现在即可接到下个任务。                                        │
│[18][主]华山送信任务(0)         现在即可接到下个任务。                                        │
│[19][主]投名状任务(0)           现在即可接到下个任务。                                        │
│[20][主]萧半和任务(0)           未接受任务。                                                  │
│[21][主]鄱阳湖寻宝(0)           现在即可接到下个任务。                                        │
│[22][特]锻造任务                未接受任务。                                                  │
│[23][特]满不懂任务              未接受任务。                                                  │
│[24][特]铜雀台任务              现在即可接到下个任务。                                        │
│[25][特]百晓生任务              现在即可接到下个任务。                                        │
│[26][特]公孙绿萼任务            现在即可接到下个任务。                                        │

村民告诉你：华容道最近被一伙山贼占据，没事最好绕道而行。
一个山贼跳了出来，阴恻恻地对你道：此山是我开，此树是我栽，要想过此路，留下买路财。
山贼往襄阳的乡间土路附近逃离。

杀    气：  紊乱
杀    气：  偏高

chanhui
你双膝跪地，两眼紧闭，口中念念有词，脸上充满悔恨之意。

> 你感觉心中的杀气渐渐消失......

│[01][门]门忠任务                未接受任务。                                                  │
│[06][主]慕容(1005)              你要去找回在未知区域出现的慕容复写给江湖豪杰的信件。          │
│[07][主]韩员外(10) 55.6%        现在即可接到下个任务。                                        │
│[08][主]都府刺杀(10) 90.9%      现在即可接到下个任务。                                        │
│[09][主]运镖(1096) 2.9%         现在即可接到下个普通镖局的任务。                              │
│[10][主]胡一刀(10) 100.0%       现在即可接到下个任务。                                        │
│[11][主]萧峰(14) 48.3%          现在即可接到下个任务。                                        │
│[12][主]韩世忠(247) 91.5%       现在即可接到下个任务。                                        │
│[13][主]公孙止(0)               现在即可接到下个任务。                                        │
│[14][主]万安塔(125) 89.3%       现在即可接到下个任务。                                        │
│[15][主]破阵(10) 44.4%          现在即可接到下个任务。                                        │
│[16][主]天珠(74) 82.2%          现在即可接到下个任务。                                        │
│[17][主]偷学(25) 80.6%          仍需二分四十二秒才能接到下个任务。                            │
│[18][主]华山送信任务(269)       现在即可接到下个任务。                                        │
│[19][主]投名状任务(10)          现在即可接到下个任务。                                        │
│[21][主]鄱阳湖寻宝(0)           现在即可接到下个任务。                                        │
│[24][特]铜雀台任务              现在即可接到下个任务。                                        │
│[25][特]百晓生任务              现在即可接到下个任务。                                        │

]]}

local define_JobDefinition = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    local obj = {}
    obj.id = assert(args.id, "id of job cannot be nil")
    obj.name = assert(args.name, "name of job cannot be nil")
    obj.code = assert(args.code, "code of job cannot be nil")
    obj.times = args.times or 0
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.id, "id of job cannot be nil")
    assert(obj.name, "name of job cannot be nil")
    assert(obj.code, "code of job cannot be nil")
    obj.times = obj.times or 0
    setmetatable(obj, self or prototype)
    return obj
  end

  -- define all the jobs
  prototype.menzhong = prototype:decorate {
    id = 1,
    name = "门忠任务",
    code = "menzhong"
  }
  prototype.murong = prototype:decorate {
    id = 6,
    name = "慕容",
    code = "murong"
  }
  prototype.hanyuanwai = prototype:decorate {
    id = 7,
    name = "韩元外",
    code = "hanyuanwai"
  }
  prototype.cisha = prototype:decorate {
    id = 8,
    name = "都府刺杀",
    code = "cisha"
  }
  prototype.hubiao = prototype:decorate {
    id = 9,
    name = "运镖",
    code = "hubiao"
  }
  prototype.huyidao = prototype:decorate {
    id = 10,
    name = "胡一刀",
    code = "huyidao"
  }
  prototype.xiaofeng = prototype:decorate {
    id = 11,
    name = "萧峰",
    code = "xiaofeng"
  }
  prototype.hanshizhong = prototype:decorate {
    id = 12,
    name = "韩世忠",
    code = "hanshizhong"
  }
  prototype.gongsunzhi = prototype:decorate {
    id = 13,
    name = "公孙止",
    code = "gongsunzhi"
  }
  prototype.wananta = prototype:decorate {
    id = 14,
    name = "万安塔",
    code = "wananta"
  }
  prototype.pozhen = prototype:decorate {
    id = 15,
    name = "破阵",
    code = "pozhen"
  }
  prototype.tianzhu = prototype:decorate {
    id = 16,
    name = "天珠",
    code = "tianzhu",
  }
  prototype.touxue = prototype:decorate {
    id = 17,
    name = "偷学",
    code = "touxue"
  }
  prototype.songxin = prototype:decorate {
    id = 18,
    name = "华山送信任务",
    code = "songxin"
  }
  prototype.toumingzhuang = prototype:decorate {
    id = 19,
    name = "投名状任务",
    code = "toumingzhuang"
  }
  prototype.poyanghu = prototype:decorate {
    id = 20,
    name = "鄱阳湖寻宝",
    code = "poyanghu"
  }
  prototype.nanjue = prototype:decorate {
    id = -1,  -- 不在jobquery中
    name = "长安男爵任务",
    code = "nanjue"
  }

  return prototype
end
local JobDefinition = define_JobDefinition()

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
    assert(type(impl.doCancel) == "function", "doCancel() of job implementation must be function")
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
    self.cancelThreshold = 3600
    self.warnThreshold = 600
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
        if currTime - self:getLastUpdateTime() >= self.cancelThreshold then
          ColourNote("red", "", "停顿超过5分钟，强制取消任务")
          return self.impl:doCancel()
        elseif currTime - self:getLastUpdateTime() >= self.warnThreshold then
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
    DAZUO_FINISH = "^[ >]*你运功完毕，深深吸了口气，站了起来。$",
    TUNA_FINISH = "^[ >]*你吐纳完毕，睁开双眼，站了起来。$",
    JOB_QUERY = "^│\\[(\\d+)\\]\\[(.*?)\\]([^\\)]+)\\((\\d+)\\)\\s+([\\d\\.]*%)?\\s+(.*?)\\s+│$",
  }

  -- 牛肉面馆
  local DiningRoomId = 3797
  -- 嘉兴钱庄
  local StoreRoomId = 271

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
    self.goldThreshold = 20
    self:debugOn()
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups("jobs_recover")
  end

  function prototype:initJobs()
    self.jobs = {}
    self.jobSeq = 0
    -- add jobs by priority
    table.insert(self.jobs, self.definedJobs.touxue)
    table.insert(self.jobs, self.definedJobs.cisha)
    table.insert(self.jobs, self.definedJobs.wananta)
    table.insert(self.jobs, self.definedJobs.murong)
  end

  function prototype:nextJob()
    local leastDelayJob
    local leastDelay = 86400
    for _, job in ipairs(self.jobs) do
      local delay = self.jobDelays[job.def.name]
      if delay then
        if delay == 0 then
          return job
        elseif delay < leastDelay then
          leastDelayJob = job
          leastDelay = delay
        end
      elseif job.impl.available and job.impl:available() then
        return job
      end
    end
    if not leastDelayJob then
      ColourNote("yellow", "", "没有可用任务，从第一个任务开始")
      return self.jobs[1]
    else
      return leastDelayJob
    end
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
    self.definedJobs.murong = Job:decorate {
      def = JobDefinition.murong,
      impl = murong
    }
    self.definedJobs.touxue = Job:decorate {
      def = JobDefinition.touxue,
      impl = touxue
    }
    self.definedJobs.tianzhu = Job:decorate {
      def = JobDefinition.tianzhu,
      impl = tianzhu
    }
    self.definedJobs.cisha = Job:decorate {
      def = JobDefinition.cisha,
      impl = cisha
    }
    self.definedJobs.huyidao = Job:decorate {
      def = JobDefinition.huyidao,
      impl = huyidao
    }
    self.definedJobs.wananta = Job:decorate {
      def = JobDefinition.wananta,
      impl = wananta
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
      exit = function()
        helper.disableTriggerGroups("jobs_query_start", "jobs_query_done")
      end
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
      enter = function()
        helper.enableTriggerGroups("jobs_recover")
      end,
      exit = function()
        helper.disableTriggerGroups("jobs_recover")
      end
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
    helper.removeTriggerGroups("jobs_recover", "jobs_query_start", "jobs_query_done")
    helper.addTrigger {
      group = "jobs_recover",
      regexp = REGEXP.DAZUO_FINISH,
      response = function()
        return self:doRecover()
      end
    }
    helper.addTrigger {
      group = "jobs_recover",
      regexp = REGEXP.TUNA_FINISH,
      response = function()
        return self:doRecover()
      end
    }
    helper.addTriggerSettingsPair {
      group = "jobs",
      start = "query_start",
      done = "query_done",
    }
    helper.addTrigger {
      group = "jobs_query_done",
      regexp = REGEXP.JOB_QUERY,
      response = function(name, line, wildcards)
        self:debug("JOB_QUERY triggered")
        local jobId = wildcards[1]
        local jobType = wildcards[2]
        local jobName = wildcards[3]
        local jobSuccessCnt = wildcards[4]
        local jobSuccessRate = wildcards[5]
        local jobDelay = wildcards[6]
        -- 现在即可接到下个任务。
        if jobDelay == "现在即可接到下个任务。" then
          self.jobDelays[jobName] = 0
        elseif jobDelay == "现在即可接到下个普通镖局的任务。" then
          self.jobDelays[jobName] = 0
        else
          local s, e = string.find(jobDelay, "仍需")
          if s == 1 then
            -- 处理时间
            local timeStr = string.sub(jobDelay, e + 1)
            local delayTime = 0
            -- 小时
            local hs, he = string.find(timeStr, "小时")
            if hs then
              local hourStr = string.sub(timeStr, 1, hs - 1)
              delayTime = delayTime + helper.ch2number(hourStr) * 3600
              timeStr = string.sub(timeStr, he + 1)
            end
            -- 分钟
            local ms, me = string.find(timeStr, "分")
            if ms then
              local minuteStr = string.sub(timeStr, 1, ms - 1)
              delayTime = delayTime + helper.ch2number(minuteStr) * 60
              timeStr = string.sub(timeStr, me + 1)
            end
            -- 秒
            local ss, se = string.find(timeStr, "秒")
            if ss then
              local secondStr = string.sub(timeStr, 1, ss - 1)
              delayTime = delayTime + helper.ch2number(secondStr)
            end
            self.jobDelays[jobName] = delayTime
          end
        end
        self:debug(jobName, self.jobDelays[jobName])
      end
    }
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
    wait.time(0.5)
    self.jobDelays = {}
    helper.enableTriggerGroups("jobs_query_start")
    SendNoEcho("set jobs query_start")
    SendNoEcho("jobquery")
    SendNoEcho("set jobs query_done")
    helper.checkUntilNotBusy()
    -- 确定任务
    self.currJob = self:nextJob()
    print("确定当前任务类型：", self.currJob.def.name)
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
    wait.time(0.5)
    helper.assureNotBusy()
    self:doCheckWeapons()
    print("武器装备检查完毕（待完善）")
    wait.time(0.5)
    helper.assureNotBusy()
    print("任务信息检查完毕（待完善）")
    wait.time(0.5)
    helper.assureNotBusy()
    status:hpbrief()
    if status.food < 120 or status.drink < 120 then
      return self:fire(Events.HUNGRY)
    end
    print("食物饮水检查完毕")
    local precondition = self.currJob:getPrecondition()
    if status.effJing < precondition.jing * status.maxJing - 1
      or status.currJingli < precondition.jingli * status.maxJingli - 1
      or status.effQi < precondition.qi * status.maxQi - 1
      or status.currNeili < precondition.neili * status.maxNeili - 1 then
      return self:fire(Events.TO_RECOVER)
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
    travel:walkto(DiningRoomId)
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
    travel:walkto(StoreRoomId)
    travel:waitUntilArrived()
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
  end

  function prototype:doRecover()
    wait.time(1)
    local pct = self.currJob:getPrecondition()
    status:hpbrief()
    -- 先恢复精
    local neiliUsed = false
    if status.effJing < status.maxJing * pct.jing - 1 then
      self:debug("精受损，进行恢复")
      if status.effJing < status.maxJing * 0.7 then
        ColourNote("yellow", "", "精严重受损，吃药！")
        SendNoEcho("do 2 eat dan")
      end
      SendNoEcho("yun inspire")
      helper.checkUntilNotBusy()
      SendNoEcho("yun inspire")
      helper.checkUntilNotBusy()
      neiliUsed = true
    end
    -- 再恢复气
    if status.effQi < status.maxQi * pct.qi - 1 then
      if status.effQi < status.maxQi * 0.7 then
        ColourNote("yellow", "", "气严重受损，吃药！")
        SendNoEcho("do 2 eat yao")
      end
      self:debug("气受损，进行恢复")
      SendNoEcho("do 2 yun heal")
      neiliUsed = true
    end
    -- 先恢复内力
    if neiliUsed then status:hpbrief() end
    if status.currNeili < status.maxNeili * pct.neili - 1 then
      local diff = status.maxNeili * pct.neili - status.currNeili
      local dzNum = math.floor(diff)
      if status.currNeili < status.maxNeili * 2 - 550 and diff < 500 then
        dzNum = 500
      end
      if dzNum > status.currQi - status.maxQi * 0.2 then
        if status.currQi <= status.maxQi * 0.5 then
          SendNoEcho("yun recover")
        end
        SendNoEcho("dazuo max")
        local line = wait.regexp(REGEXP.DAZUO_BEGIN, 4)
        if not line then
          -- todo
          return self:doRecover()
        end
      else
        SendNoEcho("dazuo " .. dzNum)
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
    else
      return self:fire(Events.RECOVERED)
    end
  end

  return prototype
end
return define_jobs():FSM()

