--
-- combat.lua
-- User: zhe.jiang
-- Date: 2017/5/18
-- Desc:
-- Change:
-- 2017/5/18 - created

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

---------------------------------------
-- consider with following points:
-- 1. skill
-- 2. weapon
-- 3. energy
-- 4. perform
-- 5. enemy
-- 6. jing, qi, neili
---------------------------------------
local define_combat = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    fight = "fight"
  }
  local Events = {
    STOP = "stop",  -- any state -> stop
    START = "start",  -- stop -> fight
  }
  local REGEXP = {
    ALIAS_START = "^combat\\s+start\\s*$",
    ALIAS_STOP = "^combat\\s+stop\\s*$",
    ALIAS_DEBUG = "^combat\\s+debug\\s+(on|off)\\s*$",
    ALIAS_MODE = "^combat\\s+mode\\s+(.*?)$",
    ENERGY = "^[ >]*���ڹ����в��ϻ���ơ�\\(���ƣ�(\\d+)%\\)$",
  }

  local PFM = {
    -- ���ڣ�Ĭ�����Կ��
    jianzong = {
      {
        weapon = "sword",
        name = "kuangfeng-kuaijian.kuangfeng",
        energy = 12,
      }
    },
    -- ���ڣ�Ĭ���������ƣ������
    qizong = {
      {
        weapon = "sword",
        name = "huashan-jianfa.jianzhang",
        energy = 12,
      },
      {
        weapon = "sword",
        name = "yunushijiu-jian.sanqingfeng",
        energy = 12
      }
    },
    -- ���ڶ����̣�Ĭ������
    ["jianzong-mingjiao"] = {
      {
        weapon = "sword",
        name = "kuangfeng-kuaijian.lianhuan",
        energy = 12,
      }
    },
    -- ���ڶ����̣�Ĭ�������
    ["qizong-mingjiao"] = {
      {
        weapon = "sword",
        name = "dugu-jiujian.poqi",
        energy = 4
      },
      {
        name = "hunyuan-zhang.wuji",
        jiali = "max",
        energy = 12
      }
    }
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
    self.defaultPFM = "qizong"
    self.pfms = PFM[self.defaultPFM]
    self.pfmId = 1
    self.testCombatPfm = "dugu-jiujian.pobing"
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups("combat")
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
      state = States.fight,
      enter = function()
        helper.enableTriggerGroups("combat")
      end,
      exit = function()
        helper.disableTriggerGroups("combat")
      end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.fight,
      event = Events.START,
      action = function() end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<fight>
    self:addTransitionToStop(States.fight)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("combat")
    helper.addTrigger {
      group = "combat",
      regexp = REGEXP.ENERGY,
      response = function(name, line, wildcards)
        self.energy = tonumber(wildcards[1])
        self:debug("��ǰ���ƣ�", self.energy)
        self:doPerformIfEnoughEnergy()
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("combat")
    helper.addAlias {
      group = "combat",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "combat",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "combat",
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
      group = "combat",
      regexp = REGEXP.ALIAS_MODE,
      response = function(name, line, wildcards)
        local mode = wildcards[1]
        if not PFM[mode] then
          ColourNote("yellow", "", "�����ڸ���ս��ģʽ��" .. mode)
        else
          self.defaultPFM = mode
          self.pfms = PFM[mode]
          self.pfmId = 1
        end
      end
    }
  end

  function prototype:setMode(mode)
    if PFM[mode] then
      self.pfms = PFM[mode]
      self.pfmId = 1
      self:debug("ս��ģʽ����Ϊ��", mode)
    else
      self:debug("ս��ģʽ�޷�������Ϊ��", mode)
    end
  end

  function prototype:addTransitionToStop(fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function()
        print("ֹͣ - ��ǰ״̬", self.currState)
      end
    }
  end

  function prototype:doPerformIfEnoughEnergy()
    if self.pfmId > #(self.pfms) then
      self.pfmId = 1
    end
    local currPfm = self.pfms[self.pfmId]
    if self.energy >= currPfm.energy then
      self:debug("������������ʩ��", currPfm.name)
      if currPfm.jiali then
        SendNoEcho("jiali " .. currPfm.jiali)
      end
      if currPfm.weapon then
        SendNoEcho("wield " .. currPfm.weapon)
        SendNoEcho("perform " .. currPfm.name)
      else
        SendNoEcho("remove shield")
        SendNoEcho("perform " .. currPfm.name)
        SendNoEcho("wear shield")
      end
      if currPfm.jiali then
        SendNoEcho("jiali 0")
      end
      -- Ŀǰ�ݲ��ж��Ƿ�ɹ�
      self.pfmId = self.pfmId + 1
    end
  end

  function prototype:start(type)
    if not type then
      self.pfms = PFM[self.defaultPFM]
    elseif not PFM[type] then
      ColourNote("yellow", "", type .. " PFM�趨������")
      self.pfms = PFM[self.defaultPFM]
    else
      self.pfms = PFM[type]
    end
    self.pfmId = 1
    return self:fire(Events.START)
  end

  function prototype:stop(type)
    if not type then
      self.pfms = PFM[self.defaultPFM]
    elseif not PFM[type] then
      ColourNote("yellow", "", type .. " PFM�趨������")
      self.pfms = PFM[self.defaultPFM]
    else
      self.pfms = PFM[type]
    end
    self.pfmId = 1
    return self:fire(Events.STOP)
  end

  return prototype
end
return define_combat():FSM()
