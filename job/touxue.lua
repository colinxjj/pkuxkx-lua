--
-- touxue.lua
-- User: zhe.jiang
-- Date: 2017/5/8
-- Desc:
-- Change:
-- 2017/5/8 - created

local patterns = {[[
ask murong about job
����Ľ�ݸ������йء�job������Ϣ��
Ľ�ݸ�˵������ߣ�����ҽ���ϰ�������ϰ�����˵�����ó������������
Ľ�ݸ�˵��������ȥ�����漸��ѧ(touxue)��������
Ľ�ݸ�����Ķ�������˵�����������ӹ��������������������Ӣ�ۺ�����ȹ����˻��˸���Ȧ������������ܵ�ͷ��
Ľ�ݸ�����Ķ�������˵���������ɺͣ�����Ȱ�������ʡ�����Ӣ�����и��Ȱ��ᣬ�����򻮸������ܵ�ͷ��
Ľ�ݸ�����Ķ�������˵�����������뼲��������������������Ӣ�����й������ż������������������
Ľ�ݸ�����Ķ�������˵�������ܹ���ǧ����������ѡ�ǧ��Ӣ�۽�������ǧָ����ǧ��������ܵ�ͷ����ȥ
Ľ�ݸ�����Ķ�������˵���������ɹ��������������ɲ����Ҵ�Ӣ�����ƻ����ң���Ю���͵�ɨ��������ܵ�����
Ľ�ݸ�����Ķ�������˵����������Ի��Ҷ����������һ�����
Ľ�ݸ�˵������������ʽ���Ƕ���ǰ�������ǵò���ô�����ˡ���

��ӹ�Ҷ����͵ѧ����һ�У�

�����û��͵ѧ�����ˡ�

ask murong about job
����Ľ�ݸ������йء�job������Ϣ��
Ľ�ݸ�˵������ߣ�����ҽ���ϰ�������ϰ�����˵�����ó��������ơ���
Ľ�ݸ�˵��������ȥ�����漸��ѧ(touxue)��������
Ľ�ݸ�����Ķ�������˵������Ӣ�����ƽ�ӡ�����������������Ǻ���
Ľ�ݸ�����Ķ�������˵������Ӣ����˫һ�ϣ�ƽƽ�����������
Ľ�ݸ�����Ķ�������˵������Ӣ��ȭ����ߣ����ƺ����޷�����ʵ�ѽ��������ܱ������
Ľ�ݸ�����Ķ�������˵������Ӣ�����ɵع�������ܺ���ǰ���Ѩ
Ľ�ݸ�����Ķ�������˵������Ӣ�������紫������������ͣЪ��ӡ��������ܱؾȴ�֮
Ľ�ݸ�����Ķ�������˵����������Ի����毣����ڸ���һ�����
Ľ�ݸ�˵������������ʽ���Ƕ���ǰ�������ǵò���ô�����ˡ���

> ����Ľ�ݸ������йء�job������Ϣ��
Ľ�ݸ�˵������ߣ�����ҽ���ϰ�������ϰ�����˵�����ó���ָ��ͨ����
Ľ�ݸ�˵��������ȥ�����漸��ѧ(touxue)��������
Ľ�ݸ�����Ķ�������˵������Ӣ�����Ӻ�ȻԾ�����ڰ�գ������мܣ�����ҽ��ʸ�꼱��񡹣��������磬һ���ⴸ�������ڸ������ܵļ���
Ľ�ݸ�����Ķ�������˵������Ӣ������Ծ����֮��ָһʽ����ɽ�ʡ�ָͻȻ��������ָ���绢��ָ�е�Ծ��ָ�󣬼���Ǻ����ܵ�����ָ��������
Ľ�ݸ�����Ķ�������˵������Ӣ�۲������������������Ľ�������ȭ��ָ��һʽ�������̴򡹣����Լл������±�����������ָ�����ֱ�ո������ܵ�ȫ��
Ľ�ݸ�����Ķ�������˵������Ӣ��ָȭ�ػ�����ȭֱ����ָ�����һʽ�������󡹣���һ����������������ܣ���绢������Ϊ����
Ľ�ݸ�������һ��ֽ�����飺
��Ŀͻ��˲�֧��MXP,��ֱ�Ӵ����Ӳ鿴ͼƬ��
��ע�⣬������֤���еĺ�ɫ���֡�
http://pkuxkx.net/antirobot/robot.php?filename=1495058088120436

> ����Ľ�ݸ������йء�job������Ϣ��
Ľ�ݸ�˵������ߣ�����ҽ���ϰ�������ϰ�����˵�����ó������潣����
Ľ�ݸ�˵��������ȥ�����漸��ѧ(touxue)��������
Ľ�ݸ�����Ķ�������˵������Ӣ��ҽ��ʸ��ӵ�к����������ն�������缲�������������ܵ��ؿ�
Ľ�ݸ�����Ķ�������˵������Ӣ�۴���ǰ��ʹ�������羪�硹�֣��г�������һ����������������ܵ�ͷ��
Ľ�ݸ�����Ķ�������˵������Ӣ�����г����ж�����һ�����ھ��졹��бб�н������ó�������������ܵ�ͷ��
Ľ�ݸ�����Ķ�������˵������Ӣ�����г���ָб���죬��â���£�һʽ���Ż����ա�����׼�������ܵ�ͷ��ָָ����
Ľ�ݸ�����Ķ�������˵����������Ի���ݣ����ڶ���һ�����
Ľ�ݸ�˵������������ʽ���Ƕ���ǰ�������ǵò���ô�����ˡ���
> �趨����������touxue = "ask_done"

> ����Ľ�ݸ������йء�job������Ϣ��
Ľ�ݸ�˵������ߣ�����ҽ���ϰ�������ϰ�����˵�����ó�fy-sword����
JOB_SKILL triggered
Ľ�ݸ�˵��������ȥ�����漸��ѧ(touxue)��������
Ľ�ݸ�����Ķ�������˵������Ӣʹ�۳�һ�С�ˮ�����ɡ�������������ˮ�����г��������������ն�������ܵ�ͷ��
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵������Ӣ��ʹ��һʽ�ġ������ķ��ԡ�׼�������ܵ�ͷ���̳�һ��
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵������Ӣ�����н�����һ�Σ�������Ϊһ����⣬ʹ����������ġ��������Ǻ��ܵ�ͷ��
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵����������Իξ����ţ����ڻ�ɽһ�����
JOB_MOTION triggered
JOB_NPC_ZONE triggered
Ľ�ݸ�˵������������ʽ���Ƕ���ǰ�������ǵò���ô�����ˡ���
> �趨����������touxue = "ask_done"

> ����Ľ�ݸ������йء�job������Ϣ��
Ľ�ݸ�˵������ߣ�����ҽ���ϰ�������ϰ�����˵�����ó�����צ����
JOB_SKILL triggered
Ľ�ݸ�˵��������ȥ�����漸��ѧ(touxue)��������
Ľ�ݸ�����Ķ�������˵������Ӣ���ڿո߷����ɣ�һʽ��ӥ���������ն���ʱ�Գ�һ������צӰ�����������������
Ľ�ݸ�����Ķ�������˵������Ӣ����������צ���棬һʽ���������ա��������������ƿն�����Ѹ���ޱȵػ����������
Ľ�ݸ�����Ķ�������˵������Ӣ�۵ĺ����ض���ʹһʽ��������ˮ�������λ���һ�����������������
Ľ�ݸ�����Ķ�������˵������Ӣ��΢΢һЦ��ʹһʽ������ڡ�����˫�ó�������,ֱ����������ܵ�ͷ��
Ľ�ݸ�����Ķ�������˵������Ӣ��ȫ��εض��Ƭ�����һ�����һʽ����ӥϮ�á���Ѹ�͵�ץ��������ܵ�ͷ��
Ľ�ݸ�����Ķ�������˵����������Ի�����ͣ���������Ĺһ�����
Ľ�ݸ�˵������������ʽ���Ƕ���ǰ�������ǵò���ô�����ˡ���
> �趨����������touxue = "ask_done"

> ����Ľ�ݸ������йء�job������Ϣ��
Ľ�ݸ�˵������ߣ�����ҽ���ϰ�������ϰ�����˵�����ó�̫���񽣡���
JOB_SKILL triggered
Ľ�ݸ�˵��������ȥ�����漸��ѧ(touxue)��������
Ľ�ݸ�����Ķ�������˵������Ӣ������һ����һ�С�̫���кۡ������г�����һ����ˮ���������ͷ�Ĳ���������
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵������Ӣ������һ����һ�С�̫���ҡ޺������г�����һ�Ƹ�����������ܵ�ͷ����������
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵����������Ի��Ө�����ڹ���Ľ��һ�����
JOB_NPC_ZONE triggered
JOB_MOTION triggered
Ľ�ݸ�˵������������ʽ���Ƕ���ǰ�������ǵò���ô�����ˡ���
> �趨����������touxue = "ask_done"

Ľ�ݸ�˵��������ȥ�����漸��ѧ(touxue)��������
Ľ�ݸ�����Ķ�������˵������Ӣ��ʹһ���С��µ��֡������Ƴ��Σ������Ϸ�˳�ƻ���������ܵ�ͷ��
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵����Ӣ����˫�����˼�Ȧ��ת��ʹ���������ѡ�����ӰƮƮ�����������ͷ��
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵������Ӣ�����ƻ�ס��ǰ��һ���������һ�С�б�������������������ͷ��
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵������Ӣ��ʹ��һ���ϡ����֡�������һ���������������������ܵ�ͷ��
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵������Ӣ��ʹ���������⡹��̤����������������ǰ����һ���ײ��������ܵ�ͷ��
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵������Ӣ�ۡ��١���һ�������ȿ�أ�һ�С�ƽ�������˫�Ƴ���ֱ�ǹ�������ͷ��
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵����������Ի���壬����̩ɽһ�����

Ľ�ݸ�˵������ߣ�����ҽ���ϰ�������ϰ�����˵�����ó�һָ������
JOB_SKILL triggered
Ľ�ݸ�˵��������ȥ�����漸��ѧ(touxue)��������
Ľ�ݸ�����Ķ�������˵������Ӣ��������������ʽ�����Ź�ɡ���˫��ʳָ�˲����һ��������������������ܵ�ȫ��ҪѨ
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵������Ӣ�����ƻأ�Ьһʽ������ա�չ��������ָǰ���˸��뻡���͵�һ˦������������ܵ�ͷ��
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵������Ӣ����ϥ������һʽ�𡸷��ޱߡ���������ȭ���⣬����Ĵֱָ����ңң���Ÿ�������һ��
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵������Ӣ��˫ָ��£һ��ʽ�����������һ�������һ�����ֺ�ǰ�ͺ����������ܵ��ظ���
JOB_MOTION triggered
Ľ�ݸ�����Ķ�������˵����������Ի����꣬�����ٰ���һ�����
JOB_NPC_ZONE triggered
JOB_MOTION triggered

]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local captcha = require "pkuxkx.captcha"

-- ȥ���������ַ�
local ExcludeCharacters = {}
for _, c in ipairs({
  {
    "��","Ӣ", "��",
    "��", "��", "��", "��",
    "��", "��", "��", "��", "��", "��", ",", "��", "��", "��"
  }
}) do
  ExcludeCharacters[c] = true
end
local PrecisionThreshold = 0.5
local RecallThreshold = 0.5
local FightTimeThreshold = 60

local define_TouxueMotion = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    local obj = {}
    obj.raw = assert(args.raw, "raw of touxue motion cannot be nil")
    local chars = {}
    local map = {}
    local charUniqCnt = 0
    for i = 1, string.len(obj.raw), 2 do
      local char = string.sub(obj.raw, i, i+1) -- ����gbkΪ˫�ֽ�
      if not ExcludeCharacters[char] then
        table.insert(chars, char)
        if not map[char] then
          map[char] = true
          charUniqCnt = charUniqCnt + 1
        end
      end
    end
    obj.simplified = table.concat(chars, "")
    obj.cnt = charUniqCnt
    obj.map = map
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
local TouxueMotion = define_TouxueMotion()

local define_touxue = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    search = "search",
    fight = "fight",
    submit = "submit",
  }
  local Events = {
    STOP = "stop",  -- any state -> stop
    START = "start",  -- stop -> ask
    PREPARED = "prepared",  -- ask -> search
    TARGET_FOUND = "target_found",  -- search -> fight
    LEARNED = "learned",  -- fight -> submit
  }
  local REGEXP = {
    ALIAS_START = "^touxue\\s+start\\s*$",
    ALIAS_STOP = "^touxue\\s+stop\\s*$",
    ALIAS_DEBUG = "^touxue\\s+debug\\s+(on|off)\\s*$",
    ALIAS_SHOW = "^touxue\\s+show\\s*$",
    ALIAS_PRECISION = "^touxue\\s+precision\\s+(\\d+)\\s*$",
    ALIAS_RECALL = "^touxue\\s+recall\\s+(\\d+)\\s*$",
    ALIAS_SEARCH = "^touxue\\s+search\\s+(.+?)\\s+(.+?)\\s*$",
    JOB_SKILL = "^[ >]*Ľ�ݸ�˵������.*���ҽ���ϰ�������ϰ�����˵�����ó�(.*)����$",
    JOB_NPC_ZONE = "^[ >]*Ľ�ݸ�����Ķ�������˵����������Ի(.*?)������(.*?)һ�����$",
    JOB_MOTION = "^[ >]*Ľ�ݸ�����Ķ�������˵����(.*)$",
    JOB_NEED_CAPTCHA = "^[ >]*Ľ�ݸ�������һ��ֽ�����飺$",
    WORK_TOO_FAST = "^[ >]*Ľ�ݸ�˵��������ʱ��û��ʲô���ˡ���$",
  }

  local JobRoomId = 479

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
    self.precisionPercent = PrecisionThreshold
    self.recallPercent = RecallThreshold
    self:debugOn()
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups("touxue_ask_start", "touxue_ask_done")
    helper.removeTriggerGroups("touxue_search", "touxue_fight")
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
        SendNoEcho("set jobs job_done")  -- integration with jobs module
      end,
      exit = function() end
    }
    self:addState {
      state = States.ask,
      enter = function()
        helper.enableTriggerGroups("touxue_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("touxue_ask_start", "touxue_ask_done")
      end
    }
    self:addState {
      state = States.search,
      enter = function() end,
      exit = function()
        helper.disableTriggerGroups("touxue_search")
      end
    }
    self:addState {
      state = States.fight,
      enter = function() end,
      exit = function()
        -- be sure all skills are set as before
        SendNoEcho("halt")
        SendNoEcho("bei strike")
        SendNoEcho("bei cuff")
        helper.disableTriggerGroups("touxue_fight")
      end
    }
    self:addState {
      state = States.submit,
      enter = function()
        helper.enableTriggerGroups("touxue_submit_start")
      end,
      exit = function()
        helper.disableTimerGroups("touxue_submit_start", "touxue_submit_done")
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
        helper.checkUntilNotBusy()
        SendNoEcho("halt")
        travel:walkto(JobRoomId)
        travel:waitUntilArrived()
        self:debug("�ȴ�1�����������")
        wait.time(1)
        return self:doAsk()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<ask>
    self:addTransition {
      oldState = States.ask,
      newState = States.search,
      event = Events.PREPARED,
      action = function()
        return self:doSearch()
      end
    }
    self:addTransitionToStop(States.ask)
    -- transition from state<search>
    self:addTransition {
      oldState = States.search,
      newState = States.fight,
      event = Events.TARGET_FOUND,
      action = function()
        return self:doFight()
      end
    }
    self:addTransitionToStop(States.search)
    -- transition from state<fight>
    self:addTransition {
      oldState = States.fight,
      newState = States.submit,
      event = Events.LEARNED,
      action = function()
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.submit)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("touxue_ask_start", "touxue_ask_done")
    helper.addTriggerSettingsPair {
      group = "touxue",
      start = "ask_start",
      done = "ask_done"
    }
    helper.addTrigger {
      group = "touxue_ask_done",
      regexp = REGEXP.JOB_SKILL,
      response = function(name, line, wildcards)
        self:debug("JOB_SKILL triggered")
        self.skill = wildcards[1]
      end
    }
    helper.addTrigger {
      group = "touxue_ask_done",
      regexp = REGEXP.JOB_MOTION,
      response = function(name, line, wildcards)
        self:debug("JOB_MOTION triggered")
        if self.jobMotionInline then
          if not self.rawMotions then
            self.rawMotions = {}
          end
          -- ���������ֽ�ʱ������
          local rawMotion = string.gsub(wildcards[1], ",", "")
          local len = string.len(rawMotion)
          if len % 2 ~= 0 then
            ColourNote("yellow", "", "�쳣�����������֣�����Ϊ" .. len)
          end
          table.insert(self.rawMotions, rawMotion)
        end
      end,
      sequence = 10,
    }
    helper.addTrigger {
      group = "touxue_ask_done",
      regexp = REGEXP.JOB_NPC_ZONE,
      response = function(name, line, wildcards)
        self:debug("JOB_NPC_ZONE triggered")
        self.jobMotionInline = false
        self.npc = wildcards[1]
        self.zoneName = wildcards[2]
      end,
      sequence = 5,  -- must be higher than JOB_MOTION
    }
    helper.addTrigger {
      group = "touxue_ask_done",
      regexp = REGEXP.WORK_TOO_FAST,
      response = function()
        self.workTooFast = true
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("touxue")
    helper.addAlias {
      group = "touxue",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "touxue",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "touxue",
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
      group = "touxue",
      regexp = REGEXP.ALIAS_SHOW,
      response = function()
        self:show()
      end
    }
    helper.addAlias {
      group = "touxue",
      regexp = REGEXP.ALIAS_PRECISION,
      response = function(name, line, wildcards)
        local pct = tonumber(wildcards[1])
        if pct < 0 or pct > 100 then
          ColourNote("red", "", "׼ȷ�ٷֱȱ�����0-100֮��")
        else
          self.precisionPercent = pct
        end
      end
    }
    helper.addAlias {
      group = "touxue",
      regexp = REGEXP.ALIAS_RECALL,
      response = function(name, line, wildcards)
        local pct = tonumber(wildcards[1])
        if pct < 0 or pct > 100 then
          ColourNote("red", "", "�ٻذٷֱȱ�����0-100֮��")
        else
          self.recallPercent = pct
        end
      end
    }
    helper.addAlias {
      group = "touxue",
      regexp = REGEXP.ALIAS_SEARCH,
      response = function(name, line, wildcards)
        self.npc = wildcards[1]
        self.zoneName = wildcards[2]
        if self.DEBUG then self:show() end
        return self:doPrepare()
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

  function prototype:doAsk()
    -- reset all job info
    self.zoneName = nil
    self.npc = nil
    self.skill = nil
    self.rawMotions = nil
    self.jobMotionInline = true
    self.needCaptcha = nil
    self.workTooFast = false
    SendNoEcho("set touxue ask_start")
    SendNoEcho("ask murong fu about job")
    SendNoEcho("set touxue ask_done")
    helper.checkUntilNotBusy()
    if self.workTooFast then
      self:debug("����CD�У��ȴ�8��������")
      wait.time(8)
      return self:doAsk()
    elseif self.needCaptcha then
      ColourNote("silver", "", "���ֶ�������֤��Ϣ����ʽΪ��touxue <����> <������>")
      return
    elseif not self.zoneName or not self.npc or not self.skill or not self.rawMotions or #(self.rawMotions) == 0 then
      -- todo
      ColourNote("yellow", "", "�޷���ȡ��������Ϣ������ʧ��")
      return self:doCancel()
    end
    if self.DEBUG then self:show() end
    return self:doPrepare()
  end

  function prototype:doPrepare()
    -- ȷ������
    local zone = travel:getMatchedZone(self.zoneName)
    if not zone then
      ColourNote("red", "", "���� " .. self.zoneName .. " ���ɴ����ʧ��")
      wait.time(1)
      return self:doCancel()
    end
    -- ���������Ŀ�ʼ����
    local startRoomCode = zone.centercode
    local startRoom = travel.roomsByCode[startRoomCode]
    if not startRoom then
      ColourNote("red", "", "���� " .. self.zoneName .. " ���Ľڵ���Ч������ʧ��")
      wait.time(1)
      return self:doCancel()
    end

    self.startRoom = startRoom
    self.zone = zone

    -- ����ʽ���зֽ�
    self.motions = {}
    for _, rawMotion in ipairs(self.rawMotions) do
      local motion = TouxueMotion:new {
        raw = rawMotion
      }
      self.motions[motion.simplified] = motion
    end
    return self:fire(Events.PREPARED)
  end

  function prototype:doSearch()
    wait.time(1)
    helper.checkUntilNotBusy()
    SendNoEcho("halt")
    travel:walkto(self.startRoom.id)
    travel:waitUntilArrived()
    -- Ѱ��Ŀ��
    self.npcId = nil
    helper.addOneShotTrigger {
      group = "touxue_search",
      regexp = "^[ >]*" .. self.npc .. "\\((.*?)\\)$",
      response = function(name, line, wildcards)
        self:debug("NPC_SEARCH triggered")
        self.npcId = string.lower(wildcards[1])
      end
    }
    local onStep = function()
      return self.npcId ~= nil
    end
    local onArrive = function()
      if self.npcId then
        ColourNote("green", "", "����Ŀ�ִ꣬��͵ѧ")
        return self:fire(Events.TARGET_FOUND)
      else
        ColourNote("yellow", "", "δ����Ŀ�꣬����ʧ��")
        return self:doCancel()
      end
    end
    helper.checkUntilNotBusy()
    SendNoEcho("halt")
    return travel:traverseZone(self.zone.code, onStep, onArrive)
  end

  function prototype:doFight()
    -- ������ʽ������Ϣ
    self.motionsLearned = {}
    self.motionsToLearn = {}
    local motionCnt = 0
    for name, motion in pairs(self.motions) do
      self.motionsToLearn[name] = motion
      motionCnt = motionCnt + 1
    end
    -- ��Ӵ���
    helper.addTrigger {
      group = "touxue_fight",
      regexp = "^[ >]*[^\\(]*" .. self.npc .. ".*$",
      response = function(name, line, widlcards)
        self:debug("NPC_MOTION triggered")
        if #(self.motionsLearned) == motionCnt then
          ColourNote("green", "", "�Ѿ�ѧ��ȫ����ʽ")
          return
        end
        for name, motion in pairs(self.motionsToLearn) do
          if self.motionsLeared[name] then
            self:debug("������ѧϰ", name)
            break
          else
            local result = self:evaluateMotion(motion, line)
            if result.success then
              self:debug(motion.simplified, "׼ȷ�ٷֱȣ�", result.precision, "�ٻذٷֱȣ�", result.recall);
              if result.precision >= self.precisionPercent and result.recall >= self.recallPercent then
                self:debug("����������ִ��͵ѧ")
                SendNoEcho("touxue " .. self.npcId)
                self.motionsToLearn[motion.simplified] = nil
                table.insert(self.motionsLearned, motion)
                break
              end
            else
              ColourNote("yellow", "", result.message)
            end
          end
        end
      end
    }

    helper.checkUntilNotBusy()
    SendNoEcho("halt")
    -- �Ӵ�װ�����书
    SendNoEcho("follow " .. self.npcId)
    SendNoEcho("unwield all")
    SendNoEcho("bei none")
    local fightStartTime = os.time()
    helper.enableTriggerGroups("touxue_fight")
    SendNoEcho("fight " .. self.npcId)
    while true do
      wait.time(4)
      if #(self.motionsLearned) == motionCnt then
        return self:fire(Events.LEARNED)
      end
      local currTime = os.time()
      if currTime - fightStartTime >= 40 then
        ColourNote("yellow", "", "͵ѧʱ�䳬��" .. FightTimeThreshold .. "�룬ֹͣfight")
        break
      end
    end
    return self:fire(Events.LEARNED)
  end

  function prototype:doSubmit()
    SendNoEcho("halt")
    helper.checkUntilNotBusy()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    wait.time(1)
--    self.submitSuccess = false
--    SendNoEcho("set touxue submit_start")
--    SendNoEcho("ask touxue fu about finish")
--    SendNoEcho("set touxue submit_done")
--    helper.checkUntilNotBusy()
    SendNoEcho("drop huo tong")
    SendNoEcho("drop yun tie")
    -- todo
  end

  function prototype:evaluateMotion(motion, line)
    if string.len(line) % 2 ~= 0 then
      return {
        success = false,
        message = "��ǰ���ӿ��ܴ��ڷ������ַ�������",
        precision = 0,
        recall = 0,
      }
    else
      local chars = {}
      local charCnt = 0
      local matchedChars = {}
      local matchedCharCnt = 0
      for i = 1, len, 2 do
        local char = string.sub(line, i, i+1)
        if not chars[char] then
          chars[char] = true
          charCnt = charCnt + 1
        end
        if motion.map[char] and not matchedChars[char] then
          matchedChars[char] = true
          matchedCharCnt = matchedCharCnt + 1
        end
      end
      return {
        success = true,
        precision = math.floor(matchedCharCnt / charCnt * 100),
        recall = math.floor(matchedCharCnt / motion.cnt * 100),
      }
    end
  end

  function prototype:doCancel()
    helper.checkUntilNotBusy()
    SendNoEcho("halt")
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    SendNoEcho("ask murong fu about fail")
    helper.checkUntilNotBusy()
    return self:fire(Events.STOP)
  end

  function prototype:show()
    print("͵ѧ������", self.npc)
    print("͵ѧ����", self.zoneName)
    print("͵ѧ���ܣ�", self.skill)
    print("͵ѧ��ʽ����", self.rawMotions and #(self.rawMotions) or 0)
  end

  return prototype
end
return define_touxue():FSM()

