--
-- hanshizhong.lua
-- User: zhe.jiang
-- Date: 2017/5/12
-- Desc:
-- Change:
-- 2017/5/12 - created

local patterns = {[[
642

韩世忠(han shizhong)告诉你：你去休息休息，过段时间再来吧。

韩世忠说道：「我听说有一群异族奸细在福州的北门附近出没，你带上我的兵符，去打探(datan)一下，必须要留下一两个奸细，给他们一个教训。」

datan
你心中暗道：就是这里了，于是紧跟着几个形迹可疑的人走去。

这时，你展开了精心绘制的地区地图，找到了异族奸细的行迹。
你的客户端不支持MXP,请直接打开链接查看图片。
请注意，忽略验证码中的红色文字。
http://pkuxkx.net/antirobot/robot.php?filename=1496618202176383

你离开了这一片奸细出没的区域。


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
        print("停止 - 当前状态", self.currState)
      end
    }
  end

  return prototype
end
return define_hanshizhong():FSM()


