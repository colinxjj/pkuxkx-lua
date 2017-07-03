--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/19
-- Time: 13:33
-- To change this template use File | Settings | File Templates.
--

local pattern = [[
≡━◎个人档案◎━━━━━━━━━━━━━━━━━━━━━━━━≡

【 剑  童 】华山派剑士 撸啊(Luar)

 你是一位十六岁的未婚男性人类，丙申年十二月二十一日巳时一刻生。

 膂力：[ 35]  悟性：[ 45]  根骨：[ 18]  身法：[ 18]

 你是华山派第二十代弟子， 你的师父是梁发。


 你曾经结束过九个生命，其中有零个是其他玩家，零个是宠物。
 你共经历过零次死亡的痛苦，其中有零次是命丧其他玩家之手。

 杀    气：  正常
 银行存款：  一百二十四两黄金

 国    籍：  无国籍                              国家积分：  0

 等    级：   0/5
 实战经验：  六年功力■□□□□
■■■■■■■■■■■■■■■■■■■■■■■■■□□□□□□□□□□□□□□□(63.25%)

 道    德：  0                                   潜    能：  1.10万
 师门忠诚：  0                                   江湖声望：  7486
 愿    望：  0                                   武 学 点：  0
 战斗评价：  不足挂齿

≡━━━━━━━━━━━━━━━━━━━━━━◎北大侠客行◎━━≡

]]


local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local Item = require "pkuxkx.Item"

--------------------------------------------------------------
-- status.lua
-- 状态捕捉，包含自身精气状态，身上携带物品，当前房间人与物
-- status:hpbrief() 精气状态捕捉，食物饮水需预先在mud中设置set hpbrief long
-- status:id() 自身携带物品捕捉
-- status:idhere() 当前房间物品/人物捕捉，与id()共用列表
-- status:inventory() 自身携带物品重量与个数捕捉
-- status:money() 自身携带金钱数目捕捉
-- status:score() 自身信息捕捉
-- status:showHp() 显示自身状态
-- status:showItems() 显示物品列表（自身，或者房间，互斥）
-- status:showInventory() 显示负重情况
-- status:showMoney() 显示携带金钱情况
-- status:showScore() 显示自身信息
--------------------------------------------------------------

