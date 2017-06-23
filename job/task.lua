--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/4/21
-- Time: 7:42
-- To change this template use File | Settings | File Templates.
--

local patterns = {[[
����˵����������ԩ�Ҳ���ͷ���������ɣ�����
>
ne
�����������뿪��

test
������������ɱ���㣡

                ���������������
������������������������������������������������������������������
        �����������������       (δ���)
        ��Ħ�����������         (δ���)
        �������̫����           (δ���)
        ������������             (δ���)
        ��Ī��Ķ���             (δ���)
        �������彣             (δ���)
        ����ɺ������             (δ���)
        ���߹��Ĳ���             (δ���)
        �������               (δ���)
        ��ܽ��ͷ��               (δ���)
        ���������Ů��           (δ���)
        ũ��ĳ�ͷ               (δ���)
        ��¡�Ĺ�ӡ               (δ���)
        �˻�ͷ�Ĵ�Ѫ��˿��       (δ���)
        ������İ���             (δ���)
        �в�ɮ�Ļ�Ե��           (δ���)
        ���޼ɵ�ľ��             (δ���)
        ŷ���˵İ���             (δ���)
        ���õ����               (δ���)
        �������ܵ��廨��         (δ���)
        ���������               (δ���)
        ����ˮ�������           (δ���)
        �Ħ�ǵ��׽           (δ���)
        ½�������������         (δ���)
        ������Ļ���             (δ���)
        �����ľ����澭           (δ���)
        ����Ⱥ����ϼ��           (δ���)
        ���������ָ��           (δ���)
        ���ʦ̫������           (δ���)
        ��ǧ���ˮ��             (δ���)
        �ﲮ��Ķ�����           (δ���)
        ���������ľ��           (δ���)
        �������               (δ���)
        ��ҩʦ����ʯ��           (δ���)
        ɵ�õ��ձ�               (δ���)
        �½��ϵĻ�����           (δ���)
        ���Ʒɵ�������           (δ���)
������������������������������������������������������������������
��һ����ʤģʽʤ���������ǣ���ɽ��
��һ����ʤģʽ��ʼ��ʱ���ǣ���ʮһ��ŷ֡�


]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

local define_fsm = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop"
  }
  local Events = {
    STOP = "stop",
    START = "start"
  }
  local REGEXP = {
    ALIAS_START = "^fsmalias\\s+start\\s*$",
    ALIAS_STOP = "^fsmalias\\s+stop\\s*$",
    ALIAS_DEBUG = "^fsmalias\\s+debug\\s+(on|off)\\s*$",
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
  end

  function prototype:disableAllTriggers()

  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
      end,
      exit = function() end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransitionToStop(States.stop)

  end

  function prototype:initTriggers()

  end

  function prototype:initAliases()
    helper.removeAliasGroups("fsmalias")
    helper.addAlias {
      group = "fsmalias",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "fsmalias",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "fsmalias",
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
        print("ֹͣ - ��ǰ״̬", self.currState)
      end
    }
  end

  return prototype
end
return define_fsm():FSM()
