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
-- ������������ʵ��
local songxin = require "job.songxin"
local nanjue = require "job.nanjue"
local murong = require "job.murong"
local touxue = require "job.touxue"
local tianzhu = require "job.tianzhu"
local cisha = require "job.cisha"
local huyidao = require "job.huyidao"
local wananta = require "job.wananta"

-- �������
local banghui = require "common.banghui"
local captcha = require "pkuxkx.captcha"

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

��[01][��]��������                δ��������                                                  ��
��[02][��]��������                δ��������                                                  ��
��[03][��]����                    δ��������                                                  ��
��[04][��]��Ϸ����                δ��������                                                  ��
��[05][��]���ѻ���                δ��������                                                  ��
��[06][��]Ľ������(0)             ���ڼ��ɽӵ��¸�����                                        ��
��[07][��]��Ա�⸴��(0)           ���ڼ��ɽӵ��¸�����                                        ��
��[08][��]��ͳ�Ƹ���ɱ(0)         ���ڼ��ɽӵ��¸�����                                        ��
��[09][��]��������(0)             ���ڼ��ɽӵ��¸������ھֵ�����                              ��
��[10][��]��һ������(0)           ���ڼ��ɽӵ��¸�����                                        ��
��[11][��]��������(0)             ���ڼ��ɽӵ��¸�����                                        ��
��[12][��]����������(0)           ���ڼ��ɽӵ��¸�����                                        ��
��[13][��]����ֹ����(0)           ���ڼ��ɽӵ��¸�����                                        ��
��[14][��]��������(0) ��        ���ڼ��ɽӵ��¸�����                                        ��
��[15][��]��������(0)             ���ڼ��ɽӵ��¸�����                                        ��
��[16][��]��������(0)             ���ڼ��ɽӵ��¸�����                                        ��
��[17][��]͵ѧ����(0)             ���ڼ��ɽӵ��¸�����                                        ��
��[18][��]��ɽ��������(0)         ���ڼ��ɽӵ��¸�����                                        ��
��[19][��]Ͷ��״����(0)           ���ڼ��ɽӵ��¸�����                                        ��
��[20][��]���������(0)           δ��������                                                  ��
��[21][��]۶����Ѱ��(0)           ���ڼ��ɽӵ��¸�����                                        ��
��[22][��]��������                δ��������                                                  ��
��[23][��]����������              δ��������                                                  ��
��[24][��]ͭȸ̨����              ���ڼ��ɽӵ��¸�����                                        ��
��[25][��]����������              ���ڼ��ɽӵ��¸�����                                        ��
��[26][��]������������            ���ڼ��ɽӵ��¸�����                                        ��

��������㣺���ݵ������һ��ɽ��ռ�ݣ�û������Ƶ����С�
һ��ɽ�����˳������������ض��������ɽ���ҿ������������ԣ�Ҫ�����·��������·�ơ�
ɽ���������������·�������롣

ɱ    ����  ����
ɱ    ����  ƫ��

chanhui
��˫ϥ��أ����۽��գ����������дʣ����ϳ����ں�֮�⡣

> ��о����е�ɱ��������ʧ......

