--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/6/5
-- Time: 7:20
-- To change this template use File | Settings | File Templates.
--

local patterns = {[[
7

你向蒙面杀手打听有关『fight』的消息。
蒙面杀手说道：「要打便打，不必多言！」

ask xiao about job
你向萧峰打听有关『job』的消息。
萧峰点了点头：好！
你的客户端不支持MXP,请直接打开链接查看图片。
请注意，忽略验证码中的红色文字。
http://pkuxkx.net/antirobot/robot.php?filename=1496619389147359

蒙面杀手脸色微变，说道：「佩服，佩服！」


-- sheng

你战胜了蒙面杀手!
蒙面杀手深深地叹了口气。
从蒙面杀手身上掉了出来一只朱睛冰蟾
算了，我认输啦，算你狠！
> 你向蒙面杀手打听有关『认输』的消息。
蒙面杀手说道：「老子已经认输了，你还讨什么口舌之利？！」
> 蒙面杀手纵身远远的去了。


突然间你身形电闪，瞬间逼近蒙面杀手，剑掌交替中向蒙面杀手奋力击出三剑两掌！

( 蒙面杀手似乎十分疲惫，看来需要好好休息了。 )『蒙面杀手(damage:+1154 wound:+384 气血:49%/68%)』
( 蒙面杀手已经一副头重脚轻的模样，正在勉力支撑著不倒下去。 )『蒙面杀手(damage:+668 气血:31%/68%)』

蒙面杀手向后一纵，恨恨地说道：「君子报仇，十年不晚！」


你战胜了蒙面杀手!
蒙面杀手深深地叹了口气。
从蒙面杀手身上掉了出来一些黄金
算了，我认输啦，算你狠！
> 你向蒙面杀手打听有关『认输』的消息。
蒙面杀手说道：「老子已经认输了，你还讨什么口舌之利？！」

-- qin
你向萧峰打听有关『job』的消息。
萧峰点了点头：好！
萧峰道：「传闻西夏一品堂派出了若干蒙面杀手，最近出现在湟中附近的大道。
          此人于中原武林颇为有用，你去将他擒回这里交给我。打晕其之后若他再醒来，可直接点晕(dian)他。
          此人武功深不可测，千万小心！」
萧峰拍拍你的肩，说道：「好兄弟，就交给你了！珍重！」



你战胜了蒙面杀手!
叫老子认输？嘿嘿，你别做梦了！
> 经过一段时间后，你终于完全从紧张地战斗氛围中解脱出来。

你走近蒙面杀手，只见蒙面杀手衣领上几个蝇头小字，显是蒙面杀手姓名。

你战胜了呼延鹏三!
叫老子认输？嘿嘿，你别做梦了！

呼延鹏三脚下一个不稳，跌在地上一动也不动了。

你将呼延鹏三扶了起来背在背上。
>


-- quan
你向萧峰打听有关『job』的消息。
萧峰点了点头：好！
萧峰道：「传闻西夏一品堂派出了若干蒙面杀手，最近出现在桃花岛附近的山路。
          此人加入西夏一品堂不久，尚可教化，你去劝劝(quan)他吧。
          此人武功颇强，务须准备周全。」
萧峰拍拍你的肩，说道：「好兄弟，就交给你了！珍重！」


你走上前去，试图劝服蒙面杀手，但蒙面杀手不耐烦的转了个身，不愿听你说下去。
看来教训教训他再试试，可能效果会更好。
> 蒙面杀手深深吸了几口气，脸色看起来好多了。

你嘿嘿一笑：「蒙面杀手，你都到了如此田地，怎地还是执迷不悟？」
蒙面杀手深深地叹了口气。
蒙面杀手纵身远远的去了。

ask xiao about finish
你向萧峰打听有关『finish』的消息。
萧峰说道：「很好。撸兄弟，辛苦你了！」
你被奖励了：
        六千零八点经验；
        一千九百八十二点潜能；
        一百七十一点江湖声望。
你已经完成了四次劝服杀手的工作。
萧峰说道：「我也筹集了一些银两，已经嘱人存入你的帐户。」
萧峰说道：「虽然不多，但是略表心意。」
你获得了四份火铜【劣质】。ll

ask xiao about finish
你向萧峰打听有关『finish』的消息。
萧峰说道：「很好。撸兄弟，辛苦你了！」
你被奖励了：
        一万零六百七十二点经验；
        六千四百零三点潜能；
        一千一百十六点江湖声望。
你已经完成了四次战胜杀手的工作。
萧峰说道：「我也筹集了一些银两，已经嘱人存入你的帐户。」
萧峰说道：「虽然不多，但是略表心意。」
你获得了三份陨铁【劣质】。

]]}


local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local captcha = require "pkuxkx.captcha"

local XiaofengMode = {
  KILL = 1,  -- 杀
  CAPTURE = 2,  -- 擒
  PERSUADE = 3,  -- 劝
  WIN = 4,  -- 胜
}

