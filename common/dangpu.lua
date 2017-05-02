--
-- dangpu.lua
-- User: zhe.jiang
-- Date: 2017/5/2
-- Desc:
-- Change:
-- 2017/5/2 - created

local helper = require "pkuxkx.helper"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

local define_dangpu = function()
  local prototype = {}
  prototype.__index = prototype

  local REGEXP = {
    ALIAS_START = "^dangpu\\s+start\\s+(.+?)\\s*$",
    ALIAS_STOP = "^dangpu\\s+stop\\s*$",
    ALIAS_DEBUG = "^dangpu\\s+debug\\s+(on|off)\\s*$",
    -- ��� ���� ���� ���� ������
    LIST_INFO = "^[ >]*��(\\d+)\\s*��(.*?)\\s*��(\\?|\\d+)\\s*��(\\?|\\d+)\\s*��(\\?|\\d+)\\s*��$",
    BOUGHT = "^[ >]*����������.*$",
    CANNOT_BUY = "^[ >]*ָ���ʽ��buy ��$",
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
    self.DEBUG = true
    self.includeUnknown = true
    self.items = {}
    self.currItem = nil
    self.itemsToBuy = {}
  end

  function prototype:debug(...)
    if self.DEBUG then
      print(...)
    end
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("dangpu_info_start", "dangpu_info_done")
    helper.addTriggerSettingsPair {
      group = "dangpu",
      start = "info_start",
      done = "info_done"
    }
    helper.addTrigger {
      group = "dangpu_info_done",
      regexp = REGEXP.LIST_INFO,
      response = function(name, line, wildcards)
        self:debug("LIST_INFO triggered")
        local id = tonumber(wildcards[1])
        local name = wildcards[2]
        local level = wildcards[3] -- maybe ?
        local value = wildcards[4] -- maybe ?
        local holes = wildcards[5] -- maybe ?
        if holes == "?" then
          if self.includeUnknown then
            self:debug("����δ֪������Ʒ�����빺���嵥", id, name)
            table.insert(self.itemsToBuy, {id = id, name = name, level = level, value = value, holes = holes})
          end
        else
          if tonumber(holes) > self.currItem.holes then
            self:debug("���ֺ��ʿ�����Ʒ�����빺���嵥", id, name)
            table.insert(self.itemsToBuy, {id = id, name = name, level = level, value = value, holes = holes})
          end
        end
      end
    }
    helper.addTriggerSettingsPair {
      group = "dangpu",
      start = "buy_start",
      done = "buy_done",
    }
    helper.addTrigger {
      group = "dangpu_buy_done",
      regexp = REGEXP.BOUGHT,
      response = function()

      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("dangpu")
    helper.addAlias {
      group = "dangpu",
      regexp = REGEXP.ALIAS_START,
      response = function(name, line, wildcards)
        local items = utils.split(wildcards[1])
        for _, item in ipairs(items) do
          local ii = utils.split(item, ":")
          table.insert(self.items, {name = ii[1], holes = ii[2] or 2})
        end
        print("���̻���������", "�Ƿ����δ֪��Ʒ��", self.includeUnknown)
        for _, item in self.items do
          print("��ע��Ʒ���ͣ�", item.name, "��ע������", item.holes)
        end
        helper.checkUntilNotBusy()
        travel:walkto(241) -- �����ٱ�ի
        travel:waitUntilArrived()
        helper.enableTimerGroups("dangpu")
      end
    }
    helper.addAlias {
      group = "dangpu",
      regexp = REGEXP.ALIAS_STOP,
      response = function(name, line, wildcards)
        helper.disableTimerGroups("dangpu")

      end
    }
  end

  function prototype:doList()
    self.itemsToBuy = {}
    SendNoEcho("set dangpu info_start")
    SendNoEcho("list " .. self.currItem.name)
    -- make sure traverse all pages
    SendNoEcho(" ")
    SendNoEcho(" ")
    SendNoEcho(" ")
    SendNoEcho("q")
    SendNoEcho("set dangpu info_done")
    helper.checkUntilNotBusy()
    self:debug("׼��������Ʒ��Ŀ��", #(self.itemsToBuy))
  end

  function prototype:doBuy()
    while #(self.itemsToBuy) > 0 do
      self.bought = false
      local item = table.remove(self.itemsToBuy)
      SendNoEcho("set dangpu buy_start")
      SendNoEcho("buy " .. item.id)
      SendNoEcho("set dangpu buy_done")
      helper.checkUntilNotBusy()
      self:debug("�Ƿ��ѹ���", self.bought)
      wait.time(2)
    end

  end

  return prototype
end
return define_dangpu():new()


