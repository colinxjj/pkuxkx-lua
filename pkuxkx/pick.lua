--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/21
-- Time: 10:53
-- To change this template use File | Settings | File Templates.
--
local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

local patterns = [[
id
你身上携带物品的别称如下 :

侠客行战靴           = xkx shoes, shoes
蓝马褂               = cloth
路引                 = lu yin, luyin, newbie guider, guider
锦囊                 = jin nang, nang, baoshi dai, dai, gem bag, sachet
铜板                 = coin, coins, coin_money
白银                 = silver, ingot, silver_money

id
等等，系统喘气中......

一两白银(Silver)
八文铜板(Coin)


l coin
一百七十三文铜板(Coin)
这是流通中单位最小的货币，约要一百文铜板才值得一两白银。

>
l silver
一两白银(Silver)
白花花的银子，人见人爱的银子。


i jian
你身上id为jian的东西有下面这些：
( 1)  长剑(Changjian)
( 2)  长剑(Changjian)
( 3)  长剑(Changjian)

sell jian
你身上没有jian

sell cloth
这样东西不值钱。
这样东西不能买卖。

i
┌──────────────────────────────────────────────────┐
│        你身上带着六件东西          (负重  2%)：                                                    │
├───────────────────────[装  备]───────────────────────┤
│                                 -- [帽子]__   ???   __[副兵] --                                 │
│                                 -- [护面]__    o  o ☆ __[护腕] --                                 │
│                                 -- [披风]__   ??? ?__[手套] --                                 │
│                                 -- [护肩]__ ??Ψ  ? __[铠甲] --                                 │
│                    明黄锦袍   (+1) [衣服]__ ????? __[护肩] --                                 │
│                                 -- [腰带]__ ?  ?     __[盾牌] --                                 │
│                                 -- [主兵]__ ★?禁?   __[护腿] --                                 │
│                                 -- [护腿]__ ??  ?? __[鞋子] 侠客行战靴   (+1)                  │
├───────────────────────[饰  品]───────────────────────┤
│  Ψ[项链]                   --                                      --                   [护心]?  │
│  ★[戒指]                   --                                      --                   [戒指]☆  │
├───────────────────────[其  它]───────────────────────┤
│路引(Lu yin)                                      锦囊(Jin nang)                                    │
│一两白银(Silver)                                  一百七十三文铜板(Coin)                            │
?──────────────────────────────────────────────────?

│        你身上带着六件东西          (负重  1%)：

你刚要前行，忽然发现江水决堤，不由暗自庆幸，还好没过去。


]]


