--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/4/3
-- Time: 19:41
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"

local define_donate = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    donate = "donate"
  }
  local Events = {
    STOP = "stop",
    START = "start",
    DONATE = "donate",
    NO_MONEY = "no_money",
    NO_MONEY_IN_BANK = "no_money_in_bank",
    BUY_WEAPON = "buy_weapon",
  }
  local REGEXP = {
    ALIAS_START = "^donating\\s+start\\s+([a-z0-9_]+)\\s+(.+)$",
    ALIAS_STOP = "^donating\\s+stop\\s*$",
    ALIAS_DEBUG = "^donating\\s+debug\\s+(on|off)\\s*$",
    WEAPON_BOUGHT = "^[ >]*你向当铺买下.*$",
    WEAPON_DONATED = "^[ >]*你把.*交给一名襄阳来的士兵。他对你表示感谢。$",
    NO_MONEY = "^[ >]*你没有足够的钱。$",
    NO_MONEY_IN_BANK = "^[ >]*你没有存那么多的钱。$",
    MONEY_WITHDRAWED = "^[ >]*你从银号里取出.*$",
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
    self.weaponBuyId = nil
    self.weaponId = nil
    self.noMoney = false
    self.noMoneyInBank = false
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups("donate")
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
      state = States.donate,
      enter = function()
        helper.enableTriggerGroups("donate")
      end,
      exit = function()
        helper.enableTriggerGroups("donate")
      end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.donate,
      event = Events.START,
      action = function()
        assert(self.weaponBuyId, "购买武器id不可为空")
        assert(self.weaponId, "武器Id不可为空")
        return self:fire(Events.BUY_WEAPON)
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<donate>
    self:addTransition {
      oldState = States.donate,
      newState = States.donate,
      event = Events.DONATE,
      action = function()
        return travel:walkto(1034, function()
          self:doDonate()
        end)
      end
    }
    self:addTransition {
      oldState = States.donate,
      newState = States.donate,
      event = Events.BUY_WEAPON,
      action = function()
        self.noMoney = false
        return travel:walkto(30, function()
          return self:doBuy()
        end)
      end
    }
    self:addTransition {
      oldState = States.donate,
      newState = States.donate,
      event = Events.NO_MONEY,
      action = function()
        return travel:walkto(91, function()
          return self:doWithdraw()
        end)
      end
    }
    self:addTransition {
      oldState = States.donate,
      newState = States.donate,
      event = Events.NO_MONEY_IN_BANK,
      action = function()
        return self:fire(Events.STOP)
      end
    }
    self:addTransitionToStop(States.donate)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("donate")
    helper.addTrigger {
      group = "donate",
      regexp = REGEXP.NO_MONEY,
      response = function()
        self.noMoney = true
      end
    }
    helper.addTrigger {
      group = "donate",
      regexp = REGEXP.NO_MONEY_IN_BANK,
      response = function()
        self.noMoneyInBank = true
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("donate")
    helper.addAlias {
      group = "donate",
      regexp = REGEXP.ALIAS_START,
      response = function(name, line, wildcards)
        self.weaponBuyId = wildcards[1]
        self.weaponId = wildcards[2]
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "donate",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "donate",
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

  function prototype:doBuy()
    local cnt = 0
    while not self.noMoney do
      wait.time(1)
      SendNoEcho("buy " .. self.weaponBuyId)
      local line = wait.regexp(REGEXP.WEAPON_BOUGHT, 1)
      if line then
        cnt = cnt + 1
        if cnt >= 10 then
          return self:fire(Events.DONATE)
        end
      end
    end
    return self:fire(Events.NO_MONEY)
  end

  function prototype:doDonate()
    while true do
      helper.assureNotBusy()
      SendNoEcho("donate " .. self.weaponId)
      local line = wait.regexp(REGEXP.WEAPON_DONATED, 2)
      if not line then
        return self:fire(Events.BUY_WEAPON)
      else
        wait.time(1)
      end
    end
  end

  function prototype:doWithdraw()
    while not self.noMoneyInBank do
      SendNoEcho("qu 5 gold")
      local line = wait.regexp(REGEXP.MONEY_WITHDRAWED, 1)
      if line then
        return self:fire(Events.BUY_WEAPON)
      end
    end
    return self:fire(Events.NO_MONEY_IN_BANK)
  end

  return prototype
end
return define_donate():FSM()
