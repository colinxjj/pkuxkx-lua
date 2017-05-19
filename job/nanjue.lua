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
require "getstyle"

-- nanjue job data structure
local define_NanjueJob = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    local obj = {}
    obj.code = assert(args.code, "code of job cannot be nil")
    obj.name = assert(args.name, "name of job cannot be nil")
    obj.level = assert(args.level, "level of job cannot be nil")
    obj.status = assert(args.status, "status of job cannot be nil")
    obj.startTime = assert(args.startTime, "startTime of job cannot be nil")
    obj.endTime = assert(args.endTime, "endTime of job cannot be nil")
    obj.location = assert(args.location, "location of job cannot be nil")
    obj.requirements = assert(args.requirements, "requirements of job cannot be nil")
    obj.players = assert(args.players, "players of job cannot be nil")
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.code, "code of job cannot be nil")
    assert(obj.name, "name of job cannot be nil")
    assert(obj.level, "level of job cannot be nil")
    assert(obj.status, "status of job cannot be nil")
    assert(obj.startTime, "startTime of job cannot be nil")
    assert(obj.endTime, "endTime of job cannot be nil")
    assert(obj.location, "location of job cannot be nil")
    assert(obj.requirements, "requirements of job cannot be nil")
    assert(obj.players, "players of job cannot be nil")
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
local NanjueJob = define_NanjueJob()

-- nanjue stranger(路人) data structure
local define_NanjueStranger = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    local obj = {}
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:confirmed()
    assert(self.shoeType, "shoeType cannot be nil")
    assert(self.shoeColor, "shoeColor cannot be nil")
    assert(self.clothType, "clothType cannot be nil")
    assert(self.clothColor, "clothColor cannot be nil")
    assert(self.height, "height cannot be nil")
    assert(self.weight, "weight cannot be nil")
    assert(self.age, "age cannot be nil")
    assert(self.gender, "gender cannot be nil")
    assert(self.roomId, "roomId cannot be nil")
    assert(self.name, "name cannot be nil")
    assert(self.id, "id cannot be nil")
    assert(self.seq, "seq cannot be nil")
    -- self.identifyFeature
  end

  function prototype:show()
    print("当前路人信息如下：")
    print("姓名：", self.name)
    print("性别：", self.gender)
    print("年龄：", self.age)
    print("身高：", self.height)
    print("体重：", self.weight)
    print("衣服材质：", self.clothType)
    print("衣服颜色：", self.clothColor)
    print("鞋子材质：", self.shoeType)
    print("鞋子颜色：", self.shoeColor)
    if self.identifyFeature then
      print("证词内容：", next(self.identifyFeature))
    else
      print("证词内容：", "无")
    end
  end

  return prototype
