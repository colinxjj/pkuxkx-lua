--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/7
-- Time: 19:59
--
-- try to use FSM to rewrite the job logic
--

require "wait"

-- import modules from pkuxkx
local pkuxkx = require "pkuxkx"
local FSM = pkuxkx.FSM
local helper = pkuxkx.helper
local locate = pkuxkx.locate
local walkto = pkuxkx.walkto

local huashan = {}

--huashan.li2yue = {"s", "se", "su", "eu", "su", "eu", "su", "su", "sd", "su", "s", "s" }
--huashan.yue2li = {"n", "n", "nd", "nu", "nd", "nd", "wd", "nd", "wd", "nd", "nw", "n"}

local define_patrol = function()
  local prototype = FSM.inheritedMeta()
  -- define own states and events
  local States = {
    stop = "stop",
    ask = "ask",
    work = "work",
    submit = "submit",
    wait_ask = "wait_ask",
    wait_submit = "wait_submit"
  }
  local Events = {
    START = "start",
    NO_JOB_AVAILABLE = "no_job_available",
    NEW_JOB = "new_job",
    PREV_JOB_NOT_FINISH = "prev_job_not_finish",
    WORK_DONE = "work_done",
    SUBMIT_ACCEPT = "submit_ok",
    WORK_MISS = "work_miss",
    WORK_TOO_FAST = "work_too_fast",
    PAUSE_WAIT = "pause_wait",
    STOP = "stop"
  }
  local Paths = {
    {path="n",name="练武场"},
    {path="n",name="玉女峰"},
    {path="e",name="玉女祠"},
    {path="sd",name="后山小路"},
    {path="sd",name="后山小路"},
    {path="sd",name="小院"},
    {path="nu",name="后山小路"},
    {path="nu",name="后山小路"},
    {path="nu",name="玉女祠"},
    {path="w",name="玉女峰"},
    {path="nd",name="镇岳宫"},
    {path="eu",name="朝阳峰"},
    {path="wd",name="镇岳宫"},
    {path="nu",name="苍龙岭"},
    {path="wu",name="舍身崖"},
    {path="ed",name="苍龙岭"},
    {path="nd",name="猢狲愁"},
    {path="nd",name="老君沟"},
    {path="nu",name="华山别院"},
    {path="sd",name="老君沟"},
    {path="wd",name="百尺峡"},
    {path="nd",name="千尺幢"},
    {path="wd",name="青柯坪"},
    {path="nd",name="莎萝坪"},
    {path="nw",name="华山脚下"},
    {path="n",name="玉泉院"}}
  local Rooms = {
    ["练武场"] = 1,
    ["玉女峰"] = 1,
    ["玉女祠"] = 1,
    ["后山小路"] = 2,
    ["小院"] = 1,
    ["镇岳宫"] = 1,
    ["朝阳峰"] = 1,
    ["苍龙岭"] = 1,
    ["舍身崖"] = 1,
    ["猢狲愁"] = 1,
    ["老君沟"] = 1,
    ["华山别院"] = 1,
    ["百尺峡"] = 1,
    ["千尺幢"] = 1,
    ["青柯坪"] = 1,
    ["莎萝坪"] = 1,
    ["华山脚下"] = 1,
    ["玉泉院"] = 1
  }

  prototype.regexp = {
    --ASK_YUE = "^[ >]*你向岳灵珊打听有关『job』的消息。$",
    NEW_JOB="^[ >]*岳灵珊拿出一张地图，把华山需要巡逻的区域用不同颜色标注出来，并和你说了一遍。$",
    PREV_JOB_NOT_FINISH = "^[ >]*岳灵珊说道：「你上次任务还没有完成呢！」$",
    NEXT_JOB_WAIT = "^[ >]*岳灵珊说道：「等你忙完再来找我吧。」$",
    NEXT_JOB_TOO_FAST = "^[ >]*岳灵珊说道：「等你忙完再来找我吧。」$",
    ASK_START = "^[ >]*设定环境变量：huashan_patrol = \"ask_start\"$",
    ASK_DONE = "^[ >]*设定环境变量：huashan_patrol = \"ask_done\"$",
    PATROLLING="^[ >]*你在(.+?)巡弋，尚未发现敌踪。$",    -- used in wait.regexp
    WORK_DONE="^[ >]*设定环境变量：huashan_patrol = \"work_done\"$",
    REJECT_LING="^[ >]*岳灵珊不想要令牌，你就自个留着吧。$",
    ACCEPT_LING="^[ >]*你给岳灵珊一块令牌。$",
    SUBMIT_START = "^[ >]*设定环境变量：huashan_patrol = \"submit_start\"$",
    SUBMIT_DONE = "^[ >]*设定环境变量：huashan_patrol = \"submit_done\"$",
    NOT_BUSY = "^[ >]*你现在不忙。$",
    DZ_FINISH = "^[ >]*(你感觉内力充盈，显然内功又有进境。|你将运转于任督二脉间的内息收回丹田，深深吸了口气，站了起来。)$",
    DZ_NEILI_ADDED = "^[ >]*你的内力增加了！！$"
  }

  function prototype:FSM()
    local obj = FSM:new()
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self.DEBUG = false
    self:initStates()
    self:initTransitions()
    self:initTriggers()
    self:initAliases()
    -- set state to stop by default
    self:setState(States.stop)
    self.eventToSend = nil
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        -- disable all triggers
        helper.disableTriggerGroups(
          "huashan_patrol_ask_start",
          "huashan_patrol_ask_done",
          "huashan_patrol_work",
          "huashan_patrol_submit_start",
          "huashan_patrol_submit_done",
          "huashan_patrol_wait_ask",
          "huashan_patrol_wait_submit")
      end,
      exit = function() end
    }
    self:addState {
      state = States.ask,
      enter = function()
        helper.disableTriggerGroups("huashan_patrol_ask_done")
        helper.enableTriggerGroups("huashan_patrol_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups(
          "huashan_patrol_ask_start",
          "huashan_patrol_ask_done")
      end
    }
    self:addState {
      state = States.work,
      enter = function()
        helper.enableTriggerGroups("huashan_patrol_work")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_patrol_work")
      end
    }
    self:addState {
      state = States.submit,
      enter = function()
        helper.disableTriggerGroups("huashan_patrol_submit_done")
        helper.enableTriggerGroups("huashan_patrol_submit_start")
      end,
      exit = function()
        helper.disableTriggerGroups(
          "huashan_patrol_submit_start",
          "huashan_patrol_submit_done")
      end
    }
    self:addState {
      state = States.wait_ask,
      enter = function()
        helper.enableTriggerGroups("huashan_patrol_wait_ask")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_patrol_wait_ask")
      end
    }
    self:addState {
      state = States.wait_submit,
      enter = function()
        helper.enableTriggerGroups("huashan_patrol_wait_submit")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_patrol_wait_submit")
      end
    }
  end

  local addTransitionToStop = function(self, fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function()
        print("停止巡逻任务 - 当前状态", self.currState)
      end
    }
  end

  function prototype:initTransitions()
    -- transitions from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.ask,
      event = Events.START,
      action = function()
        locate:clearRoomInfo()
        -- 岳灵珊在华山客厅2916
        walkto:walkto(2916, function()
          self:doAsk()
        end)
      end
    }
    -- transitions from state<ask>
    self:addTransition {
      oldState = States.ask,
      newState = States.work,
      event = Events.NEW_JOB,
      action = function()
        -- 仅在获得新任务时，加载房间列表
        self:reloadRooms()
        self:doWork()
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.wait_ask,
      event = Events.NO_JOB_AVAILABLE,
      action = function()
        locate:clearRoomInfo()
        -- 在练功室2921打坐等待ask
        walkto:walkto(2921, function()
          SendNoEcho("dz max")
        end)
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.work,
      event = Events.PREV_JOB_NOT_FINISH,
      action = function() self:doWork() end
    }
    addTransitionToStop(self, States.ask)
    -- transitions from state<work>
    self:addTransition {
      oldState = States.work,
      newState = States.submit,
      event = Events.WORK_DONE,
      action = function()
        locate:clearRoomInfo()
        -- 前往客厅交任务
        walkto:walkto(2916, function()
          self:doSubmit()
        end)
      end
    }
    addTransitionToStop(self, States.work)
    -- transitions from state<submit>
    self:addTransition {
      oldState = States.submit,
      newState = States.ask,
      event = Events.SUBMIT_ACCEPT,
      action = function()
        -- 就在当前房间
        self:doAsk()
      end
    }
    self:addTransition {
      oldState = States.submit,
      newState = States.work,
      event = Events.WORK_MISS,
      action = function()
        self:doWork()
      end
    }
    self:addTransition {
      oldState = States.submit,
      newState = States.wait_submit,
      event = Events.WORK_TOO_FAST,
      action = function()
        locate:clearRoomInfo()
        -- 在练功室2921打坐等待submit
        walkto:walkto(2921, function()
          SendNoEcho("dz max")
        end)
      end
    }
    addTransitionToStop(self, States.submit)
    -- transitions from state<wait_ask>
    self:addTransition {
      oldState = States.wait_ask,
      newState = States.ask,
      event = Events.PAUSE_WAIT,
      action = function()
        locate:clearRoomInfo()
        -- 尝试再次询问
        walkto:walkto(2916, function()
          self:doAsk()
        end)
      end
    }
    addTransitionToStop(self, States.wait_ask)
    -- transitions from state<wait_submit>
    self:addTransition {
      oldState = States.wait_submit,
      newState = States.submit,
      event = Events.PAUSE_WAIT,
      action = function()
        locate:clearRoomInfo()
        -- 尝试再次提交
        walkto:walkto(2916, function()
          self:doSubmit()
        end)
      end
    }
    addTransitionToStop(self, States.wait_submit)
  end

  function prototype:assureNotBusy()
    while true do
      SendNoEcho("halt")
      -- busy or wait for 3 seconds to resend
      local line = wait.regexp(self.regexp.NOT_BUSY, 3)
      if line then break end
    end
  end

  function prototype:doAsk()
    SendNoEcho("set huashan_patrol ask_start")
    SendNoEcho("ask yue about job")
    SendNoEcho("set huashan_patrol ask_done")
  end

  function prototype:doSubmit()
    SendNoEcho("set huashan_patrol submit_start")
    SendNoEcho("give yue ling")
    SendNoEcho("set huashan_patrol submit_done")
  end

  function prototype:doWork()
    self:debug("加载巡逻路径")
    self:reloadPaths()
    self:debug("开始巡逻")
    while #(self.paths) > 0 do
      local next = table.remove(self.paths)
      -- 到达下一个房间，此处有强假设，到达下一个房间不会失败
      self:assureNotBusy()
      SendNoEcho(next.path)
      if self.rooms[next.name] and self.rooms[next.name] > 0 then
        self:debug("首次进入巡逻房间，等待巡逻命令")
        -- wait at most 10 seconds for the notion
        local _, wildcards = wait.regexp(self.regexp.PATROLLING, 8)
        if wildcards and wildcards[1] then
          local currRoom = wildcards[1]
          if self.rooms[currRoom] and self.rooms[currRoom] > 0 then
            self.rooms[currRoom] = self.rooms[currRoom] - 1
          end
        else
          print("该地区应当显示巡逻提示但没有显示！")
        end
      end
    end
    self:debug("巡逻遍历完成")
    wait.time(1)
    SendNoEcho("set huashan_patrol work_done")
  end

  function prototype:reloadRooms()
    self.rooms = {}
    for k, v in pairs(Rooms) do
      self.rooms[k] = v
    end
  end

  function prototype:reloadPaths()
    -- copy and reverse paths
    self.paths = {}
    for i = #(Paths),1,-1 do
      table.insert(self.paths, Paths[i])
    end
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "huashan_patrol_ask_start", "huashan_patrol_ask_done",
      "huashan_patrol_work",
      "huashan_patrol_submit_start", "huashan_patrol_submit_done",
      "huashan_patrol_wait_ask", "huashan_patrol_wait_submit"
    )

    helper.addTrigger {
      group = "huashan_patrol_ask_start",
      regexp = self.regexp.ASK_START,
      response = function()
        self:debug("ASK_START triggered")
        helper.enableTriggerGroups("huashan_patrol_ask_done")
      end
    }
    -- ask result can be 3 types, so store the
    helper.addTrigger {
      group = "huashan_patrol_ask_done",
      regexp = self.regexp.NEW_JOB,
      response = function()
        self:debug("NEW_JOB triggered")
        self.eventToSend = Events.NEW_JOB
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_ask_done",
      regexp = self.regexp.PREV_JOB_NOT_FINISH,
      response = function()
        self:debug("PREV_JOB_NOT_FINISH triggered")
        self.eventToSend = Events.PREV_JOB_NOT_FINISH
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_ask_done",
      regexp = self.regexp.NEXT_JOB_WAIT,
      response = function()
        self:debug("NEXT_JOB_WAIT triggered")
        self.eventToSend = Events.NEXT_JOB_WAIT
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_ask_done",
      regexp = self.regexp.ASK_DONE,
      response = function()
        self:debug("ASK_DONE triggered")
        if not self.eventToSend then
          print("出错，没有获取到任务询问结果")
          self.eventToSend = nil
        else
          local event = self.eventToSend
          self.eventToSend = nil
          self:fire(event)
        end
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_work",
      regexp = self.regexp.WORK_DONE,
      response = function()
        self:debug("WORK_DONE triggered")
        self:fire(Events.WORK_DONE)
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_submit_start",
      regexp = self.regexp.SUBMIT_START,
      response = function()
        self:debug("SUBMIT_START triggered")
        helper.enableTriggerGroups("huashan_patrol_submit_done")
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_submit_done",
      regexp = self.regexp.REJECT_LING,
      response = function()
        local allPatrolled = true
        for room, cnt in pairs(self.rooms) do
          if cnt > 0 then
            print("发现有房间未巡逻到", room)
            allPatrolled = false
            break
          end
        end
        if not allPatrolled then
          print("有部分区域没有巡逻到，重新巡逻")
          self:fire(Events.WORK_MISS)
        else
          print("巡逻时间太快，尝试打坐等待")
          self:fire(Events.WORK_TOO_FAST)
        end
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_submit_done",
      regexp = self.regexp.ACCEPT_LING,
      response = function()
        self:fire(Events.SUBMIT_ACCEPT)
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_submit_done",
      regexp = self.regexp.SUBMIT_DONE,
      response = function()
        if not self.eventToSend then
          print("出错，没有获取到任务提交结果")
          self.eventToSend = nil
        else
          local event = self.eventToSend
          self.eventToSend = nil
          self:fire(self.eventToSend)
        end
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_wait_ask",
      regexp = self.regexp.DZ_FINISH,
      response = function()
        SendNoEcho("dz max")
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_wait_ask",
      regexp = self.regexp.DZ_NEILI_ADDED,
      response = function()
        self:fire(Events.PAUSE_WAIT)
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_wait_submit",
      regexp = self.regexp.DZ_FINISH,
      response = function()
        SendNoEcho("dz max")
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_wait_submit",
      regexp = self.regexp.DZ_NEILI_ADDED,
      response = function()
        self:fire(Events.PAUSE_WAIT)
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("huashan_patrol")

    helper.addAlias {
      group = "huashan_patrol",
      regexp = "^patrol$",
      response = function()
        print("PATROL华山新手巡逻任务，用法如下：")
        print("patrol start", "开始巡逻")
        print("patrol stop", "完成当前任务后，停止巡逻")
        print("patrol debug on/off", "开启/关闭巡逻调试模式")
      end
    }

    helper.addAlias {
      group = "huashan_patrol",
      regexp = "^patrol\\s+start\\s*",
      response = function()
        -- 手动开始时，总是重新加载房间
        self:reloadRooms()
        self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "huashan_patrol",
      regexp = "^patrol\\s+stop\\s*$",
      response = function()
        self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "huashan_patrol",
      regexp = "^patrol\\s+debug\\s+(on|off)\\s*$",
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self:debugOn()
        elseif cmd == "off" then
          self:debugOff()
        end
      end
    }
  end

  return prototype
end
huashan.patrol = define_patrol().FSM()

return huashan


