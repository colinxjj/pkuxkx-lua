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
local helper = pkuxkx.helper
local locate = pkuxkx.locate
local walkto = pkuxkx.walkto

local huashan = {}

--huashan.li2yue = {"s", "se", "su", "eu", "su", "eu", "su", "su", "sd", "su", "s", "s" }
--huashan.yue2li = {"n", "n", "nd", "nu", "nd", "nd", "wd", "nd", "wd", "nd", "nw", "n"}

local define_patrol = function()
  local prototype = {}
  prototype.__index = prototype
  -- implement FSM
  local State = {
    stop = "stop",
    ask = "ask",
    work = "work",
    submit = "submit",
    wait_ask = "wait_ask",
    wait_submit = "wait_submit"
  }
  local Event = {
    START = "start",
    NO_JOB_AVAILABLE = "no_job_available",
    GOT_JOB = "got_job",
    PREV_JOB_NOT_FINISH = "prev_job_not_finish",
    WORK_DONE = "work_done",
    SUBMIT_ACCEPT = "submit_ok",
    WORK_MISS = "work_miss",
    WORK_TOO_FAST = "work_too_fast",
    STOP = "stop"
  }

  prototype._paths = {
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
  prototype._rooms = {
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
  prototype._delay = 1
  prototype.regexp = {
    ASK_YUE = "^[ >]*你向岳灵珊打听有关『job』的消息。$",
    GOT_JOB="^[ >]*岳灵珊拿出一张地图，把华山需要巡逻的区域用不同颜色标注出来，并和你说了一遍。$",
    PREV_JOB_REMAINED = "^[ >]*岳灵珊说道：「你上次任务还没有完成呢！」$",
    NEXT_JOB_WAIT = "^[ >]*岳灵珊说道：「等你忙完再来找我吧。」$",
    PATROLLING="^[ >]*你在(.+?)巡弋，尚未发现敌踪。$",
    GO="^[ >]*设定环境变量：huashan_patrol = \"go\"",
    POTENTIAL_ROOM="^[ >]*([^ ]+)$",
    REJECT_LING="^[ >]*岳灵珊不想要令牌，你就自个留着吧。",
    ACCEPT_LING="^[ >]*你给岳灵珊一块令牌。$",
    SUBMIT_END = "^[ >]*设定环境变量：huashan_patrol = \"submit_end\"",
    BUSY_CHECK = "^[ >]*你现在不忙。$",
    DZ_FINISH = "^[ >]*你感觉内力充盈，显然内功又有进境。$",
    DZ_NEILI_ADDED = "^[ >]*你的内力增加了！！$"
  }

  function prototype:FSM()
    local obj = {}
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self.DEBUG = false
    self.currState = self.state.stop
    self.eventToSend = nil
    self.transitions = {}
    for _, state in State do self.transitions[state] = {} end
    -- transitions start from stop
    self:addTransition {
      oldState = State.stop,
      newState = State.ask,
      event = Event.START,
      action = function()
        self:reloadRooms()
        self:doAsk()
      end
    }
    -- transitions start from ask
    self:addTransition {
      oldState = State.ask,
      newState = State.ask,
      event = Event.NO_JOB_AVAILABLE,
      action = coroutine.create(function()
        wait.time(5)

      end)
    }
  end

  function prototype:set(state) self.currState = state end

  function prototype:get() return self.currState end

  function prototype:fire(event)

  end

  function prototype:addTransition(args)
    local oldState = assert(args.oldState, "oldState cannot be nil")
    local newState = assert(args.newState, "newState cannot be nil")
    local event = assert(args.event, "event cannot be nil")
    local action = assert(args.action, "action cannot be nil")
    -- by default action is executed after state change
    local transition = {
      newState = newState
    }
    if type(action) == "function" then
      transition.after = action
    elseif type(action) == "thread" then
      transition.after = function()
        local ok, ret = coroutine.resume(action)
        return ret
      end
    elseif type(action) == "table" then
      transition.before = action.before
      transition.after = action.after
    else
      error("action can only be function or table" ,2)
    end
    self.transitions[oldState][event] = transition
  end



  function prototype:newInstance()
    local obj = {}
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self.DEBUG = false
    self.continuous = true
    self.currRoom = nil
    self:initTriggers()
    self:initAliases()
  end

  function prototype:debug(...)
    if (self.DEBUG) then print(...) end
  end

  function prototype:stop()
    self.continuous = false
    self.currRoom = nil
  end

  -- before ask job, prepare the rooms and paths for patrol
  function prototype:reloadRooms()
    self.rooms = {}
    for k, v in pairs(prototype._rooms) do
      self.rooms[k] = v
    end
  end

  function prototype:reloadPaths()
    -- copy and reverse paths
    self.paths = {}
    for i = #(prototype._paths),1,-1 do
      table.insert(self.paths, prototype._paths[i])
    end
  end

  function prototype:startAsk()
    helper.enableTriggerGroups("huashan_patrol_ask")
    SendNoEcho("ask yue about job")
    SendNoEcho("set huashan_patrol ask_end")
  end

  function prototype:start()
    self.continuous = true
    locate:clearRoomInfo()
    self:reloadRooms()
    -- 岳灵珊在华山客厅2916
    walkto:walkto(2916, function()
      self:startAsk()
    end)
  end

  function prototype:prepareWork()
    helper.disableTriggerGroups("huashan_patrol_ask", "huashan_patrol_ask_result")
    self:reloadRooms()
  end

  function prototype:assureNotBusy()
    while true do
      SendNoEcho("halt")
      -- busy or wait for 3 seconds to resend
      local line = wait.regexp("^[ >]*你现在不忙。$", 3)
      if line then break end
    end
  end

  function prototype:worker()
    return coroutine.create(function()
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
          local _, wildcards = wait.regexp(self.regexp.PATROLLING, 6)
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
      -- 完成巡逻
      locate:clearRoomInfo()
      walkto:walkto(2916, function()
        helper.enableTriggerGroups("huashan_patrol_submit")
        SendNoEcho("give yue ling")
        SendNoEcho("set huashan_patrol submit_end")
      end)
    end)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("huashan_patrol_ask", "huashan_patrol_ask_result", "huashan_patrol_submit")

    helper.addTrigger {
      group = "huashan_patrol_ask",
      regexp = self.regexp.ASK_YUE,
      response = function()
        helper.enableTriggerGroups("huashan_patrol_ask_result")
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_ask_result",
      regexp = self.regexp.GOT_JOB,
      response = function()
        self:prepareWork()
        local worker = self:worker()
        local ok, error = coroutine.resume(worker)
        if not ok then
          print(error)
        end
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_ask_result",
      regexp = self.regexp.PREV_JOB_REMAINED,
      response = function()
        if self.continuous then
          print("之前任务没有完成，尝试完成")
          self:prepareWork()
          local worker = self:worker()
          coroutine.resume(worker)
        else
          helper.disableTriggerGroups("huashan_patrol_ask", "huashan_patrol_ask_result")
          print("停止巡逻")
        end
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_ask_result",
      regexp = self.regexp.NEXT_JOB_WAIT,
      response = function()
        if self.continuous then
          self:debug("等待5秒后继续询问")
          wait.time(5)
          self:startAsk()
        end
      end
    }

    helper.addTrigger {
      group = "huashan_patrol_submit",
      regexp = self.regexp.SUBMIT_END,
      response = function() helper.disableTriggerGroups("huashan_patrol_submit") end
    }
    helper.addTrigger {
      group = "huashan_patrol_submit",
      regexp = self.regexp.REJECT_LING,
      response = function()
        -- check if rooms are all patrolled
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
          if self.continuous then
            coroutine.resume(self:worker())
          end
        else
          print("巡逻时间太快，尝试打坐等待")
        end
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_submit",
      regexp = self.regexp.ACCEPT_LING,
      response = function()
        if self.continuous then
          self:start()
        end
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_dz",
      regexp = self.regexp.DZ_FINISH,
      response = function()
        if self.keepDZ then
          SendNoEcho("dz max")
        elseif self.needSubmit then
          helper.disableTriggerGroups("huashan_patrol_dz")
        end
      end
    }
    helper.addTrgger {
      group = "huashan_patrol_dz",
      regexp = self.regexp.DZ_NEILI_ADDED,
      response = function()

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
      response = function() self:start() end
    }
    helper.addAlias {
      group = "huashan_patrol",
      regexp = "^patrol\\s+stop\\s*$",
      response = function() self:stop() end
    }
    helper.addAlias {
      group = "huashan_patrol",
      regexp = "^patrol\\s+debug\\s+(on|off)\\s*$",
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self.DEBUG = true
        elseif cmd == "off" then
          self.DEBUG = false
        end
      end
    }
  end

  return prototype
end
huashan.patrol = define_patrol().newInstance()

return huashan


