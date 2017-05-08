--
-- murong.lua
-- User: zhe.jiang
-- Date: 2017/4/20
-- Desc:
-- Change:
-- 2017/4/20 - created

local patterns = {[[

ask pu about job
你向仆人打听有关『job』的消息。
仆人说道：「壮士能为慕容世家出力，真是太好了。」
仆人叹道：家贼难防，有人偷走了少爷的信件，据传曾在以下地点附近出现，你去把它找回来吧！
你的客户端不支持MXP,请直接打开链接查看图片。
请注意，忽略验证码中的红色文字。
http://pkuxkx.net/antirobot/robot.php?filename=1492781942600002

慕容世家家贼死了。

你从慕容世家家贼的尸体身上搜出一封信件。

give pu xin
仆人对着你点了点头。
仆人说道：「干得好！」
你给仆人一封信件。
> 由于你成功的找回慕容复写给江湖豪杰的信件，被奖励：
一千零九十点实战经验，
一百四十八点潜能，
八十点江湖声望作为答谢。
仆人看着你会心地一笑。
仆人在你的耳边悄声说道：为了表达对你的谢意，我已经在你的帐户存了一些辛苦费！

你向仆人打听有关『job』的消息。
仆人说道：「壮士能为慕容世家出力，真是太好了。」
仆人叹道：家贼难防，有人偷走了少爷的信件，据传曾在『临安府怡红馆』附近出现，你去把它找回来吧！

]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

local define_murong = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    search = "search",
    kill = "kill",
    submit = "submit",
  }
  local Events = {
    STOP = "stop",  -- any status -> stop
    START = "start",  -- stop -> ask
    NEW_JOB = "new_job",  -- ask -> search
    NEW_JOB_CAPTCHA = "new_job_captcha",
    GARBAGE = "^[ >]*你获得了.*份(石炭|玄冰)【.*?】。$",
    NEXT_SEARCH = "next_search",  -- search -> search
    JIAZEI_FOUND = "jiazei_found",  -- search -> kill
    JIAZEI_MISS = "jiazei_miss", -- kill -> search
    JIAZEI_KILLED = "jiazei_killed", -- kill -> submit
  }
  local REGEXP = {
    ALIAS_START = "^murong\\s+start\\s*$",
    ALIAS_STOP = "^murong\\s+stop\\s*$",
    ALIAS_DEBUG = "^murong\\s+debug\\s+(on|off)\\s*$",
    ALIAS_SEARCH = "^murong\\s+search\\s+(.*?)\\s*$",
    CAPTCHA_LINK = "^(http://pkuxkx.net/antirobot.*)$",
    JOB_INFO = "^[ >]*仆人叹道：家贼难防，有人偷走了少爷的信件，据传曾在『(.*?)』附近出现，你去把它找回来吧.*$",
    WORK_TOO_FAST = "^[ >]*仆人对着你摇了摇头说：「你刚做过任务，先去休息休息吧。」$",
    JIAZEI_DESC = "^\\s*(.*?)发现的 慕容世家内鬼\\((.*)\\).*$",
    JIAZEI_KILLED = "^[ >]*慕容世家内鬼死了。$",
    JIAZEI_MISSED = "^[ >]*你想杀谁？$",
  }

  local ExcludedZones = {
    ["黄河南岸"] = true,
    ["黄河北岸"] = true,
    ["长江"] = true,
    ["长江北岸"] = true
  }

  function prototype:FSM()
    local obj = FSM:new()
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  local SearchDepth = 5

  function prototype:postConstruct()
    self:initStates()
    self:initTransitions()
    self:initTriggers()
    self:initAliases()
    self:initTimers()
    self:setState(States.stop)
    self.precondition = {
      jing = 1,
      qi = 1,
      neili = 1.6,
      jingli = 1
    }

    self.myName = "撸啊"

    self.DEBUG = true
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups("murong_ask_start", "murong_ask_done", "murong_search")
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
        SendNoEcho("set jobs job_done")  -- jobs框架
      end,
      exit = function() end
    }
    self:addState {
      state = States.ask,
      enter = function()
        helper.enableTriggerGroups("murong_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("murong_ask_start", "murong_ask_done")
      end
    }
    self:addState {
      state = States.search,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.kill,
      enter = function() end,
      exit = function()
        helper.disableTriggerGroups("murong_kill")
        helper.disableTimerGroups("murong_kill")
      end
    }
    self:addState {
      state = States.submit,
      enter = function() end,
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
        return self:doAsk()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<ask>
    self:addTransition {
      oldState = States.ask,
      newState = States.search,
      event = Events.NEW_JOB,
      action = function()
        return self:doPrepareSearch()
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.search,
      event = Events.NEW_JOB_CAPTCHA,
      action = function()
        ColourNote("yellow", "", "需要识别验证码，请手动输入murong search <位置信息>")
        ColourNote("yellow", "", self.captchaLink)
      end
    }
    self:addTransitionToStop(States.ask)
    -- transition from state<search>
    self:addTransition {
      oldState = States.search,
      newState = States.search,
      event = Events.NEXT_SEARCH,
      action = function()
        return self:doSearch()
      end
    }
    self:addTransition {
      oldState = States.search,
      newState = States.search,
      event = Events.NEW_JOB_CAPTCHA,
      action = function()
        assert(self.searchLocation, "searchLocation cannot be nil")
        return self:doPrepareSearch()
      end
    }
    self:addTransition {
      oldState = States.search,
      newState = States.kill,
      event = Events.JIAZEI_FOUND,
      action = function()
        return self:doKill()
      end
    }
    self:addTransitionToStop(States.search)
    -- transition from state<kill>
    self:addTransition {
      oldState = States.kill,
      newState = States.search,
      event = Events.JIAZEI_MISS,
      action = function()
        local currRoom = travel.roomsById[travel.currRoomId]
        self.searchRooms = { currRoom }
        self.searchedRoomIds = {}  -- this is required as we may skip it because it's previously searched
        return self:doSearch()
      end
    }
    self:addTransition {
      oldState = States.kill,
      newState = States.submit,
      event = Events.JIAZEI_KILLED,
      action = function()
        helper.checkUntilNotBusy()
        SendNoEcho("get xin from corpse")
        SendNoEcho("get gold from corpse")
        SendNoEcho("get silver from corpse")
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.kill)
    -- transition from state<submit>
    self:addTransitionToStop(States.submit)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("murong_ask_start", "murong_ask_done",
      "murong_search", "murong_kill")
    helper.addTriggerSettingsPair {
      group = "murong",
      start = "ask_start",
      done = "ask_done"
    }
    helper.addTrigger {
      group = "murong_ask_done",
      regexp = REGEXP.JOB_INFO,
      response = function(name, line, wildcards)
        self.searchLocation = wildcards[1]
      end
    }
    helper.addTrigger {
      group = "murong_ask_done",
      regexp = REGEXP.CAPTCHA_LINK,
      response = function(name, line, wildcards)
        self.captchaLink = wildcards[1]
      end
    }
    helper.addTrigger {
      group = "murong_ask_done",
      regexp = REGEXP.WORK_TOO_FAST,
      response = function(name, line, wildcards)
        self.workTooFast = true
      end
    }
    -- jiazei名称固定
    helper.addTrigger {
      group = "murong_search",
      regexp = REGEXP.JIAZEI_DESC,
      response = function(name, line, wildcards)
        local playerName = wildcards[1]
        self:debug("JIAZEI_DESC triggered", playerName)
        if playerName == self.myName then
          --找到家贼，则设置目标地点为当前房间编号
          self:debug("发现家贼")
          self.targetRoomId = travel.traverseRoomId
          self.jiazeiId = string.lower(wildcards[2])
        else
          self:debug("别人的家贼")
        end
      end
    }
    helper.addTrigger {
      group = "murong_kill",
      regexp = REGEXP.JIAZEI_KILLED,
      response = function()
        self:debug("JIAZEI_KILLED triggered")
        self.jiazeiKilled = true
      end
    }
    helper.addTrigger {
      group = "murong_kill",
      regexp = REGEXP.JIAZEI_MISSED,
      response = function()
        self:debug("JIAZEI_MISSED triggered")

      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("murong")
    helper.addAlias {
      group = "murong",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "murong",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "murong",
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
      group = "murong",
      regexp = REGEXP.ALIAS_SEARCH,
      response = function(name, line, wildcards)
        self.searchLocation = wildcards[1]
        return self:fire(Events.NEW_JOB_CAPTCHA)
      end
    }
  end

  function prototype:initTimers()
    helper.removeTimerGroups("murong_kill")
    helper.addTimer {
      group = "murong_kill",
      interval = 2,
      response = function()
        if not self.killSeconds then
          self.killSeconds = 0
        else
          self.killSeconds = self.killSeconds + 2
        end
        self:debug("战斗时间", self.killSeconds)
        if self.killSeconds % 3 == 0 then
--          SendNoEcho("perform dugu-jiujian.poqi")
          SendNoEcho("wield sword")
          SendNoEcho("perform huashan-jianfa.jianzhang")
--          SendNoEcho("perform yunushijiu-jian.sanqingfeng")
          SendNoEcho("perform dugu-jiujian.pobing")
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

  function prototype:doAsk()
    travel:walkto(479)
    travel:waitUntilArrived()
    self.searchLocation = nil
    self.captchaLink = nil
    self.workTooFast = false
    SendNoEcho("set murong ask_start")
    SendNoEcho("ask pu about job")
    SendNoEcho("set murong ask_done")
    helper.checkUntilNotBusy()
    if self.workTooFast then
      self:debug("工作太快，无法获取任务，等待5秒后重新询问")
      wait.time(5)
      return self:doAsk()
    elseif self.captchaLink then
      return self:fire(Events.NEW_JOB_CAPTCHA)
    elseif self.searchLocation then
      return self:fire(Events.NEW_JOB)
    else
      ColourNote("yellow", "", "没有获取到任务地点，任务失败")
      return self:doCancel()
    end
  end

  function prototype:doPrepareSearch()
    local place = helper.ch2place(self.searchLocation)
    if place and place.area and ExcludedZones[place.area] then
      ColourNote("yellow", "", "任务失败，特殊区域不建议搜索 " .. self.searchLocation)
      return self:doCancel()
    end
    local searchRooms = travel:getMatchedRooms {
      fullname = self.searchLocation
    }
    if #(searchRooms) == 0 then
      ColourNote("yellow", "", "任务失败，无法匹配到房间 " .. self.searchLocation)
      return self:doCancel()
    else
      self.searchRooms = searchRooms
      self.searchedRoomIds = {}
      return self:fire(Events.NEXT_SEARCH)
    end
  end

  function prototype:doSearch()
    if #(self.searchRooms) == 0 then
      ColourNote("yellow", "", "任务失败，没有更多的可搜索房间")
      return self:doCancel()
    else
      local nextRoom = table.remove(self.searchRooms)
      if self.searchedRoomIds[nextRoom.id] then
        return self:doSearch()
      end

      self.targetRoomId = nil
      helper.checkUntilNotBusy()
      self:doPowerup()
      travel:walkto(nextRoom.id)
      travel:waitUntilArrived()
      helper.enableTriggerGroups("murong_search")
      local onStep = function()
        -- 将每个经历的地点都放入已搜索列表
        self.searchedRoomIds[travel.traverseRoomId] = true
        return self.targetRoomId ~= nil  -- 停止条件，找到伙计
      end
      local onArrive = function()
        helper.disableTriggerGroups("murong_search")
        if self.targetRoomId then
          self:debug("遍历结束，已经发现家贼，并确定目标房间：", self.targetRoomId)
          return self:fire(Events.JIAZEI_FOUND)
        else
          self:debug("没有发现家贼，尝试下一个地点")
          wait.time(1)
          return self:fire(Events.NEXT_SEARCH)
        end
      end
      return travel:traverseNearby(SearchDepth, onStep, onArrive)
    end
  end

  function prototype:doPowerup()
    SendNoEcho("yun powerup")
    SendNoEcho("wield sword")
  end

  function prototype:doSubmit()
    helper.checkUntilNotBusy()
    travel:walkto(479)
    travel:waitUntilArrived()
    SendNoEcho("drop shi tan")
    SendNoEcho("drop xuan bing")
    SendNoEcho("give xin to pu")
    helper.checkUntilNotBusy()
    return self:fire(Events.STOP)
  end

  function prototype:doKill()
    SendNoEcho("halt")
    self:doPowerup()
    SendNoEcho("killall " .. self.jiazeiId)
    SendNoEcho("perform dugu-jiujian.poqi")
    self.killSeconds = nil
    self.jiazeiKilled = false
    helper.enableTriggerGroups("murong_kill")
    helper.enableTimerGroups("murong_kill")

    while not self.jiazeiKilled do
      wait.time(3)
      self:debug("检查家贼是否已被杀死")
    end

    self:debug("家贼已被杀死，成功返回")
    return self:fire(Events.JIAZEI_KILLED)
  end

  -- jobs 框架
  function prototype:doStart()
    return self:fire(Events.START)
  end

  function prototype:doCancel()
--    ColourNote("red", "", "调试模式，请手动取消任务")

    helper.assureNotBusy()
    travel:walkto(479)
    travel:waitUntilArrived()
    wait.time(1)
    SendNoEcho("ask pu about fail")
    helper.checkUntilNotBusy()
    return self:fire(Events.STOP)
  end

  return prototype
end
return define_murong():FSM()

