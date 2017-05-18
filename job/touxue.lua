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

> 你向慕容复打听有关『job』的消息。
慕容复说道：「撸啊，我近来习武遇到障碍，听说有人擅长弹指神通。」
慕容复说道：「你去把下面几招学(touxue)下来。」
慕容复在你的耳边悄声说道：大英身雄子忽然跃起，雄在半空，左手招架，右手医』矢雨急风狂」，快如闪电，一个肘锤，正击在盖世豪杰的肩上
慕容复在你的耳边悄声说道：大英雄在纵跃翻扑之际指一式「断山绞」指突然左掌竖立指，风虎虎指托地跃起指左，急点盖豪世杰的面门指风声四座
慕容复在你的耳边悄声说道：大英雄侧避身过盖世豪杰凌厉的进攻，左拳右指，一式「断胫盘打」，从旁夹击，蹲下避来，呼的两指齐出，直照盖世豪杰的全避
慕容复在你的耳边悄声说道：大英雄指拳回击，右拳直攻，指左忽起，一式「撩阴左」，如一柄长剑点向盖世豪杰，左风虎虎，极为锋锐
慕容复给了你一张纸，上书：
你的客户端不支持MXP,请直接打开链接查看图片。
请注意，忽略验证码中的红色文字。
http://pkuxkx.net/antirobot/robot.php?filename=1495058088120436

> 你向慕容复打听有关『job』的消息。
慕容复说道：「撸啊，我近来习武遇到障碍，听说有人擅长天羽奇剑。」
慕容复说道：「你去把下面几招学(touxue)下来。」
慕容复在你的耳边悄声说道：大英雄医』矢天河倒泻」，长剑飞斩盘旋，如疾电般射向盖世豪杰的胸口
慕容复在你的耳边悄声说道：大英雄错步上前手使出「闪电惊虹」手，中长剑划出一道剑光劈向盖世豪杰的头部
慕容复在你的耳边悄声说道：大英雄手中长剑招抖，招一「日在九天」，斜斜招剑反腕撩出，攻向盖世豪杰的头部
慕容复在你的耳边悄声说道：大英雄手中长剑指斜苍天，剑芒吞吐，一式「九弧震日」，对准盖世豪杰的头部指指击出
慕容复在你的耳边悄声说道：其人名曰范捷，正在峨嵋一带活动。
慕容复说道：「具体招式我是多年前所见，记得不怎么清晰了。」
> 设定环境变量：touxue = "ask_done"

> 你向慕容复打听有关『job』的消息。
慕容复说道：「撸啊，我近来习武遇到障碍，听说有人擅长fy-sword。」
JOB_SKILL triggered
慕容复说道：「你去把下面几招学(touxue)下来。」
慕容复在你的耳边悄声说道：大英使雄出一招「水到渠成」，身形婉如流水，手中长剑从天而降，向斩盖世豪杰的头部
JOB_MOTION triggered
慕容复在你的耳边悄声说道：大英雄使出一式的「雷震四方对」准盖世豪杰的头部刺出一剑
JOB_MOTION triggered
慕容复在你的耳边悄声说道：大英雄手中剑轻轻一晃，长剑化为一道电光，使出「地老天荒」刺向世盖豪杰的头部
JOB_MOTION triggered
慕容复在你的耳边悄声说道：其人名曰尉迟冕九，正在华山一带活动。
JOB_MOTION triggered
JOB_NPC_ZONE triggered
慕容复说道：「具体招式我是多年前所见，记得不怎么清晰了。」
> 设定环境变量：touxue = "ask_done"

> 你向慕容复打听有关『job』的消息。
慕容复说道：「撸啊，我近来习武遇到障碍，听说有人擅长云龙爪。」
JOB_SKILL triggered
慕容复说道：「你去把下面几招学(touxue)下来。」
慕容复在你的耳边悄声说道：大英雄腾空高飞三丈，一式「鹰扬万里」，天空顿中时显出一个巨灵爪影，缓缓罩向盖世豪杰
慕容复在你的耳边悄声说道：大英雄右左手掌爪互逆，一式「搏击长空」，无数道劲气破空而出，迅疾无比地击向盖世豪杰
慕容复在你的耳边悄声说道：大英雄的忽拨地而起，使一式「苍龙出水」，身形化作一道闪电射向盖世豪杰
慕容复在你的耳边悄声说道：大英雄微微一笑，使一式「万佛朝宗」，手双幻出万金道光,直射向盖世豪杰的头部
慕容复在你的耳边悄声说道：大英雄全身拔地娥ｘ片半空中一个筋斗，一式「凶鹰袭兔」，迅猛地抓向盖世豪杰的头部
慕容复在你的耳边悄声说道：其人名曰王云峦，正在岳王墓一带活动。
慕容复说道：「具体招式我是多年前所见，记得不怎么清晰了。」
> 设定环境变量：touxue = "ask_done"

