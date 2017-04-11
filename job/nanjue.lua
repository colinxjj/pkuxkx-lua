--
-- nanjue.lua
-- User: zhe.jiang
-- Date: 2017/4/5
-- Desc:
-- �о�����
-- ���²��裺
-- 1. ������
-- 2. ѯ��·��
-- 3. �жϵ���
-- 4. ս����ָ��
-- 5. ���ͻ����
-- Change:
-- 2017/4/5 - created

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"
local NanjueJob = require "job.NanjueJob"
local NanjueStranger = require "job.NanjueStranger"
require "getstyle"

--------------------------------------------------------------
-- nanjue.lua
--
-- �����б�
-- �Ա�man, woman
-- ���䣺young, medium, old
-- height: tall, short, normal(default)
-- weight: fat, thin, normal(default)
-- clothType: fabric, cotton, silk
-- clothColor: dark, light, normal
-- shoeType: fabric, boot, sandal
-- shoeColor: dark, light, normal
--
--------------------------------------------------------------
local define_nanjue = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    record = "record",
    collect = "collect",
    fight = "fight",
    submit = "submit",
  }
  local Events = {
    STOP = "stop",
    START = "start",
    JOB_RECORDED = "job_recorded",
    NO_JOB_AVAILABLE = "no_job_available",
    CRIMINAL_ANALYZED = "criminal_analyzed",
    CRIMINAL_TO_CATCH = "criminal_to_catch",
    CRIMINAL_TO_TESTIFY = "criminal_to_testify",
  }
  local REGEXP = {
    -- �����ʾ �������� ����״̬ ����ʱ�� ��ֹʱ�� ����ص� ����Ҫ�� �������
    JOB_INFO = "^\\s+([0-9_]+?)\\s+(.*?)��(.*?)��\\s+(\\d+:\\d+:\\d+)\\s+(\\d+:\\d+:\\d+)\\s+(.*?)\\s+(.*?)\\s+(\\d+)$",
    RECORD_FAIL = "^[ >]*��ô�����㣡�ҿ����ǻ����˰ɡ�$",
    GENDER_AGE = "^[ >]*(��|��)������Լ(.*)���ꡣ$",
    CLOTH = "^\\s*����һ��(.*?)\\(.*$",
    SHOE = "^\\s*���Ŵ�һ˫(.*?)\\(.*$",
    FIGURE = "^����һ(?:λ|��)(.*?)�����ˡ�$",
    IDENTIFY_GENDER = "^.*(��|Ů|���˺�).*",
    -- todo
    IDENTIFY_FEATURE = "^.*(��ɫ�·�|��ɫЬ��|������|���а�|һ˫��Ь|ǳɫЬ��|���˺�|��|Ů|������|�߸���|�׷��Բ�|�е㷢��).*$",
    CRIMINAL_AUTOKILL = "^[ >]*�㷢������׼��Ǳ�ӵ��ﷸ����ס���ﷸ��ȥ·��$",
    CRINIMAL_TESTIFIED = "^[ >]*�㷢������׼��Ǳ�ӵ��ﷸ���򸽽�Ѳ�ֵĽ������ٱ��ˣ�����ȥ�����콱�ˡ�$",
    TESTIFY_FAIL = "^[ >]*���򸽽��Ľ����������ָ֤���̵ĵ��ٷ��������������ĵ�����ʹ�����������볤���ǡ�$",
    CONFIRM_FAIL = "^[ >]*��Ѱ������������̫���ʱ�䣬�����˵����Ļ��ɣ����������˳����ǡ�$",
  }
  -- ���ģ�����1��
  local Centers = {
    ["С����"] = 2321,  -- ok
    ["������"] = 2313,  -- ����
    ["���ַ�"] = 2350,
    ["����"] = 2330,
    ["���Ӽ�"] = 2323, -- ok
    ["����"] = 1405,  -- ok
    ["ͨ���Ŵ��"] = 2284,  -- ok
  }
  local ClothType = {
    ["˿֯����"] = "silk",
    ["˿�����"] = "silk",
    ["����"] = "silk",
    ["˿֯����"] = "silk",
    ["����ɴ"] = "silk",
    ["����"] = "silk",
    ["����"] = "fabric",
    ["Բ����"] = "fabric",
    ["�Ҳ���"] = "fabric",
    ["�����"] = "fabric",
    ["����ȹ"] = "fabric",
    ["�����"] = "fabric",
    ["�̴�װ"] = "fabric",
    ["��������"] = "silk",
    ["���"] = "cotton",
    ["����"] = "cotton",
    ["�ް�"] = "cotton",
    ["��Ƥ��"] = "cotton",
    ["�̰�"] = "cotton",
    ["�ȼ�"] = "cotton",
  }
  local ShoeType = {
    ["ţƤ��ѥ"] = "boot",
    ["��ѥ"] = "boot",
    ["Ůʽ��ѥ"] = "boot",
    ["Ůʽ��ѥ"] = "boot",
    ["���׿�ѥ"] = "boot",
    ["���ǽ�ѥ"] = "boot",
    ["�廨Ь"] = "fabric",
    ["��Ь"] = "fabric",
    ["��Ь"] = "fabric",
    ["��Ь"] = "fabric",
    ["��Ь"] = "fabirc",
    ["ǧ��ײ�Ь"] = "fabric",
    ["ľ��"] = "sandal",
    ["��Ь"] = "sandal",
    ["��Ь"] = "sandal",
  }
  local ColorType = {
    ["black"] = "dark",
    ["red"] = "dark",
    ["blue"] = "dark",
    ["purple"] = "dark",
    ["green"] = "light",
    ["yellow"] = "light",
    ["cyan"] = "light",
    ["white"] = "light",
  }
  local FigureType = {
    ["����쳣����ߴ�"] = {
      weight = "fat",
      height = "tall"
    },
    ["��С����"] = {
      weight = "thin",
      height = "short"
    },
    ["��ķ�����С"] = {
      weight = "fat",
      height = "short"
    },
    ["����ϸ�����������ͦ��"] = {
      weight = "thin",
      height = "tall"
    },
    ["����һ�����"] = {
      weight = "thin",
      height = "tall"
    },
    ["��С����"] = {
      weight = "fat",
      height = "short"
    },
    ["�ߴ����"] = {
      weight = "fat",
      height = "tall"
    },
    ["��С���"] = {
      weight = "thin",
      height = "short"
    },
  }

  local TraverseDepth = 1

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
    self:resetOnStop()
  end

  function prototype:resetOnStop()
    self.waitThread = nil
    self.strangers = {}
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
      "nanjue_info_start", "nanjue_info_done",
      "nanjue_look_start", "nanjue_look_done"
    )
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:resetOnStop()
        self:disableAllTriggers()
        SendNoEcho("set jobs job_done")  -- cooperate with other module
      end,
      exit = function() end
    }
    self:addState {
      state = States.record,
      enter = function()
        self.recordSuccess = nil
        helper.enableTriggerGroups("nanjue_info_start", "nanjue_record_start")
      end,
      exit = function()
        self.recordSuccess = nil
        helper.disableTriggerGroups(
          "nanjue_info_start", "nanjue_info_done",
          "nanjue_record_start", "nanjue_record_done")
      end
    }
  end

  function prototype:initTransitions()
    -- transition from state<start>
    self:addTransition {
      oldState = States.stop,
      newState = States.record,
      event = Events.START,
      action = function()
        return travel:walkto(2289, function()
          return self:doAskInfo()
        end)
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<record>
    self:addTransition {
      oldState = States.record,
      newState = States.collect,
      event = Events.JOB_RECORDED,
      action = function()
        return self:doCollect()
      end
    }
    self:addTransitionToStop(States.record)
    -- transition from state<collect>
    self:addTransition {
      oldState = States.collect,
      newState = States.collect,
      event = Events.CRIMINAL_ANALYZED,
      action = function()
        return self:doTestify()
      end
    }
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "nanjue_info_start", "nanjue_info_done",
      "nanjue_look_start", "nanjue_look_done"
    )
    -- trigger for info
    helper.addTrigger {
      group = "nanjue_info_start",
      regexp = helper.settingRegexp("nanjue", "info_start"),
      response = function()
        helper.enableTriggerGroups("nanjue_info_done")
      end
    }
    helper.addTrigger {
      group = "nanjue_info_done",
      regexp = helper.settingRegexp("nanjue", "info_done"),
      response = function()
        helper.disableTriggerGroups("nanjue_info_done")
        if #(self.jobs) == 0 then
          return self:fire(Events.NO_JOB_AVAILABLE)
        else
          self.selectedJob = nil
          for _, job in ipairs(self.jobs) do
            if job.level == "��" and Centers[job.location] then
              self.selectedJob = job
              break
            end
          end
          if self.selectedJob then
            return self:doRecord()
          else
            return self:fire(Events.NO_JOB_AVAILABLE)
          end
        end
      end
    }
    helper.addTrigger {
      group = "nanjue_info_done",
      regexp = REGEXP.JOB_INFO,
      response = function(name, line, wildcards)
        self:debug("JOB_INFO triggered")
        local jobCode = wildcards[1]
        local jobName = wildcards[2]
        local jobLevel = wildcards[3]
        local jobStatus = wildcards[4]
        local jobStartTime = wildcards[5]
        local jobEndTime = wildcards[6]
        local jobLocation = wildcards[7]
        local jobRequirement = wildcards[8]
        local jobPlayers = tonumber(wildcards[9])
        local currTime = os.date("*t")
        local ss = utils.split(jobStartTime, ":")
        local startTime = os.time {
          year = currTime.year,
          month = currTime.month,
          day = currTime.day,
          hour = tonumber(ss[1]),
          min = tonumber(ss[2]),
          sec = tonumber(ss[3])
        }
        local es = utils.split(jobEndTime, ":")
        local endTime = os.time {
          year = currTime.year,
          month = currTime.month,
          day = currTime.day,
          hour = tonumber(es[1]),
          min = tonumber(es[2]),
          sec = tonumber(es[3])
        }
        -- ֻ��5�����ڵ�����
        -- ֻ��û�������������
        -- ֻ���µ�����
        if endTime - currTime >= 5 * 60 and jobPlayers == 0 and jobStatus == "�½�" then
          table.insert(self.jobs, NanjueJob:decorate {
            code = jobCode,
            name = jobName,
            level = jobLevel,
            status = jobStatus,
            startTime = startTime,
            endTime = endTime,
            location = jobLocation,
            requirement = jobRequirement,
            players = jobPlayers
          })
        end
      end
    }
    -- trigger for record
    helper.addTrigger {
      group = "nanjue_record_start",
      regexp = helper.settingRegexp("nanjue", "record_start"),
      response = function()
        helper.enableTriggerGroups("nanjue_record_done")
      end
    }
    helper.addTrigger {
      group = "nanjue_record_done",
      regexp = helper.settingRegexp("nanjue", "record_done"),
      response = function()
        helper.disableTriggerGroups("nanjue_record_done")
        if self.recordSuccess then
          return self:fire(Events.JOB_RECORDED)
        else
          return self:fire(Events.NO_JOB_AVAILABLE)
        end
      end
    }
    helper.addTrigger {
      group = "nanjue_record_done",
      regexp = REGEXP.RECORD_FAIL,
      response = function()
        self.recordSuccess = false
      end
    }

    -- trigger for looking
    helper.addTrigger {
      group = "nanjue_look_start",
      regexp = helper.settingRegexp("nanjue", "look_start"),
      response = function()
        helper.enableTriggerGroups("nanjue_look_done")
      end
    }
    helper.addTrigger {
      group = "nanjue_look_done",
      regexp = helper.settingRegexp("nanjue", "look_done"),
      response = function()
        helper.disableTriggerGroups("nanjue_look_done")
      end
    }
    helper.addTrigger {
      group = "nanjue_look_done",
      regexp = REGEXP.GENDER_AGE,
      response = function(name, line, wildcards)
        local subject, age = wildcards[1], wildcards[2]
        if subject == "��" then
          self.currStranger.gender = "man"
        elseif subject == "��" then
          self.currStranger.gender = "woman"
        end
        if age == "��ʮ" or age == "��ʮ" then
          self.currStranger.age = "young"
        elseif age == "��ʮ" or age == "��ʮ" then
          self.currStranger.age = "medium"
        else
          self.currStranger.age = "old"
        end
      end
    }
    helper.addTrigger {
      group = "nanjue_look_done",
      regexp = REGEXP.FIGURE,
      response = function(name, line, wildcards)
        local figure = wildcards[1]
        local figureType = FigureType[figure]
        if figureType then
          self.currStranger.weight = figureType.weight
          self.currStranger.height = figureType.height
        else
          print("�޷�����·����ģ�", figure)
        end
      end
    }
    helper.addTrigger {
      group = "nanjue_look_done",
      regexp = REGEXP.CLOTH,
      response = function(name, line, wildcards, styles)
        local cloth = wildcards[1]
        local clothType = ClothType[cloth]
        if clothType then
          self.currStranger.clothType = clothType
        else
          print("�޷����ҵ��·����ͣ�����Ϊ���£�", cloth)
          self.currStranger.clothType = "fabric"
        end
        local col = string.find(line, cloth)
        local style = GetStyle(styles, col)
        local color = RGBColourToName(style.textcolour)
        local colorType = ColorType[color]
        if colorType then
          self.currStranger.clothColor = colorType
        else
          print("�޷����ҵ��·���ɫ��ǳ������Ϊ����")
          self.currStranger.clothColor = "normal"
        end
        self:debug("�·����ͣ�", clothType, "�·���ɫ��", color)
      end
    }
    helper.addTrigger {
      group = "nanjue_look_done",
      regexp = REGEXP.SHOE,
      response = function(name, line, wildcards, styles)
        local shoe = wildcards[1]
        local shoeType = ShoeType[shoe]
        if shoeType then
          self.currStranger.shoeType = shoeType
        else
          print("�޷����ҵ�Ь�����ͣ�����Ϊ��Ь��", shoe)
          self.currStranger.shoeType = "fabric"
        end
        local col = string.find(line, shoe)
        local style = GetStyle(styles, col)
        local color = RGBColourToName(style.textcolour)
        local colorType = ColorType[color]
        if colorType then
          self.currStranger.shoeColor = colorType
        else
          print("�޷����ҵ�Ь����ɫ��ǳ������Ϊ����")
          self.currStranger.shoeColor = "normal"
        end
        self:debug("Ь�����ͣ�", shoeType, "Ь����ɫ��", color)
      end
    }
    -- trigger for asking
    helper.addTrigger {
      group = "nanjue_ask_start",
      regexp = helper.settingRegexp("nanjue", "ask_start"),
      response = function()
        helper.enableTriggerGroups("nanjue_ask_done")
      end
    }
    helper.addTrigger {
      group = "nanjue_ask_done",
      regexp = helper.settingRegexp("nanjue", "ask_done"),
      response = function()
        helper.disableTriggerGroups("annjue_ask_done")
      end
    }
    helper.addTrigger {
      group = "nanjue_ask_done",
      regexp = REGEXP.IDENTIFY_GENDER,
      response = function(name, line, wildcards)
        local gender = wildcards[1]
        if not self.currStranger.identifyFeatures then
          self.currStranger.identifyFeatures = {}
        end
        if gender == "��" or gender == "���˺�" then
          self.currStranger.identifyFeatures.gender = "man"
        elseif gender == "Ů" then
          self.currStranger.identifyFeatures.gender = "woman"
        end
      end
    }
    helper.addTrigger {
      group = "nanjue_ask_done",
      regexp = REGEXP.IDENTIFY_CLOTH,
      response = function(name, line, wildcards)

      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("nanjue")
    helper.addAlias {
      group = "nanjue",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "nanjue",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "nanjue",
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

  function prototype:doRecord()
    self.recordSuccess = true
    SendNoEcho("set nanjue record_start")
    SendNoEcho("record " .. self.selectedJob.id)
    SendNoEcho("set nanjue record_done")
  end

  function prototype:doAskInfo()
    self.jobsInfo = {}
    SendNoEcho("set nanjue info_start")
    SendNoEcho("ask shaoyin about ������Ϣ")
    SendNoEcho("set nanjue info_done")
  end

  function prototype:doLookStranger(id)
    SendNoEcho("set nanjue look_start")
    SendNoEcho("look " .. id)
    SendNoEcho("set nanjue look_done")
  end

  function prototype:doAskStranger(id)
    SendNoEcho("set nanjue ask_start")
    SendNoEcho("ask " .. id .. " about ��Ϣ")
    SendNoEcho("set nanjue ask_done")
  end

  function prototype:doCollect()
    travel:walkto(self.targetRoomId)
    travel:waitUntilArrived()
    helper.assureNotBusy()
    local onEachStep = function()
      return self:doCollectWhenTraverse()
    end
    local onArrive = function()
      return self:analyzeCriminalAfterTraverse()
    end
    return travel:traverseNearby(1, onEachStep, onArrive)
  end

  function prototype:doCollectWhenTraverse()
    status:idhere()
    local seq = 0
    for _, item in ipairs(status.items) do
      -- todo
      if string.find(item.itemIds, "luren") then
        seq = seq + 1
        local name = item.name
        local id = item.id
        self:debug("����·��", seq, name, id)
        self.currStranger = NanjueStranger:decorate {
          id = id,
          name = name,
          seq = seq,
          roomId = travel.traverseRoomId
        }
        prototype:doLookStranger(id)
        helper.assureNotBusy()
        wait.time(1)
        prototype:doAskStranger(id)
        helper.assureNotBusy()
        wait.time(1)
        if self.DEBUG then
          self.currStranger:show()
        end
        self.currStranger:confirmed()
        table.insert(self.strangers, self.currStranger)
      end
    end
    return false
  end

  function prototype:analyzeCriminalAfterTraverse()
    self.suspects = {}
    -- �ռ��ﷸ��Ϣ
    -- ��������֤��
    self.witnesses = {}
    self.silents = {}
    for _, stranger in ipairs(self.strangers) do
      if stranger.identifyFeatures then
        table.insert(self.witnesses, stranger)
      else
        table.insert(self.silents, stranger)
      end
    end
    -- �ж�֤���Ƿ���ì��
    local conflicts = {}
    local conflictDict = {}
    for i = 1, #(self.witnesses) - 1 do
      for j = i + 1, #(self.witnesses) - 1 do
        local this = self.witnesses[i]
        local that = self.witnesses[j]
        for featureName, featureValue in paris(this.identifyFeatures) do
          if that.identifyFeature[featureName] and that.identifyFeature[featureName] ~= featureValue then
            print("����֤��ì�ܣ�", featureName)
            print("·�ˣ�", this.name, "֤�ʣ�", featureValue)
            print("·�ˣ�", that.name, "֤�ʣ�", that.identifyFeature[featureName])
            table.insert(conflicts, {
              this = this,
              that = that
            })
            -- ���ĳ��������֤�ʶ���ì�ܣ�����˱�Ϊ����
            if conflictDict[this] then
              table.insert(self.suspects, this)
              print("·��" .. this.name .. "�볬��1������·�˴���ì��֤�ʣ���Ϊ����")
              return self:fire(Events.CRIMINAL_ANALYZED)
            else
              conflictDict[this] = true
            end
            if conflictDict[that] then
              table.insert(self.suspects, that)
              print("·��" .. that.name .. "�볬��1������·�˴���ì��֤�ʣ���Ϊ����")
              return self:fire(Events.CRIMINAL_ANALYZED)
            else
              conflictDict[that] = true
            end
          end
        end
      end
    end
    if #conflicts > 0 then
      print("֤���д���ì�ܣ���������֤����")
      for _, conflict in ipairs(conflicts) do
        -- ����this��ȷ
        local featuresExcludedThat = self:featuresExcluded(self.witnesses, conflict.that)
        -- ���that�Ƿ��������
        local thatFit = true
        for k, v in pairs(featuresExcludedThat) do
          if conflict.that[k] ~= v then
            thatFit = false
            break
          end
        end
        if thatFit then
          print("·��" .. conflict.that.name .. "�п���Ϊ������")
          table.insert(self.suspects, conflict.that)
        end
        -- ����that��ȷ
        local featuresExcludedThis = self:featuresExcluded(self.witnesses, conflict.this)
        -- ���this�Ƿ��������
        local thisFit = true
        for k, v in pairs(featuresExcludedThis) do
          if conflict.this[k] ~= v then
            thisFit = false
            break
          end
        end
        if thisFit then
          print("·��" .. conflict.this.name .. "�п���Ϊ������")
          table.insert(self.suspects, conflict.this)
        end
      end
    else
      print("֤�˵�֤����һ�µģ��п����ﷸ�ڷ�֤���У�Ҳ�п����ﷸ��֤���ж���˵֤��Ϊ��")
      -- ����֤��
      local features = self:featuresExcluded(self.witnesses)
      for _, silent in ipairs(self.silents) do
        local fit = true
        for k, v in pairs(features) do
          if silent[k] ~= v then
            fit = false
            break
          end
        end
        if fit then
          print("·��" .. silent.name .. "��������֤�˵���������Ϊ������")
          table.insert(self.suspects, silent)
        end
      end
      -- ���֤��
      for _, witness in ipairs(self.witnesses) do
        local features = self:featuresExcluded(self.witnesses, witness)
        local fit = true
        for k, v in pairs(features) do
          if witness[k] ~= v then
            fit = false
            break
          end
        end
        if fit then
          print("·��" .. witness.name .. "��֤�ʣ������˷�������֤�˵�����֤�ʣ���Ϊ������")
          table.insert(self.suspects, witness)
        end
      end
    end
    return self:fire(Events.CRINIMAL_ANALYZED)
  end

  function prototype:featuresExcluded(witnesses, excluded)
    local remainedFeatures = {}
    for _, witness in ipairs(witnesses) do
      if witness ~= excluded then
        for k, v in pairs(witness.identifyFeatures) do
          remainedFeatures[k] = v
        end
      end
    end
    return remainedFeatures
  end

  function prototype:doTestify()
    if #(self.suspects) == 0 then
      print("û�з����κ������ˣ���֤���������ѡһ��")
      local randomCrinimal = self.witness[math.random(#(self.witnesses))]
      table.insert(self.suspects, randomCrinimal)
    end
    self.currSuspect = nil
    self.currCriminal = nil
    for i = 1, #(self.suspects) do
      self.currSuspect = self.suspects[i]
      if self.selectedJob.level == "��" then
        print("��ģʽ������ֱ�Ӵ���")
        travel:walkto(self.currSuspect.roomId)
        travel:waitUntilArrived()
        wait.time(2)
        SendNoEcho("ask " .. self.currSuspect.id .. " about ����")
        -- todo
      else
        print("����ģʽ��ֻtestify����ս��")
      end
    end
  end

  function prototype:doTestify()

  end


  function prototype:doStart()
    return self:fire(Events.START)
  end

  function prototype:doCancel()
    helper.assureNotBusy()
    travel:walkto(2289)
    travel:waitUntilArrived()
    SendNoEcho("record cancel")
    helper.assureNotBusy()
    return self:fire(Events.STOP)
  end

  function prototype:doSubmit()
    helper.assureNotBusy()
    travel:walkto(2289)
    travel:waitUntilArrived()
    SendNoEcho("ask shaoyin about ����")
    helper.assureNotBusy()
    return self:fire(Events.STOP)
  end

  return prototype
end
return define_nanjue():FSM()

