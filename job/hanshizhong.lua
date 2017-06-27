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

你瞬间感到了危险临近，奸细就在附近！

> 树丛
不知不觉，你竟跟到了一处不知名的所在。

异族奸细可能在东南面略高的地方。
溪间

>
su
异族奸细可能在南面略高的地方。
看起来辛生永想杀死你！
看起来司马生亮想杀死你！
看起来邓剑想杀死你！
树桩
    异族奸细 辛生永(Xin shengyong)
    异族奸细 司马生亮(Sima shengliang)
    异族奸细 邓剑(Deng jian)

]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"

local define_hanshizhong = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    search = "search",
    submit = "submit",
  }
  local Events = {
    STOP = "stop",
    START = "start",
    SEARCH = "search",
  }
  local REGEXP = {}

  local JobRoomId = 642

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
    helper.removeAliasGroups("hanshizhong")
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


