--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/20
-- Time: 22:24
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"
local Player = require "pkuxkx.Player"

local patterns = [[


岳不群说道：「多谢小兄弟，请将这封密函火速送到洛阳观音堂附近的林群永手上。」

密函(Mi han)
这是一封盖着火漆印戳的密函，封面上却没有写是谁寄出的。

           收信人：孙六康(Sun liukang)



你伸手向怀中一摸，发现密函已经不翼而飞！

时贵杰仰首狂笑道：「你，把密函给我乖乖交出来吧！」
pu
什么？
> 时贵杰说道：「嘿嘿，让本大爷来教训教训你！」
樊彪羽笑道：「时贵杰你别逞能，点子爪子硬，老子来帮你！」

樊彪羽死了。

你伸手向怀中一摸，发现密函已经不翼而飞！
凌雪说道：「既然甘当岳不群那老贼的走狗，就别怪本大爷不客气了！」
看起来凌雪想杀死你！

你战胜了凌雪!

余梅仰首狂笑道：「你，把密函给我乖乖交出来吧！」
余梅说道：「既然甘当岳不群那老贼的走狗，就别怪本大爷不客气了！」
看起来余梅想杀死你！


无事忙 媒婆(Mei_po)

峨嵋派第四代弟子「我不是NPC」费柯(Fei ke)

你从怀中掏出信交给白雕，道：「这是岳不群先生托在下送给您的信，请收好。」
你的任务完成，快回去复命吧。


完成任务后，你被奖励了：

]]

