--
-- dztn.lua
-- User: zhe.jiang
-- Date: 2017/5/8
-- Desc:
-- Change:
-- 2017/5/8 - created

local helper = require "pkuxkx.helper"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"
local nanjue = require "job.nanjue"

local define_module = function()
  local prototype = {}
  prototype.__index = prototype

  local REGEXP = {
    TUNA_FINISH = "^[ >]*你吐纳完毕，睁开双眼，站了起来。$",
    DAZUO_FINISH = "^[ >]*你运功完毕，深深吸了口气，站了起来。$",
    NOT_ENOUGH_JING = "^[ >]*(你现在精不足，无法修行精力.*|你现在精严重不足，无法满足吐纳最小要求。|你现在精不够，无法控制内息的流动！)$",
    NOT_ENOUGH_QI = "^[ >]*(你现在的气太少了，无法产生内息运行全身经脉.*|你现在气血严重不足，无法满足打坐最小要求。|你现在身体状况太差了，无法集中精神！)$",
    JINGLI_MAX = "^[ >]*你现在精力接近圆满状态。$",
    NEILI_MAX = "^[ >]*你现在内力接近圆满状态。$",
    ALIAS_CMD = "^dztn\\s+(dazuo|tuna|start|stop)\s*$",
    ALIAS_DEBUG = "^dztn\\s+debug\\s+(on|off)\\s*$",
    ALIAS_NANJUE = "^dztn\\s+nanjue\\s+(on|off)\\s*$",
  }

  local DztnRoomId = 2918
  local DiningRoomId = 3798

  function prototype:new()
    local obj = {}
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self:initTriggers()
    self:initAliases()
    self.DEBUG = true
    self.mode = "dazuo"
    self.startTime = 0
    self.includeNanjue = true
    self.lastNanjueTime = 0
  end

  function prototype:debug(...)
    if self.DEBUG then
      print(...)
    end
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("dztn")

    helper.addTrigger {
      group = "dztn",
      regexp = REGEXP.TUNA_FINISH,
      response = function()
        self:debug("TUNA_FINISH triggered")
        return self:doDztn()
      end
    }
    helper.addTrigger {
      group = "dztn",
      regexp = REGEXP.DAZUO_FINISH,
      response = function(name, line, wildcards)
        self:debug("DAZUO_FINISH triggered")
        return self:doDztn()
      end
    }
    helper.addTrigger {
      group = "dztn",
      regexp = REGEXP.NOT_ENOUGH_JING,
      response = function()
        self:debug("NOT_ENOUGH_JING triggered")
        wait.time(3)
        SendNoEcho("yun regenerate")
        return self:doDztn()
      end
    }
    helper.addTrigger {
      group = "dztn",
      regexp = REGEXP.NOT_ENOUGH_QI,
      response = function()
        self:debug("NOT_ENOUGH_QI triggered")
        wait.time(3)
        SendNoEcho("yun recover")
        return self:doDztn()
      end
    }
    helper.addTrigger {
      group = "dztn",
      regexp = REGEXP.JINGLI_MAX,
      response = function()
        SendNoEcho("tuna 10")
      end
    }
    helper.addTrigger {
      group = "dztn",
      regexp = REGEXP.NEILI_MAX,
      response = function()
        SendNoEcho("dazuo 10")
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("dztn")
    helper.addAlias {
      group = "dztn",
      regexp = REGEXP.ALIAS_CMD,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "dazuo" or cmd == "tuna" then
          self.mode = cmd
        elseif cmd == "start" then
          travel:walkto(DztnRoomId)
          travel:waitUntilArrived()
          wait.time(1)
          helper.enableTriggerGroups("dztn")
          return self:doDztn()
        elseif cmd == "stop" then
          helper.disableTriggerGroups("dztn")
        else
          ColourNote("red", "", "unknown command for dztn module")
        end
      end
    }
    helper.addAlias {
      group = "dztn",
      regexp = REGEXP.ALIAS_DEBUG,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self.DEBUG = true
        else
          self.DEBUG = false
        end
      end
    }
    helper.addAlias {
      group = "dztn",
      regexp = REGEXP.ALIAS_NANJUE,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self.includeNanjue = true
        else
          self.includeNanjue = false
        end
      end
    }
  end

  function prototype:doDztn()
    status:hpbrief()
    if status.food < 150 or status.drink < 150 then
      return self:doEat()
    end
    if self.DEBUG then
      local currTime = os.time()
      local timeDiff = currTime - self.lastNanjueTime
      self:debug("距上次男爵任务时间：", timeDiff)
    end
    if self.includeNanjue and os.time() - 60 * 15 > self.lastNanjueTime then
      return self:doNanjue()
    end
    if status.currJing < status.maxJing / 2 and self.mode == "tuna" then
      SendNoEcho("yun regenerate")
    end
    if status.currQi < status.maxQi / 2 and self.mode == "dazuo" then
      SendNoEcho("yun recover")
    end
    if self.mode == "tuna" then
      SendNoEcho("tuna max")
    elseif self.mode == "dazuo" then
      SendNoEcho("dazuo max")
    end
  end

  function prototype:doEat()
    helper.disableTriggerGroups("dztn")
    travel:walkto(DiningRoomId)
    travel:waitUntilArrived()
    wait.time(1)
    helper.assureNotBusy()
    SendNoEcho("do 2 eat")
    helper.assureNotBusy()
    SendNoEcho("do 2 drink")
    helper.assureNotBusy()
    wait.time(1)
    travel:walkto(DztnRoomId)
    travel:waitUntilArrived()
    helper.enableTriggerGroups("dztn")
    return self:doDztn()
  end

  function prototype:doNanjue()
    local nanjueStartTime = os.time()
    helper.disableTriggerGroups("dztn")
    nanjue:doStart()
    wait.time(10)
    while nanjue.currState ~= "stop" do
      self:debug("男爵任务仍在进行中")
      wait.time(10)
    end
    local currTime = os.time()
    if currTime - nanjueStartTime < 60 then
      self:debug("男爵任务结束过快，需要fullme，自动禁止")
      self.includeNanjue = false
    end
    self.lastNanjueTime = currTime
    travel:walkto(DztnRoomId)
    travel:waitUntilArrived()
    wait.time(1)
    helper.enableTriggerGroups("dztn")
    return self:doDztn()
  end

  return prototype
end
return define_module():new()

