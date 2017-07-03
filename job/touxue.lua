--
-- touxue.lua
-- User: zhe.jiang
-- Date: 2017/5/8
-- Desc:
-- Change:
-- 2017/5/8 - created

local patterns = {[[

]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
-- local captcha = require "pkuxkx.captcha"
local combat = require "pkuxkx.combat"

-- ȥ���������ַ�
local ExcludeCharacters = {}
for _, c in ipairs({
  "��","Ӣ", "��", "��", "��", "��", "��", "��", "��",
  "��", "��", "��", "��", "��", "��", ",", "��", "��",
  "��", "��", "��", "��" }) do
  ExcludeCharacters[c] = true
end
local PrecisionThreshold = 50
local RecallThreshold = 50
-- �㷨ʱ������ �������㷨ʱ��������û�����͵ѧʱ����ʱִ��͵ѧֱ��ս������
local AlgoTimeThreshold = 40
-- ս��ʱ������
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
    ALIAS_FIGHT = "^touxue\\s+fight\\s+(.+?)\\s*$",
    ALIAS_FIGHT2 = "^touxue\\s+fight2\\s+(.*?)\\s+(.*?)\\s*$",
    ALIAS_MANUAL = "^touxue\\s+manual\\s+(on|off)\\s*$",
    ALIAS_MANUAL_SEARCH = "^touxue\\s+manualsearch\\s+(on|off)\\s*$",
    JOB_SKILL = "^[ >]*Ľ�ݸ�˵������.*���ҽ���ϰ�������ϰ�����˵�����ó�(.*)����$",
    JOB_NPC_ZONE = "^[ >]*Ľ�ݸ�����Ķ�������˵����������Ի(.*?)������(.*?)һ�����$",
    JOB_MOTION = "^[ >]*Ľ�ݸ�����Ķ�������˵����(.*)$",
    JOB_NEED_CAPTCHA = "^[ >]*Ľ�ݸ�������һ��ֽ�����飺$",
    WORK_TOO_FAST = "^[ >]*Ľ�ݸ�˵��������ʱ��û��ʲô���ˡ���$",
    CANNOT_TOUXUE = "^[ >]*�����û��͵ѧ�����ˡ�$",
    UNWIELD_SWORD = "^[ >]*�㽫.*?����һ�ӣ�ֻ��.*?ͻȻ��ù�â������·����������ǹ���ɢƮ���ˣ�$",
    WIELD_SWORD = "^[ >]*.*?ͻȻ�Զ�Ծ�������У�ֻ��һ���׹�ֱ͸.*?��������Ȼ������$",
    TICK = helper.settingRegexp("touxue", "tick"),
    MOTION_LEARNED = "^[ >]*���.*?����͵ѧ����һ�У�$",
    -- WON = "^[ >]*��սʤ��(.*?)!$",
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
    self:initTimers()
    self:setState(States.stop)
    self.precisionPercent = PrecisionThreshold
    self.recallPercent = RecallThreshold
    self.precondition = {
      jing = 0.95,
      qi = 0.95,
      neili = 0.95,
      jingli = 0.95
    }
    self.manual = false
    self.manualsearch = false
    self:debugOn()
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups("touxue_ask_start", "touxue_ask_done")
    helper.removeTriggerGroups("touxue_search", "touxue_fight_npc")
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
      enter = function()
        helper.removeTriggerGroups("touxue_fight_npc")
        helper.enableTriggerGroups("touxue_fight")
      end,
      exit = function()
        helper.disableTriggerGroups("touxue_fight")
        helper.removeTriggerGroups("touxue_fight_npc")
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
        -- be sure all skills are set as before
        SendNoEcho("halt")
        SendNoEcho("follow none")
        SendNoEcho("bei strike cuff")
        SendNoEcho("jifa sword dugu-jiujian")
        SendNoEcho("unwield all")
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.submit)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("touxue_ask_start", "touxue_ask_done", "touxue_fight")
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
          local rawMotion = string.gsub(wildcards[1], "[,!\\.]", "")
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
      regexp = REGEXP.JOB_NEED_CAPTCHA,
      response = function()
        self.needCaptcha = true
      end
    }
    helper.addTrigger {
      group = "touxue_ask_done",
      regexp = REGEXP.WORK_TOO_FAST,
      response = function()
        self.workTooFast = true
      end
    }
    helper.addTrigger {
      group = "touxue_fight",
      regexp = REGEXP.TICK,
      response = function()
        if self.motionLearning then
          SendNoEcho("touxue " .. self.npcId)
        else
          -- busy myself
--          SendNoEcho("wield jitui")
          SendNoEcho("unwield all")
          SendNoEcho("wield jitui")
        end
      end
    }
    helper.addTrigger {
      group = "touxue_fight",
      regexp = REGEXP.MOTION_LEARNED,
      response = function()
        if self.motionLearning then
          self:debug("͵ѧ����ʽ��", self.motionLearning)
          self.motionsToLearn[self.motionLearning] = nil
          table.insert(self.motionsLearned, self.motionLearning)
          self.motionLearning = nil
        end
      end
    }
    helper.addTrigger {
      group = "touxue_fight",
      regexp = REGEXP.CANNOT_TOUXUE,
      response = function()
        self:debug("CANNOT_TOUXUE triggered")
        self.cannotTouxue = true
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
    helper.addAlias {
      group = "touxue",
      regexp = REGEXP.ALIAS_FIGHT,
      response = function(name, line, wildcards)
        local npcId = wildcards[1]
        if self.currState ~= "search" then
          if not self.npc or not self.rawMotions then
            ColourNote("red", "", "��NPC��Ϣ����������Ϣ���޷�����͵ѧ")
            return
          else
            self:debug("��ǰ״̬�޸�Ϊ��" .. self.currState .. " -> " .. States.search)
            self:debug("Ŀ��NPC ID�޸�Ϊ��" .. npcId)
            self.currState = States.search
          end
        end
        self.npcId = npcId
        return self:fire(Events.TARGET_FOUND)
      end
    }
    helper.addAlias {
      group = "touxue",
      regexp = REGEXP.ALIAS_FIGHT2,
      response = function(name, line, wildcards)
        local npcName = wildcards[1]
        local npcId = wildcards[2]
        if self.currState ~= "search" then
          if not self.npc or not self.rawMotions then
            ColourNote("red", "", "��NPC��Ϣ����������Ϣ���޷�����͵ѧ")
            return
          else
            self:debug("��ǰ״̬�޸�Ϊ��" .. self.currState .. " -> " .. States.search)
            self:debug("Ŀ��NPC ID�޸�Ϊ��" .. npcId)
            self.currState = States.search
          end
        end
        self.npc = npcName
        self.npcId = npcId
        return self:fire(Events.TARGET_FOUND)
      end
    }
    helper.addAlias {
      group = "touxue",
      regexp = REGEXP.ALIAS_MANUAL,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self:debug("�����ֶ�ģʽ�����޷��Զ�������NPCʱ�����ֶ��ҵ�ִ������touxue fight <npc id>")
          self.manual = true
        else
          self:debug("�ر��ֶ�ģʽ���޷��Զ�������NPCʱ��ֱ��ȡ������")
          self.manual = false
        end
      end
    }
    helper.addAlias {
      group = "touxue",
      regexp = REGEXP.ALIAS_MANUAL_SEARCH,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self:debug("�����ֶ�����ģʽ���ҵ�Ŀ��ִ��touxue fight <npc id>")
          self.manualsearch = true
        else
          self:debug("�ر��ֶ�����ģʽ���Զ���������Ŀ�겢ִ��͵ѧ")
          self.manualsearch = false
        end
      end
    }
  end

  function prototype:initTimers()

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
      wait.time(10)
      return self:doAsk()
    elseif self.needCaptcha then
      ColourNote("yellow", "", "���ֶ�������֤��Ϣ����ʽΪ��touxue search <����> <������>")
      return
    elseif not self.zoneName or not self.npc or not self.skill or not self.rawMotions or #(self.rawMotions) == 0 then
      ColourNote("yellow", "", "�޷���ȡ��������Ϣ������ʧ��")
      return self:doCancel()
    elseif self.skill == "��ڤ�Ʒ�" then
      ColourNote("red", "", "͵ѧ��ڤ����Ҫ��������������")
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
      if self.manual then
        ColourNote("yellow", "", "�ֶ�ģʽ�������ҵ���touxue fight <npc id>")
      else
        wait.time(1)
        return self:doCancel()
      end
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
      self:debug("�򻯺���ʽ��", motion.simplified)
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

    -- ��ʹ���ֶ�����ģʽʱ����ʾ��Ϣ�����б���
    if self.manualsearch then
      ColourNote("yellow", "", "�ֶ�����ģʽ���ҵ�Ŀ���ִ��touxue fight <npc id>")
      return
    end
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
        if self.manual then
          ColourNote("yellow", "", "���ֶ�Ѱ��Ŀ�꣬�ҵ���ִ������touxue fight <npc id>")
        else
          return self:doCancel()
        end
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
    self.motionLearning = nil
    self.cannotTouxue = false
    local motionCnt = 0
    for name, motion in pairs(self.motions) do
      self.motionsToLearn[name] = motion
      motionCnt = motionCnt + 1
    end

    helper.checkUntilNotBusy()
    SendNoEcho("halt")
    -- �Ӵ�װ�����书
    SendNoEcho("follow " .. self.npcId)
    SendNoEcho("unwield all")
    SendNoEcho("jifa sword none")
    SendNoEcho("bei none")
    SendNoEcho("yun recover")
    SendNoEcho("set skip_combat 0")
    local fightStartTime = os.time()
    -- ��Ӵ���
    helper.addTrigger {
      group = "touxue_fight_npc",
      regexp = "^[ >]*[^\\(]*" .. self.npc .. ".*$",
      response = function(name, line, widlcards)
        self:debug("NPC_MOTION triggered")
        if #(self.motionsLearned) == motionCnt then
          ColourNote("green", "", "�Ѿ�ѧ��ȫ����ʽ")
          return
        end
        for name, motion in pairs(self.motionsToLearn) do
          if self.motionsLearned[name] then
            self:debug("������ѧϰ", name)
            break
          else
            local result = self:evaluateMotion(motion, line)
            if result.success then
              if result.precision >= self.precisionPercent and result.recall >= self.recallPercent then
                self:debug(motion.simplified, "׼ȷ��", result.precision, "�ٻأ�", result.recall)
                self:debug("�������������õ�ǰ͵ѧ��ʽ")
                self.motionLearning = motion.simplified
                return
              else
                self:debug("׼ȷ��", result.precision, "�ٻأ�", result.recall)
              end
            else
              ColourNote("yellow", "", result.message)
            end
          end
        end
      end
    }
    helper.addTrigger {
      group = "touxue_fight_npc",
      regexp = "^[ >]*" .. self.npc .. "���ˡ�$",
      response = function()
        ColourNote("yellow", "", "͵ѧĿ���������޷�͵ѧ��׼������")
        self.cannotTouxue = true
      end
    }
    helper.enableTriggerGroups("touxue_fight_npc")
    combat:stop()
    SendNoEcho("killall " .. self.npcId)
    while true do
      wait.time(1)
      -- always busy myself
      if #(self.motionsLearned) == motionCnt then
        ColourNote("green", "", "������ѧ��")
        return self:fire(Events.LEARNED)
      end
      if self.cannotTouxue then
        self:debug("͵ѧ����������")
        return self:fire(Events.LEARNED)
      end
      local duration = os.time() - fightStartTime
      if duration >= FightTimeThreshold then
        ColourNote("yellow", "", "͵ѧʱ��ﵽ" .. duration .. "�룬ֹͣfight")
        break
      elseif duration >= AlgoTimeThreshold then
        self:debug("�㷨ʱ���������ʱ����")
        if duration % 4 == 0 then
          SendNoEcho("touxue " .. self.npcId)
        end
      else
        SendNoEcho("set touxue tick")
      end
    end
    return self:fire(Events.LEARNED)
  end

  function prototype:doSubmit()
    SendNoEcho("set skip_combat 1")
    helper.checkUntilNotBusy()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    wait.time(1)
    self.submitSuccess = false
    SendNoEcho("set touxue submit_start")
    SendNoEcho("ask murong fu about finish")
    SendNoEcho("set touxue submit_done")
    helper.checkUntilNotBusy()
    SendNoEcho("drop huo tong")
    SendNoEcho("drop yun tie")
    return self:fire(Events.STOP)
  end

  function prototype:evaluateMotion(motion, line)
    local line = string.gsub(string.gsub(line, self.npc, ""), "[,!\\.]", "")
    local len = string.len(line)
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

  function prototype:doCancel()
    SendNoEcho("halt")
    SendNoEcho("bei strike cuff")
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    self.submitSuccess = false
    SendNoEcho("ask murong fu about finish")
    helper.checkUntilNotBusy()
    return self:fire(Events.STOP)
  end

  function prototype:doStart()
    return self:fire(Events.START)
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

