--
-- jobs.lua
-- User: zhe.jiang
-- Date: 2017/4/5
-- Desc:
--
-- 任务统计与调度插件
--
-- Change:
-- 2017/4/5 - created

local helper = require "pkuxkx.helper"

local define_jobs = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new()
    local obj = {}
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self:initTriggers()
    self:initAliases()
    self.waitThread = nil
    self.jobs = {}
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("jobs_query_start", "jobs_query_done")
    -- jobquery triggers
    helper.addTrigger {
      group = "jobs_query_start",
      regexp = helper.settingRegexp("jobs", "query_start"),
      response = function()
        helper.enableTriggerGroups("jobs_query_done")
      end
    }
    helper.addTrigger {
      group = "jobs_query_done",
      regexp = helper.settingRegexp("jobs", "query_done"),
      response = function()
        helper.disableTriggerGroups("jobs_query_done")
        local thread = self.waitThread
        if thread then
          self.waitThread = nil
          local ok, err = coroutine.resume(thread)
          if not ok then
            ColourNote ("deeppink", "black", "Error raised in trigger function (in wait module)")
            ColourNote ("darkorange", "black", debug.traceback (thread))
            error (err)
          end -- if
        end
      end
    }
  end

  function prototype:initAliases()

  end

  function prototype:doQuery()
    if self.waitThread then
      error("Previous thread is not disposed")
    end
    self.waitThread = assert(coroutine.running(), "Must be in coroutine")
    SendNoEcho("set jobs query_start")
    SendNoEcho("jobquery")
    SendNoEcho("set jobs query_done")
    -- ignore arguments
    return coroutine.yield()
  end

  return prototype
end
return define_jobs():new()

