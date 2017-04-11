--
-- nanjue.lua
-- User: zhe.jiang
-- Date: 2017/4/5
-- Desc:
-- 男爵任务
-- 大致步骤：
-- 1. 领任务
-- 2. 询问路人
-- 3. 判断盗贼
-- 4. 战斗或指认
-- 5. 领赏或放弃
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
-- 特征列表
-- 性别：man, woman
-- 年龄：young, medium, old
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
    -- 任务表示 任务名称 任务状态 发布时间 截止时间 任务地点 资质要求 认领玩家
    JOB_INFO = "^\\s+([0-9_]+?)\\s+(.*?)「(.*?)」\\s+(\\d+:\\d+:\\d+)\\s+(\\d+:\\d+:\\d+)\\s+(.*?)\\s+(.*?)\\s+(\\d+)$",
    RECORD_FAIL = "^[ >]*怎么又是你！我看你是机器人吧。$",
    GENDER_AGE = "^[ >]*(他|她)看起来约(.*)多岁。$",
    CLOTH = "^\\s*□身穿一件(.*?)\\(.*$",
    SHOE = "^\\s*□脚穿一双(.*?)\\(.*$",
    FIGURE = "^这是一(?:位|个)(.*?)的行人。$",
    IDENTIFY_GENDER = "^.*(男|女|流浪汉).*",
    -- todo
    IDENTIFY_FEATURE = "^.*(深色衣服|深色鞋子|身穿布衣|身穿夹袄|一双布鞋|浅色鞋子|流浪汉|男|女|矮个子|高个子|白发苍苍|有点发胖).*$",
    CRIMINAL_AUTOKILL = "^[ >]*你发现了正准备潜逃的罪犯，拦住了罪犯的去路。$",
    CRINIMAL_TESTIFIED = "^[ >]*你发现了正准备潜逃的罪犯，向附近巡街的金吾卫举报了，可以去衙门领奖了。$",
    TESTIFY_FAIL = "^[ >]*你向附近的金吾卫错误地指证上铺的盗劫犯，惊动了真正的盗贼，使得他立即逃离长安城。$",
    CONFIRM_FAIL = "^[ >]*你寻找线索消耗了太多的时间，引起了盗贼的怀疑，盗贼逃离了长安城。$",
  }
  -- 中心，辐射1格
  local Centers = {
    ["小雁塔"] = 2321,  -- ok
    ["大雁塔"] = 2313,  -- 中心
    ["长乐坊"] = 2350,
    ["东市"] = 2330,
    ["国子监"] = 2323, -- ok
    ["西市"] = 1405,  -- ok
    ["通化门大街"] = 2284,  -- ok
  }
  local ClothType = {
    ["丝织长衫"] = "silk",
    ["丝绸短襦"] = "silk",
    ["绸袍"] = "silk",
    ["丝织儒衫"] = "silk",
    ["轻罗纱"] = "silk",
    ["旗袍"] = "silk",
    ["坎肩"] = "fabric",
    ["圆领衫"] = "fabric",
    ["灰布衫"] = "fabric",
    ["灰马褂"] = "fabric",
    ["百褶裙"] = "fabric",
    ["蓝马褂"] = "fabric",
    ["短打劲装"] = "fabric",
    ["天蓝锦袍"] = "silk",
    ["鹤氅"] = "cotton",
    ["长袄"] = "cotton",
    ["棉袄"] = "cotton",
    ["狼皮袄"] = "cotton",
    ["短袄"] = "cotton",
    ["比甲"] = "cotton",
  }
  local ShoeType = {
    ["牛皮短靴"] = "boot",
    ["马靴"] = "boot",
    ["女式短靴"] = "boot",
    ["女式长靴"] = "boot",
    ["薄底快靴"] = "boot",
    ["七星剑靴"] = "boot",
    ["绣花鞋"] = "fabric",
    ["锦鞋"] = "fabric",
    ["凤鞋"] = "fabric",
    ["布鞋"] = "fabric",
    ["麻鞋"] = "fabirc",
    ["千层底布鞋"] = "fabric",
    ["木屐"] = "sandal",
    ["草鞋"] = "sandal",
    ["破鞋"] = "sandal",
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
    ["身材异常魁梧高大"] = {
      weight = "fat",
      height = "tall"
    },
    ["娇小玲珑"] = {
      weight = "thin",
      height = "short"
    },
    ["身材丰满矮小"] = {
      weight = "fat",
      height = "short"
    },
    ["丰胸细腰，身材苗条挺拔"] = {
      weight = "thin",
      height = "tall"
    },
    ["宛如一根竹竿"] = {
      weight = "thin",
      height = "tall"
    },
    ["矮小粗胖"] = {
      weight = "fat",
      height = "short"
    },
    ["高大魁梧"] = {
      weight = "fat",
      height = "tall"
    },
    ["矮小灵活"] = {
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
            if job.level == "简单" and Centers[job.location] then
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
        -- 只做5分钟内的任务
        -- 只做没有人认领的任务
        -- 只做新的任务
        if endTime - currTime >= 5 * 60 and jobPlayers == 0 and jobStatus == "新建" then
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
        if subject == "他" then
          self.currStranger.gender = "man"
        elseif subject == "她" then
          self.currStranger.gender = "woman"
        end
        if age == "二十" or age == "三十" then
          self.currStranger.age = "young"
        elseif age == "四十" or age == "五十" then
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
          print("无法鉴别路人身材：", figure)
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
          print("无法查找到衣服类型，设置为布衣：", cloth)
          self.currStranger.clothType = "fabric"
        end
        local col = string.find(line, cloth)
        local style = GetStyle(styles, col)
        local color = RGBColourToName(style.textcolour)
        local colorType = ColorType[color]
        if colorType then
          self.currStranger.clothColor = colorType
        else
          print("无法查找到衣服颜色深浅，设置为中性")
          self.currStranger.clothColor = "normal"
        end
        self:debug("衣服类型：", clothType, "衣服颜色：", color)
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
          print("无法查找到鞋子类型，设置为布鞋：", shoe)
          self.currStranger.shoeType = "fabric"
        end
        local col = string.find(line, shoe)
        local style = GetStyle(styles, col)
        local color = RGBColourToName(style.textcolour)
        local colorType = ColorType[color]
        if colorType then
          self.currStranger.shoeColor = colorType
        else
          print("无法查找到鞋子颜色深浅，设置为中性")
          self.currStranger.shoeColor = "normal"
        end
        self:debug("鞋子类型：", shoeType, "鞋子颜色：", color)
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
        if gender == "男" or gender == "流浪汉" then
          self.currStranger.identifyFeatures.gender = "man"
        elseif gender == "女" then
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
        print("停止 - 当前状态", self.currState)
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
    SendNoEcho("ask shaoyin about 任务信息")
    SendNoEcho("set nanjue info_done")
  end

  function prototype:doLookStranger(id)
    SendNoEcho("set nanjue look_start")
    SendNoEcho("look " .. id)
    SendNoEcho("set nanjue look_done")
  end

  function prototype:doAskStranger(id)
    SendNoEcho("set nanjue ask_start")
    SendNoEcho("ask " .. id .. " about 消息")
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
        self:debug("发现路人", seq, name, id)
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
    -- 收集罪犯信息
    -- 检索所有证人
    self.witnesses = {}
    self.silents = {}
    for _, stranger in ipairs(self.strangers) do
      if stranger.identifyFeatures then
        table.insert(self.witnesses, stranger)
      else
        table.insert(self.silents, stranger)
      end
    end
    -- 判断证词是否有矛盾
    local conflicts = {}
    local conflictDict = {}
    for i = 1, #(self.witnesses) - 1 do
      for j = i + 1, #(self.witnesses) - 1 do
        local this = self.witnesses[i]
        local that = self.witnesses[j]
        for featureName, featureValue in paris(this.identifyFeatures) do
          if that.identifyFeature[featureName] and that.identifyFeature[featureName] ~= featureValue then
            print("发现证词矛盾：", featureName)
            print("路人：", this.name, "证词：", featureValue)
            print("路人：", that.name, "证词：", that.identifyFeature[featureName])
            table.insert(conflicts, {
              this = this,
              that = that
            })
            -- 如果某人与多个人证词都有矛盾，则该人必为凶手
            if conflictDict[this] then
              table.insert(self.suspects, this)
              print("路人" .. this.name .. "与超过1个其他路人存在矛盾证词，必为凶手")
              return self:fire(Events.CRIMINAL_ANALYZED)
            else
              conflictDict[this] = true
            end
            if conflictDict[that] then
              table.insert(self.suspects, that)
              print("路人" .. that.name .. "与超过1个其他路人存在矛盾证词，必为凶手")
              return self:fire(Events.CRIMINAL_ANALYZED)
            else
              conflictDict[that] = true
            end
          end
        end
      end
    end
    if #conflicts > 0 then
      print("证词中存在矛盾，嫌疑人在证人中")
      for _, conflict in ipairs(conflicts) do
        -- 假设this正确
        local featuresExcludedThat = self:featuresExcluded(self.witnesses, conflict.that)
        -- 检查that是否符合条件
        local thatFit = true
        for k, v in pairs(featuresExcludedThat) do
          if conflict.that[k] ~= v then
            thatFit = false
            break
          end
        end
        if thatFit then
          print("路人" .. conflict.that.name .. "有可能为嫌疑人")
          table.insert(self.suspects, conflict.that)
        end
        -- 假设that正确
        local featuresExcludedThis = self:featuresExcluded(self.witnesses, conflict.this)
        -- 检查this是否符合条件
        local thisFit = true
        for k, v in pairs(featuresExcludedThis) do
          if conflict.this[k] ~= v then
            thisFit = false
            break
          end
        end
        if thisFit then
          print("路人" .. conflict.this.name .. "有可能为嫌疑人")
          table.insert(self.suspects, conflict.this)
        end
      end
    else
      print("证人的证词是一致的，有可能罪犯在非证人中，也有可能罪犯在证人中而所说证词为假")
      -- 检查非证人
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
          print("路人" .. silent.name .. "符合所有证人的描述，列为嫌疑人")
          table.insert(self.suspects, silent)
        end
      end
      -- 检查证人
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
          print("路人" .. witness.name .. "有证词，但该人符合其他证人的所有证词，列为嫌疑人")
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
      print("没有发现任何嫌疑人，在证人中随机挑选一个")
      local randomCrinimal = self.witness[math.random(#(self.witnesses))]
      table.insert(self.suspects, randomCrinimal)
    end
    self.currSuspect = nil
    self.currCriminal = nil
    for i = 1, #(self.suspects) do
      self.currSuspect = self.suspects[i]
      if self.selectedJob.level == "简单" then
        print("简单模式，可以直接逮捕")
        travel:walkto(self.currSuspect.roomId)
        travel:waitUntilArrived()
        wait.time(2)
        SendNoEcho("ask " .. self.currSuspect.id .. " about 盗贼")
        -- todo
      else
        print("其他模式，只testify，不战斗")
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
    SendNoEcho("ask shaoyin about 领赏")
    helper.assureNotBusy()
    return self:fire(Events.STOP)
  end

  return prototype
end
return define_nanjue():FSM()

