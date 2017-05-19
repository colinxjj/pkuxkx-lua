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
local captcha = require "pkuxkx.captcha"

-- 去除掉干扰字符
local ExcludeCharacters = {}
for _, c in ipairs({
  "大","英", "雄", "盖", "世", "豪", "杰", "你", "的",
  "，", "。", "「", "」", "』", "ｘ", ",", "∞", "≌", "￥", "↓" }) do
  ExcludeCharacters[c] = true
end
local PrecisionThreshold = 50
local RecallThreshold = 50
-- 算法时间限制 当超过算法时间限制且没有完成偷学时，定时执行偷学直到战斗结束
local AlgoTimeThreshold = 40
-- 战斗时间限制
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
      local char = string.sub(obj.raw, i, i+1) -- 中文gbk为双字节
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
    JOB_SKILL = "^[ >]*慕容复说道：「.*，我近来习武遇到障碍，听说有人擅长(.*)。」$",
    JOB_NPC_ZONE = "^[ >]*慕容复在你的耳边悄声说道：其人名曰(.*?)，正在(.*?)一带活动。$",
    JOB_MOTION = "^[ >]*慕容复在你的耳边悄声说道：(.*)$",
    JOB_NEED_CAPTCHA = "^[ >]*慕容复给了你一张纸，上书：$",
    WORK_TOO_FAST = "^[ >]*慕容复说道：「暂时我没有什么事了。」$",
    CANNOT_TOUXUE = "^[ >]*你恐怕没有偷学机会了。$",
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
    self.precondition = {
      jing = 0.95,
      qi = 0.95,
      neili = 0.95,
      jingli = 0.95
    }
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
        self:debug("等待1秒后请求任务")
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
          -- 当有奇数字节时，警告
          local rawMotion = string.gsub(wildcards[1], "[,!\\.]", "")
          local len = string.len(rawMotion)
          if len % 2 ~= 0 then
            ColourNote("yellow", "", "异常长度描述出现，长度为" .. len)
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
          ColourNote("red", "", "准确百分比必须在0-100之间")
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
          ColourNote("red", "", "召回百分比必须在0-100之间")
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
        print("停止 - 当前状态", self.currState)
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
      self:debug("任务CD中，等待8秒后继续接")
      wait.time(10)
      return self:doAsk()
    elseif self.needCaptcha then
      ColourNote("yellow", "", "请手动输入验证信息，格式为：touxue search <人名> <区域名>")
      return
    elseif not self.zoneName or not self.npc or not self.skill or not self.rawMotions or #(self.rawMotions) == 0 then
      -- todo
      ColourNote("yellow", "", "无法获取到任务信息，任务失败")
      return self:doCancel()
    end
    if self.DEBUG then self:show() end
    return self:doPrepare()
  end

  function prototype:doPrepare()
    -- 确定区域
    local zone = travel:getMatchedZone(self.zoneName)
    if not zone then
      ColourNote("red", "", "区域 " .. self.zoneName .. " 不可达，任务失败")
      wait.time(1)
      return self:doCancel()
    end
    -- 从区域中心开始遍历
    local startRoomCode = zone.centercode
    local startRoom = travel.roomsByCode[startRoomCode]
    if not startRoom then
      ColourNote("red", "", "区域 " .. self.zoneName .. " 中心节点无效，任务失败")
      wait.time(1)
      return self:doCancel()
    end

    self.startRoom = startRoom
    self.zone = zone

    -- 对招式进行分解
    self.motions = {}
    for _, rawMotion in ipairs(self.rawMotions) do
      local motion = TouxueMotion:new {
        raw = rawMotion
      }
      self:debug("简化后招式：", motion.simplified)
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
    -- 寻找目标
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
        ColourNote("green", "", "发现目标，执行偷学")
        return self:fire(Events.TARGET_FOUND)
      else
        ColourNote("yellow", "", "未发现目标，任务失败")
        return self:doCancel()
      end
    end
    helper.checkUntilNotBusy()
    SendNoEcho("halt")
    return travel:traverseZone(self.zone.code, onStep, onArrive)
  end

  function prototype:doFight()
    -- 增加招式跟踪信息
    self.motionsLearned = {}
    self.motionsToLearn = {}
    self.cannotTouxue = false
    local motionCnt = 0
    for name, motion in pairs(self.motions) do
      self.motionsToLearn[name] = motion
      motionCnt = motionCnt + 1
    end

    helper.checkUntilNotBusy()
    SendNoEcho("halt")
    -- 接触装备和武功
    SendNoEcho("follow " .. self.npcId)
    SendNoEcho("unwield all")
    SendNoEcho("bei none")
    SendNoEcho("yun qi")
    SendNoEcho("set skip_combat 0")
    local fightStartTime = os.time()
    -- 添加触发
    helper.addTrigger {
      group = "touxue_fight",
      regexp = "^[ >]*[^\\(]*" .. self.npc .. ".*$",
      response = function(name, line, widlcards)
        self:debug("NPC_MOTION triggered")
        if #(self.motionsLearned) == motionCnt then
          ColourNote("green", "", "已经学会全部招式")
          return
        end
        for name, motion in pairs(self.motionsToLearn) do
          if self.motionsLearned[name] then
            self:debug("此招已学习", name)
            break
          else
            local result = self:evaluateMotion(motion, line)
            if result.success then
              if result.precision >= self.precisionPercent and result.recall >= self.recallPercent then
                self:debug(motion.simplified, "准确：", result.precision, "召回：", result.recall)
                self:debug("符合条件，执行偷学")
                SendNoEcho("touxue " .. self.npcId)
                self.motionsToLearn[motion.simplified] = nil
                table.insert(self.motionsLearned, motion)
                break
              else
                self:debug("准确：", result.precision, "召回：", result.recall)
              end
            else
              ColourNote("yellow", "", result.message)
            end
          end
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
    SendNoEcho("fight " .. self.npcId)
    wait.time(1)
    -- 打开触发
    helper.enableTriggerGroups("touxue_fight")
    while true do
      wait.time(4)
      if #(self.motionsLearned) == motionCnt then
        ColourNote("green", "", "招数已学满")
        return self:fire(Events.LEARNED)
      end
      if self.cannotTouxue then
        self:debug("偷学机会已用完")
        return self:fire(Events.LEARNED)
      end
      local duration = os.time() - fightStartTime
      if duration >= FightTimeThreshold then
        ColourNote("yellow", "", "偷学时间达到" .. duration .. "秒，停止fight")
        break
      elseif duration >= AlgoTimeThreshold then
        self:debug("算法时间结束，定时出招")
        SendNoEcho("touxue " .. self.npcId)
      end
    end
    return self:fire(Events.LEARNED)
  end

  function prototype:doSubmit()
    SendNoEcho("halt")
    SendNoEcho("follow none")
    SendNoEcho("bei strike cuff")
    SendNoEcho("set skip_combat 1")
    helper.removeTriggerGroups("touxue_fight")
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
    print("偷学人名：", self.npc)
    print("偷学区域：", self.zoneName)
    print("偷学技能：", self.skill)
    print("偷学招式数：", self.rawMotions and #(self.rawMotions) or 0)
  end

  return prototype
end
return define_touxue():FSM()