local define_songxin = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    wenhao = "wenhao",
    dining = "dining",
    wait_robber = "wait_robber",
    killing = "killing",
    songxin = "songxin",
  }
  local Events = {
    STOP = "stop",  --  any state -> stop
    DRAWALL = "drawall",  --  stop -> ask (with all newbie gears)
    START = "start",  --  stop -> ask
    HUNGRY = "hungry",  --  ask -> dining
    FULL = "full",  --  dining -> ask
    NO_JOB_AVAILABLE = "no_job_available",  --  ask -> ask
    PREV_JOB_NOT_FINISH = "prev_job_not_finish",  --  ask -> ask
    NEW_JOB_WENHAO = "new_job_wenhao",  --  ask -> wenhao
    WENHAO_DONE = "wenhao_done",  -- wenhao -> ask
    NEW_JOB_SONGXIN = "new_job_songxin",  --  ask -> wait_robber
    ROBBER_APPEAR = "robber_appear",  -- wait_robber -> killing
    ROBBER_CLEARED = "robber_cleared",  -- killing -> songxin
    MAIL_MISS = "mail_miss",  -- killing -> ask (cancel first)
    SONGXIN_FINISH = "songxin_finish",  -- songxin -> ask (submit first)
    SONGXIN_FAIL = "songxin_fail",  -- songxin -> ask (cancel first)
  }
  local REGEXP = {
    NO_JOB_AVAILABLE = "^[ >]*岳不群说道：「你刚刚做过任务，先去休息一会吧。」$",
    PREV_JOB_NOT_FINISH = "^[ >]*岳不群说道：「你上次任务还没有完成呢！」$",
    NEW_JOB_WENHAO = "^[ >]*岳不群看着你，道：好久没有见过(.*?) 这些人了，你在江湖中，如果遇到这些前辈中的一个，代我向他问个好\\(wenhao\\)吧，并把礼品带给他。\\s*$",
    NEW_JOB_SONGXIN = "^[ >]*yue songxin$";
    ROBBER_HIT = "^[ >]*(.*)说道：「嘿嘿，让本大爷来教训教训你！」$",
    ROBBER_AUTOKILL = "^[ >]*(.*)说道：「既然甘当岳不群那老贼的走狗，就别怪本大爷不客气了！」$",
    ROBBER_ASSIST = "^[ >]*(.*)笑道：「(.*)你别逞能，点子爪子硬，老子来帮你！」$",
    ROBBER_DEFEATED = "^[ >]*你战胜了(.*)!$",
    ROBBER_DEAD = "^[ >]*(.*)死了。$",
    MAIL_MISS = "^[ >]*你伸手向怀中一摸，发现密函已经不翼而飞！$",
    SONGXIN_FINISH = "^[ >]*你的任务完成，快回去复命吧。$",
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
    -- the depth to traverse to find songxin npc
    self.traverseDepth = 5
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
      state = States.ask,
      enter = function()
        self.waitJob = false
        self.jobType = nil
        self.prevNotDone = false
        -- wenhao
        self.wenhaoList = nil
        -- songxin
        self.songxinName = nil
        self.songxinZone = nil
        self.songxinLocation = nil
        helper.enableTriggerGroups("songxin_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("songxin_ask_done", "songxin_ask_start")
      end
    }
    self:addState {
      state = States.wenhao,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.dining,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.wait_robber,
      enter = function()
        helper.enableTriggerGroups("songxin_wait_robber")
      end,
      exit = function()
        helper.disableTriggerGroups("songxin_wait_robber")
      end
    }
    self:addState {
      state = States.killing,
      enter = function()
        helper.enableTriggerGroups("songxin_killing")
      end,
      exit = function()
        helper.disableTriggerGroups("songxin_killing")
      end
    }
    self:addState {
      state = States.songxin,
      enter = function() end,
      exit = function() end
    }
  end

  function prototype:addTransitionToStop(fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function()
        print("停止，当前状态", self.currState)
      end
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
    self:addTransition {
      oldState = States.stop,
      newState = States.ask,
      event = Events.DRAWALL,
      action = function()
        self:doGetGears()
        wait.time(2)
        self.assureNotBusy()
        return self:doAsk()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<ask>
    self:addTransition {
      oldState = States.ask,
      newState = States.wenhao,
      event = Events.NEW_JOB_WENHAO,
      action = function()
        assert(self.wenhaoList, "wenhaoList cannot be nil")
        print("使用wenhao模块")
        local players = {}
        for i = 1, #(self.wenhaoList) do
          table.insert(players, self.wenhaoList[i])
        end
        wenhao:startWithPlayers(players)
        wenhao:waitUntilDone()
        return self:fire(Events.WENHAO_DONE)
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.ask,
      event = Events.NO_JOB_AVAILABLE,
      action = function()
        print("等待10秒后再询问")
        wait.time(10)
        return self:doAsk()
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.ask,
      event = Events.PREV_JOB_NOT_FINISH,
      action = function()
        print("放弃后等待10秒再询问")
        SendNoEcho("ask yue about fail")
        SendNoEcho("fail")
        wait.time(10)
        return self:doAsk()
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.wait_robber
    }
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "songxin_ask_start", "songxin_ask_done")
    -- 询问任务
    helper.addTrigger {
      group = "songxin_ask_start",
      regexp = helper.settingRegexp("songxin", "ask_done"),
      response = function()
        helper.enableTriggerGroups("songxin_ask_done")
      end
    }
    helper.addTrigger {
      group = "songxin_ask_done",
      regexp = REGEXP.NO_JOB_AVAILABLE,
      response = function()
        self.waitJob = true
      end
    }
    helper.addTrigger {
      group = "songxin_ask_done",
      regexp = REGEXP.PREV_JOB_NOT_FINISH,
      response = function()
        self.prevNotDone = true
      end
    }
    helper.addTrigger {
      group = "songxin_ask_done",
      regexp = REGEXP.NEW_JOB_WENHAO,
      response = function(name, line, wildcards)
        self:debug("问好玩家有", wildcards[1])
        local patterns = utils.split(wildcards[1], " ")
        local players = {}
        for _, pattern in ipairs(patterns) do
          local str = utils.split(pattern, "(") -- the utils.split implementatin is not different
          local name = str[1]
          local id = string.gsub(str[2], "%)", "")
          table.insert(players, Player:decorate {name=name, id=id})
        end
        self.wenhaoList = players
        self.jobType = "wenhao"
      end
    }
    helper.addTrigger {
      group = "songxin_ask_done",
      regexp = REGEXP.NEW_JOB_SONGXIN,
      response = function(name, line, wildcards)
        -- todo
      end
    }
    helper.addTrigger {
      group = "songxin_ask_done",
      regexp = helper.settingRegexp("songxin", "ask_done"),
      response = function()
        if self.prevNotDone then
          self:debug("之前任务未完成！")
          -- wait.time(1)
          return self:fire(Events.PREV_JOB_NOT_FINISH)
        end
        if self.waitJob then
          self:debug("当前无任务")
          return self:fire(Events.NO_JOB_AVAILABLE)
        end
        if self.jobType == "wenhao" then
          return self:fire(Events.NEW_JOB_WENHAO)
        elseif self.jobType == "songxin" then
          return self:fire(Events.NEW_JOB_SONGXIN)
        else
          print("没有接收到任何任务信息，停止")
          return self:fire(Events.STOP)
        end
      end
    }
  end

  function prototype:initAliases() end

  function prototype:doGetGears()
    travel:walkto(183)
    travel:waitUntilArrived()
    SendNoEcho("do 2 draw sword")
    SendNoEcho("draw armor")
    SendNoEcho("draw surcoat")
    SendNoEcho("draw head")
    SendNoEcho("draw boots")
    SendNoEcho("draw cloth")
    SendNoEcho("remove all")
    SendNoEcho("wear all")
    SendNoEcho("wield all")
    print("装备齐全，整装待发！")
  end

  function prototype:disableAllTriggers()

  end

  function prototype:doAsk()
    -- 检查食物饮水
    status:hpbrief()
    if status.food < 150 or status.drink < 150 then
      return self:fire(Events.HUNGRY)
    end
    -- 检查当前内力与精力
--    while status.currNeili < status.maxNeili do


      -- 询问任务
    return travel:walkto(66, function()
      SendNoEcho("set songxin ask_start")
      SendNoEcho("ask yue about job")
      SendNoEcho("set songxin ask_done")  -- will trigger next step
    end)
  end

  return prototype
end
return define_songxin():FSM()