--
-- fullskills.lua
-- User: zhe.jiang
-- Date: 2017/5/16
-- Desc:
-- Change:
-- 2017/5/16 - created

local helper = require "pkuxkx.helper"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"
local captcha = require "pkuxkx.captcha"
local nanjue = require "job.nanjue"

local Skills = {
  {
    basic = "force",
    special = "zixia-shengong",
    mode = "lingwu"
  },
  {
    basic = "sword",
    special = "huashan-jianfa",
    mode = "both",
    weapon = "sword"
  },
  {
    basic = "sword",
    special = "dugu-jiujian",
    mode = "lian",
    weapon = "sword",
  },
  {
    basic = "dodge",
    special = "huashan-shenfa",
    mode = "both",
  },
  {
    basic = "parry",
    special = "dugu-jiujian",
    mode = "lingwu",
    weapon = "sword",
  },
  -- 剑宗
  {
    basic = "sword",
    special = "kuangfeng-kuaijian",
    mode = "lian",
    weapon = "sword"
  },
  {
    basic = "parry",
    special = "hunyuan-zhang",
    mode = "lian",
  },
  {
    basic = "strike",
    special = "hunyuan-zhang",
    mode = "lingwu",
  },
--  -- 气宗
--  {
--    basic = "parry",
--    special = "yunushijiu-jian",
--    mode = "lian",
--    weapon = "sword",
--  },
--  -- 气宗
--  {
--    basic = "sword",
--    special = "yangwu-jian",
--    mode = "lian",
--    weapon = "sword",
--  },
  -- 剑宗
  {
    basic = "sword",
    special = "xiyi-jian",
    mode = "lian",
    weapon = "sword"
  },
  {
    basic = "parry",
    special = "poyu-quan",
    mode = "lian",
  },
  {
    basic = "cuff",
    special = "poyu-quan",
    mode = "lingwu",
  },

}
-- 两次睡觉间间隔秒数
local SleepInterval = 60
-- 每秒打坐内力值
local DzNumPerSecond = 76
-- 每次领悟次数
local LingwuNum = 100  -- 1 - 500
-- 每次练习次数
local LianNum = 20  -- 1 - 500
-- 是否在升级时转换技能（设置为true时将平均提升技能）
local LevelupSwitch = false
-- 睡觉地点
local SleepRoomId = 2921
-- 技能提升地点
local SkillRoomId = 2918
-- 保留与上限级差
local ReservedLimitGap = 3