end
local NanjueStranger = define_NanjueStranger()

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
    testify = "testify",
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
    TESTIFY_SUCCESS = "testify_success",
    TESTIFY_FAIL = "testify_fail",
    CONTINUE = "continue",  -- the convenient way to continuously do 5 jobs
  }
  local REGEXP = {
    ALIAS_START = "^nanjue\\s+start\\s*$",
    ALIAS_STOP = "^nanjue\\s+stop\\s*$",
    ALIAS_DEBUG = "^nanjue\\s+debug\\s+(on|off)\\s*$",
    -- 任务标识 任务名称 任务状态 发布时间 截止时间 任务地点 资质要求 认领玩家
    JOB_INFO = "^\\s*([0-9_]+?)\\s+(.*?)「(.*?)」\\s+(.*?)\\s+(\\d+:\\d+:\\d+)\\s+(\\d+:\\d+:\\d+)\\s+(.*?)\\s+(.*?)\\s+(\\d+)$",
    RECORD_SUCCESS = "^[ >]*最近长安城内出现不少盗窃事件，有人报告.*$",
    RECORD_FAIL = "^[ >]*怎么又是你！我看你是机器人吧。$",
    PREV_JOB_NOT_FINISH = "^[ >]*你先把手头上的工作完成以后才能接着领下一个任务。$",
    GENDER_AGE = "^[ >]*(他|她)看起来约(.*)多岁。$",
    CLOTH = "^\\s*□身穿一件(.*?)\\(.*$",
    SHOE = "^\\s*□脚穿一双(.*?)\\(.*$",
    FIGURE = "^这是一(?:位|个)(.*?)的行人。$",
    -- CRIMINAL_AUTOKILL = "^[ >]*你发现了正准备潜逃的罪犯，拦住了罪犯的去路。$",
    TESTIFY_SUCCESS = "^[ >]*你发现了正准备潜逃的罪犯，向附近巡街的金吾卫举报了，可以去衙门领奖了。$",
    TESTIFY_FAIL = "^[ >]*你向附近的金吾卫错误地指证上铺的盗劫犯，惊动了真正的盗贼，使得他立即逃离长安城。$",
    CONFIRM_FAIL = "^[ >]*你寻找线索消耗了太多的时间，引起了盗贼的怀疑，盗贼逃离了长安城。$",
  }
  -- 中心，辐射1格
  local Center = {
    ["小雁塔"] = 2321,  -- ok
    ["大雁塔"] = 2313,  -- ok
    ["长乐坊"] = 2349,
    ["东市"] = 2330,  -- ok
    ["国子监"] = 2323, -- ok
    ["西市"] = 1405,  -- ok
    ["通化门大街"] = 2284,  -- ok
    ["西市附近的顺街"] = 2319,  -- ok
    ["东市附近的顺街"] = 2316,  -- ok
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
    ["天蓝锦袍"] = "fabric",
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
    ["麻鞋"] = "fabric",
    ["千层底布鞋"] = "fabric",
    ["木屐"] = "sandal",
    ["草鞋"] = "sandal",
    ["破鞋"] = "sandal",
  }
  local ColorType = {
    ["silver"] = "light",
    ["lime"] = "light",
    ["green"] = "light",
    ["yellow"] = "light",
    ["teal"] = "light",
    ["white"] = "light",
    ["olive"] = "light",
    ["magenta"] = "dark",  -- 待定，粉色
    ["black"] = "dark",
    ["red"] = "dark",
    ["blue"] = "dark",
    ["purple"] = "dark",
    ["maroon"] = "dark",
    ["navy"] = "dark",  -- 深蓝

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
  local IdentifyFeature = {
    ["深色衣服"] = {
      k = "clothColor",
      v = "dark"
    },
    ["浅色衣服"] = {
      k = "clothColor",
      v = "light"
    },
    ["深色鞋子"] = {
      k = "shoeColor",
      v = "dark"
    },
    ["浅色鞋子"] = {
      k = "shoeColor",
      v = "light"
    },
    ["身穿布衣"] = {
      k = "clothType",
      v = "fabric"
    },
    ["身穿夹袄"] = {
      k = "clothType",
      v = "cotton"
    },
    ["丝绸衣服"] = {
      k = "clothType",
      v = "silk"
    },
    ["一双布鞋"] = {
      k = "shoeType",
      v = "fabric"
    },
    ["一双凉鞋"] = {
      k = "shoeType",
      v = "sandal"
    },
    ["一双靴子"] = {
      k = "shoeType",
      v = "boot"
    },
    ["流浪汉"] = {
      k = "gender",
      v = "man"
    },
    ["男"] = {
      k = "gender",
      v = "man"
    },
    ["女"] = {
      k = "gender",
      v = "woman"
    },
    ["矮个子"] = {
      k = "height",
      v = "short"
    },
    ["高个子"] = {
      k = "height",
      v = "tall"
    },
    ["不太高"] = {
      k = "height",
      v = "short"
    },
    ["白发苍苍"] = {
      k = "age",
      v = "old"    -- 此处有疑问？
    },
    ["头发花白"] = {
      k = "age",
      v = "old"
    },
    ["半只脚埋入棺材"] = {
      k = "age",
      v = "old"
    },
    ["年轻"] = {
      k = "age",
      v = "young"
    },
    ["青年人"] = {
      k = "age",
      v = "young"
    },
    ["中年"] = {
      k = "age",
      v = "medium"
    },
    ["老大不小"] = {
      k = "age",
      v = "medium"
    },
    ["有点发胖"] = {
      k = "weight",
      v = "fat"
    },
    ["有点胖"] = {
      k = "weight",
      v = "fat"
    },
    ["微微发福"] = {
      k = "weight",
      v = "fat"
    },
    ["猴子"] = {
      k = "weight",
      v = "thin"
    },
    ["有点偏廋"] = {
      k = "weight",
      v = "thin"
    },
    ["有点偏瘦"] = {
      k = "weight",
      v = "thin"
    },
    ["竹竿"] = {
      k = "weight",
      v = "thin"
    },
  }

  local JobRoomId = 2289
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
    -- debug purpose
    self.DEBUG = true

    self.precondition = {
      jing = 0.96,
      qi = 0.96,
      jingli = 0.5,
      neili = 0.1
    }

    self.availableTime = 0
  end

  function prototype:available()
    return os.time() > self.availableTime
  end

  function prototype:resetOnStop()
    self.waitThread = nil
    self.strangers = {}
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
      "nanjue_info_start", "nanjue_info_done",
      "nanjue_record_start", "nanjue_record_done",
      "nanjue_look_start", "nanjue_look_done",
      "nanjue_ask_start", "nanjue_ask_done",
      "nanjue_testify_start", "nanjue_testify_done",
      "nanjue_submit_start", "nanjue_submit_done"
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
        self.prevNotFinish = nil
        helper.enableTriggerGroups("nanjue_info_start", "nanjue_record_start")
      end,
      exit = function()
        self.recordSuccess = nil
        self.prevNotFinish = nil
        helper.disableTriggerGroups(
          "nanjue_info_start", "nanjue_info_done",
          "nanjue_record_start", "nanjue_record_done")
      end
    }
    self:addState {
      state = States.collect,
      enter = function()
        helper.enableTriggerGroups("nanjue_ask_start", "nanjue_look_start")
      end,
      exit = function()
        helper.disableTriggerGroups(
          "nanjue_ask_start", "nanjue_ask_done",
          "nanjue_look_start", "nanjue_look_done"
        )
      end
    }
    self:addState {
      state = States.testify,
      enter = function()
        helper.enableTriggerGroups("nanjue_testify_start")
      end,
      exit = function()
        helper.disableTriggerGroups("nanjue_testify_start", "nanjue_testify_done")
      end
    }
    self:addState {
      state = States.submit,
      enter = function()
        helper.enableTriggerGroups("nanjue_submit_start")
      end,
      exit = function()
        helper.disableTriggerGroups("nanjue_submit_start", "nanjue_submit_done")
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
        travel:walkto(JobRoomId)
        travel:waitUntilArrived()
        return self:doAskInfo()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<record>
    self:addTransition {
      oldState = States.record,
      newState = States.stop,
      event = Events.NO_JOB_AVAILABLE,
      action = function()
        print("没有可用的任务")
      end
    }
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
      newState = States.testify,
      event = Events.CRIMINAL_ANALYZED,
      action = function()
        return self:doTestify()
      end
    }
    self:addTransitionToStop(States.collect)
    -- transition from state<testify>
    self:addTransition {
      oldState = States.testify,
      newState = States.submit,
      event = Events.TESTIFY_SUCCESS,
      action = function()
        return self:doSubmit()
      end
    }
    self:addTransition {
      oldState = States.testify,
      newState = States.submit,
      event = Events.TESTIFY_FAIL,
      action = function()
        return self:doCancel()
      end
    }
    self:addTransitionToStop(States.testify)
    -- transition from submit<submit>
    self:addTransition {
      oldState = States.submit,
      newState = States.record,
      event = Events.CONTINUE,
      action = function()
        -- we must reset all variables before do next job
        self:resetOnStop()
        travel:walkto(JobRoomId)
        travel:waitUntilArrived()
        return self:doAskInfo()
      end
    }
    self:addTransitionToStop(States.submit)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "nanjue_info_start", "nanjue_info_done",
      "nanjue_look_start", "nanjue_look_done",
      "nanjue_testify_start", "nanjue_testify_done",
      "nanjue_submit_start", "nanjue_submit_done"
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
        self:debug("目前可用任务数：", #(self.jobs))
        if #(self.jobs) == 0 then
          return self:fire(Events.NO_JOB_AVAILABLE)
        else
          self.selectedJob = nil
          for _, job in ipairs(self.jobs) do
            local targetRoomId = Center[job.location]
            if targetRoomId then
              self.targetRoomId = targetRoomId
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
        local jobRequirements = wildcards[8]
        local jobPlayers = tonumber(wildcards[9])
        local currTime = os.date("*t")
        local currTs = os.time()
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

        if endTime > self.availableTime then
          self.availableTime = endTime
        end

        -- 只做1分钟内的任务
        -- 只做没有人认领的任务
        -- 只做新的任务
        local restTime = endTime - currTs
        self:debug("任务剩余时间：", restTime, "接任务玩家数：", jobPlayers, "任务状态", jobStatus)
        if restTime >= 60 and jobPlayers == 0 and jobStatus == "新建" then
          self:debug("添加进入可选列表")
          table.insert(self.jobs, NanjueJob:decorate {
            code = jobCode,
            name = jobName,
            level = jobLevel,
            status = jobStatus,
            startTime = startTime,
            endTime = endTime,
            location = jobLocation,
            requirements = jobRequirements,
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
        if self.prevNotFinish then
          SendNoEcho("record cancel")
          self:debug("等待两秒重新接任务")
          wait.time(2)
          return self:doRecord()
        elseif self.recordSuccess then
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
        -- 被鉴定为机器人时，将可用时间向后推24小时
        self.availableTime = os.time() + 86400
      end
    }
    helper.addTrigger {
      group = "nanjue_record_done",
      regexp = REGEXP.PREV_JOB_NOT_FINISH,
      response = function()
        self.prevNotFinish = true
      end
    }
    helper.addTrigger {
      group = "nanjue_record_done",
      regexp = REGEXP.RECORD_SUCCESS,
      response = function()
        self.recordSuccess = true
      end
    }
    -- trigger for look
    helper.addTrigger {
      group = "nanjue_look_start",
      regexp = helper.settingRegexp("nanjue", "look_start"),
      response = function()
        helper.enableTriggerGroups("nanjue_look_done")
        self.lookCloth = true
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
        self:debug("GENDER_AGE triggered")
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
        self:debug("FIGURE triggered")
        local figure = wildcards[1]
        local figureType = FigureType[figure]
        if figureType then
          self.currStranger.weight = figureType.weight
          self.currStranger.height = figureType.height
        else
          ColourNote("yellow", "", "无法鉴别路人身材：", figure)
        end
      end
    }
    helper.addTrigger {
      group = "nanjue_look_done",
      regexp = REGEXP.CLOTH,
      response = function(name, line, wildcards, styles)
        self:debug("CLOTH triggered", self.lookCloth)
        if self.lookCloth then  -- 只观察第一件衣服
          self.lookCloth = false
          local cloth = wildcards[1]
          local clothType = ClothType[cloth]
          if clothType then
            self.currStranger.clothType = clothType
          else
            ColourNote("yellow", "", "无法查找到衣服类型，设置为布衣：", cloth)
            self.currStranger.clothType = "fabric"
          end
          local col = string.find(line, cloth)
          local style = GetStyle(styles, col)
          local color = RGBColourToName(style.textcolour)
          local colorType = ColorType[color]
          if colorType then
            self.currStranger.clothColor = colorType
          else
            ColourNote("yellow", "", "无法查找到衣服颜色深浅，设置为中性")
            self.currStranger.clothColor = "normal"
          end
          self:debug("衣服类型：", clothType, "衣服颜色：", color)
        end
      end
    }
    helper.addTrigger {
      group = "nanjue_look_done",
      regexp = REGEXP.SHOE,
      response = function(name, line, wildcards, styles)
        self:debug("SHOE triggered")
        local shoe = wildcards[1]
        local shoeType = ShoeType[shoe]
        if shoeType then
          self.currStranger.shoeType = shoeType
        else
          ColourNote("yellow", "", "无法查找到鞋子类型，设置为布鞋：", shoe)
          self.currStranger.shoeType = "fabric"
        end
        local col = string.find(line, shoe)
        local style = GetStyle(styles, col)
        local color = RGBColourToName(style.textcolour)
        local colorType = ColorType[color]
        if colorType then
          self.currStranger.shoeColor = colorType
        else
          ColourNote("yellow", "", "无法查找到鞋子颜色深浅，设置为中性")
          self.currStranger.shoeColor = "normal"
        end
        self:debug("鞋子类型：", shoeType, "鞋子颜色：", color)
      end
    }
    -- trigger for ask
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
        helper.disableTriggerGroups("nanjue_ask_done")
      end
    }
    helper.addTrigger {
      group = "nanjue_ask_done",
      regexp = self:identifyFeatureRegexp(),
      response = function(name, line, wildcards)
        self:debug("IDENTIFY_FEATURE triggered")
        local feature = wildcards[1]
        local identified = IdentifyFeature[feature]
        if identified then
          self.currStranger.identifyFeature = {}
          self.currStranger.identifyFeature[identified.k] = identified.v
        else
          ColourNote("yellow", "", "无法鉴定特征！")
        end
      end
    }
    -- trigger for testify
    helper.addTrigger {
      group = "nanjue_testify_start",
      regexp = helper.settingRegexp("nanjue", "testify_start"),
      response = function()
        helper.enableTriggerGroups("nanjue_testify_done")
      end
    }
    helper.addTrigger {
      group = "nanjue_testify_done",
      regexp = helper.settingRegexp("nanjue", "testify_done"),
      response = function()
        helper.disableTriggerGroups("nanjue_testify_done")
        if self.testifySuccess then
          return self:fire(Events.TESTIFY_SUCCESS)
        else
          return self:fire(Events.TESTIFY_FAIL)
        end
      end
    }
    helper.addTrigger {
      group = "nanjue_testify_done",
      regexp = REGEXP.TESTIFY_SUCCESS,
      response = function()
        self.testifySuccess = true
      end
    }
  end

  function prototype:identifyFeatureRegexp()
    local patterns = {}
    for pattern in pairs(IdentifyFeature) do
      table.insert(patterns, pattern)
    end
    return "^.*(" .. table.concat(patterns, "|") .. ").*$"
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
    self.prevNotFinish = false
    SendNoEcho("set nanjue record_start")
    SendNoEcho("record " .. self.selectedJob.code)
    SendNoEcho("set nanjue record_done")
  end

  function prototype:doAskInfo()
    self.jobs = {}
    SendNoEcho("set nanjue info_start")
    SendNoEcho("ask shaoyin about 任务信息")
    SendNoEcho("set nanjue info_done")
  end

  function prototype:doLookStranger()
    SendNoEcho("set nanjue look_start")
    SendNoEcho("look " .. self.currStranger.id)
    SendNoEcho("set nanjue look_done")
  end

  function prototype:doAskStranger()
    SendNoEcho("set nanjue ask_start")
    SendNoEcho("ask " .. self.currStranger.id .. " about 消息")
    SendNoEcho("set nanjue ask_done")
  end

  function prototype:doCollect()
    self.checkedRoomIds = {}
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
    -- 先获取该房间是否已经被检查
    local currRoomId = travel.traverseRoomId
    if not self.checkedRoomIds[currRoomId] then
      self.checkedRoomIds[currRoomId] = true
      status:idhere()
      local seq = 0
      for _, item in ipairs(status.items) do
        -- todo
        if string.find(item.ids, "luren") then
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
          self:doLookStranger()
          helper.assureNotBusy()
          wait.time(1)
          self:doAskStranger()
          helper.assureNotBusy()
          wait.time(1)
          if self.DEBUG then
            self.currStranger:show()
          end
          self.currStranger:confirmed()
          table.insert(self.strangers, self.currStranger)
        end
      end
    end
    return false
  end

  ----
  -- 判断逻辑：
  -- 1. 如果路人证词中描述特征与自身相符，则该路人必定不是罪犯，且该特征必为真
  -- 2. 所有不是罪犯的路人的证词都是真，可能不提供证词
  -- 3. 罪犯的证词为假
  ----
  function prototype:analyzeCriminalAfterTraverse()
    -- 嫌疑人列表
    self.suspects = {}
    -- 证人列表
    self.witnesses = {}
    -- 不发言路人列表
    self.silents = {}
    -- 必定不是罪犯列表
    self.nonCriminals = {}
    -- 必定为真的特征列表
    self.trueFeatures = {}

    -- 区分证人与不发言
    -- 并将所有人都放入嫌疑人名单
    for _, stranger in ipairs(self.strangers) do
      if stranger.identifyFeature then
        table.insert(self.witnesses, stranger)
      else
        table.insert(self.silents, stranger)
      end
      table.insert(self.suspects, stranger)
    end

    self:debug("鉴定必定为真的证词，和必定不是罪犯的证人，并从嫌疑人名单移除")
    for _, witness in ipairs(self.witnesses) do
      local toldTruth = false
      for k, v in pairs(witness.identifyFeature) do
        if witness[k] == v then
          self:debug("路人" .. witness.name .. "必定不是罪犯，因为证词与自身符合", k, v)
          toldTruth = true
          break
        end
      end
      if toldTruth then
        table.insert(self.nonCriminals, witness)
        for i = 1, #(self.suspects) do
          if self.suspects[i] == witness then
            table.remove(self.suspects, i)
            break
          end
        end
        for k, v in pairs(witness.identifyFeature) do
          self.trueFeatures[k] = v
        end
      end
    end
    self:debug("从必定为真的证词出发，查找不符合该证词描述的人，添加到非罪犯列表")
    while true do
      local suspectCnt = #(self.suspects)
      for i = 1, suspectCnt do
        local diff = false
        local suspect = self.suspects[i]
        for k, v in pairs(self.trueFeatures) do
          if suspect[k] ~= v then
            diff = true
            break
          end
        end
        if diff then
          self:debug("从真证词出发，路人" .. suspect.name .. "必定不是罪犯，加入非罪犯列表")
          table.insert(self.nonCriminals, suspect)
          table.remove(self.suspects, i)
          if suspect.identifyFeature then
            self:debug("路人" .. suspect.name .. "有证词，证词添加到必定为真的证词列表")
            for k, v in pairs(suspect.identifyFeature) do
              self.trueFeatures[k] = v
            end
          end
          break
        end
      end
      -- 如果嫌疑人没有减少，则退出循环
      if #(self.suspects) == suspectCnt then
        break
      end
    end

    if #(self.suspects) > 1 then
      self:debug("仍有多名嫌疑人，目前确认为真的罪犯特征：")
      for k, v in pairs(self.trueFeatures) do
        self:debug(k, v)
      end

      while true do
        local suspectCnt = #(self.suspects)
        for i = 1, suspectCnt do
          local diff = false
          local suspect = self.suspects[i]
          local features = self:featuresExcluded(self.witnesses, suspect)
          for k, v in pairs(features) do
            if suspect[k] ~= v then
              diff = true
            end
          end
          if diff then
            self:debug("假定路人" .. suspect.name .. "有罪，推断出矛盾，该人不是罪犯")
            table.insert(self.nonCriminals, suspect)
            table.remove(self.suspects, i)
            if suspect.identifyFeature then
              self:debug("路人" .. suspect.name .. "有证词，证词添加到必定为真的证词列表")
              for k, v in pairs(suspect.identifyFeature) do
                self.trueFeatures[k] = v
              end
            end
            break
          end
        end
        -- 如果嫌疑人没有减少，则退出循环
        if #(self.suspects) == suspectCnt then
          break
        end
      end
    end

    -- 最终步骤
    if #(self.suspects) == 0 then
      self:debug("所有路人都被排除嫌疑，判定过程有错误！补救方法为选择满足特征最多的路人")
      local fallbackStranger
      local maxFits = 0
      for _, stranger in ipairs(self.strangers) do
        local fits = 0
        for k, v in pairs(self.trueFeatures) do
          if stranger[k] == v then
            fits = fits + 1
          end
        end
        if fits > maxFits then
          maxFits = fits
          fallbackStranger = stranger
        end
      end
      self:debug("符合特征最多的路人被标记为嫌疑人", fallbackStranger.name)
      self.suspects = {fallbackStranger}
      return self:fire(Events.CRIMINAL_ANALYZED)
    elseif #(self.suspects) == 1 then
      self:debug("仅剩1人有嫌疑，确定为罪犯")
      return self:fire(Events.CRIMINAL_ANALYZED)
    else
      self:debug("仍有多名嫌疑人，尝试选择有证词的作为嫌疑人")
      local suspects = {}
      for _, s in ipairs(self.suspects) do
        if s.identifyFeature then
          table.insert(suspects, s)
        end
      end
      if #suspects > 1 then
        self:debug("仍有多名嫌疑人有证词，选择第一个")
        self.suspects = suspects
      elseif #suspects == 1 then
        self:debug("仅有一人有证词，选作嫌疑人：", suspects[1].name)
        self.suspects = suspects
      else
        self:debug("没有人有证词，选择第一个")
      end
      return self:fire(Events.CRIMINAL_ANALYZED)
    end
  end

  function prototype:featuresExcluded(witnesses, excluded)
    local remainedFeatures = {}
    for _, witness in ipairs(witnesses) do
      if witness ~= excluded then
        for k, v in pairs(witness.identifyFeature) do
          remainedFeatures[k] = v
        end
      end
    end
    return remainedFeatures
  end

  function prototype:doTestify()
    if #(self.suspects) == 0 then
      print("没有发现任何嫌疑人，在证人中随机挑选一个")
      local randomCriminal = self.witnesses[math.random(#(self.witnesses))]
      table.insert(self.suspects, randomCriminal)
    end
    self.currSuspect = nil
    -- todo 可加强，目前只指认，不战斗
    if self.DEBUG then
      local names = {}
      for _, suspect in ipairs(self.suspects) do
        table.insert(names, suspect.name)
      end
      self:debug("嫌疑人有：", table.concat(names, ", "))
    end
    local id, suspect = next(self.suspects)
    self.currSuspect = suspect
    travel:walkto(self.currSuspect.roomId)
    travel:waitUntilArrived()
    wait.time(2)
    self.testifySuccess = false
    SendNoEcho("set nanjue testify_start")
    SendNoEcho("testify " .. self.currSuspect.id)
    SendNoEcho("set nanjue testify_done")
  end

  function prototype:doStart()
    return self:fire(Events.START)
  end

  function prototype:doCancel()
    helper.assureNotBusy()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    SendNoEcho("record cancel")
    wait.time(2)
    helper.assureNotBusy()
    return self:fire(Events.CONTINUE)
  end

  function prototype:doSubmit()
    helper.assureNotBusy()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    SendNoEcho("ask shaoyin about 领赏")
    wait.time(2)
    helper.assureNotBusy()
    return self:fire(Events.CONTINUE)
  end

  return prototype
end
return define_nanjue():FSM()

