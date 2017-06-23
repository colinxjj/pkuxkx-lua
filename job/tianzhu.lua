--
-- tianzhu.lua
-- User: zhe.jiang
-- Date: 2017/4/23
-- Desc:
-- Change:
-- 2017/4/23 - created


local patterns = {[[

莲花生大士(lianhuasheng dashi)告诉你：我推测天珠可能即将在福州的密室房梁出世，你不妨去看一看。

历经艰辛之后，你获取了出世的天珠，可以把它交给莲花生大士复命了。

give dashi tian zhu
莲花生大士默默接过你手中的天珠，轻轻抚摸着。
> 莲花生大士给了你一枚天珠，并嘱咐到：在短期内佩戴(pei)在身会有凝神醒脑、提升修为的作用。
莲花生大士轻笑，居然有一颗山◎玉髓包裹在天珠的外面，你也一起拿去吧。
莲花生大士说道：「建康府的南贤与我有旧，你可以去他那里请教真气运行的规则。」

]]}


local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local captcha = require "pkuxkx.captcha"

local define_tianzhu = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    fight = "fight",
    submit = "submit",
  }
  local Events = {
    STOP = "stop",  -- any state -> stop
    START = "start",  -- stop -> ask
    GO = "go",  -- ask -> fight
    CAPTCHA = "captcha",  --> ask -> ask
    CANNOT_GO = "cannot_go",  -- ask -> stop
    BACK = "back",  -- fight -> submit
  }
  local REGEXP = {
    ALIAS_START = "^tianzhu\\s+start\\s*$",
    ALIAS_STOP = "^tianzhu\\s+stop\\s*$",
    ALIAS_DEBUG = "^tianzhu\\s+debug\\s+(on|off)\\s*$",
    ALIAS_SEARCH = "^tianzhu\\s+search\\s+(.+)$",
    ALIAS_BACK = "^tianzhu\\s+back\\s*$",
    JOB_INFO = "^[ >]*莲花生大士\\(lianhuasheng dashi\\)告诉你：我推测天珠可能即将在(.*?)出世，你不妨去看一看。$",
    CAPTCHA = "^[ >]*请注意，忽略验证码中的红色文字。$",
    REWARDED = "^[ >]*莲花生大士给了你一枚天珠，并嘱咐到.*$",
    OBTAINED = "^[ >]*历经艰辛之后，你获取了出世的天珠，可以把它交给莲花生大士复命了。$",
    ZHENQI = "^[ >]*莲花生大士说道：「建康府的南贤与我有旧，你可以去他那里请教真气运行的规则。」$",
  }

  local JobRoomId = 1842

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

  function prototype:resetOnStop()
    self.needCaptcha = false
    self.targetLocation = nil
  end

  function prototype:disableAllTriggers()

  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
        self:resetOnStop()
      end,
      exit = function() end
    }
    self:addState {
      state = States.ask,
      enter = function()
        helper.enableTriggerGroups("tianzhu_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("tianzhu_ask_start", "tianzhu_ask_done")
      end
    }
    self:addState {
      state = States.fight,
      enter = function()
        helper.enableTriggerGroups("tianzhu_fight")
      end,
      exit = function()
        helper.disableTriggerGroups("tianzhu_fight")
      end
    }
    self:addState {
      state = States.submit,
      enter = function() 
        helper.enableTriggerGroups("tianzhu_submit")
      end,
      exit = function() 
        helper.disableTriggerGroups("tianzhu_submit")
      end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransitionToStop(States.stop)
    self:addTransition {
      oldState = States.stop,
      newState = States.ask,
      event = Events.START,
      action = function()
        return self:doGetJob()
      end
    }
    -- transition from state<ask>
    self:addTransition {
      oldState = States.ask,
      newState = States.stop,
      event = Events.CANNOT_GO,
      action = function()
        return self:doCancel()
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.fight,
      event = Events.GO,
      action = function()
        assert(self.targetLocation, "target location cannot be nil")
        return self:doGo()
      end
    }
    self:addTransitionToStop(States.ask)
    -- transition from state<fight>
    self:addTransition {
      oldState = States.fight,
      newState = States.submit,
      event = Events.BACK,
      action = function()
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.fight)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("tianzhu_ask_start", "tianzhu_ask_done", "tianzhu_submit")
    helper.addTriggerSettingsPair {
      group = "tianzhu",
      start = "ask_start",
      done = "ask_done",
    }
    helper.addTrigger {
      group = "tianzhu_ask_done",
      regexp = REGEXP.JOB_INFO,
      response = function(name, line, wildcards)
        self:debug("JOB_INFO triggered")
        self.targetLocation = wildcards[1]
      end
    }
    helper.addTrigger {
      group = "tianzhu_ask_done",
      regexp = REGEXP.CAPTCHA,
      response = function()
        self.needCaptcha = true
      end
    }

    helper.addTrigger {
      group = "tianzhu_fight",
      regexp = REGEXP.OBTAINED,
      response = function()
        SendNoEcho("get silver from corpse")
        SendNoEcho("get silver from corpse 2")
        SendNoEcho("get silver from corpse 3")
        SendNoEcho("get silver from corpse 4")
        SendNoEcho("get silver from corpse 5")
        ColourNote("green", "", "已获取天珠，返回请输入tianzhu back")
      end
    }

    helper.addTrigger {
      group = "tianzhu_submit",
      regexp = REGEXP.REWARDED,
      response = function()
        ColourNote("green", "", "任务完成，佩戴(pei)或碾碎(break)天珠")
        wait.time(1)
        return self:fire(Events.STOP)
      end
    }
    helper.addTrigger {
      group = "tianzhu_submit",
      regexp = REGEXP.ZHENQI,
      response = function()
        ColourNote("lime", "", "快去询问真气")
        ColourNote("lime", "", "快去询问真气")
        ColourNote("lime", "", "快去询问真气")
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("tianzhu")
    helper.addAlias {
      group = "tianzhu",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "tianzhu",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "tianzhu",
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
      group = "tianzhu",
      regexp = REGEXP.ALIAS_SEARCH,
      response = function(name, line, wildcards)
        self.targetLocation = wildcards[1]
        return self:fire(Events.GO)
      end
    }
    helper.addAlias {
      group = "tianzhu",
      regexp = REGEXP.ALIAS_BACK,
      response = function()
        return self:doSubmit()
      end
    }
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

  function prototype:doGetJob()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    wait.time(1)
    self.targetLocation = nil
    self.needCaptcha = false
    SendNoEcho("set tianzhu ask_start")
    SendNoEcho("ask dashi about job")
    SendNoEcho("set tianzhu ask_done")
    helper.checkUntilNotBusy()
    if self.targetLocation then
      return self:fire(Events.GO)
    elseif self.needCaptcha then
      ColourNote("yellow", "", "请手动输入验证码，格式为：tianzhu search <地点>")
    else
      print("未获取到任务信息，等待8秒后继续询问")
      wait.time(8)
      return self:doGetJob()
    end
  end

  function prototype:doCancel()
    ColourNote("red", "", "请手动取消任务")
  end

  function prototype:doGo()
    travel:walktoFirst {
      fullname = self.targetLocation
    }
    travel:waitUntilArrived()
    print("到达目的地")
  end

  function prototype:doSubmit()
    travel:stop()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    wait.time(1)
    SendNoEcho("give dashi tian zhu")
    wait.time(1)
    helper.checkUntilNotBusy()
    return self:fire(Events.STOP)
  end

  return prototype
end
return define_tianzhu():FSM()