local define_fullskills = function()
  local prototype = {}
  prototype.__index = prototype

  local REGEXP = {
    ALIAS_START = "^fullskills\\s+start\\s*$",
    ALIAS_STOP = "^fullskills\\s+stop\\s*$",
    ALIAS_DEBUG = "^fullskills\\s+debug\\s+(on|off)\\s*$",
    ALIAS_GAP = "^fullskills\\s+gap\\s+(\\d+)\\s*$",
    ALIAS_NANJUE = "^fullskills\\s+nanjue\\s+(on|off)\\s*$",
    SLEPT = "^[ >]*你往床上一躺，开始睡觉。$",
    WAKE_UP = "^[ >]*你一觉醒来，精神抖擞地活动了几下手脚。$",
    CANNOT_SLEEP = "^[ >]*你刚在三分钟内睡过一觉, 多睡对身体有害无益.*$",
    DAZUO_FINISH = "^[ >]*你运功完毕，深深吸了口气，站了起来。$",
    SKILL_LEVEL_UP = "^[ >]*你的「.*?」进步了！$",
    CANNOT_IMPROVE = "^[ >]*(你的基本功夫比你的高级功夫还高|你的.*?的级别还没有.*?的级别高，不能通过练习来提高|你需要提高基本功，不然练得再多也没有用).*$",
    CANNOT_DAZUO = "^[ >]*你现在的气太少了，无法产生内息运行全身经脉。$",
    CANNOT_LIAN = "^[ >]*你的内力不够.*$",
    DG9J_JING = "^[ >]*你目前精神状态并不足以领悟独孤九剑。$",
  }

  function prototype:new()
    local obj = {}
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self:initTriggers()
    self:initAliases()
    self.DEBUG = true
    self.skillStack = {}
    self:populateSkillStack()
    self.limitGap = ReservedLimitGap
    -- calculate lingwu count and number
    local cnt = LingwuNum / 50
    if cnt < 1 then
      self.lingwuCnt = 1
      self.lingwuNum = LingwuNum
    elseif cnt == math.floor(cnt) then
      self.lingwuCnt = math.floor(cnt)
      self.lingwuNum = 50
    else
      self.lingwuCnt = math.ceil(cnt)
      self.lingwuNum = math.floor(LingwuNum / self.lingwuCnt)
    end
    self.includeNanjue = true
  end

  function prototype:populateSkillStack()
    for i = #Skills, 1, -1 do
      table.insert(self.skillStack, Skills[i])
    end
  end

  function prototype:debug(...)
    if self.DEBUG then
      print(...)
    end
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("fullskills")
    helper.addTrigger {
      group = "fullskills",
      regexp = REGEXP.CANNOT_SLEEP,
      response = function()
        wait.time(5)
        SendNoEcho("sleep")
      end
    }
    helper.addTrigger {
      group = "fullskills",
      regexp = REGEXP.WAKE_UP,
      response = function()
        self.startTime = os.time()
        travel:walkto(SkillRoomId)
        travel:waitUntilArrived()
        return self:doStart()
      end
    }
    helper.addTrigger {
      group = "fullskills",
      regexp = REGEXP.DAZUO_FINISH,
      response = function()
        return self:doFull()
      end
    }
    helper.addTrigger {
      group = "fullskills",
      regexp = REGEXP.CANNOT_IMPROVE,
      response = function()
        self.canImprove = false
      end
    }
    helper.addTrigger {
      group = "fullskills",
      regexp = REGEXP.SKILL_LEVEL_UP,
      response = function()
        self.skillLevelup = true
      end
    }
    helper.addTrigger {
      group = "fullskills",
      regexp = REGEXP.CANNOT_LIAN,
      response = function()
        self.canLian = false
      end
    }
    helper.addTrigger {
      group = "fullskills",
      regexp = REGEXP.CANNOT_DAZUO,
      response = function()
        wait.time(5)
        return self:doPrepare()
      end
    }
    helper.addTrigger {
      group = "fullskills",
      regexp = REGEXP.DG9J_JING,
      response = function()
        SendNoEcho("yun regenerate")
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("fullskills")
    helper.addAlias {
      group = "fullskills",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:start()
      end
    }
    helper.addAlias {
      group = "fullskills",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:stop()
      end
    }
    helper.addAlias {
      group = "fullskills",
      regexp = REGEXP.ALIAS_DEBUG,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self.DEBUG = true
        else
          self.DEBUG = false
        end
      end
    }
    helper.addAlias {
      group = "fullskills",
      regexp = REGEXP.ALIAS_GAP,
      response = function(name, line, wildcards)
        local gap = tonumber(wildcards[1])
        self:debug("设置上限级差为：", gap)
        self.limitGap = gap
      end
    }
    helper.addAlias {
      group = "fullskills",
      regexp = REGEXP.ALIAS_NANJUE,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self.includeNanjue = true
        else
          self.includeNanjue = false
        end
      end
    }
  end

  function prototype:start()
    status:sk()
    self.limit = status.skillLimit
    self:debug("当前技能上限为", self.limit, "上限级差为：", self.limitGap, "技能限制设定为：", self.limit - self.limitGap)

    helper.enableTriggerGroups("fullskills")
    self.stopped = false

    helper.checkUntilNotBusy()
    SendNoEcho("halt")
    travel:walkto(SkillRoomId)
    travel:waitUntilArrived()
    self.startTime = os.time()
    return self:doStart()
  end

  function prototype:stop()
    helper.disableTriggerGroups("fullskills")
    self.stopped = true

    SendNoEcho("halt")
  end

  function prototype:doStart()
    if self.includeNanjue then
      return nanjue:doIfAvailable(function()
        travel:walkto(SkillRoomId)
        travel:waitUntilArrived()
        wait.time(1)
        return self:doInternalStart()
      end)
    end
    return self:doInternalStart()
  end

  function prototype:doInternalStart()
    local diff = os.time() - self.startTime
    if diff > SleepInterval then
      self:debug("睡觉间隔已达到" .. diff, "开始fullskills")
      return self:doFull()
    else
      return self:doPrepare()
    end
  end

  function prototype:doPrepare()
    status:hpbrief()
    if status.food < 150 then
      SendNoEcho("do 3 eat ganliang")
    end
    if status.drink < 150 then
      SendNoEcho("do 3 drink jiudai")
    end
    local neiliDiff = status.maxNeili * 2 - status.currNeili
    local dzNumPerMin = DzNumPerSecond * 60
    -- 满内力，直接开搞
    if neiliDiff <= 10 then
      return self:doFull()
    elseif neiliDiff > dzNumPerMin then
      if status.maxQi * 0.8 < dzNumPerMin then
        SendNoEcho("yun recover")
        SendNoEcho("dazuo max")
      else
        SendNoEcho("yun recover")
        SendNoEcho("dazuo " .. dzNumPerMin)
      end
    else
      SendNoEcho("dazuo max")
    end
  end

  function prototype:doFull()
    -- 从技能栈获取当前技能
    if #(self.skillStack) == 0 then
      self:populateSkillStack()
    end
    self.currSkill = table.remove(self.skillStack)
    if self.currSkill.weapon then
      SendNoEcho("wield " .. self.currSkill.weapon)
    else
      SendNoEcho("unwield all")
    end
    -- 激发相应技能
    SendNoEcho("jifa " .. self.currSkill.basic .. " " .. self.currSkill.special)
    self.canImprove = true
    self.skillLevelup = false
    local workCmd
    local recoverCmd
    local testCmd
    if self.currSkill.mode == "lingwu" then
      -- 检查技能是否不大于上限
      status:skbrief(self.currSkill.basic)
      if status.skillLevel >= self.limit - self.limitGap then
        self:debug("技能", self.currSkill.basic, "达到技能限制")
        return self:doFull()
      end
      workCmd = "do " .. self.lingwuCnt .. " lingwu " .. self.currSkill.basic .. " " .. self.lingwuNum
      testCmd = "lingwu " .. self.currSkill.basic .. " 1"
      recoverCmd = "yun regenerate"
    elseif self.currSkill.mode == "lian" then
      status:skbrief(self.currSkill.special)
      if status.skillLevel >= self.limit - self.limitGap then
        self:debug("技能", self.currSkill.special, "达到技能限制")
        return self:doFull()
      end
      workCmd = "lian " .. self.currSkill.basic .. " " .. LianNum
      testCmd = "lian " .. self.currSkill.basic .. " 1"
      recoverCmd = "yun recover"
    elseif self.currSkill.mode == "both" then -- both的情况，先尝试练
      status:skbrief(self.currSkill.special)
      if status.skillLevel >= self.limit - self.limitGap then
        self:debug("both! 技能", self.currSkill.special, "达到技能限制")
        status:skbrief(self.currSkill.basic)
        if status.skillLevel >= self.limit - self.limitGap then
          self:debug("both! 技能", self.currSkill.basic, "达到技能限制")
          return self:doFull()
        end
      end
      workCmd = "lian " .. self.currSkill.basic .. " " .. LianNum
      testCmd = "lian " .. self.currSkill.basic .. " 1"
      recoverCmd = "yun recover"
    else
      error("unknown mode for fullskills")
    end
    -- 检查是否可提高
    SendNoEcho(testCmd)
    helper.checkUntilNotBusy()
    if not self.canImprove then
      if self.currSkill.mode == "both" then
        -- 重置标记位
        self.canImprove = true
        -- 尝试领悟
        workCmd = "do " .. self.lingwuCnt .. " lingwu " .. self.currSkill.basic .. " " .. self.lingwuNum
        testCmd = "lingwu " .. self.currSkill.basic .. " 1"
        recoverCmd = "yun regenerate"
        -- 检查是否可提高
        SendNoEcho(testCmd)
        helper.checkUntilNotBusy()
        if not self.canImprove then
          return self:doFull()
        end
      else
        return self:doFull()
      end
    end

    SendNoEcho(recoverCmd)
    status:hpbrief()
    local jing1 = status.currJing
    local qi1 = status.currQi
    local neili1 = status.currNeili
    SendNoEcho(workCmd)
    status:hpbrief()
    local jing2 = status.currJing
    local qi2 = status.currQi
    local neili2 = status.currNeili

    local jingCost = jing1 - jing2
    if jingCost < 0 then jingCost = 0 end
    local qiCost = qi1 - qi2
    if qiCost < 0 then qiCost = 0 end
    local neiliCost = neili1 - neili2
    if neiliCost < 0 then neiliCost = 0 end
    self:debug("初始测算 - ", "精消耗：", jingCost, "气消耗：", qiCost, "内力消耗：", neiliCost)
    if jingCost > qiCost then
      qiCost = 0
      self:debug("忽略气消耗")
    else
      jingCost = 0
      self:debug("忽略精消耗")
    end
    self.canLian = true
    while not self.stopped do
      wait.time(0.2)
      status:hpbrief()
      if not self.canImprove then
        if self.currSkill.mode == "both" then
          self:debug("对于同时提高技能，将其放回技能栈重新判断")
          table.insert(self.skillStack, self.currSkill)
        end
        return self:doFull()
      end
      if not self.canLian then
        table.insert(self.skillStack, self.currSkill)
        return self:doSleep()
      end
      if (jingCost > 0 and status.currJing < jingCost and status.currNeili < 500)
        or (qiCost > 0 and status.currQi < qiCost and status.currNeili < 500) then
        -- 睡觉前需要将正在联系的技能再次放入栈中
        -- 考虑参数levelupSwitch
        if LevelupSwitch and self.skillLevelup then
          self:debug("技能已升级，选择下一技能作为提升技能")
        else
          table.insert(self.skillStack, self.currSkill)
        end
        return self:doSleep()
      end
      if neiliCost == 0 and status.currNeili > 0 then
        self:debug("无内力消耗，直接恢复")
        SendNoEcho(recoverCmd)
      elseif neiliCost > 0 and qiCost > 0 and status.currQi / qiCost < status.currNeili / neiliCost then
        self:debug("气消耗大于内力消耗，直接恢复")
        SendNoEcho(recoverCmd)
      end
      self.canLian = true
      SendNoEcho(workCmd)
    end
  end

  function prototype:doSleep()
    travel:walkto(SleepRoomId)
    travel:waitUntilArrived()
    SendNoEcho("sleep")
  end

  return prototype
end
return define_fullskills():new()



