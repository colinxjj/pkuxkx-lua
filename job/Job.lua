--
-- Job.lua
-- User: zhe.jiang
-- Date: 2017/4/6
-- Desc:
-- ����ӿڣ�Ҫ�����ʵ��doStart, doCancel, getLastUpdateTime����
-- ͬʱ���������Լ��������ɻ�ʧ�ܺ�����set jobs job_done��
--
-- Change:
-- 2017/4/6 - created

local helper = require "pkuxkx.helper"

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
          ColourNote("red", "", "ͣ�ٳ���5���ӣ�ǿ��ȡ������")
          return self:cancel()
        elseif currTime - self:getLastUpdateTime() >= 180 then
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
return define_Job()
