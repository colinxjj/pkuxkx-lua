--
-- xiulian.lua
-- User: zhe.jiang
-- Date: 2017/4/24
-- Desc:
-- Change:
-- 2017/4/24 - created

local helper = require "pkuxkx.helper"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"
local nanjue = require "job.nanjue"

local define_xiulian = function()
  local prototype = {}
  prototype.__index = prototype

  local REGEXP = {
    XIULIAN_FINISH = "^[ >]*你从玄幻之境回过神来，顿觉内功修为增进不小。$",
    NEILI_ADDED = "^[ >]*你的内力增加了！！$",
    EXP_LIMIT = "^[ >]*由于缺乏实战经验，你无法领会更高深的武功。$",
    DZ_FINISH = "^[ >]*(你将运转于任督二脉间的内息收回丹田，深深吸了口气，站了起来。)$",
    ALIAS_START = "xlforce\\s+start\\s*$",
    ALIAS_STOP = "xlforce\\s+stop\\s*$",
    ALIAS_DEBUG = "xlforce\s+debug\\s+(on|off)\\s*$",
    ALIAS_ROOM = "xlforce\\s+room\\s+(\\d+)\\s*$",
    ALIAS_FORCE = "xlforce\\s+force\\s+(.*?)\\s*$",
    ALIAS_DZ = "xlforce\\s+dz\\s*$",
    ALIAS_NANJUE = "xlforce\\s+nanjue\\s+(on|off)\\s*$",
  }

  function prototype:new()
    local obj = {}
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self:initTriggers()
    self:initAliases()

    self.forceId = "zixia-shengong"
    self.roomId = 2918
    self.includeNanjue = true
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("xiulian", "xiulian_dz")
    helper.addTrigger {
      group = "xiulian",
      regexp = REGEXP.XIULIAN_FINISH,
      response = function()
        return self:doXiulian()
      end
    }
    helper.addTrigger {
      group = "xiulian_dz",
      regexp = REGEXP.NEILI_ADDED,
      response = function()
        return self:doDz()
      end
    }
    helper.addTrigger {
      group = "xiulian_dz",
      regexp = REGEXP.DZ_FINISH,
      response = function()
        return self:doDz()
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("xiulian")
    helper.addAlias {
      group = "xiulian",
      regexp = REGEXP.ALIAS_START,
      response = function()
        helper.checkUntilNotBusy()
        helper.enableTriggerGroups("xiulian")
        if self.roomId then
          travel:walkto(self.roomId)
          travel:waitUntilArrived()
        end
        wait.time(1)
        return self:doXiulian()
      end
    }
    helper.addAlias {
      group = "xiulian",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        helper.disableTriggerGroups("xiulian", "xiulian_dz")
      end
    }
    helper.addAlias {
      group = "xiulian",
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
      group = "xiulian",
      regexp = REGEXP.ALIAS_ROOM,
      response = function(name, line, wildcards)
        local roomId = tonumber(wildcards[1])
        if roomId == nil then
          self.roomId = nil
        else
          self.roomId = roomId
        end
      end
    }
    helper.addAlias {
      group = "xiulian",
      regexp = REGEXP.ALIAS_FORCE,
      response = function(name, line, wildcards)
        self.forceName = wildcards[1]
      end
    }
    helper.addAlias {
      group = "xiulian",
      regexp = REGEXP.ALIAS_DZ,
      response = function(name, line, wildcards)
        helper.checkUntilNotBusy()
        helper.enableTriggerGroups("xiulian_dz")
        if self.roomId then
          travel:walkto(self.roomId)
          travel:waitUntilArrived()
        end
        wait.time(1)
        return self:doDz()
      end
    }
    helper.addAlias {
      group = "xiulian",
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

  function prototype:doXiulian()
    if self.includeNanjue then
      if nanjue:available() then
        return nanjue:doIfAvailable(function()
          travel:walkto(self.roomId)
          travel:waitUntilArrived()
          wait.time(1)
          return self:doInternalXiulian()
        end)
      end
    end
    return self:doInternalXiulian()
  end

  function prototype:doInternalXiulian()
    status:hpbrief()
    if status.food < 150 then
      SendNoEcho("do 2 eat ganliang")
    end
    if status.drink < 150 then
      SendNoEcho("do 2 drink jiudai")
    end
    helper.checkUntilNotBusy()
    SendNoEcho("xiulian " .. self.forceId)
  end

  function prototype:doDz()
    status:hpbrief()
    if status.food < 150 then
      SendNoEcho("do 2 eat ganliang")
    end
    if status.drink < 150 then
      SendNoEcho("do 2 drink jiudai")
    end
    helper.checkUntilNotBusy()
    SendNoEcho("dz")
  end

  return prototype
end
return define_xiulian():new()