��[01][��]��������                δ��������                                                  ��
��[06][��]Ľ��(1005)              ��Ҫȥ�һ���δ֪������ֵ�Ľ�ݸ�д���������ܵ��ż���          ��
��[07][��]��Ա��(10) 55.6%        ���ڼ��ɽӵ��¸�����                                        ��
��[08][��]������ɱ(10) 90.9%      ���ڼ��ɽӵ��¸�����                                        ��
��[09][��]����(1096) 2.9%         ���ڼ��ɽӵ��¸���ͨ�ھֵ�����                              ��
��[10][��]��һ��(10) 100.0%       ���ڼ��ɽӵ��¸�����                                        ��
��[11][��]����(14) 48.3%          ���ڼ��ɽӵ��¸�����                                        ��
��[12][��]������(247) 91.5%       ���ڼ��ɽӵ��¸�����                                        ��
��[13][��]����ֹ(0)               ���ڼ��ɽӵ��¸�����                                        ��
��[14][��]����(125) 89.3%       ���ڼ��ɽӵ��¸�����                                        ��
��[15][��]����(10) 44.4%          ���ڼ��ɽӵ��¸�����                                        ��
��[16][��]����(74) 82.2%          ���ڼ��ɽӵ��¸�����                                        ��
��[17][��]͵ѧ(25) 80.6%          ���������ʮ������ܽӵ��¸�����                            ��
��[18][��]��ɽ��������(269)       ���ڼ��ɽӵ��¸�����                                        ��
��[19][��]Ͷ��״����(10)          ���ڼ��ɽӵ��¸�����                                        ��
��[21][��]۶����Ѱ��(0)           ���ڼ��ɽӵ��¸�����                                        ��
��[24][��]ͭȸ̨����              ���ڼ��ɽӵ��¸�����                                        ��
��[25][��]����������              ���ڼ��ɽӵ��¸�����                                        ��

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
    name = "��������",
    code = "menzhong"
  }
  prototype.murong = prototype:decorate {
    id = 6,
    name = "Ľ��",
    code = "murong"
  }
  prototype.hanyuanwai = prototype:decorate {
    id = 7,
    name = "��Ԫ��",
    code = "hanyuanwai"
  }
  prototype.cisha = prototype:decorate {
    id = 8,
    name = "������ɱ",
    code = "cisha"
  }
  prototype.hubiao = prototype:decorate {
    id = 9,
    name = "����",
    code = "hubiao"
  }
  prototype.huyidao = prototype:decorate {
    id = 10,
    name = "��һ��",
    code = "huyidao"
  }
  prototype.xiaofeng = prototype:decorate {
    id = 11,
    name = "����",
    code = "xiaofeng"
  }
  prototype.hanshizhong = prototype:decorate {
    id = 12,
    name = "������",
    code = "hanshizhong"
  }
  prototype.gongsunzhi = prototype:decorate {
    id = 13,
    name = "����ֹ",
    code = "gongsunzhi"
  }
  prototype.wananta = prototype:decorate {
    id = 14,
    name = "����",
    code = "wananta"
  }
  prototype.pozhen = prototype:decorate {
    id = 15,
    name = "����",
    code = "pozhen"
  }
  prototype.tianzhu = prototype:decorate {
    id = 16,
    name = "����",
    code = "tianzhu",
  }
  prototype.touxue = prototype:decorate {
    id = 17,
    name = "͵ѧ",
    code = "touxue"
  }
  prototype.songxin = prototype:decorate {
    id = 18,
    name = "��ɽ��������",
    code = "songxin"
  }
  prototype.toumingzhuang = prototype:decorate {
    id = 19,
    name = "Ͷ��״����",
    code = "toumingzhuang"
  }
  prototype.poyanghu = prototype:decorate {
    id = 20,
    name = "۶����Ѱ��",
    code = "poyanghu"
  }
  prototype.nanjue = prototype:decorate {
    id = -1,  -- ����jobquery��
    name = "�����о�����",
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
          ColourNote("red", "", "ͣ�ٳ���5���ӣ�ǿ��ȡ������")
          return self.impl:doCancel()
        elseif currTime - self:getLastUpdateTime() >= self.warnThreshold then
          ColourNote("yellow", "", "ͣ�ٳ���3���ӣ�����")
        else
          print("�ȴ�60�������鿴״̬")
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
    CANNOT_STORE_MONEY = "^[ >]*��Ŀǰ���д��.*���ٴ���ô���Ǯ������С�ſ��ѱ����ˡ�$",
    CANNOT_DAZUO = "^[ >]*�����������ڹ�����ȫ����Ѫ�ָ����޷�������������������$",
    CANNOT_RECOVER = "^[ >]*��������������������Ѫ�ָ����޷��ٷֳ���������$",
    TUNA_BEGIN = "^[ >]*����ϥ���£���ʼ����������$",
    DAZUO_BEGIN = "^[ >]*�������������ù���һ����Ϣ��ʼ������������$",
    DAZUO_FINISH = "^[ >]*���˹���ϣ��������˿�����վ��������$",
    TUNA_FINISH = "^[ >]*��������ϣ�����˫�ۣ�վ��������$",
    JOB_QUERY = "^��\\[(\\d+)\\]\\[(.*?)\\]([^\\)]+)\\((\\d+)\\)\\s+([\\d\\.]*%)?\\s+(.*?)\\s+��$",
  }

  -- ţ�����
  local DiningRoomId = 3797
  -- ����Ǯׯ
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
      ColourNote("yellow", "", "û�п������񣬴ӵ�һ������ʼ")
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
        -- ���ڼ��ɽӵ��¸�����
        if jobDelay == "���ڼ��ɽӵ��¸�����" then
          self.jobDelays[jobName] = 0
        elseif jobDelay == "���ڼ��ɽӵ��¸���ͨ�ھֵ�����" then
          self.jobDelays[jobName] = 0
        else
          local s, e = string.find(jobDelay, "����")
          if s == 1 then
            -- ����ʱ��
            local timeStr = string.sub(jobDelay, e + 1)
            local delayTime = 0
            -- Сʱ
            local hs, he = string.find(timeStr, "Сʱ")
            if hs then
              local hourStr = string.sub(timeStr, 1, hs - 1)
              delayTime = delayTime + helper.ch2number(hourStr) * 3600
              timeStr = string.sub(timeStr, he + 1)
            end
            -- ����
            local ms, me = string.find(timeStr, "��")
            if ms then
              local minuteStr = string.sub(timeStr, 1, ms - 1)
              delayTime = delayTime + helper.ch2number(minuteStr) * 60
              timeStr = string.sub(timeStr, me + 1)
            end
            -- ��
            local ss, se = string.find(timeStr, "��")
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
        print("ֹͣ - ��ǰ״̬", self.currState)
      end
    }
  end

  function prototype:doPrepare()
    -- check status
    print("׼������")
    wait.time(0.5)
    self.jobDelays = {}
    helper.enableTriggerGroups("jobs_query_start")
    SendNoEcho("set jobs query_start")
    SendNoEcho("jobquery")
    SendNoEcho("set jobs query_done")
    helper.checkUntilNotBusy()
    -- ȷ������
    self.currJob = self:nextJob()
    print("ȷ����ǰ�������ͣ�", self.currJob.def.name)
    status:money()
    if status.silvers > self.silverThreshold
      or status.golds > self.goldThreshold then
      self:debug(
        "���Ͻ�Ǯ�����޶",
        "gold:" .. status.golds,
        "silver:" .. status.silvers)
      return self:fire(Events.RICH)
    end
    print("Я����Ǯ������")
    wait.time(0.5)
    helper.assureNotBusy()
    self:doCheckWeapons()
    print("����װ�������ϣ������ƣ�")
    wait.time(0.5)
    helper.assureNotBusy()
    print("������Ϣ�����ϣ������ƣ�")
    wait.time(0.5)
    helper.assureNotBusy()
    status:hpbrief()
    if status.food < 120 or status.drink < 120 then
      return self:fire(Events.HUNGRY)
    end
    print("ʳ����ˮ������")
    local precondition = self.currJob:getPrecondition()
    if status.effJing < precondition.jing * status.maxJing - 1
      or status.currJingli < precondition.jingli * status.maxJingli - 1
      or status.effQi < precondition.qi * status.maxQi - 1
      or status.currNeili < precondition.neili * status.maxNeili - 1 then
      return self:fire(Events.TO_RECOVER)
    end
    print("����״̬������")
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
    print("׼��ǰ��Ǯׯ��Ǯ")
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
      print("Ǯׯ�洢��������")
      return self:fire(Events.STOP)
    else
      return self:fire(Events.POOR)
    end
  end

  function prototype:doRecover()
    wait.time(1)
    local pct = self.currJob:getPrecondition()
    status:hpbrief()
    -- �Ȼָ���
    local neiliUsed = false
    if status.effJing < status.maxJing * pct.jing - 1 then
      self:debug("�����𣬽��лָ�")
      if status.effJing < status.maxJing * 0.7 then
        ColourNote("yellow", "", "���������𣬳�ҩ��")
        SendNoEcho("do 2 eat dan")
      end
      SendNoEcho("yun inspire")
      helper.checkUntilNotBusy()
      SendNoEcho("yun inspire")
      helper.checkUntilNotBusy()
      neiliUsed = true
    end
    -- �ٻָ���
    if status.effQi < status.maxQi * pct.qi - 1 then
      if status.effQi < status.maxQi * 0.7 then
        ColourNote("yellow", "", "���������𣬳�ҩ��")
        SendNoEcho("do 2 eat yao")
      end
      self:debug("�����𣬽��лָ�")
      SendNoEcho("do 2 yun heal")
      neiliUsed = true
    end
    -- �Ȼָ�����
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
      -- �ٻָ�����
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

