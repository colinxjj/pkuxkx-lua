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
������Я����Ʒ�ı������ :

������սѥ           = xkx shoes, shoes
�����               = cloth
·��                 = lu yin, luyin, newbie guider, guider
����                 = jin nang, nang, baoshi dai, dai, gem bag, sachet
ͭ��                 = coin, coins, coin_money
����                 = silver, ingot, silver_money

id
�ȵȣ�ϵͳ������......

һ������(Silver)
����ͭ��(Coin)


l coin
һ����ʮ����ͭ��(Coin)
������ͨ�е�λ��С�Ļ��ң�ԼҪһ����ͭ���ֵ��һ��������

>
l silver
һ������(Silver)
�׻��������ӣ��˼��˰������ӡ�


i jian
������idΪjian�Ķ�����������Щ��
( 1)  ����(Changjian)
( 2)  ����(Changjian)
( 3)  ����(Changjian)

sell jian
������û��jian

sell cloth
����������ֵǮ��
������������������

i
��������������������������������������������������������������������������������������������������������
��        �����ϴ�����������          (����  2%)��                                                    ��
������������������������������������������������[װ  ��]������������������������������������������������
��                                 -- [ñ��]__   ???   __[����] --                                 ��
��                                 -- [����]__    o  o �� __[����] --                                 ��
��                                 -- [����]__   ??? ?__[����] --                                 ��
��                                 -- [����]__ ??��  ? __[����] --                                 ��
��                    ���ƽ���   (+1) [�·�]__ ????? __[����] --                                 ��
��                                 -- [����]__ ?  ?     __[����] --                                 ��
��                                 -- [����]__ ��?��?   __[����] --                                 ��
��                                 -- [����]__ ??  ?? __[Ь��] ������սѥ   (+1)                  ��
������������������������������������������������[��  Ʒ]������������������������������������������������
��  ��[����]                   --                                      --                   [����]?  ��
��  ��[��ָ]                   --                                      --                   [��ָ]��  ��
������������������������������������������������[��  ��]������������������������������������������������
��·��(Lu yin)                                      ����(Jin nang)                                    ��
��һ������(Silver)                                  һ����ʮ����ͭ��(Coin)                            ��
?����������������������������������������������������������������������������������������������������?

��        �����ϴ�����������          (����  1%)��

���Ҫǰ�У���Ȼ���ֽ�ˮ���̣����ɰ������ң�����û��ȥ��


]]


