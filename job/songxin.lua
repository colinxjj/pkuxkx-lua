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
local wenhao = require "huashan.wenhao"

local define_songxin = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    wenhao = "wenhao",
    recover = "recover",
    wait_robber = "wait_robber",
    killing = "killing",
    songxin = "songxin",
  }
  local Events = {
    STOP = "stop",  --  any state -> stop
    DRAWALL = "drawall",  --  stop -> ask (with all newbie gears)
    START = "start",  --  stop -> ask
    NOT_ENOUGH_NEILI = "not_enough_neili",  --  ask -> recover
    ENOUGH_NEILI = "enough_neili",  --  recover -> ask
    NO_JOB_AVAILABLE = "no_job_available",  --  ask -> ask
    PREV_JOB_NOT_FINISH = "prev_job_not_finish",  --  ask -> ask
    NEW_JOB_WENHAO = "new_job_wenhao",  --  ask -> wenhao
    WENHAO_DONE = "wenhao_done",  -- wenhao -> ask
    NEW_JOB_SONGXIN = "new_job_songxin",  --  ask -> ask
    SONGXIN_ROOM_REACHABLE = "songxin_room_reachable",  --  ask -> wait_robber
    SONGXIN_ROOM_NOT_REACHABLE = "songxin_room_not_reachable",  --  ask -> ask 
    ROBBER_FOUND = "robber_found",  -- wait_robber -> killing
    ROBBER_KILLED = "robber_killed",  -- killing -> killing
    MAIL_MISS = "mail_miss",  -- killing -> ask (cancel first)
    SONGXIN_NEXT_ROOM = "songxin_next_room",  --  killing -> songxin
    SONGXIN_FINISH = "songxin_finish",  -- songxin -> ask (submit first)
    SONGXIN_FAIL = "songxin_fail",  -- songxin -> ask (cancel first)
  }
  local REGEXP = {
    ALIAS_START = "^songxin\\s+start\\s*$",
    ALIAS_STOP = "^songxin\\s+stop\\s*$",
    ALIAS_DEBUG = "^songxin\\s+debug\\s+(on|off)\\s*$",
    NO_JOB_AVAILABLE = "^[ >]*(岳不群说道：「.*先下去休息休息吧。」|岳不群脸一沉道：「上次交给小兄弟的任务才失败不久，还是等等吧。」.*)$",
    PREV_JOB_NOT_FINISH = "^[ >]*岳不群说道：「你不是要过任务了吗？快去完成它吧。」$",
    NEW_JOB_WENHAO = "^[ >]*岳不群看着你，道：好久没有见过(.*?) 这些人了，你在江湖中，如果遇到这些前辈中的一个，代我向他问个好\\(wenhao\\)吧，并把礼品带给他。\\s*$",
    NEW_JOB_SONGXIN = "^[ >]*岳不群(?:说道|道)：「多谢.*送到(.*)附近的(.*)手(上|中)。」$";
    NEW_JOB_SONGXIN_PUBLIC = "岳不群对你道：「我这里正好有封密函，麻烦你跑一趟，交给(.*)附近的(.*)。」$",
    ROBBER_HIT = "^[ >]*(.*)说道：「嘿嘿，让本大爷来教训教训你！」$",
    ROBBER_AUTOKILL = "^[ >]*(.*)说道：「既然甘当岳不群那老贼的走狗，就别怪本大爷不客气了！」$",
    ROBBER_ASSIST = "^[ >]*(.*)笑道：「(.*)你别逞能，点子爪子硬，老子来帮你！」$",
    ROBBER_DEFEATED = "^[ >]*你战胜了(.*)!$",
    ROBBER_ESCAPED = "^[ >]*你一眨眼间，(.*)已经不知去向。$",
    ROBBER_DISAPPEARED = "^[ >]*(.*)纵身远远的去了。$",
    ROBBER_DEAD = "^[ >]*(.*)死了。$",
    MAIL_MISS = "^[ >]*你伸手向怀中一摸，发现密函已经不翼而飞！$",
    SONGXIN_FINISH = "^[ >]*你的任务完成，快回去复命吧。$",
    SONGXIN_TARGET_DESC = "^\\s*收信人：(.*)\\((.*)\\)$",
    MAIL_PICKED = "^[ >]*你从.*(搜|拿)出一封密函。$",
    DAZUO_BEGIN = "^[ >]*你坐下来运气用功，一股内息开始在体内流动。$",
    DAZUO_FINISH = "^[ >]*你运功完毕，深深吸了口气，站了起来。$",
  }

  function prototype:FSM()
    local obj = FSM:new()
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self.lastUpdateTime = os.time()
    self:initStates()
    self:initTransitions()
    self:initTriggers()
    self:initAliases()
    self:setState(States.stop)
    -- the depth to traverse to find songxin npc
    self.traverseDepth = 6
    -- the threshold of neili to start a new job
    self.neiliThreshold = 1.2
    -- the threshold of neili to start to wait robber
    self.neiliWaitThreshold = 1.4
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
        SendNoEcho("set jobs job_done")  -- cooperate with other module
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
        --self.wenhaoList = nil
        -- songxin
        self.songxinFound = false
        self.songxinFinished = false
        --self.songxinOrigName = nil
        --self.songxinOrigLocation = nil
        --self.songxinId = nil    -- note id is in capital case
        --self.songxinName = nil
        --self.songxinRooms = nil
        helper.enableTriggerGroups("songxin_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("songxin_ask_done", "songxin_ask_start")
      end
    }
    self:addState {
      state = States.wenhao,
      enter = function()
      end,
      exit = function() end
    }
    self:addState {
      state = States.recover,
      enter = function()
      end,
      exit = function() end
    }
    self:addState {
      state = States.wait_robber,
      enter = function()
        self.robbers = {}
        self.robberCnt = 0
        self.defeated = 0
        self.robbersToKill = {}
        self.killed = 0
        self.robbersKilled = {}
        self.escaped = 0
        self.robbersEscaped = {}
        self.mailMiss = false
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
      enter = function()
        self.songxinFound = false
        self.songxinFinished = false
        helper.enableTriggerGroups("songxin_songxin")
      end,
      exit = function()
        helper.removeTriggerGroups("songxin_one_shot")
        helper.disableTriggerGroups("songxin_songxin")
      end
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
      newState = States.recover,
      event = Events.NOT_ENOUGH_NEILI,
      action = function()
        self:doRecover(self.neiliThreshold)
        return self:fire(Events.ENOUGH_NEILI)
      end
    }
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
        print("放弃当前任务")
        SendNoEcho("ask yue about fail")
        SendNoEcho("fail")
        helper.assureNotBusy()
        return self:fire(Events.STOP)
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.ask,
      event = Events.NEW_JOB_SONGXIN,
      action = function()
        self:debug("原始地址：", self.songxinOrigLocation, "收信人：", self.songxinOrigName)
        return self:doConfirmTarget()
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.wait_robber,
      event = Events.SONGXIN_ROOM_REACHABLE,
      action = function()
        return self:doWaitRobber()
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.ask,
      event = Events.SONGXIN_ROOM_NOT_REACHABLE,
      action = function()
        helper.assureNotBusy()
        return self:doCancel()
      end
    }
    self:addTransitionToStop(States.ask)
    -- transition from state<recover>
    self:addTransition {
      oldState = States.recover,
      newState = States.ask,
      event = Events.ENOUGH_NEILI,
      action = function()
        wait.time(1)
        return self:doAsk()
      end
    }
    self:addTransitionToStop(States.recover)
    -- transition from state<wait_robber>
    self:addTransition {
      oldState = States.wait_robber,
      newState = States.killing,
      event = Events.ROBBER_FOUND,
      action = function()
        SendNoEcho("yun powerup")
      end
    }
    self:addTransitionToStop(States.wait_robber)
    -- transition from state<killing>
    self:addTransition {
      oldState = States.killing,
      newState = States.killing,
      event = Events.ROBBER_KILLED,
      action = function()
        self:doGetFromCorpse()
      end
    }
    self:addTransition {
      oldState = States.killing,
      newState = States.ask,
      event = Events.MAIL_MISS,
      action = function()
        return self:doCancel()
      end
    }
    self:addTransition {
      oldState = States.killing,
      newState = States.songxin,
      event = Events.SONGXIN_NEXT_ROOM,
      action = function()
        return self:doSongxin()
      end
    }
    self:addTransitionToStop(States.killing)
    -- transition from state<songxin>
    self:addTransition {
      oldState = States.songxin,
      newState = States.songxin,
      event = Events.SONGXIN_NEXT_ROOM,
      action = function()
        self:debug("等待3秒，寻找下一个地点")
        wait.time(3)
        return self:doSongxin()
      end
    }
    self:addTransition {
      oldState = States.songxin,
      newState = States.ask,
      event = Events.SONGXIN_FAIL,
      action = function()
        helper.assureNotBusy()
        return self:doCancel()
      end
    }
    self:addTransition {
      oldState = States.songxin,
      newState = States.ask,
      event = Events.SONGXIN_FINISH,
      action = function()
        helper.assureNotBusy()
        self:doSubmit()
        helper.assureNotBusy()
        return self:fire(Events.STOP)
      end
    }
    self:addTransitionToStop(States.songxin)
    -- transition from state<wenhao>
    self:addTransition {
      oldState = States.wenhao,
      newState = States.ask,
      event = Events.WENHAO_DONE,
      action = function()
        wait.time(2)
        helper.assureNotBusy()
        return self:fire(Events.STOP)
      end
    }
    self:addTransitionToStop(States.wenhao)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "songxin_ask_start", "songxin_ask_done",
      "songxin_wait_robber", "songxin_killing",
      "songxin_songxin")
    -- 询问任务
    helper.addTrigger {
      group = "songxin_ask_start",
      regexp = helper.settingRegexp("songxin", "ask_start"),
      response = function()
        self:debug("SONGXIN_ASK_START triggered")
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
        self.jobType = "songxin"
        self.songxinOrigLocation = wildcards[1]
        self.songxinOrigName = wildcards[2]
      end
    }
    -- 公共送信任务描述有变化
    helper.addTrigger {
      group = "songxin_ask_done",
      regexp = REGEXP.NEW_JOB_SONGXIN_PUBLIC,
      response = function(name, line, wildcards)
        self.jobType = "songxin"
        self.songxinOrigLocation = wildcards[1]
        self.songxinOrigName = wildcards[2]
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
    -- 等待强盗
    helper.addTrigger {
      group = "songxin_wait_robber",
      regexp = REGEXP.MAIL_MISS,
      response = function(name, line, wildcards)
        self:debug("MAIL_MISS triggered")
        self.mailMiss = true
      end
    }
    helper.addTrigger {
      group = "songxin_wait_robber",
      regexp = REGEXP.ROBBER_HIT,
      response = function(name, line, wildcards)
        local robber = wildcards[1]
        if not self.robbers[robber] then
          print("发现强盗：", robber)
          self.robbers[robber] = true
          self.robberCnt = self.robberCnt + 1
          return self:fire(Events.ROBBER_FOUND)
        end
      end
    }
    helper.addTrigger {
      group = "songxin_wait_robber",
      regexp = REGEXP.ROBBER_AUTOKILL,
      response = function(name, line, wildcards)
        local robber = wildcards[1]
        if not self.robbers[robber] then
          print("发现强盗：", robber)
          self.robbers[robber] = true
          self.robberCnt = self.robberCnt + 1
          return self:fire(Events.ROBBER_FOUND)
        end
      end
    }
    -- 战斗
    helper.addTrigger {
      group = "songxin_killing",
      regexp = REGEXP.ROBBER_ASSIST,
      response = function(name, line, wildcards)
        local robber2 = wildcards[1]
        local robber = wildcards[2]
        if self.robbers[robber] then
          if not self.robbers[robber2] then
            print("好兄弟，讲义气。两个一起上就两个一起杀")
            self.robbers[robber2] = true
            self.robberCnt = self.robberCnt + 1
          end
        end
      end
    }
    helper.addTrigger {
      group = "songxin_killing",
      regexp = REGEXP.ROBBER_DEFEATED,
      response = function(name, line, wildcards)
        local robber = wildcards[1]
        if self.robbers[robber] then
          self.defeated = self.defeated + 1
          if self.robberCnt == self.defeated + self.escaped then
            print("所有强盗都打败了，直接开杀")
            status:idhere()
            for _, npc in pairs(status.items) do
              if self.robbers[npc.name] then
                table.insert(self.robbersToKill, npc)
              end
            end
            return self:doKill()
          end
        end
      end
    }
    helper.addTrigger {
      group = "songxin_killing",
      regexp = REGEXP.ROBBER_DEAD,
      response = function(name, line, wildcards)
        local robber = wildcards[1]
        if self.robbers[robber] then
          self.robbersKilled[robber] = true
          self.killed = self.killed + 1
          if self.killed + self.escaped == self.robberCnt then
            print("所有强盗都被杀死了，开始搜尸体")
            return self:fire(Events.ROBBER_KILLED)
          end
        end
      end
    }
    local onEscaped = function(name, line, wildcards)
      local robber = wildcards[1]
      if self.robbers[robber] then
        self.robbersEscaped[robber] = true
        self.escaped = self.escaped + 1
        if self.killed + self.escaped == self.robberCnt then
          print("所有强盗都被杀死或已逃走，开始搜尸体")
          return self:fire(Events.ROBBER_KILLED)
        elseif self.defeated + self.escaped == self.robberCnt then
          print("所有强盗都打败了，直接开杀")
          status:idhere()
          for _, npc in pairs(status.items) do
            if self.robbers[npc.name] then
              table.insert(self.robbersToKill, npc)
            end
          end
          return self:doKill()
        else
          print("仍然有强盗在战斗中")
        end
      end
    end
    helper.addTrigger {
      group = "songxin_killing",
      regexp = REGEXP.ROBBER_ESCAPED,
      response = onEscaped
    }
    helper.addTrigger {
      group = "songxin_killing",
      regexp = REGEXP.ROBBER_DISAPPEARED,
      response = onEscaped
    }
    helper.addTrigger {
      group = "songxin_killing",
      regexp = REGEXP.MAIL_PICKED,
      response = function(name, line, wildcards)
        self:debug("MAIL_PICKED triggered")
        self.mailMiss = false
      end
    }
    helper.addTrigger {
      group = "songxin_songxin",
      regexp = REGEXP.SONGXIN_FINISH,
      response = function()
        self:debug("SONGXIN_FINISH triggered")
        self.songxinFinished = true
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("songxin")

    helper.addAlias {
      group = "songxin",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "songxin",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "songxin",
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
    travel:walkto(66)
    travel:waitUntilArrived()
    
    -- 检查食物饮水
    status:hpbrief()
    -- 简单起见，仅检查当前内力，不考虑受伤，精力等问题
    if status.currNeili < status.maxNeili * self.neiliThreshold then
      print("恢复内力至超过上限")
      return self:fire(Events.NOT_ENOUGH_NEILI)
    end
    
    -- 询问任务
    SendNoEcho("set songxin ask_start")
    SendNoEcho("ask yue about job")
    SendNoEcho("set songxin ask_newline")
    SendNoEcho("set songxin ask_done")  -- will trigger next step
  end
  
  function prototype:doRecover(threshold)
    SendNoEcho("yun recover")
    status:hpbrief()
    if status.currNeili < status.maxNeili * threshold then
      SendNoEcho("dazuo 150")
      local startDazuo = wait.regexp(REGEXP.DAZUO_BEGIN, 5)
      if not startDazuo then
        print("身体状态太差无法打坐，等待5秒后重试")
        wait.time(5)
        return self:doRecover(threshold)
      end
      local endDazuo = wait.regexp(REGEXP.DAZUO_FINISH, 20)
      if not endDazuo then
        print("未知原因导致无法打坐，直接退出")
        return self:fire(Events.STOP)
      end
      -- 继续打坐
      return self:doRecover(threshold)
    end
    print("内力满足要求")
  end

  function prototype:doConfirmTarget()
    -- check target name and id
    SendNoEcho("look mi han")
    local line, wildcards = wait.regexp(REGEXP.SONGXIN_TARGET_DESC, 5)
    if not line then
      error("无法确认收信人")
    end
    self.songxinName = wildcards[1]
    self.songxinId = wildcards[2]
    self.songxinRooms = travel:getMatchedRooms {
      fullname = self.songxinOrigLocation
    }
    if #(self.songxinRooms) > 5 then
      print("送信同名地点超过5个，放弃该任务")
      return self:fire(Events.SONGXIN_ROOM_NOT_REACHABLE)
    elseif #(self.songxinRooms) == 0 then
      -- todo: 查找不到的地点记录日志
      print("查找不到送信地点：", self.songxinOrigLocation)
      return self:fire(Events.SONGXIN_ROOM_NOT_REACHABLE)
    else
      print("可以定位送信地点，个数为：", #(self.songxinRooms))
      return self:fire(Events.SONGXIN_ROOM_REACHABLE)
    end
  end

  function prototype:doWaitRobber()
    -- 假死地点
    self:doRecover(self.neiliWaitThreshold)
    travel:walkto(208)
    travel:waitUntilArrived()
    -- SendNoEcho("jiali max")
    SendNoEcho("unwield sword")
    SendNoEcho("wield sword")
    DoAfter(20, "yun powerup")
  end

  function prototype:doCancel()
    print("取消任务")
    travel:walkto(66)
    travel:waitUntilArrived()
    SendNoEcho("ask yue about fail")
    helper.assureNotBusy()
    return self:fire(Events.STOP)
  end

  function prototype:doStart()
    return self:fire(Events.START)
  end

--  function prototype:doWaitUntilDone()
--    local currCo = assert(coroutine.running(), "Must be in coroutine")
--    helper.addOneShotTrigger {
--      group = "jobs_one_shot",
--      regexp = helper.settingRegexp("jobs", "job_done"),
--      response = helper.resumeCoRunnable(currCo)
--    }
--    return coroutine.yield()
--  end

  function prototype:doKill()
    for _, robber in pairs(self.robbersToKill) do
      if not self.robbersKilled[robber.name] then
        self:debug("比武场无法使用killall，所以使用kill")
        SendNoEcho("kill " .. string.lower(robber.id))
      end
    end
  end

  function prototype:doGetFromCorpse()
    wait.time(1)
    helper.assureNotBusy()
    local i = 0
    for robber in pairs(self.robbersKilled) do
      i = i + 1
      print("捡取物品：", robber)
      if i == 1 then
        SendNoEcho("get mi han from corpse")
        SendNoEcho("get gold from corpse")
        SendNoEcho("get silver from corpse")
      else
        SendNoEcho("get mi han from corpse 2")
        SendNoEcho("get gold from corpse 2")
        SendNoEcho("get silver from corpse 2")
      end
    end
    SendNoEcho("set songxin kill_done")
    wait.regexp(helper.settingRegexp("songxin", "kill_done"), 5)
    if self.mailMiss then
      print("没有拿回密函，任务失败了！")
      return self:fire(Events.MAIL_MISS)
    else
      return self:fire(Events.SONGXIN_NEXT_ROOM)
    end
  end

  function prototype:doSongxin()
    if #(self.songxinRooms) > 0 then
      local room = table.remove(self.songxinRooms)
      print("准备前往：", room.id, room.name)
      travel:walkto(room.id)
      travel:waitUntilArrived()
      helper.assureNotBusy()
      -- add one shot trigger
      helper.addOneShotTrigger {
        group = "songxin_one_shot",
        regexp = self.songxinName .. "\\(" .. self.songxinId .. "\\)$",
        response = function()
          self.songxinFound = true
        end
      }
      local onStep = function()
        if self.songxinFound then
          SendNoEcho("songxin " .. string.lower(self.songxinId))
          return self.songxinFinished
        end
        return self.songxinFinished
      end
      local onArrived = function()
        if self.songxinFinished then
          return self:fire(Events.SONGXIN_FINISH)
        else
          return self:fire(Events.SONGXIN_NEXT_ROOM)
        end
      end
      return travel:traverseNearby(self.traverseDepth, onStep, onArrived)
    else
      self:debug("没有多余的地点可以查找，任务失败")
      return self:fire(Events.SONGXIN_FAIL)
    end
  end

  function prototype:doSubmit()
    travel:walkto(66)
    travel:waitUntilArrived()
    SendNoEcho("ask yue about finish")
  end

  return prototype
end
return define_songxin():FSM()
