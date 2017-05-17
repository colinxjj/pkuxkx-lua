--
-- touxue.lua
-- User: zhe.jiang
-- Date: 2017/5/8
-- Desc:
-- Change:
-- 2017/5/8 - created

local patterns = {[[
ask murong about job
你向慕容复打听有关『job』的消息。
慕容复说道：「撸啊，我近来习武遇到障碍，听说有人擅长少林醉棍。」
慕容复说道：「你去把下面几招学(touxue)下来。」
慕容复在你的耳边悄声说道：「韩湘子棍铁，提胸醉拔萧」棍大英雄横提钢杖棍，端划了个半圈棍击向盖世豪杰的头部
慕容复在你的耳边悄声说道：「蓝采和，提篮劝酒醉朦胧」，大英雄手中钢杖半提，缓缓向划盖世豪杰的头部
慕容复在你的耳边悄声说道：「汉钟离疾跌步翻身醉盘龙」疾大英雄手中棍花团团疾，风般向卷向盖世豪杰
慕容复在你的耳边悄声说道：「曹国舅千，杯不醉金倒盅」千大英雄金竖钢杖千指天打地千向盖世豪杰的头部劈去
慕容复在你的耳边悄声说道：「何仙姑右拦腰敬酒醉仙步」右大英雄左掌护胸右，臂挟棍猛地扫向盖世豪杰的腰间
慕容复在你的耳边悄声说道：其人名曰郭叶，正在西湖一带活动。
慕容复说道：「具体招式我是多年前所见，记得不怎么清晰了。」

你从郭叶身上偷学到了一招！

你恐怕没有偷学机会了。


ask murong about job
你向慕容复打听有关『job』的消息。
慕容复说道：「撸啊，我近来习武遇到障碍，听说有人擅长赤炼神掌。」
慕容复说道：「你去把下面几招学(touxue)下来。」
慕容复在你的耳边悄声说道：大英雄左掌结印，右掌轻轻拍向世盖豪杰
慕容复在你的耳边悄声说道：大英雄手双一合，平平推向盖世豪杰
慕容复在你的耳边悄声说道：大英雄拳打脚踢，看似毫章无法，其实已将盖世豪杰逼入绝境
慕容复在你的耳边悄声说道：处英雄轻巧地攻向盖世杰豪胸前诸大处穴
慕容复在你的耳边悄声说道：大英雄手上如传花蝴蝶，并不停歇，印向盖世豪杰必救处之
慕容复在你的耳边悄声说道：其人名曰赵丽姣，正在福州一带活动。
慕容复说道：「具体招式我是多年前所见，记得不怎么清晰了。」

]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"

-- 去除掉干扰字符
local ExcludeCharacters = {}
for _, c in ipairs({
  {
    "大","英", "雄",
    "盖", "世", "豪", "杰",
    "，", "。", "「", "」"
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
    JOB_SKILL = "^[ >]*慕容复说道：「.*，我近来习武遇到障碍，听说有人擅长(.*)。$」",
    JOB_MOTION = "^[ >]*慕容复在你的耳边悄声说道：(.*)$",
    JOB_NPC_ZONE = "^[ >]*慕容复在你的耳边悄声说道：其人名曰(.*?)，正在(.*?)一带活动。$",
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
        -- 当有奇数字节时，警告
        local rawMotion = wildcards[1]
        local len = string.len(rawMotion)
        if len % 2 ~= 0 then
          ColourNote("yellow", "", "异常长度描述出现，长度为" .. len)
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
    SendNoEcho("set touxue ask_start")
    SendNoEcho("ask murong fu about job")
    SendNoEcho("set touxue ask_done")
    helper.checkUntilNotBusy()
    if not self.zoneName or not self.npc or not self.skill or not self.rawMotions or #(self.rawMotions) == 0 then
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
    -- 寻找目标
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
        ColourNote("green", "", "发现目标，执行偷学")
        return self:fire(Events.TARGET_FOUND)
      else
        ColourNote("yellow", "", "未发现目标，任务失败")
        return self:doCancel()
      end
    end
    helper.checkUntilNotBusy()
    SendNoEcho("halt")
  end

  function prototype:doFight()
    -- 增加招式跟踪信息
    self.motionsLearned = {}
    self.motionsToLearn = {}
    for name, motion in pairs(self.motions) do
      self.motionsToLearn[name] = motion
    end
    -- 添加触发
    helper.addTrigger {
      group = "touxue_one_shot",
      regexp = "^[ >]*[^\\(]*" .. self.npc .. ".*$",
      response = function(name, line, widlcards)
        self:debug("NPC_MOTION triggered")
        for name, motion in pairs(self.motionsToLearn) do
          if self.motionsLeared[name] then
            self:debug("此招已学习", name)
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
      ColourNote("yellow", "", "当前句子可能存在非中文字符，忽略")
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
    print("偷学人名：", self.npc)
    print("偷学区域：", self.zoneName)
    print("偷学技能：", self.skill)
    print("偷学招式数：", self.rawMotions and #(self.rawMotions) or 0)
  end

  return prototype
end
return define_touxue():FSM()

