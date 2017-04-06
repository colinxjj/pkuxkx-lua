--
-- nanjue.lua
-- User: zhe.jiang
-- Date: 2017/4/5
-- Desc:
-- 男爵任务
-- 大致步骤：
-- 1. 领任务
-- 2. 询问路人
-- 3. 判断盗贼
-- 4. 战斗或指认
-- 5. 领赏或放弃
-- Change:
-- 2017/4/5 - created

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local NanjueJob = require "pkuxkx.NanjueJob"

local define_nanjue = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    record = "record",
    collect = "collect",
    fight = "fight",
    submit = "submit",
  }
  local Events = {
    STOP = "stop",
    START = "start",
    JOB_RECORDED = "job_recorded",
    NO_JOB_AVAILABLE = "no_job_available",
  }
  local REGEXP = {
    -- 任务表示 任务名称 任务状态 发布时间 截止时间 任务地点 资质要求 认领玩家
    JOB_INFO = "^\\s+([0-9_]+?)\\s+(.*?)「(.*?)」\\s+(\\d+:\\d+:\\d+)\\s+(\\d+:\\d+:\\d+)\\s+(.*?)\\s+(.*?)\\s+(\\d+)$",

  }
  local Locations = {
    ["小雁塔"] = 2322,
    ["大雁塔"] = 2314,
    ["长乐坊"] = 2350,
    ["东市"] = 2330,
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
  end

  function prototype:disableAllTriggers()

  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
      end,
      exit = function() end
    }
    self:addState {
      state = States.record,
      enter = function()
        helper.enableTriggerGroups("nanjue_info_start")
      end,
      exit = function()
        helper.disableTriggerGroups("nanjue_info_start", "nanjue_info_done")
      end
    }
  end

  function prototype:initTransitions()
    -- transition from state<start>
    self:addTransition {
      oldState = States.stop,
      newState = States.record,
      event = Events.START,
      action = function()
        return travel:walkto(2289, function()
          return self:doAskInfo()
        end)
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<record>
    self:addTransition {
      oldState = States.record,
      newState = States.collect,
      event = Eventsski
    }
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("nanjue_info_start", "nanjue_info_done")

    helper.addTrigger {
      group = "nanjue_info_start",
      regexp = helper.settingRegexp("nanjue", "info_start"),
      response = function()
        helper.enableTriggerGroups("nanjue_info_done")
      end
    }
    helper.addTrigger {
      group = "nanjue_info_done",
      regexp = helper.settingRegexp("nanjue", "info_done"),
      response = function()
        helper.disableTriggerGroups("nanjue_info_done")
        if #(self.jobs) == 0 then
          return self:fire(Events.NO_JOB_AVAILABLE)
        else
          self.selectedJob = nil
          for _, job in ipairs(self.jobs) do
            if job.level == "简单" and Locations[job.location] then
              self.selectedJob = job
              break
            end
          end
          if self.selectedJob then
            SendNoEcho("record " .. self.selectedJob.id)
            return self:fire(Events.JOB_RECORDED)
          else
            return self:fire(Events.NO_JOB_AVAILABLE)
          end
        end
      end
    }
    helper.addTrigger {
      group = "nanjue_info_done",
      regexp = REGEXP.JOB_INFO,
      response = function(name, line, wildcards)
        self:debug("JOB_INFO triggered")
        local jobCode = wildcards[1]
        local jobName = wildcards[2]
        local jobLevel = wildcards[3]
        local jobStatus = wildcards[4]
        local jobStartTime = wildcards[5]
        local jobEndTime = wildcards[6]
        local jobLocation = wildcards[7]
        local jobRequirement = wildcards[8]
        local jobPlayers = tonumber(wildcards[9])

        local currTime = os.date("*t")
        local ss = utils.split(jobStartTime, ":")
        local startTime = os.time {
          year = currTime.year,
          month = currTime.month,
          day = currTime.day,
          hour = tonumber(ss[1]),
          min = tonumber(ss[2]),
          sec = tonumber(ss[3])
        }
        local es = utils.split(jobEndTime, ":")
        local endTime = os.time {
          year = currTime.year,
          month = currTime.month,
          day = currTime.day,
          hour = tonumber(es[1]),
          min = tonumber(es[2]),
          sec = tonumber(es[3])
        }
        -- 只做5分钟内的任务
        -- 只做没有人认领的任务
        -- 只做新的任务
        if endTime - currTime >= 5 * 60 and jobPlayers == 0 and jobStatus == "新建" then
          table.insert(self.jobs, NanjueJob:decorate {
            code = jobCode,
            name = jobName,
            level = jobLevel,
            status = jobStatus,
            startTime = startTime,
            endTime = endTime,
            location = jobLocation,
            requirement = jobRequirement,
            players = jobPlayers
          })
        end
      end
    }
  end

  function prototype:initAliases()

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

  function prototype:doAskInfo()
    self.jobsInfo = {}
    SendNoEcho("set nanjue info_start")
    SendNoEcho("ask shaoyin about 任务信息")
    SendNoEcho("set nanjue info_done")
  end

  return prototype
end
return define_nanjue():FSM()

