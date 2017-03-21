--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/19
-- Time: 13:33
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"

local define_status = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    catch = "catch",
  }
  local Events = {
    STOP = "stop",
    CATCH = "catch",
    SHOW = "show"
  }

  local REGEXP = {
    -- 经验，潜能，最大内力，当前内力，最大精力，当前精力
    -- 最大气血，有效气血，当前气血，最大精神，有效精神，当前精神
    HPBRIEF_LINE = "^[ >]*#(-?\\d+),(-?\\d+),(-?\\d+),(-?\\d+),(-?\\d+),(-?\\d+)$",
    -- 真气，真元，食物，饮水
    HPBRIEF_LINE_EX = "^[ >]*#(-?\\d+),(-?\\d+),(-?\\d+),(-?\\d+)$",
    ALIAS_STATUS_CATCH = "^status\\s+catch\\s*$",
    ALIAS_STATUS_SHOW = "^status\\s+show\\s*$"
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
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self.catchNum = 1
      end,
      exit = function()
        self.catchNum = 1
      end
    }
    self:addState {
      state = States.catch,
      enter = function()
        helper.disableTriggerGroups("status_hpbrief_done")
        helper.enableTriggerGroups("status_hpbrief_start")
      end,
      exit = function()
        helper.disableTriggerGroups("status_hpbrief_start", "status_hpbrief_done")
      end
    }
  end

  function prototype:initTransitions()
    self:addTransition {
      oldState = States.stop,
      newState = States.catch,
      event = Events.CATCH,
      action = function()
        self:doCatch()
      end
    }
    self:addTransition {
      oldState = States.catch,
      newState = States.stop,
      event = Events.STOP,
      action = function() end
    }
    self:addTransition {
      oldState = States.stop,
      newState = States.stop,
      event = Events.SHOW,
      action = function()
        self:doShow()
      end
    }
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
    helper.addTrigger {
      group = "status_hpbrief_done",
      regexp = REGEXP.HPBRIEF_LINE,
      response = function(name, line, wildcards)
        local catchNum = self.catchNum
        if catchNum == 1 then
          self.exp = tonumber(wildcards[1])
          self.pot = tonumber(wildcards[2])
          self.maxNeili = tonumber(wildcards[3])
          self.currNeili = tonumber(wildcards[4])
          self.maxJingli = tonumber(wildcards[5])
          self.currJingli = tonumber(wildcards[6])
          self.catchNum = catchNum + 1
        elseif catchNum == 2 then
          self.maxQi = tonumber(wildcards[1])
          self.effQi = tonumber(wildcards[2])
          self.currQi = tonumber(wildcards[3])
          self.maxJing = tonumber(wildcards[4])
          self.effJing = tonumber(wildcards[5])
          self.currJing = tonumber(wildcards[6])
          self.catchNum = catchNum + 1
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
          print("错误触发了hpbrief第三行的正则")
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
        self:catch()
      end
    }
    helper.addAlias {
      group = "status",
      regexp = REGEXP.ALIAS_STATUS_SHOW,
      response = function()
        self:fire(Events.SHOW)
      end
    }
  end

  function prototype:doCatch()
    if self.waitThread then
      error("Previous thread is not disposed")
    end
    self.waitThread = assert(coroutine.running(), "Must be in coroutine")
    SendNoEcho("set status hpbrief_start")
    SendNoEcho("hpbrief")
    SendNoEcho("set status hpbrief_done")
    return coroutine.yield()
  end

  function prototype:doShow()
    print("精：", self.currJing, "/", self.maxJing)
    print("气：", self.currQi, "/", self.maxQi)
    print("内力：", self.currNeili, "/", self.maxNeili)
    print("精力：", self.currJingli, "/", self.maxJingli)
    print("经验：", self.exp, "潜能：", self.pot)
    print("食物：", self.food, "饮水：", self.drink)
  end

  function prototype:current()
    return {
      exp = self.exp,
      pot = self.pot,
      maxNeili = self.maxNeili,
      currNeili = self.currNeili,
      maxJingli = self.maxJingli,
      currJingli = self.currJingli,
      maxQi = self.maxQi,
      effQi = self.effQi,
      currQi = self.currQi,
      maxJing = self.maxJing,
      effJing = self.effJing,
      currJing = self.currJing,
      zhenqi = self.zhenqi,
      zhenyuan = self.zhenyuan,
      food = self.food,
      drink = self.drink,
    }
  end

  function prototype:catch()
    self:fire(Events.CATCH)
    self:fire(Events.STOP)
  end

  function prototype:show()
    self:fire(Events.SHOW)
  end

  return prototype
end

return define_status():FSM()