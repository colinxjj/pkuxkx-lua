--
-- Job.lua
-- User: zhe.jiang
-- Date: 2017/4/6
-- Desc:
-- 任务接口
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
    assert(type(impl.doWaitUntilDone) == "function", "notifyDone() of job implementation must be function")
    assert(type(impl.doCancel) == "function", "doStop() of job implementation must be function")
    assert(type(impl.doWait) == "function", "doWait() of job implmeentation must be function")
    assert(type(impl.getLastUpdateTime) == "function", "getLastUpdateTime() of job implementation must be function")
    obj.impl = impl
    setmetatable(obj, self or prototype)
    self:postConstruct()
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.def, "definition of job cannot be nil")
    local impl = assert(obj.impl, "implementation cannot be nil")
    assert(type(impl.doStart) == "function", "doStart() of job implementation must be function")
    assert(type(impl.doWaitUntilDone) == "function", "notifyDone() of job implementation must be function")
    assert(type(impl.doCancel) == "function", "doStop() of job implementation must be function")
    assert(type(impl.doWait) == "function", "doWait() of job implmeentation must be function")
    assert(type(impl.getLastUpdateTime) == "function", "getLastUpdateTime() of job implementation must be function")
    setmetatable(obj, self or prototype)
    self:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self.waitThread = nil
    self.stopped = false
  end

  function prototype:start()
    assert(self.stopped, "stopped flag must be true before start")
    self.stopped = false
    self.impl.doStart()  -- must be an async call
  end

  function prototype:stop()
    self.impl.doCancel()
    self.stopped = true
  end

  function prototype:waitUntilDone()
    local antiIdle

    antiIdle = function()
      return coroutine.wrap(function()
        local currTime = os.time()
        if currTime - self:getLastUpdateTime >= 300 then
          ColourNote("red", "", "停顿超过5分钟，强制取消任务")
          return self:cancel()
        elseif currTime - self:getLastUpdateTime >= 180 then
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

    self.impl.doWaitUntilDone() -- this is a long-time yield and before this we need to periodically check status
  end

  function prototype:getLastUpdateTime()
    return self.impl.getLastUpdateTime()
  end

  return prototype
end
--return define_AbstractJob()