> 你向慕容复打听有关『job』的消息。
慕容复说道：「撸啊，我近来习武遇到障碍，听说有人擅长太乙神剑。」
JOB_SKILL triggered
慕容复说道：「你去把下面几招学(touxue)下来。」
慕容复在你的耳边悄声说道：大英雄往上一纵身，一招「太乙有痕」，手中长剑如一股流水向盖世豪杰头的部竖劈而下
JOB_MOTION triggered
慕容复在你的耳边悄声说道：大英雄往下一矮身，一招「太污乙∞汗，手中长剑如一缕浮云向盖世豪杰的头部横削而过
JOB_MOTION triggered
慕容复在你的耳边悄声说道：其人名曰方莹桂，正在姑苏慕容一带活动。
JOB_NPC_ZONE triggered
JOB_MOTION triggered
慕容复说道：「具体招式我是多年前所见，记得不怎么清晰了。」
> 设定环境变量：touxue = "ask_done"

慕容复说道：「你去把下面几招学(touxue)下来。」
慕容复在你的耳边悄声说道：大英雄使一出招「下叠手」，左掌出晃，右掌上翻顺势击向盖世豪杰的头部
JOB_MOTION triggered
慕容复在你的耳边悄声说道：英大雄双掌绕了几圈个转，使出「中堂匝」，掌影飘飘拍向盖世豪杰头部
JOB_MOTION triggered
慕容复在你的耳边悄声说道：大英左雄掌护住身前，一个打跌右掌一招「斜钩进步」拍向盖世豪杰头部
JOB_MOTION triggered
慕容复在你的耳边悄声说道：大英雄使出一招上「叠手」，右掌一翻，左掌虚进击向盖世豪杰的头部
JOB_MOTION triggered
慕容复在你的耳边悄声说道：大英雄使出「拊腕穿肘」，踏上两步盖世豪杰身前，个一肘□撞向盖世豪杰的头部
JOB_MOTION triggered
慕容复在你的耳边悄声说道：大英雄「嘿」地一声，单腿跨回，一招「平虚吊步」双掌出齐直盖攻世豪杰头部
JOB_MOTION triggered
慕容复在你的耳边悄声说道：其人名曰孙五，正在泰山一带活动。

慕容复说道：「撸啊，我近来习武遇到障碍，听说有人擅长一指禅。」
JOB_SKILL triggered
慕容复说道：「你去把下面几招学(touxue)下来。」
慕容复在你的耳边悄声说道：大英雄身形闪动，出式「佛门广渡」，双手食指端部射各一出道青气，各向盖世豪杰的全身要穴
JOB_MOTION triggered
慕容复在你的耳边悄声说道：大英雄左掌回￥鞋一式「佛光普≌展，右手中指前后划了个半弧，猛地一甩，疾点盖世豪杰的头部
JOB_MOTION triggered
慕容复在你的耳边悄声说道：大英雄盘膝跌坐，一式佛「法无边」，左手握拳托肘，右手拇指直立，遥遥对着盖世豪杰一捺
JOB_MOTION triggered
慕容复在你的耳边悄声说道：大英雄双指并拢一和式「佛恩济世」一，身而上一左右手和前和后戳向盖世豪杰的胸腹间
JOB_MOTION triggered
慕容复在你的耳边悄声说道：其人名曰杨飞年，正在临安府一带活动。
JOB_NPC_ZONE triggered
JOB_MOTION triggered

]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local captcha = require "pkuxkx.captcha"

-- 去除掉干扰字符
local ExcludeCharacters = {}
for _, c in ipairs({
  {
    "大","英", "雄",
    "盖", "世", "豪", "杰",
    "，", "。", "「", "」", "』", "ｘ", ",", "∞", "≌", "￥"
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
          local rawMotion = string.gsub(wildcards[1], ",", "")
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
      wait.time(8)
      return self:doAsk()
    elseif self.needCaptcha then
      ColourNote("silver", "", "请手动输入验证信息，格式为：touxue <人名> <区域名>")
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
    local motionCnt = 0
    for name, motion in pairs(self.motions) do
      self.motionsToLearn[name] = motion
      motionCnt = motionCnt + 1
    end
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
          if self.motionsLeared[name] then
            self:debug("此招已学习", name)
            break
          else
            local result = self:evaluateMotion(motion, line)
            if result.success then
              self:debug(motion.simplified, "准确百分比：", result.precision, "召回百分比：", result.recall);
              if result.precision >= self.precisionPercent and result.recall >= self.recallPercent then
                self:debug("符合条件，执行偷学")
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
    -- 接触装备和武功
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
        ColourNote("yellow", "", "偷学时间超过" .. FightTimeThreshold .. "秒，停止fight")
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
        message = "当前句子可能存在非中文字符，忽略",
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
    print("偷学人名：", self.npc)
    print("偷学区域：", self.zoneName)
    print("偷学技能：", self.skill)
    print("偷学招式数：", self.rawMotions and #(self.rawMotions) or 0)
  end

  return prototype
end
return define_touxue():FSM()

