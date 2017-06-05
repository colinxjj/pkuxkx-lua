--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/5/7
-- Time: 22:37
-- To change this template use File | Settings | File Templates.
--


local patterns = {[[
975

��֮��˵�����������˶����ӣ����ȵ�����С���Ⱥ����Ի�֪ͨ�㡣��

> ��֮���и������ڳ����͸�����һҳ���롣
��֮��(meng zhijing)�����㣺��һ�����ڣ��ڰ��У���ʮ�С��ڶ������ڣ���һ�У���ʮ�С����������ڣ��ھ��У������С�����(duizhao)��ҳ�����֪����Ҫ��ɱ���������ˡ�

duizhao
�㱳�����ˣ����ĵش��˾�ֽ��

��1 2 3 4 5 6 7 8 9 1011
1 �����帷˿���������հ�
2 ����ɽƽ��������կ����
3 ������������ɽ�˸���ɽ
4 �������������˿Դ����
5 ���и�����������Ŀ�ױ�
6 ���ٸ�ɽ��ԭ���󰲳���
7 ���ҺӸ�����ƽ�ٽ�Ȫׯ
8 ������������·��˿����
9 ��ɽ������Ŀɽ��Ľ�ɰ�

> �㶨��һ����������������Ҫ�ҵĺ�����������
����
    ��Ԫ �������ϳ�·������ʹ ������(Peng xiaoluan)

��Ԫ �������ϳ�·���ָ�ʹ �˽�(Gu jie)

�Ϲ���������Ķ����ˡ�

��ϲ��������˶�ͳ�Ƹ��д�����

]]}


local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"

local define_cisha = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    search = "search",
    fight = "fight",
    submit = "submit"
  }
  local Events = {
    STOP = "stop",
    START = "start"
  }
  local REGEXP = {
    ALIAS_START = "^cisha\\s+start\\s*$",
    ALIAS_STOP = "^cisha\\s+stop\\s*$",
    ALIAS_DEBUG = "^cisha\\s+debug\\s+(on|off)\\s*$",
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
    self:addTransitionToStop(States.STOP)

  end

  function prototype:initTriggers()

  end

  function prototype:initAliases()
    helper.removeAliasGroup("cisha")
    helper.addAlias {
      group = "cisha",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "cisha",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "cisha",
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
return define_cisha():FSM()
