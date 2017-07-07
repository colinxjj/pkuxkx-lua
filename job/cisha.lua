--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/5/7
-- Time: 22:37
-- To change this template use File | Settings | File Templates.
--

local patterns = {[[
975

你向孟之经打听有关『job』的消息。
孟之经说道：「我给你的你上一个任务还没完成呢。」

孟之经说道：「这里人多眼杂，你先到江南小道等候，我自会通知你。」

> 孟之经托付都府内常随送给了你一页密码。
孟之经(meng zhijing)告诉你：第一个字在：第八行，第十列。第二个字在：第一行，第十列。第三个字在：第九行，第七列。对照(duizhao)这页，你就知道你要刺杀的人在哪了。

duizhao
你背着众人，悄悄地打开了旧纸。

殺1 2 3 4 5 6 7 8 9 1011
1 疆城襄阜丝府江后明驼帮
2 曲天山平村临西岳寨凉湖
3 湖王手岳真龙山兴府苗山
4 福府曲洛曲襄城丝源中王
5 江中府昆康容嵋嵋目白北
6 北临府山花原阜大安城曲
7 安家河府安谷平临教泉庄
8 城寺清州西武路府丝白麒
9 长山寺州天目山西慕成安

> 你定睛一看，彭晓峦正是你要找的汉奸卖国贼！
东街
    大元 建康府南城路安抚副使 彭晓峦(Peng xiaoluan)

大元 建康府南城路招讨副使 顾杰(Gu jie)

你向董波冲打听有关『fight』的消息。
董波冲说道：「你怕了吗？」

上官年往东落荒而逃了。

恭喜！你完成了都统制府行刺任务！

]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local combat = require "pkuxkx.combat"
local captcha = require "pkuxkx.captcha"

local define_cisha = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    ask = "ask",
    wait = "wait",
    search = "search",
    kill = "kill",
    submit = "submit"
  }
  local Events = {
    STOP = "stop",
    START = "start",
    WAIT = "wait",
    ZONE_CONFIRMED = "zone_confirmed",
    KILL = "kill",
    KILLED = "killed",
  }
  local REGEXP = {
    ALIAS_START = "^cisha\\s+start\\s*$",
    ALIAS_STOP = "^cisha\\s+stop\\s*$",
    ALIAS_DEBUG = "^cisha\\s+debug\\s+(on|off)\\s*$",
    ALIAS_DUIZHAO = "^cisha\\s+duizhao\\s+([0-9,]+?)$",
    JOB_WAIT_LOCATION = "^[ >]*孟之经说道：「这里人多眼杂，你先到(.*?)等候，我自会通知你。」$",
    WORK_TOO_FAST = "^[ >]*孟之经说道：「你上次大发神威之后，汉奸们都大多不敢出头了，过段时间再来吧.*」$",
    PREV_NOT_FINISH = "^[ >]*孟之经说道：「我给你的你上一个任务还没完成呢。」$",
    HINT = "^[ >]*孟之经\\(meng zhijing\\)告诉你：(.*)对照\\(duizhao\\)这页，你就知道你要刺杀的人在哪了。$",
    DUIZHAO_MAP = "^(\\d+) *(.+)$",
    FOUND = "^[ >]*你定睛一看，(.*?)正是你要找的汉奸卖国贼！$",
    -- TITLE_NAME = "^[ >]*大元.*?(?:招讨|安抚|宣抚)副使 *(.*?)\\((.*?)\\)$",
    TITLE_NAME = "^[ >]*大元.*?副使 *(.*?)\\((.*?)\\)$",
    FINISHED = "^[ >]*恭喜！你完成了都统制府行刺任务！$",
    GARBAGE = "^[ >]*你获得了.*份(石炭|玄冰|陨铁)【.*?】。$",
    MINGJIAO_WEAPON = "^ *□手持.*?圣火令\\(.*?\\)$",
    CAPTCHA = "^[ >]*请注意，忽略验证码中的红色文字。$",
  }
  local JobRoomId = 975

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

    self.precondition = {
      jing = 1,
      qi = 1,
      neili = 1.4,
      jingli = 1
    }

    self.DEBUG = true
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
      "cisha_ask_start", "cisha_ask_done",
      "cisha_wait",
      "cisha_duizhao_start", "cisha_duizhao_done",
      "cisha_search",
      "cisha_kill",
      "cisha_look_start", "cisha_look_done",
      "cisha_submit")
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        helper.removeTriggerGroups("cisha_one_shot")
        self:disableAllTriggers()
        SendNoEcho("set jobs job_done")
      end,
      exit = function() end
    }
    self:addState {
      state = States.ask,
      enter = function()
        helper.enableTriggerGroups("cisha_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("cisha_ask_start", "cisha_ask_done")
      end
    }
    self:addState {
      state = States.wait,
      enter = function()
        helper.enableTriggerGroups("cisha_wait", "cisha_duizhao_start")
      end,
      exit = function()
        helper.disableTriggerGroups("cisha_wait", "cisha_duizhao_start", "cisha_duizhao_done")
      end
    }
    self:addState {
      state = States.search,
      enter = function()
        helper.enableTriggerGroups("cisha_search")
      end,
      exit = function()
        helper.disableTriggerGroups("cisha_search")
      end
    }
    self:addState {
      state = States.kill,
      enter = function()
        helper.enableTriggerGroups("cisha_kill", "cisha_look_start")
      end,
      exit = function()
        helper.disableTriggerGroups("cisha_kill", "cisha_look_start", "cisha_look_done")
      end
    }
    self:addState {
      state = States.submit,
      enter = function()
        helper.enableTriggerGroups("cisha_submit")
      end,
      exit = function()
        helper.disableTriggerGroups("cisha_submit")
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
      newState = States.wait,
      event = Events.WAIT,
      action = function()
        assert(self.waitRoomId, "wait room id cannot be nil")
        return self:doWait()
      end
    }
    self:addTransitionToStop(States.ask)
    -- transition from state<wait>
    self:addTransition {
      oldState = States.wait,
      newState = States.search,
      event = Events.ZONE_CONFIRMED,
      action = function()
        assert(self.searchZone, "search zone cannot be nil")
        return self:doSearch()
      end
    }
    self:addTransitionToStop(States.wait)
    -- transition from state<search>
    self:addTransition {
      oldState = States.search,
      newState = States.kill,
      event = Events.KILL,
      action = function()
        return self:doKill()
      end
    }
    self:addTransitionToStop(States.search)
    -- transition from state<kill>
    self:addTransition {
      oldState = States.kill,
      newState = States.submit,
      event = Events.KILLED,
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
      "cisha_ask_start", "cisha_ask_done", "cisha_wait",
      "cisha_duizhao_start", "cisha_duizhao_done", "cisha_search",
      "cisha_kill", "cisha_look_start", "cisha_look_done",
      "cisha_submit")
    helper.addTriggerSettingsPair {
      group = "cisha",
      start = "ask_start",
      done = "ask_done"
    }
    helper.addTrigger {
      group = "cisha_ask_done",
      regexp = REGEXP.JOB_WAIT_LOCATION,
      response = function(name, line, wildcards)
        local rooms = travel:getMatchedRooms {
          name = wildcards[1],
          zone = "建康府"
        }
        if rooms and #rooms > 0 then
          self.waitRoomId = rooms[1].id
        end
      end
    }
    helper.addTrigger {
      group = "cisha_ask_done",
      regexp = REGEXP.WORK_TOO_FAST,
      response = function()
        self:debug("WORK_TOO_FAST triggered")
        self.workTooFast = true
      end
    }
    helper.addTrigger {
      group = "cisha_ask_done",
      regexp = REGEXP.PREV_NOT_FINISH,
      response = function()
        self:debug("PREV_NOT_FINISH triggered")
        self.prevNotFinish = true
      end
    }
    helper.addTrigger {
      group = "cisha_wait",
      regexp = REGEXP.HINT,
      response = function(name, line, wildcards)
        self:debug("HINT triggered")
        local rawHint = wildcards[1]
        for _, c in ipairs({"一", "二", "三", "四", "五"}) do
          local s, e, rowChr, columnChr = string.find(rawHint, "第" .. c .. "个字在：第(.-)行，第(.-)列。")
          if rowChr and columnChr then
            if not self.hint then
              self.hint = {}
            end
            table.insert(self.hint, {
              row = helper.ch2number(rowChr),
              column = helper.ch2number(columnChr)
            })
          end
        end
      end
    }
    helper.addTrigger {
      group = "cisha_wait",
      regexp = REGEXP.CAPTCHA,
      response = function(name, line, wildcards)
        self:debug("CAPTCHA triggered")
        self.needCaptcha = true
      end
    }
    helper.addTriggerSettingsPair {
      group = "cisha",
      start = "duizhao_start",
      done = "duizhao_done"
    }
    helper.addTrigger {
      group = "cisha_duizhao_done",
      regexp = REGEXP.DUIZHAO_MAP,
      response = function(name, line, wildcards)
        local rowId = tonumber(wildcards[1])
        local text = wildcards[2]
        if not self.duizhaoMap then
          self.duizhaoMap = {}
        end
        self.duizhaoMap[rowId] = text
      end
    }
    helper.addTrigger {
      group = "cisha_search",
      regexp = REGEXP.FOUND,
      response = function(name, line, wildcards)
        self:debug("FOUND triggered")
        self.npcName = wildcards[1]
      end
    }
    helper.addTrigger {
      group = "cisha_search",
      regexp = REGEXP.TITLE_NAME,
      response = function(name, line, wildcards)
        self:debug("TITLE_NAME triggered")
        if self.searching then
          if self.npcName then
            if self.npcName == wildcards[1] then
              self.npcId = string.lower(wildcards[2])
              self:debug("贼人ID为：", self.npcId)
              self.npcFound = true
            else
              self:debug("这是别人的贼人，目标名称：", self.npcName)
            end
          else
            self:debug("这是别人的贼人，目标还未遭遇")
          end
        else
          self:debug("不在搜索过程中，忽略该贼人")
        end
      end
    }
    helper.addTrigger {
      group = "cisha_kill",
      regexp = REGEXP.FINISHED,
      response = function()
        self:debug("FINISHED triggered")
        self.finished = true
      end
    }
    helper.addTrigger {
      group = "cisha_submit",
      regexp = REGEXP.GARBAGE,
      response = function(name, line, wildcards)
        local item = wildcards[1]
        if item == "石炭" then
          SendNoEcho("drop shi tan")
        elseif item == "玄冰" then
          SendNoEcho("drop xuan bing")
        elseif item == "陨铁" then
          SendNoEcho("drop yun tie")
        end
      end
    }
    helper.addTriggerSettingsPair {
      group = "cisha",
      start = "look_start",
      done = "look_done"
    }
    helper.addTrigger {
      group = "cisha_look_done",
      regexp = REGEXP.MINGJIAO_WEAPON,
      response = function()
        self:debug("MINGJIAO_WEAPON triggered")
        self.npcMingjiao = true
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("cisha")
    helper.addAlias {
      group = "cisha",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "cisha",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "cisha",
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
      group = "cisha",
      regexp = REGEXP.ALIAS_DUIZHAO,
      response = function(name, line, wildcards)
        self.hint = {}
        local ns = utils.split(wildcards[1], ",")
        for i = 1, #(ns), 2 do
          table.insert(self.hint, {
            row = tonumber(ns[i]),
            column = tonumber(ns[i + 1])
          })
        end
        return self:doDuizhao()
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
    self.waitRoomId = nil
    self.workTooFast = false
    self.prevNotFinish = false
    SendNoEcho("set cisha ask_start")
    SendNoEcho("ask meng about job")
    SendNoEcho("set cisha ask_done")
    helper.checkUntilNotBusy()
    if self.prevNotFinish then
      ColourNote("yellow", "", "上次任务未完成，取消后再进行询问")
      wait.time(1)
      SendNoEcho("ask meng about finish")
      SendNoEcho("ask meng about fail")
      wait.time(1)
      return self:doGetJob()
    elseif self.workTooFast then
      wait.time(5)
      return self:doGetJob()
    elseif not self.waitRoomId then
      ColourNote("无法获取到等待房间，任务失败")
      return self:doCancel()
    else
      return self:fire(Events.WAIT)
    end
  end

  function prototype:doWait()
    self.needCaptcha = false
    travel:walkto(self.waitRoomId)
    travel:waitUntilArrived()
    SendNoEcho("yun recover")
    SendNoEcho("dazuo max")
    self.hint = nil
    local waitTime = 0
    while not self.needCaptcha and not self.hint do
      self:debug("等待密语提示", waitTime)
      wait.time(5)
      waitTime = waitTime + 5
    end
    if self.needCaptcha then
      ColourNote("yellow", "", "请手动输入需要对照的行列数cisha duizhao <c1>,<r1>,<c2>,<r2>,...")
      return
    elseif self.DEBUG then
      print("已获取提示信息：")
      for i, h in ipairs(self.hint) do
        print("第" .. i .. "字：", "r" .. h.row, "c" .. h.column)
      end
    end
    return self:doDuizhao()
  end

  function prototype:doDuizhao()
    assert(self.hint, "hint cannot be nil")
    self.duizhaoMap = nil
    SendNoEcho("halt")
    SendNoEcho("set cisha duizhao_start")
    SendNoEcho("duizhao")
    SendNoEcho("set cisha duizhao_done")
    helper.checkUntilNotBusy()
    local zoneWords = {}
    for i, h in ipairs(self.hint) do
      local text = self.duizhaoMap[h.row]
      local word = string.sub(text, h.column * 2 - 1, h.column * 2)
      table.insert(zoneWords, word)
    end
    local searchZoneName = table.concat(zoneWords, "")
    self:debug("搜索区域名称为：", searchZoneName)
    self.searchZone = travel:getMatchedZone(searchZoneName)
    if not self.searchZone then
      ColourNote("red", "", "指定搜索区域不可达，任务失败")
      return self:doCancel()
    else
      return self:fire(Events.ZONE_CONFIRMED)
    end
  end

  function prototype:doSearch()
    self.npcName = nil
    self.npcId = nil

    -- 行走到中心节点然后遍历
    local centerCode = self.searchZone.centercode
    local centerRoom = travel.roomsByCode[centerCode]
    self:debug("前进至区域中心节点后遍历：", centerRoom.id)
    travel:walkto(centerRoom.id)
    travel:waitUntilArrived()
    self:debug("到达中心节点，当前贼人名：", self.npcName)

    self.searching = true
    self.npcFound = false
    local onStep = function()
      return self.npcFound
    end
    travel:traverseZone(self.searchZone.code, onStep)
    travel:waitUntilArrived()
    self.searching = false
    if self.npcFound then
      self:debug("发现贼人，杀之")
      return self:fire(Events.KILL)
    else
      self:debug("未发现贼人，任务失败")
      return self:doCancel()
    end
  end

  function prototype:doKill()
    self.finished = false
    self.npcMingjiao = false
    self:debug("检查敌手是否是明教")
    SendNoEcho("set cisha look_start")
    SendNoEcho("look " .. self.npcId)
    SendNoEcho("set cisha look_done")
    helper.checkUntilNotBusy()
    if self.npcMingjiao then
      self:debug("敌人是明教，使用化学攻击")
      if combat.defaultPFM == "qizong" then
        combat:start("qizong-mingjiao")
      elseif combat.defaultPFM == "jianzong" then
        combat:start("jianzong-mingjiao")
      else
        combat:start()
      end
    else
      self:debug("敌人不是明教，使用通常攻击")
      combat:start()
    end
    SendNoEcho("follow " .. self.npcId)
    SendNoEcho("yun powerup")
    SendNoEcho("ask " .. self.npcId .. " about fight")
    SendNoEcho("killall " .. self.npcId)
    local waitTime = 0
    while not self.finished do
      self:debug("等待完成", waitTime)
      SendNoEcho("ask " .. self.npcId .. " about fight")
      SendNoEcho("killall " .. self.npcId)
      wait.time(5)
      waitTime = waitTime + 5
    end
    SendNoEcho("follow none")
    SendNoEcho("halt")
    combat:stop()
    return self:fire(Events.KILLED)
  end

  function prototype:doSubmit()
    travel:stop()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    self:debug("等到1秒后提交")
    wait.time(1)
    SendNoEcho("ask meng about finish")
    helper.checkUntilNotBusy()
    return self:fire(Events.STOP)
  end

  function prototype:doCancel()
    travel:walkto(JobRoomId)
    travel:waitUntilArrived()
    wait.time(1)
    SendNoEcho("ask meng about fail")
    wait.time(1)
    return self:fire(Events.STOP)
--    ColourNote("red", "", "手动进行取消")
  end

  function prototype:doStart()
    return self:fire(Events.START)
  end

  return prototype
end
return define_cisha():FSM()
