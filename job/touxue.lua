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

]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"

-- ȥ���������ַ�
local ExcludeCharacters = {}
for _, c in ipairs({
  {
    "��","Ӣ", "��",
    "��", "��", "��", "��",
    "��", "��", "��", "��"
  }
}) do
  ExcludeCharacters[c] = true
end

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
    submit = "submit"
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
    JOB_SKILL = "^[ >]*Ľ�ݸ�˵������.*���ҽ���ϰ�������ϰ�����˵�����ó�(.*)��$��",
    JOB_MOTION = "^[ >]*Ľ�ݸ�����Ķ�������˵����(.*)$",
    JOB_NPC_ZONE = "^[ >]*Ľ�ݸ�����Ķ�������˵����������Ի(.*?)������(.*?)һ�����$",
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
    self.excludedChars = {}
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups("touxue_ask_start", "touxue_ask_done")
    helper.removeTriggerGroups("touxue_one_shot")
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
        if not self.rawMotions then
          self.rawMotions = {}
        end
        -- ���������ֽ�ʱ������
        local rawMotion = wildcards[1]
        local len = string.len(rawMotion)
        if len % 2 ~= 0 then
          ColourNote("yellow", "", "�쳣�����������֣�����Ϊ" .. len)
        end
        table.insert(self.rawMotions, wildcards[1])
      end
    }
    helper.addTrigger {
      group = "touxue_ask_done",
      regexp = REGEXP.JOB_NPC_ZONE,
      response = function(name, line, wildcards)
        self:debug("JOB_NPC_ZONE triggered")
        self.npc = wildcards[1]
        self.zoneName = wildcards[2]
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
    SendNoEcho("set touxue ask_start")
    SendNoEcho("ask murong fu about job")
    SendNoEcho("set touxue ask_done")
    helper.checkUntilNotBusy()
    if not self.zoneName or not self.npc or not self.skill or not self.rawMotions or #(self.rawMotions) == 0 then
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
      local motion = TouxueMotion:new(rawMotion)
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
      group = "touxue_one_shot",
      regexp = "^[ >]*" .. self.npc .. "\\(.*?\\)$",
      response = function(name, line, wildcards)
        self:debug("NPC_ONE_SHOT triggered")
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
  end

  function prototype:doFight()
    -- ������ʽ������Ϣ
    self.motionsLearned = {}
    self.motionsToLearn = {}
    for name, motion in pairs(self.motions) do
      self.motionsToLearn[name] = motion
    end
    -- ��Ӵ���
    helper.addTrigger {
      group = "touxue_one_shot",
      regexp = "^[ >]*[^\\(]*" .. self.npc .. ".*$",
      response = function(name, line, widlcards)
        self:debug("NPC_MOTION triggered")
        for name, motion in pairs(self.motionsToLearn) do
          if self.motionsLeared[name] then
            self:debug("������ѧϰ", name)
            break
          else

          end
        end
      end
    }
  end

  function prototype:evaluateMotion(motion, line)
    local len = string.len(line)
    if len % 2 ~= 0 then
      ColourNote("yellow", "", "��ǰ���ӿ��ܴ��ڷ������ַ�������")
    else
      local charCnt = len / 2
      local matchedChars = {}
      local matchedCharCnt = 0
      for i = 1, len, 2 do
        local char = string.sub(line, i, i+1)
        if motion.map[char] and not matchedChars[char] then
          matchedChars[char] = true
          matchedCharCnt = matchedCharCnt + 1
        end
      end
--      local precision =
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

