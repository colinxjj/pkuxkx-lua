--
-- hanshizhong.lua
-- User: zhe.jiang
-- Date: 2017/5/12
-- Desc:
-- Change:
-- 2017/5/12 - created

local patterns = {[[
642

������(han shizhong)�����㣺��ȥ��Ϣ��Ϣ������ʱ�������ɡ�

������˵����������˵��һȺ�����ϸ�ڸ��ݵı��Ÿ�����û��������ҵı�����ȥ��̽(datan)һ�£�����Ҫ����һ������ϸ��������һ����ѵ����

datan
�����а��������������ˣ����ǽ����ż����μ����ɵ�����ȥ��

��ʱ����չ���˾��Ļ��Ƶĵ�����ͼ���ҵ��������ϸ���м���
��Ŀͻ��˲�֧��MXP,��ֱ�Ӵ����Ӳ鿴ͼƬ��
��ע�⣬������֤���еĺ�ɫ���֡�
http://pkuxkx.net/antirobot/robot.php?filename=1496618202176383

���뿪����һƬ��ϸ��û������


]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"

local define_hanshizhong = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop"
  }
  local Events = {
    STOP = "stop",
    START = "start"
  }
  local REGEXP = {}

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

  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("hanshizhong_ask_start", "hanshizhong_ask_done")
  end

  function prototype:initAliases()

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
return define_hanshizhong():FSM()


