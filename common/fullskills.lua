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
  -- ����
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
--  -- ����
--  {
--    basic = "parry",
--    special = "yunushijiu-jian",
--    mode = "lian",
--    weapon = "sword",
--  },
--  -- ����
--  {
--    basic = "sword",
--    special = "yangwu-jian",
--    mode = "lian",
--    weapon = "sword",
--  },
  -- ����
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
-- ����˯����������
local SleepInterval = 60
-- ÿ���������ֵ
local DzNumPerSecond = 76
-- ÿ���������
local LingwuNum = 100  -- 1 - 500
-- ÿ����ϰ����
local LianNum = 20  -- 1 - 500
-- �Ƿ�������ʱת�����ܣ�����Ϊtrueʱ��ƽ���������ܣ�
local LevelupSwitch = false
-- ˯���ص�
local SleepRoomId = 2921
-- ���������ص�
local SkillRoomId = 2918
-- ���������޼���
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
    SLEPT = "^[ >]*��������һ�ɣ���ʼ˯����$",
    WAKE_UP = "^[ >]*��һ�������������ӵػ�˼����ֽš�$",
    CANNOT_SLEEP = "^[ >]*�������������˯��һ��, ��˯�������к�����.*$",
    DAZUO_FINISH = "^[ >]*���˹���ϣ��������˿�����վ��������$",
    SKILL_LEVEL_UP = "^[ >]*��ġ�.*?�������ˣ�$",
    CANNOT_IMPROVE = "^[ >]*(��Ļ����������ĸ߼����򻹸�|���.*?�ļ���û��.*?�ļ���ߣ�����ͨ����ϰ�����|����Ҫ��߻���������Ȼ�����ٶ�Ҳû����).*$",
    CANNOT_DAZUO = "^[ >]*�����ڵ���̫���ˣ��޷�������Ϣ����ȫ������$",
    CANNOT_LIAN = "^[ >]*�����������.*$",
    DG9J_JING = "^[ >]*��Ŀǰ����״̬��������������¾Ž���$",
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
        self:debug("�������޼���Ϊ��", gap)
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
    self:debug("��ǰ��������Ϊ", self.limit, "���޼���Ϊ��", self.limitGap, "���������趨Ϊ��", self.limit - self.limitGap)

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
      self:debug("˯������Ѵﵽ" .. diff, "��ʼfullskills")
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
    -- ��������ֱ�ӿ���
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
    -- �Ӽ���ջ��ȡ��ǰ����
    if #(self.skillStack) == 0 then
      self:populateSkillStack()
    end
    self.currSkill = table.remove(self.skillStack)
    if self.currSkill.weapon then
      SendNoEcho("wield " .. self.currSkill.weapon)
    else
      SendNoEcho("unwield all")
    end
    -- ������Ӧ����
    SendNoEcho("jifa " .. self.currSkill.basic .. " " .. self.currSkill.special)
    self.canImprove = true
    self.skillLevelup = false
    local workCmd
    local recoverCmd
    local testCmd
    if self.currSkill.mode == "lingwu" then
      -- ��鼼���Ƿ񲻴�������
      status:skbrief(self.currSkill.basic)
      if status.skillLevel >= self.limit - self.limitGap then
        self:debug("����", self.currSkill.basic, "�ﵽ��������")
        return self:doFull()
      end
      workCmd = "do " .. self.lingwuCnt .. " lingwu " .. self.currSkill.basic .. " " .. self.lingwuNum
      testCmd = "lingwu " .. self.currSkill.basic .. " 1"
      recoverCmd = "yun regenerate"
    elseif self.currSkill.mode == "lian" then
      status:skbrief(self.currSkill.special)
      if status.skillLevel >= self.limit - self.limitGap then
        self:debug("����", self.currSkill.special, "�ﵽ��������")
        return self:doFull()
      end
      workCmd = "lian " .. self.currSkill.basic .. " " .. LianNum
      testCmd = "lian " .. self.currSkill.basic .. " 1"
      recoverCmd = "yun recover"
    elseif self.currSkill.mode == "both" then -- both��������ȳ�����
      status:skbrief(self.currSkill.special)
      if status.skillLevel >= self.limit - self.limitGap then
        self:debug("both! ����", self.currSkill.special, "�ﵽ��������")
        status:skbrief(self.currSkill.basic)
        if status.skillLevel >= self.limit - self.limitGap then
          self:debug("both! ����", self.currSkill.basic, "�ﵽ��������")
          return self:doFull()
        end
      end
      workCmd = "lian " .. self.currSkill.basic .. " " .. LianNum
      testCmd = "lian " .. self.currSkill.basic .. " 1"
      recoverCmd = "yun recover"
    else
      error("unknown mode for fullskills")
    end
    -- ����Ƿ�����
    SendNoEcho(testCmd)
    helper.checkUntilNotBusy()
    if not self.canImprove then
      if self.currSkill.mode == "both" then
        -- ���ñ��λ
        self.canImprove = true
        -- ��������
        workCmd = "do " .. self.lingwuCnt .. " lingwu " .. self.currSkill.basic .. " " .. self.lingwuNum
        testCmd = "lingwu " .. self.currSkill.basic .. " 1"
        recoverCmd = "yun regenerate"
        -- ����Ƿ�����
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
    self:debug("��ʼ���� - ", "�����ģ�", jingCost, "�����ģ�", qiCost, "�������ģ�", neiliCost)
    if jingCost > qiCost then
      qiCost = 0
      self:debug("����������")
    else
      jingCost = 0
      self:debug("���Ծ�����")
    end
    self.canLian = true
    while not self.stopped do
      wait.time(0.2)
      status:hpbrief()
      if not self.canImprove then
        if self.currSkill.mode == "both" then
          self:debug("����ͬʱ��߼��ܣ�����Żؼ���ջ�����ж�")
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
        -- ˯��ǰ��Ҫ��������ϵ�ļ����ٴη���ջ��
        -- ���ǲ���levelupSwitch
        if LevelupSwitch and self.skillLevelup then
          self:debug("������������ѡ����һ������Ϊ��������")
        else
          table.insert(self.skillStack, self.currSkill)
        end
        return self:doSleep()
      end
      if neiliCost == 0 and status.currNeili > 0 then
        self:debug("���������ģ�ֱ�ӻָ�")
        SendNoEcho(recoverCmd)
      elseif neiliCost > 0 and qiCost > 0 and status.currQi / qiCost < status.currNeili / neiliCost then
        self:debug("�����Ĵ����������ģ�ֱ�ӻָ�")
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