local define_xiaofeng = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    search = "search",
    kill = "kill",
    persuade = "persuade",
    win = "win",
    capture = "capture",
    submit = "submit",
  }
  local Events = {
    STOP = "stop",  -- any state -> stop
    START = "start",  -- stop -> ask
    SEARCH = "search",
  }
  local REGEXP = {
    ALIAS_START = "^xiaofeng\\s+start\\s*$",
    ALIAS_STOP = "^xiaofeng\\s+stop\\s*$",
    ALIAS_DEBUG = "^xiaofeng\\s+debug\\s+(on|off)\\s*$",
--    ALIAS_CAPTURE = "^xiaofeng\\s+capture\\s+(.*)\\s*$",
--    ALIAS_PERSUADE = "^xiaofeng\\s+persuade\\s+(.*)\\s*$",
--    ALIAS_KILL = "^xiaofeng\\s+kill\\s+(.*)\\s*$",
--    ALIAS_WIN = "^xiaofeng\\s+win\\s+(.*)\\s*$",
    ALIAS_DO = "^xiaofeng\\s+(擒|杀|劝|降)\\s+(.*?)\\s*$",
    JOB_CAPTURE = "^ *此人于中原武林颇为有用，你去将他擒回这里交给我。打晕其之后若他再醒来.*$",
    JOB_PERSUADE = "^ *此人加入西夏一品堂不久，尚可教化，你去劝劝.*$",
    JOB_KILL = "^ *kill shashou$",
    JOB_WIN = "^ *win shashou$",
    JOB_CAPTCHA = "^请注意，忽略验证码中的红色文字。$",
    WORK_TOO_FAST = "^work too fast$",
    PREV_NOT_FINISH = "^prev not finish$",
    MR_RIGHT = "^[ >]*蒙面杀手说道：「要打便打，不必多言！」$",
  }

  local JobRoomId = 7

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
    self.mode = nil
    self.DEBUG = true
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
    self:addTransition {
      oldState = States.stop,
      newState = States.ask,
      event = Events.START,
      action = function()
        return self:doGetJob()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<ask>
    self:addTransition {
      oldState = States.ask,
      newState = States.search,
      event = Events.SEARCH,
      action = function()
        return self:doSearch()
      end
    }
    self:addTransition {

    }
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("xiaofeng_ask_start", "xiaofeng_ask_done")
    helper.addTriggerSettingsPair {
      group = "xiaofeng",
      start = "ask_start",
      done = "ask_done"
    }
    helper.addTrigger {
      group = "xiaofeng_ask_done",
      regexp = REGEXP.JOB_KILL,
      response = function()
        self.mode = XiaofengMode.KILL
      end
    }
    helper.addTrigger {
      group = "xiaofeng_ask_done",
      regexp = REGEXP.JOB_CAPTURE,
      response = function()
        self.mode = XiaofengMode.CAPTURE
      end
    }
    helper.addTrigger {
      group = "xiaofeng_ask_done",
      regexp = REGEXP.JOB_PERSUADE,
      response = function()
        self.mode = XiaofengMode.PERSUADE
      end
    }
    helper.addTrigger {
      group = "xiaofeng_ask_done",
      regexp = REGEXP.JOB_WIN,
      response = function()
        self.mode = XiaofengMode.WIN
      end
    }
    helper.addTriggerSettingsPair {
      group = "xiaofeng",
      start = "identify_start",
      done = "identify_done"
    }
    helper.addTrigger {
      group = "xiaofeng_identify_done",
      regexp = REGEXP.MR_RIGHT,
      response = function()
        self.identified = true
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("xiaofeng")
    helper.addAlias {
      group = "xiaofeng",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "xiaofeng",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "xiaofeng",
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
        print("停止 - 当前状态", self.currState)
      end
    }
  end

  function prototype:doGetJob()
    helper.checkUntilNotBusy()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    wait.time(1)
    self.needCaptcha = false
    self.workTooFast = false
    self.prevNotFinish = false
    self.location = nil
    self.mode = nil
    SendNoEcho("set xiaofeng ask_start")
    SendNoEcho("ask xiaofeng about job")
    SendNoEcho("set xiaofeng ask_done")
    helper.checkUntilNotBusy()
    if self.needCaptcha then
      ColourNote("yellow", "", "请手动输入验证码，xiaofeng 劝/擒/降/杀 地点")
      return
    elseif self.workTooFast then
      self:debug("等待8秒后再次询问")
      wait.time(8)
      return self:doGetJob()
    elseif self.prevNotFinish then
      self:debug("前次任务没有完成，取消之")
      wait.time(1)
      SendNoEcho("ask xiao about fail")
      return self:doGetJob()
    end

    return self:fire(Events.SEARCH)
  end

  function prototype:doStart()
    return self:fire(Events.START)
  end

  return prototype
end
return define_xiaofeng():FSM()
