--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/4/16
-- Time: 19:38
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"
local status = require "pkuxkx.status"
local travel = require "pkuxkx.travel"
local nanjue = require "job.nanjue"

--------------------------------------------------------------
-- lingwu.lua
-- 领悟基本武功，请自备干粮和酒袋
--------------------------------------------------------------

local define_learn = function()
  local prototype = {}
  prototype.__index = prototype

  local REGEXP = {
    ALIAS_START = "^learning\\s+start\\s*$",
    ALIAS_STOP = "^learning\\s+stop\\s*$",
    ALIAS_CMD = "^learning\\s+cmd\\s+(.*?)\\s*$",
    ALIAS_ROOM = "^learning\\s+room\\s+(\\d+)\\s*$",
    DAZUO_FINISH = "^[ >]*你运功完毕，深深吸了口气，站了起来。$",
    NOT_ENOUGH_JING_DAZUO = "^[ >]*你现在精不够，无法控制内息的流动！$",
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
    self.learnCmd = "xue feng for huashan-neigong 50"
    self.stopped = true
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("learning")
    helper.addTrigger {
      group = "learning",
      regexp = REGEXP.DAZUO_FINISH,
      response = function()
        return self:doLearn()
      end
    }
    helper.addTrigger {
      group = "learning",
      regexp = REGEXP.NOT_ENOUGH_JING_DAZUO,
      response = function()
        wait.time(5)
        return self:doLearn()
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("learning")

    helper.addAlias {
      group = "learning",
      regexp = REGEXP.ALIAS_START,
      response = function()
        if self.learnRoomId then
          travel:walkto(self.learnRoomId)
          travel:waitUntilArrived()
        end
        helper.enableTriggerGroups("learning")
        self.stopped = false
        self:doLearn()
      end
    }
    helper.addAlias {
      group = "learning",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        helper.disableTriggerGroups("learning")
        self.stopped = true
      end
    }
    helper.addAlias {
      group = "learning",
      regexp = REGEXP.ALIAS_CMD,
      response = function(name, line, wildcards)
        self.learnCmd = wildcards[1]
      end
    }
    helper.addAlias {
      group = "learning",
      regexp = REGEXP.ALIAS_ROOM,
      response = function(name, line, wildcards)
        local roomId = tonumber(wildcards[1])
        if roomId == 0 then
          self.learnRoomId = nil
        else
          self.learnRoomId = roomId
        end
      end
    }
  end

  function prototype:doLearn()
    while not self.stopped do
      status:hpbrief()
      if status.food < 150 then
        SendNoEcho("do 3 eat ganliang")
      end
      if status.drink < 150 then
        SendNoEcho("do 3 drink jiudai")
      end
      if status.currNeili > 700 then
        SendNoEcho("yun regenerate")
        SendNoEcho(self.learnCmd)
        wait.time(2)
      else
        SendNoEcho("yun recover")
        SendNoEcho("dazuo max")
        break
      end
    end
  end

  return prototype
end
return define_learn():new()
