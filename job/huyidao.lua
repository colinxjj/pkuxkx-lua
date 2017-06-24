--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/5/7
-- Time: 21:40
-- To change this template use File | Settings | File Templates.
--

local patterns = {[[
38

ask hu about job
你向胡一刀打听有关『job』的消息。
胡一刀说道：『我收到消息，听说黄河南岸有盗宝人涂钦筇才(ansunk)找到了闯王宝藏的地图,你可否帮忙找回来！』
胡一刀朗声说道：「前路难行，多多珍重！」

> 倪五杰看见你，阴笑一声：天堂有路你不走，地狱无门你来投！
看起来倪五杰想杀死你！

    盗 宝 人 「狂暴龙」倪五杰(Phidass)

倪五杰说道：“你有种去洛阳找我兄弟仲孙可(fonk)，他会给我报仇的！”


你在攻击中不断积蓄攻势。(气势：12%)
魏八大说道：“你有种去临安府找我兄弟东门益(ladubk)，他会给我报仇的！”



-- 模式三

ask sui cong about 藏宝图
你向胡二打听有关『藏宝图』的消息。
我发现附近的小树林里面藏着一伙盗宝人，从他们身上可能会获得线索。我这就带你过去。
林间小道 -

    一条长满荒草的小道，前面似乎通向了一片小树林！
    「仲夏」: 一轮火红的夕阳正徘徊在西方的地平线上。

    这里唯一的出口是 east。

杨树林 -

    稀稀落落得长着南方常见的杨树和小灌木，茂盛的茅草大概有一个人多高，
四周似乎危机起伏，需要小心了。
    「仲夏」: 一轮火红的夕阳正徘徊在西方的地平线上。

    这里明显的出口是 northeast 和 west。
get map from corpse
你从贝杰的尸体身上搜出一片宝藏地图残片。
]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local combat = require "pkuxkx.combat"
local captcha = require "pkuxkx.captcha"

local define_huyidao = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    search = "search",
    kill = "kill",
    submit = "submit",
  }
  local Events = {
    STOP = "stop",  -- any state -> stop
    START = "start",  -- stop -> ask
    SEARCH = "search", -- ask -> search
    KILL = "kill",  -- search -> kill
    KILLED = "killed", -- kill -> search
    FINISHED = "finished",  -- kill -> submit
    FAILED = "failed",  -- search, kill -> submit
  }
  local REGEXP = {
    ALIAS_START = "^huyidao\\s+start\\s*$",
    ALIAS_STOP = "^huyidao\\s+stop\\s*$",
    ALIAS_DEBUG = "^huyidao\\s+debug\\s+(on|off)\\s*$",
    ALIAS_SEARCH = "^huyidao\\s+search\\s+(.*?)\\s+(.*?)\\s*$",
    ALIAS_XUNBAO = "^huyidao\\s+xunbao\\s+(.*?)\\s*$",
    ALIAS_MANUAL = "^^huyidao\\s+manual\\s+(on|off)\s*$",
    JOB_INFO = "^[ >]*胡一刀说道：『我收到消息，听说(.*?)有盗宝人(.*?)\\((.*?)\\)找到了闯王宝藏的地图,你可否帮忙找回来！』$",
    MAP_COUNT = "^\\( *(\\d+)\\) *宝藏地图残片\\(Map piece\\d+\\)$",
    GIVEN = "^[ >]*你给胡一刀一.*$",
    CAPTCHA = "^获得关于盗宝人的消息。$",
  }

  local JobRoomId = 38
  local ExcludedZones = {
    ["西湖梅庄"] = true,
    ["白驼山"] = true,
    ["北京"] = true,
    ["紫禁城"] = true,
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

    self:resetOnStop()
    self.DEBUG = true
  end

  function prototype:resetOnStop()
    self.dbrs = {}
  end

  function prototype:disableAllTriggers()

  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:resetOnStop()
        self:removeTriggerGroups("huyidao_one_shot")
        self:disableAllTriggers()
      end,
      exit = function() end
    }
    self:addState {
      state = States.ask,
      enter = function()
        helper.enableTriggerGroups("huyidao_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("huyidao_ask_start", "huyidao_ask_done")
      end
    }
    self:addState {
      state = States.search,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.kill,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.submit,
      enter = function()
        helper.enableTriggerGroups("huyidao_map_start", "huyidao_give_start")
      end,
      exit = function()
        helper.disableTriggerGroups("huyidao_map_start", "huyidao_map_done",
          "huyidao_give_start", "huyidao_give_done")
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
        return self:doGetJob()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<ask>
    self:addTransition {
      oldState = States.ask,
      newState = States.search,
      event = Events.SEARCH,
      action = function()
        return self:doSearch()
      end
    }
    self:addTransitionToStop(States.ask)
    -- transition from state<search>
    self:addTransition {
      oldState = States.search,
      newState = States.kill,
      event = Events.KILL,
      action = function()
        return self:doKill()
      end
    }
    self:addTransition {
      oldState = States.search,
      newState = States.submit,
      event = Events.FAILED,
      action = function()
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.search)
    -- transition from state<kill>
    self:addTransition {
      oldState = States.kill,
      newState = States.search,
      event = Events.KILLED,
      action = function()
        return self:doSearch()
      end
    }
    self:addTransition {
      oldState = States.kill,
      newState = States.submit,
      event = Events.FINISHED,
      action = function()
        return self:doSubmit()
      end
    }
    self:addTransition {
      oldState = States.kill,
      newState = States.submit,
      event = Events.FAILED,
      action = function()
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.kill)
    -- transition from state<submit>
    self:addTransitionToStop(States.submit)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "huyidao_ask_start", "huyidao_ask_done",
      "huyidao_map_start", "huyidao_map_done",
      "huyidao_give_start", "huyidao_give_done")
    helper.addTriggerSettingsPair {
      group = "huyidao",
      start = "ask_start",
      done = "ask_done",
    }
    helper.addTrigger {
      group = "huyidao_ask_done",
      regexp = REGEXP.JOB_INFO,
      response = function(name, line, wildcards)
        self:debug("JOB_INFO triggered")
        self.searchZoneName = wildcards[1]
        self.npcName = wildcards[2]
        self.npcId = string.lower(wildcards[3])
      end
    }
    helper.addTrigger {
      group = "huyidao_ask_done",
      regexp = REGEXP.CAPTCHA,
      response = function()
        self:debug("CAPTCHA triggered")
        self.needCaptcha = true
      end
    }
    helper.addTriggerSettingsPair {
      group = "huyidao",
      start = "map_start",
      done = "map_done",
    }
    helper.addTrigger {
      group = "huyidao_map_done",
      regexp = REGEXP.MAP_COUNT,
      response = function(name, line, wildcards)
        self:debug("MAP_CNT triggered")
        local cnt = tonumber(wildcards[1])
        if self.mapCnt < cnt then
          self.mapCnt = cnt
        end
      end
    }
    helper.addTriggerSettingsPair {
      group = "huyidao",
      start = "give_start",
      done = "give_done",
    }
    helper.addTrigger {
      group = "huyidao_give_done",
      regexp = REGEXP.GIVEN,
      response = function()
        self.giveSuccess = true
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("huyidao")
    helper.addAlias {
      group = "huyidao",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "huyidao",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "huyidao",
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
      group = "huyidao",
      regexp = REGEXP.ALIAS_SEARCH,
      response = function(name, line, wildcards)
        self.npcName = wildcards[1]
        self.searchZoneName = wildcards[2]
      end
    }
    helper.addAlias {
      group = "huyidao",
      regexp = REGEXP.ALIAS_XUNBAO,
      response = function(name, line, wildcards)
        travel:walktoFirst {
          fullname = wildcards[1]
        }
        travel:waitUntilArrived()
        wait.time(1)
        SendNoEcho("xunbao")
      end
    }
    helper.addAlias {
      group = "huyidao",
      regexp = REGEXP.ALIAS_MANUAL,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self.manual = true
        else
          self.manual = false
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

  function prototype:doGetJob()
    if self.currState ~= States.ask then
      return
    end
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    self:debug("等待1秒后询问任务")
    wait.time(1)
    self.searchZoneName = nil
    self.npcName = nil
    self.npcId = nil
    self.workTooFast = false
    self.prevNotFinish = false
    self.needCaptcha = false
    SendNoEcho("set huyidao ask_start")
    SendNoEcho("ask hu about job")
    SendNoEcho("set huyidao ask_done")
    helper.checkUntilNotBusy()
    if self.prevNotFinish then
      ColourNote("yellow", "", "上次任务未完成，取消后再进行询问")
      wait.time(1)
      SendNoEcho("ask hu about fail")
      wait.time(1)
      return self:doGetJob()
    elseif self.workTooFast then
      wait.time(5)
      return self:doGetJob()
    elseif self.needCaptcha then
      ColourNote("yellow", "", "请根据验证码手动输入huyidao search <人名> <地点>")
    elseif not self.searchZoneName then
      ColourNote("red", "", "无法获取到任务信息，任务失败")
      return self:doCancel()
    elseif ExcludedZones[self.searchZoneName] then
      return self:doAskHelp()
    else
      assert(self.npcName, "npc name cannot be nil")
      return self:fire(Events.SEARCH)
    end
  end

  function prototype:doAskHelp()
    self.searchZoneName = nil
    self.npcName = nil
    self.npcId = nil
    SendNoEcho("set huyidao ask_start")
    SendNoEcho("ask hu about help")
    SendNoEcho("set huyidao ask_done")
    helper.checkUntilNotBusy()
    if not self.searchZoneName then
      ColourNote("red", "", "无法获取到任务信息，任务失败")
      return self:doCancel()
    else
      return self:fire(Events.SEARCH)
    end
  end
  
  function prototype:doSearch()
    assert(self.npcName, "npc name cannot be nil")
    local zone = travel:getMatchedZone(self.searchZoneName)
    if ExcludedZones[self.searchZoneName] or not zone then
      ColourNote("red", "", "给定区域不可达，任务失败")
      return self:fire(Events.FAILED)
    end
    local centerRoomCode = zone.centercode
    local centerRoom = travel.roomsByCode[centerRoomCode]
    self:debug("行走至中心节点后遍历：", centerRoom.id)
    travel:walkto(centerRoom.id)
    travel:waitUntilArrived()
    self:debug("遍历寻找贼人", self.npcName, self.npcId)
    self.npcFound = false

    helper.addOneShotTrigger {
      group = "huyidao_one_shot",
      regexp = "^ *盗 宝 人.*?" .. self.npcName .. "\\((.*?)\\)$",
      response = function(name, line, wildcards)
        self:debug("DBR_FOUND triggered")
        -- 不同模式可能存在npcId未知，因此更新npcId
        self.npcId = string.lower(wildcards[1])
        self.npcFound = true
      end
    }
    local onStep = function()
      return self.npcFound
    end
    SendNoEcho("yun powerup")
    travel:traverseZone(zone.code, onStep)
    travel:waitUntilArrived()
    if self.npcFound then
      return self:fire(Events.KILL)
    else
      ColourNote("yellow", "", "未发现贼人，任务失败，检查现有地图残片并返回")
      return self:fire(Events.FAILED)
    end
  end

  function prototype:doKill()
    self.npcKilled = false
    self.jobFinished = false

    helper.addOneShotTrigger {
      group  = "huyidao_one_shot",
      regexp = "^[ >]*" .. self.npcName .. "说道：“你有种去(.*?)找我兄弟(.*?)\\((.*?)\\)，他会给我报仇的！”$",
      response = function(name, line, wildcards)
        if not self.dbrs then
          self.dbrs = {}
        end
        table.insert(self.dbrs, {
          name = self.npcName,
          id = self.npcId,
          zone = self.searchZoneName
        })
        self.searchZoneName = wildcards[1]
        self.npcName = wildcards[2]
        self.npcId = string.lower(wildcards[3])
        self.npcKilled = true
      end
    }
    helper.addOneShotTrigger {
      group = "huyidao_one_shot",
      regexp = "^[ >]*" .. self.npcName .. "长叹道：“人算不如天算，想不到我兄弟五人都栽在你的手中！”$",
      response = function()
        table.insert(self.dbrs, {
          name = self.npcName,
          id = self.npcId,
          zone = self.searchZoneName
        })
        self.npcKilled = true
        self.jobFinished = true
      end
    }

    combat:start()
    SendNoEcho("halt")
    SendNoEcho("yun recover")
    SendNoEcho("yun powerup")
    SendNoEcho("wield sword")
    SendNoEcho("killall " .. self.npcId)
    SendNoEcho("perform dugu-jiujian.poqi")
    -- 限定60秒解决战斗
    local waitTime = 0
    while not self.npcKilled and waitTime < 60 do
      self:debug("战斗时长：", waitTime)
      wait.time(5)
      waitTime = waitTime + 5
    end
    self:debug("战斗时长：", waitTime)
    helper.removeTriggerGroups("huyidao_one_shot")
    if self.jobFinished then
      if self.DEBUG then
        print("盗宝人已被全部杀死：")
        for i, npc in ipairs(self.dbrs) do
          print("盗宝人" .. i, npc.name, npc.id, npc.zone)
        end
      end
      combat:stop()
      return self:fire(Events.FINISHED)
    elseif self.npcKilled then
      combat:stop()
      return self:fire(Events.KILLED)
    else
      combat:stop()
      self:debug("战斗时间过长，任务失败")
      return self:fire(Events.FAILED)
    end
  end

  function prototype:doSubmit()
    self.mapCnt = 0

    helper.checkUntilNotBusy()
    SendNoEcho("halt")
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    wait.time(1)
    SendNoEcho("set huyidao map_start")
    SendNoEcho("i map piece")
    SendNoEcho("set huyidao map_done")
    helper.checkUntilNotBusy()
    if self.mapCnt == 0 then
      self:debug("一块地图碎片都没有找到，任务彻底失败")
      SendNoEcho("ask hu about fail")
      helper.checkUntilNotBusy()
      return self:fire(Events.STOP)
    elseif self.mapCnt < 5 then
      self:debug("存在少于5块地图碎片，任务部分完成")
      for i = 1, self.mapCnt do
        while true do
          self.giveSuccess = false
          SendNoEcho("set huyidao give_start")
          SendNoEcho("give map to hu")
          SendNoEcho("set huyidao give_done")
          helper.checkUntilNotBusy()
          if self.giveSuccess then
            break
          else
            wait.time(1)
          end
        end
        wait.time(1)
      end
      return self:fire(Events.STOP)
    else
      self:debug("地图随便已找齐，直接合并")
      SendNoEcho("combine map")
      helper.checkUntilNotBusy()
      while true do
        self.giveSuccess = false
        SendNoEcho("set huyidao give_start")
        SendNoEcho("give cangbao tu to hu")
        SendNoEcho("set huyidao give_done")
        helper.checkUntilNotBusy()
        if self.giveSuccess then
          break
        else
          wait.time(1)
        end
      end
      ColourNote("yellow", "", "使用chakan bao tu获取藏宝地点，寻宝可使用huyidao xunbao <地点>")
      return self:fire(Events.STOP)
    end
  end

  -- 仅在询问失败时执行
  function prototype:doCancel()
    if self.manual then
      ColourNote("red", "", "请手动取消任务")
    else
      travel:walkto(JobRoomId)
      wait.time(1)
      SendNoEcho("ask hu about fail")
      wait.time(1)
      helper.checkUntilNotBusy()
      return self:fire(Events.STOP)
    end
  end

  return prototype
end
return define_huyidao():FSM()