local define_pick = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    status_check = "status_check",
    dining = "dining",
    sell = "sell",
    store = "store",
    plan_check = "plan_check",
    picking = "picking"
  }
  local Events = {
    STOP = "stop",  --  -> stop
    START = "start",  --  -> status_check
    HUNGRY = "hungry",  --  -> dining
    FULL = "full",  --  -> status_check
    ENOUGH_ITEMS = "enough_items",  --  -> sell
    NOT_ENOUGH_ITEMS = "not_enough_items",  --  -> status_check
    ENOUGH_MONEY = "enough_money", --  -> store
    NOT_ENOUGH_MONEY = "not_enough_money",  --  -> status_check
    PREPARE_PLAN = "prepare_plan", --  -> plan_check
    ZONE_TRAVERSABLE = "zone_traversable",  --  -> picking
    ZONE_NOT_TRAVERSABLE = "zone_not_traversable",  --  -> zone+1, status_check
    PICK_DONE = "pick_done",  --  -> status_check
    MAX_MONEY_STORED = "max_money_stored",  -- -> stop

  }
  local REGEXP = {
    ALIAS_PICK = "^picking\\s*$",
    ALIAS_PICK_DEBUG = "^picking\\s+debug\\s+(on|off)\\s*$",
    ALIAS_PICK_START = "^picking\\s+start\\s*$",
    ALIAS_PICK_STOP = "^picking\\s+stop\\s*$",
    WEIGHT_RATE = "^��\\s+�����ϴ���(.*?)������\\s+\\(����\\s*(-?\\d+)%\\)��.*",
    CANNOT_SELL_ITEM = "^[ >]*(������û��.*|����������ֵǮ��|������������������)$",
    ITEM_ID = "([^ ]+)\\s+\\=\\s+([^\"]+)$",
    COINS_DESC = "^[ >]*(.*)��ͭ��\\((Coin)\\)",
    SILVERS_DESC = "^[ >]*(.*)������\\((Silver)\\)$",
    GOLDS_DESC = "^[ >]*(.*)���ƽ�\\((Gold)\\)$",
    CANNOT_STORE_MONEY = "^[ >]*��Ŀǰ���д��.*���ٴ���ô���Ǯ������С�ſ��ѱ����ˡ�$",
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
      "qufu",
      "xiaoshancun",
      "lingzhou"
    }
    self.pickedZones = {}
    for _, zone in ipairs(self.pickZones) do
      self.pickedZones[zone] = 0
    end
    self.itemsExcluded = {
      ["ͭ��"] = true,
      ["����"] = true,
      ["�ƽ�"] = true,
      ["·��"] = true,
      ["����"] = true,
      ["������սѥ"] = true,
      ["�����"] = true,
      ["�̴�װ"] = true,
      ["����"] = true,
      ["������"] = true,
    }
    self.coinThreshold = 2000
    self.silverThreshold = 200
    self.goldThreshold = 2
    self.weightThreshold = 50
    self.itemThreshold = 15
  end

  function prototype:resetOnStop()
    self.currPickId = 1  -- this is change when picking -> rest or plan cannot be created
    self.pickItems = {}
    self.pickPlan = nil -- include the startid and the rooms
    self.itemsFull = false
    self.moneyFull = false
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
      state = States.sell,
      enter = function()
        self.itemsToSell = {}
      end,
      exit = function()
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
        helper.enableTriggerGroups("pick")
        -- only stop by user send the stop command
        self.stopPick = false
      end,
      exit = function()
        helper.disableTriggerGroups("pick")
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
      newState = States.sell,
      event = Events.ENOUGH_ITEMS,
      action = function()
        return self:doSell()
      end
    }
    self:addTransition {
      oldState = States.status_check,
      newState = States.store,
      event = Events.ENOUGH_MONEY,
      action = function()
        return self:doStore()
      end
    }
    self:addTransition {
      oldState = States.status_check,
      newState = States.plan_check,
      event = Events.PREPARE_PLAN,
      action = function()
        return self:doPlanCheck()
      end
    }
    self:addTransitionToStop(States.status_check)
    -- transitions from state<dining>
    self:addTransition {
      oldState = States.dining,
      newState = States.status_check,
      event = Events.FULL,
      action = function()
        return self:doStatusCheck()
      end
    }
    self:addTransitionToStop(States.dining)
    -- transitions from state<sell>
    self:addTransition {
      oldState = States.sell,
      newState = States.status_check,
      event = Events.NOT_ENOUGH_ITEMS,
      action = function()
        return self:doStatusCheck()
      end
    }
    self:addTransitionToStop(States.sell)
    -- transitions from state<store>
    self:addTransition {
      oldState = States.store,
      newState = States.status_check,
      event = Events.NOT_ENOUGH_MONEY,
      action = function()
        return self:doStatusCheck()
      end
    }
    self:addTransition {
      oldState = States.store,
      newState = States.stop,
      event = Events.MAX_MONEY_STORED,
      action = function()
        print("������ɣ��洢�������ޣ�ֹͣ��������")
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
        -- �����ʱ�����м���
        if self.pickedZones[currZone] then
          self.pickedZones[currZone] = self.pickedZones[currZone] + 1
        else
          self.pickedZones[currZone] = 1
        end
        self:showPickedZones()
        self:nextPick()
        return self:doStatusCheck()
      end
    }
    self:addTransitionToStop(States.picking)
  end

  function prototype:showPickedZones()
    print("����ɼ��������򼰴������£�")
    for zone, cnt in pairs(self.pickedZones) do
      print(zone, cnt)
    end
  end

  function prototype:nextPick()
    self.currPickId = self.currPickId + 1
    if self.currPickId > #(self.pickZones) then
      self.currPickId = 1
    end
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("pick")
    -- picking triggers
    self:addPickingTriggers {
      -- �ƽ𣬰���
      "^[ >]*.*��(?:�ƽ�|����)\\((.*)\\)$",
      -- ͭǮ
      "^[ >]*.*��ͭǮ\\((Coin)\\)$",
      -- ����
      "^[ >]*(?:����|�ֵ�|�ֽ�|����|����)\\((.*)\\)$"
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("pick")

    helper.addAlias {
      group = "pick",
      regexp = REGEXP.ALIAS_PICK,
      response = function()
        print("PICK������ָ�����£�")
        print("picking start", "��ʼ������")
        print("picking stop", "ֹͣ������")
        print("picking debug on/off", "����/�رյ���ģʽ")
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
        group = "pick",
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
      action = function() print("ֹͣ����ǰ״̬", fromState) end
    }
  end

  function prototype:doStatusCheck()
    wait.time(1)
    helper.assureNotBusy()

    -- ���ʳ����ˮ�Ƿ����
    status:hpbrief()
    if status.food < 100 or status.drink < 100 then
      return self:fire(Events.HUNGRY)
    end
    self:debug("ʳ����ˮ����", status.food, status.drink)
    -- ��鸺������Ʒ�����Ƿ��㹻����
    status:inventory()
    if status.weightPercent >= self.weightThreshold or status.itemCount >= self.itemThreshold then
      return self:fire(Events.ENOUGH_ITEMS)
    end
    self:debug("��Ʒ������������������", status.weightPercent, status.itemCount)
    -- ������Ƿ��㹻�洢
  status:money()
    if status.coins > self.coinThreshold
      or status.silvers > self.silverThreshold
      or status.golds > self.goldThreshold then
      self:debug(
        "���Ͻ�Ǯ�����޶",
        "gold:" .. status.coins,
        "silver:" .. status.silvers,
        "coins:" .. status.coins)
      return self:fire(Events.ENOUGH_MONEY)
    end
    self:debug("���Ͻ�����洢����", status.golds, status.silvers, status.coins)
    self:debug("״̬�����ϣ�׼�����߼ƻ�")
    return self:fire(Events.PREPARE_PLAN)
  end

  function prototype:doEat()
    travel:walkto(3798, function()
      helper.assureNotBusy()
      SendNoEcho("do 2 eat")
      helper.assureNotBusy()
      SendNoEcho("do 2 drink")
      helper.assureNotBusy()
      wait.time(3)
      return self:fire(Events.FULL)
    end)
  end

  function prototype:doSell()
    self:debug("1��������Ͽ�������Ʒ")
    wait.time(1)
    helper.assureNotBusy()
    status:id()
    if not status.items then
      error("�����޷���׽������Ʒ")
    end
    if not self.itemsToSell then
      self.itemsToSell = {}
    end
    for _, item in pairs(status.items) do
      if not self.itemsExcluded[item.name] then
        table.insert(self.itemsToSell, item)
      end
    end
    if #(self.itemsToSell) > 0 then
      if self.DEBUG then
        self:debug("��Ҫ�����Ķ����У�")
        for _, item in pairs(self.itemsToSell) do
          self:debug(item.id, item.name)
        end
      end
      -- todo δ�����Ż�Ϊ�ھͽ��ĵ��̽��г���
      return travel:walkto(30, function()
        while #(self.itemsToSell) > 0 do
          local item = table.remove(self.itemsToSell)
          local sellRetries = 0
          -- �����������Σ�����Բ��ɹ�
          while sellRetries <= 3 do
            helper.assureNotBusy()
            SendNoEcho("sell " .. item.id)
            local line = wait.regexp(REGEXP.CANNOT_SELL_ITEM, 2)
            if line then
              -- ����Ƿ����Ʒ��������
              if string.find(line, "��ֵǮ") or string.find(line, "��������") then
                helper.assureNotBusy()
                if not self.itemExcluded[item.name] then
                  SendNoEcho("drop " .. item.id)
                end
              end
              break
            end
            sellRetries = sellRetries + 1
          end
        end
        return self:fire(Events.NOT_ENOUGH_ITEMS)
      end)
    else
      self:debug("�޶�������")
      return self:fire(Events.NOT_ENOUGH_ITEMS)
    end
  end

  function prototype:doStore()
    self:debug("�ȴ�1��ǰ��Ǯׯ��Ǯ")
    wait.time(1)
    helper.assureNotBusy()
    return travel:walkto(91, function()
      wait.time(1)
      status:money()
      if status.coins > self.coinThreshold then
        helper.assureNotBusy()
        SendNoEcho("convert " .. self.coinThreshold .. " coin to silver")
        wait.time(2)
        status:money()
      end
      if status.silvers > self.silverThreshold then
        helper.assureNotBusy()
        SendNoEcho("convert " .. self.silverThreshold .. " silver to gold")
        wait.time(2)
        status:money()
      end
      if status.golds > self.goldThreshold then
        helper.assureNotBusy()
        SendNoEcho("cun " .. self.goldThreshold .. " gold")
      end
      local line = wait.regexp(REGEXP.CANNOT_STORE_MONEY, 3)
      if line then
        return self:fire(Events.MAX_MONEY_STORED)
      else
        return self:fire(Events.NOT_ENOUGH_MONEY)
      end
    end)
  end

  function prototype:doPlanCheck()
    helper.assureNotBusy()
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