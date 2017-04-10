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
    NO_JOB_AVAILABLE = "^[ >]*(����Ⱥ˵������.*����ȥ��Ϣ��Ϣ�ɡ���|����Ⱥ��һ���������ϴν���С�ֵܵ������ʧ�ܲ��ã����ǵȵȰɡ���.*)$",
    PREV_JOB_NOT_FINISH = "^[ >]*����Ⱥ˵�������㲻��Ҫ���������𣿿�ȥ������ɡ���$",
    NEW_JOB_WENHAO = "^[ >]*����Ⱥ�����㣬�����þ�û�м���(.*?) ��Щ���ˣ����ڽ����У����������Щǰ���е�һ�������������ʸ���\\(wenhao\\)�ɣ�������Ʒ��������\\s*$",
    NEW_JOB_SONGXIN = "^[ >]*����Ⱥ(?:˵��|��)������л.*�͵�(.*)������(.*)��(��|��)����$";
    NEW_JOB_SONGXIN_PUBLIC = "����Ⱥ��������������������з��ܺ����鷳����һ�ˣ�����(.*)������(.*)����$",
    ROBBER_HIT = "^[ >]*(.*)˵�������ٺ٣��ñ���ү����ѵ��ѵ�㣡��$",
    ROBBER_AUTOKILL = "^[ >]*(.*)˵��������Ȼ�ʵ�����Ⱥ���������߹����ͱ�ֱ���ү�������ˣ���$",
    ROBBER_ASSIST = "^[ >]*(.*)Ц������(.*)�����ܣ�����צ��Ӳ�����������㣡��$",
    ROBBER_DEFEATED = "^[ >]*��սʤ��(.*)!$",
    ROBBER_ESCAPED = "^[ >]*��һգ�ۼ䣬(.*)�Ѿ���֪ȥ��$",
    ROBBER_DISAPPEARED = "^[ >]*(.*)����ԶԶ��ȥ�ˡ�$",
    ROBBER_DEAD = "^[ >]*(.*)���ˡ�$",
    MAIL_MISS = "^[ >]*����������һ���������ܺ��Ѿ�������ɣ�$",
    SONGXIN_FINISH = "^[ >]*���������ɣ����ȥ�����ɡ�$",
    SONGXIN_TARGET_DESC = "^\\s*�����ˣ�(.*)\\((.*)\\)$",
    MAIL_PICKED = "^[ >]*���.*(��|��)��һ���ܺ���$",
    DAZUO_BEGIN = "^[ >]*�������������ù���һ����Ϣ��ʼ������������$",
    DAZUO_FINISH = "^[ >]*���˹���ϣ��������˿�����վ��������$",
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
        print("ֹͣ����ǰ״̬", self.currState)
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
        print("ʹ��wenhaoģ��")
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
        print("�ȴ�10�����ѯ��")
        wait.time(10)
        return self:doAsk()
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.ask,
      event = Events.PREV_JOB_NOT_FINISH,
      action = function()
        print("������ǰ����")
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
        self:debug("ԭʼ��ַ��", self.songxinOrigLocation, "�����ˣ�", self.songxinOrigName)
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
        self:debug("�ȴ�3�룬Ѱ����һ���ص�")
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
    -- ѯ������
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
        self:debug("�ʺ������", wildcards[1])
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
    -- �����������������б仯
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
          self:debug("֮ǰ����δ��ɣ�")
          -- wait.time(1)
          return self:fire(Events.PREV_JOB_NOT_FINISH)
        end
        if self.waitJob then
          self:debug("��ǰ������")
          return self:fire(Events.NO_JOB_AVAILABLE)
        end
        if self.jobType == "wenhao" then
          return self:fire(Events.NEW_JOB_WENHAO)
        elseif self.jobType == "songxin" then
          return self:fire(Events.NEW_JOB_SONGXIN)
        else
          print("û�н��յ��κ�������Ϣ��ֹͣ")
          return self:fire(Events.STOP)
        end
      end
    }
    -- �ȴ�ǿ��
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
          print("����ǿ����", robber)
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
          print("����ǿ����", robber)
          self.robbers[robber] = true
          self.robberCnt = self.robberCnt + 1
          return self:fire(Events.ROBBER_FOUND)
        end
      end
    }
    -- ս��
    helper.addTrigger {
      group = "songxin_killing",
      regexp = REGEXP.ROBBER_ASSIST,
      response = function(name, line, wildcards)
        local robber2 = wildcards[1]
        local robber = wildcards[2]
        if self.robbers[robber] then
          if not self.robbers[robber2] then
            print("���ֵܣ�������������һ���Ͼ�����һ��ɱ")
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
            print("����ǿ��������ˣ�ֱ�ӿ�ɱ")
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
            print("����ǿ������ɱ���ˣ���ʼ��ʬ��")
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
          print("����ǿ������ɱ���������ߣ���ʼ��ʬ��")
          return self:fire(Events.ROBBER_KILLED)
        elseif self.defeated + self.escaped == self.robberCnt then
          print("����ǿ��������ˣ�ֱ�ӿ�ɱ")
          status:idhere()
          for _, npc in pairs(status.items) do
            if self.robbers[npc.name] then
              table.insert(self.robbersToKill, npc)
            end
          end
          return self:doKill()
        else
          print("��Ȼ��ǿ����ս����")
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
    print("װ����ȫ����װ������")
  end

  function prototype:disableAllTriggers()

  end

  function prototype:doAsk()
    travel:walkto(66)
    travel:waitUntilArrived()
    
    -- ���ʳ����ˮ
    status:hpbrief()
    -- �����������鵱ǰ���������������ˣ�����������
    if status.currNeili < status.maxNeili * self.neiliThreshold then
      print("�ָ���������������")
      return self:fire(Events.NOT_ENOUGH_NEILI)
    end
    
    -- ѯ������
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
        print("����״̬̫���޷��������ȴ�5�������")
        wait.time(5)
        return self:doRecover(threshold)
      end
      local endDazuo = wait.regexp(REGEXP.DAZUO_FINISH, 20)
      if not endDazuo then
        print("δ֪ԭ�����޷�������ֱ���˳�")
        return self:fire(Events.STOP)
      end
      -- ��������
      return self:doRecover(threshold)
    end
    print("��������Ҫ��")
  end

  function prototype:doConfirmTarget()
    -- check target name and id
    SendNoEcho("look mi han")
    local line, wildcards = wait.regexp(REGEXP.SONGXIN_TARGET_DESC, 5)
    if not line then
      error("�޷�ȷ��������")
    end
    self.songxinName = wildcards[1]
    self.songxinId = wildcards[2]
    self.songxinRooms = travel:getMatchedRooms {
      fullname = self.songxinOrigLocation
    }
    if #(self.songxinRooms) > 5 then
      print("����ͬ���ص㳬��5��������������")
      return self:fire(Events.SONGXIN_ROOM_NOT_REACHABLE)
    elseif #(self.songxinRooms) == 0 then
      -- todo: ���Ҳ����ĵص��¼��־
      print("���Ҳ������ŵص㣺", self.songxinOrigLocation)
      return self:fire(Events.SONGXIN_ROOM_NOT_REACHABLE)
    else
      print("���Զ�λ���ŵص㣬����Ϊ��", #(self.songxinRooms))
      return self:fire(Events.SONGXIN_ROOM_REACHABLE)
    end
  end

  function prototype:doWaitRobber()
    -- �����ص�
    self:doRecover(self.neiliWaitThreshold)
    travel:walkto(208)
    travel:waitUntilArrived()
    -- SendNoEcho("jiali max")
    SendNoEcho("unwield sword")
    SendNoEcho("wield sword")
    DoAfter(20, "yun powerup")
  end

  function prototype:doCancel()
    print("ȡ������")
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
        self:debug("���䳡�޷�ʹ��killall������ʹ��kill")
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
      print("��ȡ��Ʒ��", robber)
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
      print("û���û��ܺ�������ʧ���ˣ�")
      return self:fire(Events.MAIL_MISS)
    else
      return self:fire(Events.SONGXIN_NEXT_ROOM)
    end
  end

  function prototype:doSongxin()
    if #(self.songxinRooms) > 0 then
      local room = table.remove(self.songxinRooms)
      print("׼��ǰ����", room.id, room.name)
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
      self:debug("û�ж���ĵص���Բ��ң�����ʧ��")
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
