--
-- mingxiang.lua
-- User: zhe.jiang
-- Date: 2017/4/13
-- Desc:
-- Change:
-- 2017/4/13 - created

local helper = require "pkuxkx.helper"
local status = require "pkuxkx.status"

local define_mingxiang = function()
  local prototype = {}
  prototype.__index = prototype

  local REGEXP = {
    ALIAS_START = "^mingxiang\\s+start\\s*$",
    ALIAS_STOP = "^mingxiang\\s+stop\\s*$",
    SUCCESS = "^[ >]*��ڤ���˷�ҵ�����,������������!$",
    FAIL = "^[ >]*�������޷�ڤ���ҵ�����!$",
    TUNA_FINISH = "^[ >]*��������ϣ�����˫�ۣ�վ��������$",
    GIFT = "^[ >]*�����ڤڤ���Լ���(.*)�������!$",
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
    self.gifts = {}
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("mingxiang")
    local continue = function()
      wait.time(2)
      status:hpbrief()
      helper.checkUntilNotBusy()
      if status.food < 150 then
        SendNoEcho("do 3 eat ganliang")
      end
      if status.drink < 150 then
        SendNoEcho("do 3 drink jiudai")
      end
      if status.currNeili > 1000 then
        SendNoEcho("lian parry 2")
      end
      if status.currJing > status.maxJing * 0.8 then
        SendNoEcho("north")
        SendNoEcho("read tianlong 10")
        SendNoEcho("enter hole")
      end
      if status.currJingli < 1000 then
        SendNoEcho("tuna 1000")
      else
        if #(self.gifts) > 0 then
          print("�����Ѽ��츳��", table.concat(self.gifts, ", "))
        end
        SendNoEcho("mingxiang")
      end
    end
    helper.addTrigger {
      group = "mingxiang",
      regexp = REGEXP.SUCCESS,
      response = continue
    }
    helper.addTrigger {
      group = "mingxiang",
      regexp = REGEXP.FAIL,
      response = continue
    }
    helper.addTrigger {
      group = "mingxiang",
      regexp = REGEXP.GIFT,
      response = function(name, line, wildcards)
        local gift = wildcards[1]
        table.insert(self.gifts, gift)
        print("�������츳��", gift)
        wait.time(2)
        helper.checkUntilNotBusy()
        SendNoEcho("mingxiang")
      end
    }
    helper.addTrigger {
      group = "mingxiang",
      regexp = REGEXP.TUNA_FINISH,
      response = function()
        SendNoEcho("mingxiang")
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("mingxiang")
    helper.addAlias {
      group = "mingxiang",
      regexp = REGEXP.ALIAS_START,
      response = function()
        helper.enableTriggerGroups("mingxiang")
        SendNoEcho("mingxiang")
      end
    }
    helper.addAlias {
      group = "mingxiang",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        helper.disableTriggerGroups("mingxiang")
      end
    }
  end

  return prototype
end
return define_mingxiang():new()


