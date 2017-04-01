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


����Ⱥ˵��������лС�ֵܣ��뽫����ܺ������͵����������ø�������Ⱥ�����ϡ���

�ܺ�(Mi han)
����һ����Ż���ӡ�����ܺ���������ȴû��д��˭�ĳ��ġ�

           �����ˣ�������(Sun liukang)



����������һ���������ܺ��Ѿ�������ɣ�

ʱ������׿�Ц�������㣬���ܺ����ҹԹԽ������ɣ���
pu
ʲô��
> ʱ���˵�������ٺ٣��ñ���ү����ѵ��ѵ�㣡��
������Ц������ʱ��������ܣ�����צ��Ӳ�����������㣡��

���������ˡ�

����������һ���������ܺ��Ѿ�������ɣ�
��ѩ˵��������Ȼ�ʵ�����Ⱥ���������߹����ͱ�ֱ���ү�������ˣ���
��������ѩ��ɱ���㣡

��սʤ����ѩ!

��÷���׿�Ц�������㣬���ܺ����ҹԹԽ������ɣ���
��÷˵��������Ȼ�ʵ�����Ⱥ���������߹����ͱ�ֱ���ү�������ˣ���
��������÷��ɱ���㣡


����æ ý��(Mei_po)

�����ɵ��Ĵ����ӡ��Ҳ���NPC���ѿ�(Fei ke)

��ӻ����ͳ��Ž����׵񣬵�������������Ⱥ�����������͸������ţ����պá���
���������ɣ����ȥ�����ɡ�


���������㱻�����ˣ�

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
    NO_JOB_AVAILABLE = "^[ >]*����Ⱥ˵��������ո�����������ȥ��Ϣһ��ɡ���$",
    PREV_JOB_NOT_FINISH = "^[ >]*����Ⱥ˵���������ϴ�����û������أ���$",
    NEW_JOB_WENHAO = "^[ >]*����Ⱥ�����㣬�����þ�û�м���(.*?) ��Щ���ˣ����ڽ����У����������Щǰ���е�һ�������������ʸ���\\(wenhao\\)�ɣ�������Ʒ��������\\s*$",
    NEW_JOB_SONGXIN = "^[ >]*yue songxin$";
    ROBBER_HIT = "^[ >]*(.*)˵�������ٺ٣��ñ���ү����ѵ��ѵ�㣡��$",
    ROBBER_AUTOKILL = "^[ >]*(.*)˵��������Ȼ�ʵ�����Ⱥ���������߹����ͱ�ֱ���ү�������ˣ���$",
    ROBBER_ASSIST = "^[ >]*(.*)Ц������(.*)�����ܣ�����צ��Ӳ�����������㣡��$",
    ROBBER_DEFEATED = "^[ >]*��սʤ��(.*)!$",
    ROBBER_DEAD = "^[ >]*(.*)���ˡ�$",
    MAIL_MISS = "^[ >]*����������һ���������ܺ��Ѿ�������ɣ�$",
    SONGXIN_FINISH = "^[ >]*���������ɣ����ȥ�����ɡ�$",
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
        print("������ȴ�10����ѯ��")
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
    -- ѯ������
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
        -- todo
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
    print("װ����ȫ����װ������")
  end

  function prototype:disableAllTriggers()

  end

  function prototype:doAsk()
    -- ���ʳ����ˮ
    status:hpbrief()
    if status.food < 150 or status.drink < 150 then
      return self:fire(Events.HUNGRY)
    end
    -- ��鵱ǰ�����뾫��
--    while status.currNeili < status.maxNeili do


      -- ѯ������
    return travel:walkto(66, function()
      SendNoEcho("set songxin ask_start")
      SendNoEcho("ask yue about job")
      SendNoEcho("set songxin ask_done")  -- will trigger next step
    end)
  end

  return prototype
end
return define_songxin():FSM()