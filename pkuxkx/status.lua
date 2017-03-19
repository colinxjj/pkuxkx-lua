--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/19
-- Time: 13:33
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"

local define_status = function()
  local prototype = {}
  prototype.__index = prototype

  local REGEXP = {
    -- 经验，潜能，最大内力，当前内力，最大精力，当前精力
    -- 最大气血，有效气血，当前气血，最大精神，有效精神，当前精神
    HPBRIEF_LINE = "^[ >]*#(\\d+),(\\d+),(\\d+),(\\d+),(\\d+),(\\d+)$",
    -- 真气，真元，食物，饮水
    HPBRIEF_LINE_EX = "^[ >]*#(\\d+),(\\d+),(\\d+),(\\d+)$",
    ALIAS_STATUS_CATCH = "^status\\s+catch\\s*$",
    ALIAS_STATUS_SHOW = "^status\\s+show\\s*$"
  }

  local SINGLETON
  function prototype:singleton()
    if SINGLETON then
      return SINGLETON
    else
      SINGLETON = {}
      setmetatable(SINGLETON, self or prototype)
      SINGLETON:postConstruct()
      return SINGLETON
    end
  end

  function prototype:postConstruct()
    self.catchNum = 1
    self.waitThread = nil

    self.exp = nil
    self.pot = nil
    self.maxNeili = nil
    self.currNeili = nil
    self.maxJingli = nil
    self.currJingli = nil
    self.maxQi = nil
    self.effQi = nil
    self.currQi = nil
    self.maxJing = nil
    self.effJing = nil
    self.currJing = nil
    self.zhenqi = nil
    self.zhenyuan = nil
    self.food = nil
    self.drink = nil

    self:initTriggers()
    self:initAliases()
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("status_hpbrief_start", "status_hpbrief_done")
    helper.addTrigger {
      group = "status_hpbrief_start",
      regexp = helper.settingRegexp("status", "hpbrief_start"),
      response = function()
        helper.enableTriggerGroups("status_hpbrief_done")
        self.catchNum = 1
      end
    }
    helper.addTrigger {
      group = "status_hpbrief_done",
      regexp = helper.settingRegexp("status", "hpbrief_done"),
      response = function()
        helper.disableTriggerGroups("status_hpbrief_start", "status_hpbrief_done")
        self.catchNum = 1
        if self.waitThread then
          local co = self.waitThread
          self.waitThread = nil
          return coroutine.resume(co)
        end
      end
    }
    helper.addTrigger {
      group = "status_hpbrief_done",
      regexp = REGEXP.HPBRIEF_LINE,
      response = function(name, line, wildcards)
        if self.catchNum == 1 then
          self.exp = tonumber(wildcards[1])
          self.pot = tonumber(wildcards[2])
          self.maxNeili = tonumber(wildcards[3])
          self.currNeili = tonumber(wildcards[4])
          self.maxJingli = tonumber(wildcards[5])
          self.currJingli = tonumber(wildcards[6])
          self.catchNum = self.catchNum + 1
        elseif self.catchNum == 2 then
          self.maxQi = tonumber(wildcards[1])
          self.effQi = tonumber(wildcards[2])
          self.currQi = tonumber(wildcards[3])
          self.maxJing = tonumber(wildcards[4])
          self.effJing = tonumber(wildcards[5])
          self.currJing = tonumber(wildcards[6])
          self.catchNum = self.catchNum + 1
        else
          print("错误触发了hpbrief前两行的正则")
        end
      end
    }
    helper.addTrigger {
      group = "status_hpbrief_done",
      regexp = REGEXP.HPBRIEF_LINE_EX,
      response = function(name, line, wildcards)
        if self.catchNum == 3 then
          self.zhenqi = tonumber(wildcards[1])
          self.zhenyuan = tonumber(wildcards[2])
          self.food = tonumber(wildcards[3])
          self.drink = tonumber(wildcards[4])
          self.catchNum = 1
        else
          print("错误触发了hpbrief死三行的正则")
        end
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("status")
    helper.addAlias {
      group = "status",
      regexp = REGEXP.ALIAS_STATUS_CATCH,
      response = function()
        local catcher = coroutine.wrap(function()
          self:catch()
        end)
        catcher()
      end
    }
    helper.addAlias {
      group = "status",
      regexp = REGEXP.ALIAS_STATUS_SHOW,
      response = function()
        self:show()
      end
    }
  end

  function prototype:catch()
    local currCo = assert(coroutine.running, "must in a coroutine")
    self.currThread = currCo
    helper.enableTriggerGroups("status_hpbrief_start")
    SendNoEcho("set status hpbrief_start")
    SendNoEcho("hpbrief")
    SendNoEcho("set status hpbrief_done")
    return coroutine.yield()
  end

  function prototype:show()
    print("精：", self.currJing, "/", self.maxJing)
    print("气：", self.currQi, "/", self.maxQi)
    print("内力：", self.currNeili, "/", self.maxNeili)
    print("精力：", self.currJingli, "/", self.maxJingli)
    print("经验：", self.exp, "潜能：", self.pot)
    print("食物：", self.food, "饮水：", self.drink)
  end

  return prototype
end

return define_status():singleton()