local define_pick = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    status_check = "status_check",
    dining = "dining",
    items_check = "items_check",
    sell = "sell",
    money_check = "money_check",
    store = "store",
    plan_check = "plan_check",
    picking = "picking"
  }
  local Events = {
    STOP = "stop",  --  -> stop
    START = "start",  --  -> status_check
    HUNGRY = "hungry",  --  -> dining
    FULL = "full",  --  -> item_check
    ENOUGH_ITEMS = "enough_items",  --  -> sell
    NOT_ENOUGH_ITEMS = "not_enough_items",  --  -> money_check
    ENOUGH_MONEY = "enough_money", --  -> store
    NOT_ENOUGH_MONEY = "not_enough_money",  --  -> plan_check
    ZONE_TRAVERSABLE = "zone_traversable",  --  -> picking
    ZONE_NOT_TRAVERSABLE = "zone_not_traversable",  --  -> zone+1, status_check
    PICK_DONE = "pick_done",  --  -> status_check
  }
  local REGEXP = {
    ALIAS_PICK = "^picking\\s*$",
    ALIAS_PICK_DEBUG = "^picking\\s+debug\\s+(on|off)\\s*$",
    ALIAS_PICK_START = "^picking\\s+start\\s*$",
    ALIAS_PICK_STOP = "^picking\\s+stop\\s*$",
    CHECK_ITEM_START = helper.settingRegexp("pick", "checkitem_start"),
    CHECK_ITEM_DONE = helper.settingRegexp("pick", "checkitem_done"),
    WEIGHT_RATE = "^│\\s+你身上带着(.*?)件东西\\s+\\(负重\\s*(-?\\d+)%\\)：.*",
    CANNOT_SELL_ITEM = "^(你身上没有.*|这样东西不值钱。|这样东西不能买卖。)$",
    ITEM_ID = "([^ ]+)\\s+\\=\\s+(.+)$",
    COINS_DESC = "^[ >]*(.*)文铜板\\((Coin)\\)",
    SILVERS_DESC = "^[ >]*(.*)两白银\\((Silver)\\)$",
    GOLDS_DESC = "^[ >]*(.*)两黄金\\((Gold)\\)$",
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
    self:initPickSettings()
    self:setState(States.stop)
    self:resetOnStop()
  end

  function prototype:initPickSettings()
    self.pickZones = {
      "luoyang",
      "changan",
      "yangzhou",
      "xinyang",
      "zhongyuan",
      -- "huanghenan",
      -- "changjiangbei",
      "qufu",
      "xiaoshancun",
    }
    self.pickedZones = {}
    for _, zone in ipairs(self.pickZones) do
      self.pickedZones[zone] = 0
    end
    self.itemsExcluded = {
      ["铜钱"] = true,
      ["白银"] = true,
      ["黄金"] = true,
      ["路引"] = true,
      ["锦囊"] = true,
      ["侠客行战靴"] = true,
      ["蓝马褂"] = true,
      ["短打劲装"] = true
    }
    self.coinThreshold = 2000
    self.silverThreshold = 200
    self.goldThreshold = 2
    self.weightThreshold = 50
    self.itemThreshold = 10
  end

  function prototype:resetOnStop()
    self.currPickId = 1  -- this is change when picking -> rest or plan cannot be created
    self.pickItems = {}
    self.pickPlan = nil -- include the startid and the rooms
    self.itemsFull = false
    self.moneyFull = false
    self.moneyCheckCoins = 0
    self.moneyCheckSilvers = 0
    self.moneyCheckGolds = 0
    self.stopPick = true
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:resetOnStop()
        helper.removeTriggerGroups("pick_one_shot")
      end,
      exit = function()
      end
    }
    self:addState {
      state = States.status_check,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.dining,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.items_check,
      enter = function()
        helper.enableTriggerGroups(
          "pick_item_check_start")
        self.itemCount = nil
        self.weightPercent = nil
      end,
      exit = function()
        helper.disableTriggerGroups(
          "pick_item_check_start",
          "pick_item_check_done")
      end
    }
    self:addState {
      state = States.sell,
      enter = function()
        helper.enableTriggerGroups(
          "pick_sell_check_start")
        self.itemsToSell = {}
      end,
      exit = function()
        helper.disableTriggerGroups(
          "pick_sell_check_start",
          "pick_sell_check_done")
      end
    }
    self:addState {
      state = States.money_check,
      enter = function()
        helper.enableTriggerGroups(
          "pick_money_check_start")
        self.moneyCheckCoins = 0
        self.moneyCheckSilvers = 0
        self.moneyCheckGolds = 0
      end,
      exit = function()
        helper.disableTriggerGroups(
          "pick_money_check_start",
          "pick_money_check_done")
      end
    }
    self:addState {
      state = States.store,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.plan_check,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.picking,
      enter = function()
        helper.enableTriggerGroups("pick_picking")
        -- only stop by user send the stop command
        self.stopPick = false
      end,
      exit = function()
        helper.disableTriggerGroups("pick_picking")
      end
    }
  end

  function prototype:initTransitions()
    -- transitions from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.status_check,
      event = Events.START,
      action = function()
        return self:doStatusCheck()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transitions from state<status_check>
    self:addTransition {
      oldState = States.status_check,
      newState = States.dining,
      event = Events.HUNGRY,
      action = function()
        return self:doEat()
      end
    }
    self:addTransition {
      oldState = States.status_check,
      newState = States.items_check,
      event = Events.FULL,
      action = function()
        return self:doItemsCheck()
      end
    }
    self:addTransitionToStop(States.status_check)
    -- transitions from state<dining>
    self:addTransition {
      oldState = States.dining,
      newState = States.items_check,
      event = Events.FULL,
      action = function()
        return self:doItemsCheck()
      end
    }
    self:addTransitionToStop(States.dining)
    -- transitions from state<items_check>
    self:addTransition {
      oldState = States.items_check,
      newState = States.sell,
      event = Events.ENOUGH_ITEMS,
      action = function()
        return self:doSell()
      end
    }
    self:addTransition {
      oldState = States.items_check,
      newState = States.money_check,
      event = Events.NOT_ENOUGH_ITEMS,
      action = function()
        return self:doMoneyCheck()
      end
    }
    self:addTransitionToStop(States.items_check)
    -- transitions from state<sell>
    self:addTransition {
      oldState = States.sell,
      newState = States.money_check,
      event = Events.NOT_ENOUGH_ITEMS,
      action = function()
        return self:doMoneyCheck()
      end
    }
    self:addTransitionToStop(States.sell)
    -- transitions from state<money_check>
    self:addTransition {
      oldState = States.money_check,
      newState = States.store,
      event = Events.ENOUGH_MONEY,
      action = function()
        return self:doStore()
      end
    }
    self:addTransition {
      oldState = States.money_check,
      newState = States.plan_check,
      event = Events.NOT_ENOUGH_MONEY,
      action = function()
        return self:doPlanCheck()
      end
    }
    self:addTransitionToStop(States.money_check)
    -- transitions from state<store>
    self:addTransition {
      oldState = States.store,
      newState = States.plan_check,
      event = Events.NOT_ENOUGH_MONEY,
      action = function()
        return self:doPlanCheck()
      end
    }
    self:addTransitionToStop(States.store)
    -- transitions from state<plan_check>
    self:addTransition {
      oldState = States.plan_check,
      newState = States.picking,
      event = Events.ZONE_TRAVERSABLE,
      action = function()
        return self:doPick()
      end
    }
    self:addTransition {
      oldState = States.plan_check,
      newState = States.status_check,
      event = Events.ZONE_NOT_TRAVERSABLE,
      action = function()
        self:nextPick()
        return self:doStatusCheck()
      end
    }
    self:addTransitionToStop(States.plan_check)
    -- transitions from state<picking>
    self:addTransition {
      oldState = States.picking,
      newState = States.status_check,
      event = Events.PICK_DONE,
      action = function()
        local currZone = self:currZone()
        if self.pickedZones[currZone] then
          self.pickedZones[currZone] = self.pickedZones[currZone] + 1
        else
          self.pickedZones[currZone] = 1
        end
        self:nextPick()
        return self:doStatusCheck()
      end
    }
    self:addTransitionToStop(States.picking)
  end

  function prototype:nextPick()
    self.currPickId = self.currPickId + 1
    if self.currPickId > #(self.pickZones) then
      self.currPickId = 1
    end
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "pick_item_check_start",
      "pick_item_check_done",
      "pick_sell_check_start",
      "pick_sell_check_done",
      "pick_money_check_start",
      "pick_money_check_done",
      "pick_picking"
    )
    -- item check triggers
    helper.addTrigger {
      group = "pick_item_check_start",
      regexp = helper.settingRegexp("pick", "itemcheck_start"),
      response = function()
        self:debug("激活载重检测")
        helper.enableTriggerGroups("pick_item_check_done")
      end
    }
    helper.addTrigger {
      group = "pick_item_check_done",
      regexp = REGEXP.WEIGHT_RATE,
      response = function(name, line, wildcards)
        self:debug("载重查看触发", wildcards[1], wildcards[2])
        self.itemCount = helper.ch2number(wildcards[1])
        self.weightPercent = tonumber(wildcards[2])
      end
    }
    helper.addTrigger {
      group = "pick_item_check_done",
      regexp = helper.settingRegexp("pick", "itemcheck_done"),
      response = function()
        self:debug("身上物品数目：", self.itemCount)
        self:debug("升上物品重量百分比：", self.weightPercent)
        if self.weightPercent >= self.weightThreshold or self.itemCount >= self.itemThreshold then
          return self:fire(Events.ENOUGH_ITEMS)
        else
          return self:fire(Events.NOT_ENOUGH_ITEMS)
        end
      end
    }
    -- sell check triggers
    helper.addTrigger {
      group = "pick_sell_check_start",
      regexp = helper.settingRegexp("pick", "sellcheck_start"),
      response = function()
        helper.enableTriggerGroups("pick_sell_check_done")
      end
    }
    helper.addTrigger {
      group = "pick_sell_check_done",
      regexp = REGEXP.ITEM_ID,
      response = function(name, line, wildcards)
        local itemNameCN = wildcards[1]
        local itemIds = wildcards[2]
        local itemId = string.lower(utils.split(itemIds, ",")[1])
        if not self.itemsToSell then
          self.itemsToSell = {}
        end
        if not self.itemsExcluded[itemNameCN] then
          table.insert(self.itemsToSell, itemId)
        end
      end
    }
    helper.addTrigger {
      group = "pick_sell_check_done",
      regexp = helper.settingRegexp("pick", "sellcheck_done"),
      response = function()
        helper.disableTriggerGroups("pick_sell_check_done")
        if self.itemsToSell and #(self.itemsToSell) > 0 then
          self:debug("需要售卖东西有：", table.concat(self.itemsToSell, ","))
          -- 扬州当铺30
          return travel:walkto(30, function()
            while #(self.itemsToSell) > 0 do
              local item = table.remove(self.itemsToSell)
              while true do
                SendNoEcho("sell " .. item)
                local line = wait.regexp(REGEXP.CANNOT_SELL_ITEM, 2)
                if line then break end
              end
            end
            return self:fire(Events.NOT_ENOUGH_ITEMS)
          end)
        else
          self:debug("无东西可卖")
          return self:fire(Events.NOT_ENOUGH_ITEMS)
        end
      end
    }
    -- money check triggers
    helper.addTrigger {
      group = "pick_money_check_start",
      regexp = helper.settingRegexp("pick", "moneycheck_start"),
      response = function()
        helper.enableTriggerGroups("pick_money_check_done")
      end
    }
    helper.addTrigger {
      group = "pick_money_check_done",
      regexp = helper.settingRegexp("pick", "moneycheck_done"),
      response = function()
        if self.moneyCheckCoins > self.coinThreshold
          or self.moneyCheckSilvers > self.silverThreshold
          or self.moneyCheckGolds > self.goldThreshold then
          self:debug(
            "身上金钱超过限额：",
            "gold:" .. self.moneyCheckGolds,
            "silver:" .. self.moneyCheckSilvers,
            "coins:" .. self.moneyCheckCoins)
          return self:fire(Events.ENOUGH_MONEY)
        else
          self:debug(
            "身上金钱未超过限额：",
            "gold:" .. self.moneyCheckGolds,
            "silver:" .. self.moneyCheckSilvers,
            "coins:" .. self.moneyCheckCoins)
          return self:fire(Events.NOT_ENOUGH_MONEY)
        end
      end
    }
    helper.addTrigger {
      group = "pick_money_check_done",
      regexp = REGEXP.COINS_DESC,
      response = function(name, line, wildcards)
        self.moneyCheckCoins = helper.ch2number(wildcards[1])
      end
    }
    helper.addTrigger {
      group = "pick_money_check_done",
      regexp = REGEXP.SILVERS_DESC,
      response = function(name, line, wildcards)
        self.moneyCheckSilvers = helper.ch2number(wildcards[1])
      end
    }
    helper.addTrigger {
      group = "pick_money_check_done",
      regexp = REGEXP.GOLDS_DESC,
      response = function(name, line, wildcards)
        self.moneyCheckGolds = helper.ch2number(wildcards[1])
      end
    }
    -- picking triggers
    self:addPickingTriggers {
      -- 黄金，白银
      "^[ >]*.*两(?:黄金|白银)\\((.*)\\)$",
      -- 铜钱
      "^[ >]*.*文铜钱\\((Coin)\\)$",
      -- 武器
      "^[ >]*(?:铁甲|钢刀|钢剑|钢杖|长剑)\\((.*)\\)$"
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("pick")

    helper.addAlias {
      group = "pick",
      regexp = REGEXP.ALIAS_PICK,
      response = function()
        print("PICK捡垃圾指令如下：")
        print("picking start", "开始捡垃圾")
        print("picking stop", "停止捡垃圾")
        print("picking debug on/off", "开启/关闭调试模式")
      end
    }
    helper.addAlias {
      group = "pick",
      regexp = REGEXP.ALIAS_PICK_DEBUG,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self:debugOn()
        elseif cmd == "off" then
          self:debugOff()
        end
      end
    }
    helper.addAlias {
      group = "pick",
      regexp = REGEXP.ALIAS_PICK_START,
      response = function()
        self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "pick",
      regexp = REGEXP.ALIAS_PICK_STOP,
      response = function()
        self:fire(Events.STOP)
      end
    }
  end

  -- the first catched pattern must be the English name of the item
  function prototype:addPickingTriggers(patterns)
    for _, pattern in ipairs(patterns) do
      helper.addTrigger {
        group = "pick_picking",
        regexp = pattern,
        response = function(name, line, wildcards)
          local name = string.lower(wildcards[1])
          table.insert(self.pickItems, name)
        end
      }
    end
  end

  function prototype:addTransitionToStop(fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function() print("停止，当前状态", fromState) end
    }
  end

  function prototype:doStatusCheck()
    wait.time(1)
    status:catch()
    if status.food < 100 or status.drink < 100 then
      return self:fire(Events.HUNGRY)
    else
      return self:fire(Events.FULL)
    end
  end

  function prototype:doEat()
    travel:walkto(882, function()
      SendNoEcho("ne")
      SendNoEcho("e")
      SendNoEcho("ne")
      SendNoEcho("n")
      SendNoEcho("say 狐狸狐狸")
      helper.assureNotBusy()
      SendNoEcho("do 2 eat")
      helper.assureNotBusy()
      SendNoEcho("do 2 drink")
      helper.assureNotBusy()
      SendNoEcho("out")
      SendNoEcho("s")
      SendNoEcho("sw")
      SendNoEcho("w")
      SendNoEcho("sw")
      wait.time(3)
      helper.assureNotBusy()
      return self:fire(Events.FULL)
    end)
  end

  function prototype:doItemsCheck()
    self:debug("1秒后检查身上物品")
    wait.time(1)
    SendNoEcho("set pick itemcheck_start")
    SendNoEcho("i")
    SendNoEcho("set pick itemcheck_done")
  end

  function prototype:doSell()
    self:debug("1秒后检查身上可售卖物品")
    wait.time(1)
    SendNoEcho("set pick sellcheck_start")
    SendNoEcho("id")
    SendNoEcho("set pick sellcheck_done")
  end

  function prototype:doMoneyCheck()
    self:debug("1秒后检查身上金额")
    wait.time(1)
    SendNoEcho("set pick moneycheck_start")
    SendNoEcho("get coin")
    SendNoEcho("l coin")
    SendNoEcho("get silver")
    SendNoEcho("l silver")
    SendNoEcho("get gold")
    SendNoEcho("l gold")
    SendNoEcho("set pick moneycheck_done")
  end

  function prototype:doStore()
    self:debug("等待1秒前往钱庄存钱")
    wait.time(1)
    helper.assureNotBusy()
    return travel:walkto(91, function()
      wait.time(1)
      if self.moneyCheckCoins > self.coinThreshold then
        helper.assureNotBusy()
        SendNoEcho("convert " .. self.coinThreshold .. " coin to silver")
      end
      if self.moneyCheckSilvers > self.silverThreshold then
        helper.assureNotBusy()
        SendNoEcho("convert " .. self.silverThreshold .. " silver to gold")
      end
      if self.moneyCheckGolds > self.goldThreshold then
        helper.assureNotBusy()
        SendNoEcho("cun " .. self.goldThreshold .. " gold")
      end
      return self:fire(Events.NOT_ENOUGH_MONEY)
    end)
  end

  function prototype:doPlanCheck()
    if travel:isZoneTraversable(self:currZone()) then
      return self:fire(Events.ZONE_TRAVERSABLE)
    else
      return self:fire(Events.ZONE_NOT_TRAVERSABLE)
    end
  end

  function prototype:doPick()
    local currZone = self:currZone()
    local check = function()
      if self.pickItems and #(self.pickItems) > 0 then
        while #(self.pickItems) > 0 do
          local item = table.remove(self.pickItems)
          SendNoEcho("get " .. item)
        end
      end
      -- always return false to continue traverse
      return self.stopPick
    end
    local action = function()
      return self:fire(Events.PICK_DONE)
    end

    local startCode = travel.zonesByCode[currZone].centercode
    local startId = travel.roomsByCode[startCode].id
    travel:walkto(startId, function()
      return travel:traverseZone(currZone, check, action)
    end)
  end

  function prototype:currZone()
    return self.pickZones[self.currPickId]
  end

  return prototype
end

return define_pick():FSM()