local define_status = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    hpbrief = "hpbrief",
    id = "id",
    inventory = "inventory",
    money = "money",
    score = "score",
    skbrief = "skbrief",
    sk = "sk",
  }
  local Events = {
    STOP = "stop",
    HPBRIEF = "hpbrief",
    ID = "id",
    IDHERE = "idhere",
    INVENTORY = "inventory",
    MONEY = "money",
    SCORE = "score",
    SKBRIEF = "skbrief",
    SK = "SK",
  }
  local REGEXP = {
    ALIAS_STATUS_HP = "^status\\s+hp\\s*$",
    ALIAS_STATUS_MONEY = "^status\\s+money\\s*$",
    ALIAS_STATUS_ID = "^status\\s+(id|idhere)\\s*$",
    ALIAS_STATUS_INVENTORY = "^status\\s+i\\s*$",
    ALIAS_STATUS_SCORE = "^status\\s+sc\\s*$",
    ALIAS_STATUS_SHOW = "^status\\s+show\\s+(hp|money|items|weight|sc)\\s*$",
    ALIAS_DEBUG = "^status\\s+debug\\s+(on|off)\\s*$",
    -- 经验，潜能，最大内力，当前内力，最大精力，当前精力
    -- 最大气血，有效气血，当前气血，最大精神，有效精神，当前精神
    HPBRIEF_LINE = "^[ >]*#(-?[0-9\\.]+[KMB]?),(-?[0-9\\.]+[KMB]?),(-?\\d+),(-?\\d+),(-?\\d+),(-?\\d+)$",
    -- 真气，真元，食物，饮水
    HPBRIEF_LINE_EX = "^[ >]*#(-?\\d+),(-?\\d+),(-?\\d+),(-?\\d+)$",
    ITEM_ID = "([^ ]+)\\s+\\=\\s+([^\"]+)$",
    WEIGHT_RATE = "^│\\s+你身上带着(.*?)件东西\\s+\\(负重\\s*(-?\\d+)%\\)：.*",
    COINS_DESC = "^[ >]*(.*)文铜板\\((Coin)\\)",
    SILVERS_DESC = "^[ >]*(.*)两白银\\((Silver)\\)$",
    GOLDS_DESC = "^[ >]*(.*)两黄金\\((Gold)\\)$",
    MONEY_MISS_STOP_EVALUATION = "^[ >]*你要看什么？$",
    SYSTEM_BUSY = "^[ >]*等等，系统喘气中......$",
    TITLE_DESC = "^\\s*【\\s*(.*?)\\s*】([^ ]+)(?: |「.*?」)(.*?)\\(([A-Z][a-z]*)\\)$",
    MURDEROUS_LEVEL = "^\\s*杀    气：\\s*(.+)$",
    SKBRIEF = "^[ >]*#(\\d+)/(\\d+)$",
    SKILL_LIMIT = "^[ >]*你目前所学过的技能：（共(.*?)项技能，你的技能等级最多能达到(.*?)级）$",
  }

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

    -- hpbrief internal
    self.hpbriefNum = 1
    self.waitThread = nil
    -- hpbrief exposed variables
    self.exp = nil
    self.pot = nil
    self.maxNeili = nil
    self.currNeili = nil
    self.maxJingli = nil
    self.currJingli = nil
    self.maxQi = nil
    self.effQi = nil
    self.currQi = nil
    self.maxJing = nil
    self.effJing = nil
    self.currJing = nil
    self.zhenqi = nil
    self.zhenyuan = nil
    self.food = nil
    self.drink = nil
    -- id / id here
    self.systemBusy = false
    self.items = nil
    -- inventory
    self.itemCount = 0
    self.weightPercent = 0
    -- money
    self.golds = 0
    self.silvers = 0
    self.coins = 0
    -- score
    self.id = nil
    self.name = nil
    self.rank = nil
    self.title = nil
    self.murderousLevel = 0
    -- skbrief
    self.skill = nil
    self.skillLevel = nil
    self.skillPot = nil
    -- sk
    self.skillCnt = nil
    self.skillLimit = nil
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self.hpbriefNum = 1
      end,
      exit = function()
        self.hpbriefNum = 1
      end
    }
    self:addState {
      state = States.hpbrief,
      enter = function()
        helper.enableTriggerGroups("status_hpbrief_start")
      end,
      exit = function()
        helper.disableTriggerGroups("status_hpbrief_start", "status_hpbrief_done")
      end
    }
    self:addState {
      state = States.id,
      enter = function()
        self.systemBusy = false
        helper.enableTriggerGroups("status_id_start")
      end,
      exit = function()
        helper.disableTriggerGroups("status_id_start", "status_id_done")
      end
    }
    self:addState {
      state = States.inventory,
      enter = function()
        helper.enableTriggerGroups("status_inventory_start")
      end,
      exit = function()
        helper.disableTriggerGroups("status_inventory_start", "status_inventory_done")
      end
    }
    self:addState {
      state = States.money,
      enter = function()
        helper.enableTriggerGroups("status_money_start")
      end,
      exit = function()
        helper.disableTriggerGroups("status_money_start", "status_money_done")
      end
    }
    self:addState {
      state = States.score,
      enter = function()
        helper.enableTriggerGroups("status_score_start")
      end,
      exit = function()
        helper.disableTriggerGroups("status_score_start", "status_score_done")
      end
    }
    self:addState {
      state = States.skbrief,
      enter = function()
        helper.enableTriggerGroups("status_skbrief_start")
      end,
      exit = function()
        helper.disableTriggerGroups("status_skbrief_start", "status_skbrief_done")
      end
    }
    self:addState {
      state = States.sk,
      enter = function()
        helper.enableTriggerGroups("status_sk_start")
      end,
      exit = function()
        helper.disableTriggerGroups("status_sk_start", "status_sk_done")
      end
    }
  end

  function prototype:addTransitionToStop(fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function() end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.hpbrief,
      event = Events.HPBRIEF,
      action = function()
        self:doHpbrief()
        return self:fire(Events.STOP)
      end
    }
    self:addTransition {
      oldState = States.stop,
      newState = States.id,
      event = Events.ID,
      action = function()
        self.items = nil
        self:doId()
        return self:fire(Events.STOP)
      end
    }
    self:addTransition {
      oldState = States.stop,
      newState = States.id,
      event = Events.IDHERE,
      action = function()
        self.items = nil
        self:doId(true)
        return self:fire(Events.STOP)
      end
    }
    self:addTransition {
      oldState = States.stop,
      newState = States.inventory,
      event = Events.INVENTORY,
      action = function()
        self.itemCount = 0
        self.weightPercent = 0
        self:doInventory()
        return self:fire(Events.STOP)
      end
    }
    self:addTransition {
      oldState = States.stop,
      newState = States.money,
      event = Events.MONEY,
      action = function()
        self.golds = 0
        self.silvers = 0
        self.coins = 0
        self:doMoney()
        return self:fire(Events.STOP)
      end
    }
    self:addTransition {
      oldState = States.stop,
      newState = States.score,
      event = Events.SCORE,
      action = function()
        self.id = nil
        self.name = nil
        self.title = nil
        self.rank = nil
        self.murderousLevel = 0
        self:doScore()
        return self:fire(Events.STOP)
      end
    }
    self:addTransition {
      oldState = States.stop,
      newState = States.skbrief,
      event = Events.SKBRIEF,
      action = function()
        assert(self.skill, "skill cannot be nil")
        self.skillLevel = nil
        self.skillPot = nil
        self:doSkbrief()
        return self:fire(Events.STOP)
      end
    }
    self:addTransition {
      oldState = States.stop,
      newState = States.sk,
      event = Events.SK,
      action = function()
        self.skillCnt = nil
        self.skillLimit = nil
        self:doSk()
        return self:fire(Events.STOP)
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<hpbrief>
    self:addTransitionToStop(States.hpbrief)
    -- transition from state<id>
    self:addTransitionToStop(States.id)
    -- transition from state<inventory>
    self:addTransitionToStop(States.inventory)
    -- transition from state<money>
    self:addTransitionToStop(States.money)
    -- transition from state<score>
    self:addTransitionToStop(States.score)
    -- transition from state<skbrief>
    self:addTransitionToStop(States.skbrief)
    -- transition from state<sk>
    self:addTransitionToStop(States.sk)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "status_hpbrief_start", "status_hpbrief_done",
      "status_id_start", "status_id_done",
      "status_inventory_start", "status_inventory_done",
      "status_money_start", "status_money_done",
      "status_score_start", "status_score_done",
      "status_skbrief_start", "status_skbrief_done",
      "status_sk_start", "status_sk_done")
    -- hpbrief check
    helper.addTrigger {
      group = "status_hpbrief_start",
      regexp = helper.settingRegexp("status", "hpbrief_start"),
      response = function()
        helper.enableTriggerGroups("status_hpbrief_done")
        self.hpbriefNum = 1
      end
    }
    helper.addTrigger {
      group = "status_hpbrief_done",
      regexp = helper.settingRegexp("status", "hpbrief_done"),
      response = function()
        helper.disableTriggerGroups("status_hpbrief_start", "status_hpbrief_done")
        self.hpbriefNum = 1
        local thread = self.waitThread
        if thread then
          self.waitThread = nil
          local ok, err = coroutine.resume(thread)
          if not ok then
            ColourNote ("deeppink", "black", "Error raised in trigger function (in wait module)")
            ColourNote ("darkorange", "black", debug.traceback (thread))
            error (err)
          end -- if
        end
      end
    }
    helper.addTrigger {
      group = "status_hpbrief_done",
      regexp = REGEXP.HPBRIEF_LINE,
      response = function(name, line, wildcards)
        self:debug("HPBRIEF_LINE triggered")
        local hpbriefNum = self.hpbriefNum
        if hpbriefNum == 1 then
--          self.exp = tonumber(wildcards[1])
          self.exp = helper.convertAbbrNumber(wildcards[1])
--          self.pot = tonumber(wildcards[2])
          self.pot = helper.convertAbbrNumber(wildcards[2])
          self.maxNeili = tonumber(wildcards[3])
          self.currNeili = tonumber(wildcards[4])
          self.maxJingli = tonumber(wildcards[5])
          self.currJingli = tonumber(wildcards[6])
          self.hpbriefNum = hpbriefNum + 1
        elseif hpbriefNum == 2 then
          self.maxQi = tonumber(wildcards[1])
          self.effQi = tonumber(wildcards[2])
          self.currQi = tonumber(wildcards[3])
          self.maxJing = tonumber(wildcards[4])
          self.effJing = tonumber(wildcards[5])
          self.currJing = tonumber(wildcards[6])
          self.hpbriefNum = hpbriefNum + 1
        else
          print("错误触发了hpbrief前两行的正则")
        end
      end
    }
    helper.addTrigger {
      group = "status_hpbrief_done",
      regexp = REGEXP.HPBRIEF_LINE_EX,
      response = function(name, line, wildcards)
        self:debug("HPBRIEF_LINE_EX triggered")
        if self.hpbriefNum == 3 then
          self.zhenqi = tonumber(wildcards[1])
          self.zhenyuan = tonumber(wildcards[2])
          self.food = tonumber(wildcards[3])
          self.drink = tonumber(wildcards[4])
          self.hpbriefNum = 1
        else
          print("错误触发了hpbrief第三行的正则")
        end
      end
    }
    -- id check
    helper.addTrigger {
      group = "status_id_start",
      regexp = helper.settingRegexp("status", "id_start"),
      response = function()
        self:debug("ID_START triggered")
        helper.enableTriggerGroups("status_id_done")
      end
    }
    helper.addTrigger {
      group = "status_id_done",
      regexp = helper.settingRegexp("status", "id_done"),
      response = function()
        self:debug("ID_DONE triggered")
        helper.disableTriggerGroups("status_id_done")
        local thread = self.waitThread
        if thread then
          self.waitThread = nil
          local ok, err = coroutine.resume(thread)
          if not ok then
            ColourNote ("deeppink", "black", "Error raised in trigger function (in wait module)")
            ColourNote ("darkorange", "black", debug.traceback (thread))
            error (err)
          end -- if
        end
      end
    }
    helper.addTrigger {
      group = "status_id_done",
      regexp = REGEXP.ITEM_ID,
      response = function(name, line, wildcards)
        self:debug("ITEM_ID triggered")
        local name = wildcards[1]
        local ids = string.lower(wildcards[2])
        local id = utils.split(ids, ",")[1]
        if not self.items then
          self.items = {}
        end
        table.insert(self.items, Item:decorate {
          name = name,
          id = id,
          ids = ids
        })
      end
    }
    helper.addTrigger {
      group = "status_id_done",
      regexp = REGEXP.SYSTEM_BUSY,
      response = function()
        self:debug("SYSTEM_BUSY triggered")
        self.systemBusy = true
      end
    }
    -- inventory check
    helper.addTrigger {
      group = "status_inventory_start",
      regexp = helper.settingRegexp("status", "inventory_start"),
      response = function()
        helper.enableTriggerGroups("status_inventory_done")
      end
    }
    helper.addTrigger {
      group = "status_inventory_done",
      regexp = helper.settingRegexp("status", "inventory_done"),
      response = function()
        helper.disableTriggerGroups("status_inventory_done")
        local thread = self.waitThread
        if thread then
          self.waitThread = nil
          local ok, err = coroutine.resume(thread)
          if not ok then
            ColourNote ("deeppink", "black", "Error raised in trigger function (in wait module)")
            ColourNote ("darkorange", "black", debug.traceback (thread))
            error (err)
          end -- if
        end
      end
    }
    helper.addTrigger {
      group = "status_inventory_done",
      regexp = REGEXP.WEIGHT_RATE,
      response = function(name, line, wildcards)
        self:debug("载重查看触发", wildcards[1], wildcards[2])
        self.itemCount = helper.ch2number(wildcards[1])
        self.weightPercent = tonumber(wildcards[2])
      end
    }
    -- money check
    helper.addTrigger {
      group = "status_money_start",
      regexp = helper.settingRegexp("status", "money_start"),
      response = function()
        helper.enableTriggerGroups("status_money_done")
      end
    }
    helper.addTrigger {
      group = "status_money_done",
      regexp = helper.settingRegexp("status", "money_done"),
      response = function()
        helper.disableTriggerGroups("status_money_done")
        local thread = self.waitThread
        if thread then
          self.waitThread = nil
          local ok, err = coroutine.resume(thread)
          if not ok then
            ColourNote ("deeppink", "black", "Error raised in trigger function (in wait module)")
            ColourNote ("darkorange", "black", debug.traceback (thread))
            error (err)
          end -- if
        end
      end
    }
    helper.addTrigger {
      group = "status_money_done",
      regexp = REGEXP.GOLDS_DESC,
      response = function(name, line, wildcards)
        self.golds = helper.ch2number(wildcards[1])
      end
    }
    helper.addTrigger {
      group = "status_money_done",
      regexp = REGEXP.SILVERS_DESC,
      response = function(name, line, wildcards)
        self.silvers = helper.ch2number(wildcards[1])
      end
    }
    helper.addTrigger {
      group = "status_money_done",
      regexp = REGEXP.COINS_DESC,
      response = function(name, line, wildcards)
        self.coins = helper.ch2number(wildcards[1])
      end
    }
    helper.addTrigger {
      group = "status_money_done",
      regexp = REGEXP.MONEY_MISS_STOP_EVALUATION,
      response = function()
        self:debug("检查金钱时，阻止look miss触发其他条件")
      end,
      sequence = 1,  -- very high priority
      stopEvaluation = true  --
    }
    -- score check
    helper.addTrigger {
      group = "status_score_start",
      regexp = helper.settingRegexp("status", "score_start"),
      response = function()
        helper.enableTriggerGroups("status_score_done")
      end
    }
    helper.addTrigger {
      group = "status_score_done",
      regexp = helper.settingRegexp("status", "score_done"),
      response = function()
        helper.disableTriggerGroups("status_score_done")
        local thread = self.waitThread
        if thread then
          self.waitThread = nil
          local ok, err = coroutine.resume(thread)
          if not ok then
            ColourNote ("deeppink", "black", "Error raised in trigger function (in wait module)")
            ColourNote ("darkorange", "black", debug.traceback (thread))
            error (err)
          end -- if
        end
      end
    }
    helper.addTrigger {
      group = "status_score_done",
      regexp = REGEXP.TITLE_DESC,
      response = function(name, line, wildcards)
        self.title = string.gsub(wildcards[1], " ", "")
        self.rank = wildcards[2]
        self.name = wildcards[3]
        self.id = string.lower(wildcards[4])
      end
    }
    helper.addTrigger {
      group = "status_score_done",
      regexp = REGEXP.MURDEROUS_LEVEL,
      response = function(name, line, wildcards)
        if wildcards[1] == "正常" then
          self.murderousLevel = 0
        else
          self.murderousLevel = 1
        end
      end
    }
    -- skbrief check
    helper.addTrigger {
      group = "status_skbrief_start",
      regexp = helper.settingRegexp("status", "skbrief_start"),
      response = function()
        helper.enableTriggerGroups("status_skbrief_done")
      end
    }
    helper.addTrigger {
      group = "status_skbrief_done",
      regexp = helper.settingRegexp("status", "skbrief_done"),
      response = function()
        helper.disableTriggerGroups("status_skbrief_done")
        local thread = self.waitThread
        if thread then
          self.waitThread = nil
          local ok, err = coroutine.resume(thread)
          if not ok then
            ColourNote ("deeppink", "black", "Error raised in trigger function (in wait module)")
            ColourNote ("darkorange", "black", debug.traceback (thread))
            error (err)
          end -- if
        end
      end
    }
    helper.addTrigger {
      group = "status_skbrief_done",
      regexp = REGEXP.SKBRIEF,
      response = function(name, line, wildcards)
        self.skillLevel = tonumber(wildcards[1])
        self.skillPot = tonumber(wildcards[2])
      end
    }
    -- sk check
    helper.addTrigger {
      group = "status_sk_start",
      regexp = helper.settingRegexp("status", "sk_start"),
      response = function()
        helper.enableTriggerGroups("status_sk_done")
      end
    }
    helper.addTrigger {
      group = "status_sk_done",
      regexp = helper.settingRegexp("status", "sk_done"),
      response = function()
        helper.disableTriggerGroups("status_sk_done")
        local thread = self.waitThread
        if thread then
          self.waitThread = nil
          local ok, err = coroutine.resume(thread)
          if not ok then
            ColourNote ("deeppink", "black", "Error raised in trigger function (in wait module)")
            ColourNote ("darkorange", "black", debug.traceback (thread))
            error (err)
          end -- if
        end
      end
    }
    helper.addTrigger {
      group = "status_sk_done",
      regexp = REGEXP.SKILL_LIMIT,
      response = function(name, line, wildcards)
        self.skillCnt = helper.ch2number(wildcards[1])
        self.skillLimit = helper.ch2number(wildcards[2])
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("status")
    helper.addAlias {
      group = "status",
      regexp = REGEXP.ALIAS_STATUS_HP,
      response = function()
        return self:hpbrief()
      end
    }
    helper.addAlias {
      group = "status",
      regexp = REGEXP.ALIAS_STATUS_MONEY,
      response = function()
        return self:money()
      end
    }
    helper.addAlias {
      group = "status",
      regexp = REGEXP.ALIAS_STATUS_ID,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "id" then
          return self:id()
        else
          return self:idhere()
        end
      end
    }
    helper.addAlias {
      group = "status",
      regexp = REGEXP.ALIAS_STATUS_INVENTORY,
      response = function()
        return self:inventory()
      end
    }
    helper.addAlias {
      group = "status",
      regexp = REGEXP.ALIAS_STATUS_SCORE,
      response = function()
        return self:score()
      end
    }
    helper.addAlias {
      group = "status",
      regexp = REGEXP.ALIAS_STATUS_SHOW,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "hp" then
          self:showHp()
        elseif cmd == "items" then
          self:showItems()
        elseif cmd == "money" then
          self:showMoney()
        elseif cmd == "weight" then
          self:showInventory()
        elseif cmd == "sc" then
          self:showScore()
        else
          ColourNote("red", "", "unknown command:" .. cmd, 2)
        end
      end
    }
    helper.addAlias {
      group = "status",
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

  function prototype:doHpbrief()
    if self.waitThread then
      error("Previous thread is not disposed")
    end
    self.waitThread = assert(coroutine.running(), "Must be in coroutine")
    SendNoEcho("set status hpbrief_start")
    SendNoEcho("hpbrief")
    SendNoEcho("set status hpbrief_done")
    return coroutine.yield()
  end

  function prototype:doId(isHere)
    while true do
      if self.waitThread then
        error("Previous thread is not disposed")
      end
      self.waitThread = assert(coroutine.running(), "Must be in coroutine")

      SendNoEcho("set status id_start")
      if isHere then
        SendNoEcho("id here")
      else
        SendNoEcho("id")
      end
      SendNoEcho("set status id_done")
      -- ignore arguments
      coroutine.yield()
      if self.systemBusy then
        -- reset
        self.systemBusy = false
        self:debug("等待3秒重试")
        wait.time(3)
      else
        break
      end
    end
  end

  function prototype:doInventory()
    if self.waitThread then
      error("Previous thread is not disposed")
    end
    self.waitThread = assert(coroutine.running(), "Must be in coroutine")
    SendNoEcho("set status inventory_start")
    SendNoEcho("inventory")
    SendNoEcho("set status inventory_done")
    return coroutine.yield()
  end

  function prototype:doMoney()
    if self.waitThread then
      error("Previous thread is not disposed")
    end
    self.waitThread = assert(coroutine.running(), "Must be in coroutine")
    SendNoEcho("set status money_start")
    SendNoEcho("look gold")
    SendNoEcho("look silver")
    SendNoEcho("look coin")
    SendNoEcho("set status money_done")
    return coroutine.yield()
  end

  function prototype:doScore()
    if self.waitThread then
      error("Previous thread is not disposed")
    end
    self.waitThread = assert(coroutine.running(), "Must be in coroutine")
    SendNoEcho("set status score_start")
    SendNoEcho("score")
    SendNoEcho("set status score_done")
    return coroutine.yield()
  end

  function prototype:doSkbrief()
    assert(self.skill, "skill cannot be nil")
    if self.waitThread then
      error("Previous thread is not disposed")
    end
    self.waitThread = assert(coroutine.running(), "Must be in coroutine")
    SendNoEcho("set status skbrief_start")
    SendNoEcho("skbrief " .. self.skill)
    SendNoEcho("set status skbrief_done")
    return coroutine.yield()
  end

  function prototype:doSk()
    if self.waitThread then
      error("Previous thread is not disposed")
    end
    self.waitThread = assert(coroutine.running(), "Must be in coroutine")
    SendNoEcho("set status sk_start")
    SendNoEcho("sk")
    SendNoEcho("set status sk_done")
    return coroutine.yield()
  end

  function prototype:showHp()
    print("精：", self.currJing, "/", self.maxJing)
    print("气：", self.currQi, "/", self.maxQi)
    print("内力：", self.currNeili, "/", self.maxNeili)
    print("精力：", self.currJingli, "/", self.maxJingli)
    print("经验：", self.exp, "潜能：", self.pot)
    print("食物：", self.food, "饮水：", self.drink)
  end

  function prototype:showItems()
    if not self.items then
      print("无物品列表")
    else
      print("物品列表：")
      for _, item in pairs(self.items) do
        print("名称：", item.name, "ID：", item.id)
      end
    end
  end

  function prototype:showMoney()
    print("当前身上携带金额：")
    print("黄金：", self.golds)
    print("白银：", self.silvers)
    print("铜钱：", self.coins)
  end

  function prototype:showInventory()
    print("携带物品件数：", self.itemCount)
    print("负重百分比：", self.weightPercent)
  end

  function prototype:showScore()
    print("ID：", self.id)
    print("姓名：", self.name)
    print("阶级：", self.rank)
    print("头衔：", self.title)
    print("杀气：", self.murderousLevel)
  end

  function prototype:hpbrief()
    return self:fire(Events.HPBRIEF)
  end

  function prototype:id()
    return self:fire(Events.ID)
  end

  function prototype:idhere()
    return self:fire(Events.IDHERE)
  end

  function prototype:money()
    return self:fire(Events.MONEY)
  end

  function prototype:inventory()
    return self:fire(Events.INVENTORY)
  end

  function prototype:score()
    return self:fire(Events.SCORE)
  end

  function prototype:skbrief(skill)
    self.skill = skill
    return self:fire(Events.SKBRIEF)
  end

  function prototype:sk()
    return self:fire(Events.SK)
  end

  return prototype
end

return define_status():FSM()
