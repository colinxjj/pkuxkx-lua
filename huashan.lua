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
    {path="n",name="���䳡"},
    {path="n",name="��Ů��"},
    {path="e",name="��Ů��"},
    {path="sd",name="��ɽС·"},
    {path="sd",name="��ɽС·"},
    {path="sd",name="СԺ"},
    {path="nu",name="��ɽС·"},
    {path="nu",name="��ɽС·"},
    {path="nu",name="��Ů��"},
    {path="w",name="��Ů��"},
    {path="nd",name="������"},
    {path="eu",name="������"},
    {path="wd",name="������"},
    {path="nu",name="������"},
    {path="wu",name="������"},
    {path="ed",name="������"},
    {path="nd",name="�����"},
    {path="nd",name="�Ͼ���"},
    {path="nu",name="��ɽ��Ժ"},
    {path="sd",name="�Ͼ���"},
    {path="wd",name="�ٳ�Ͽ"},
    {path="nd",name="ǧ�ߴ�"},
    {path="wd",name="���ƺ"},
    {path="nd",name="ɯ��ƺ"},
    {path="nw",name="��ɽ����"},
    {path="n",name="��ȪԺ"}}
  prototype._rooms = {
    ["���䳡"] = 1,
    ["��Ů��"] = 1,
    ["��Ů��"] = 1,
    ["��ɽС·"] = 2,
    ["СԺ"] = 1,
    ["������"] = 1,
    ["������"] = 1,
    ["������"] = 1,
    ["������"] = 1,
    ["�����"] = 1,
    ["�Ͼ���"] = 1,
    ["��ɽ��Ժ"] = 1,
    ["�ٳ�Ͽ"] = 1,
    ["ǧ�ߴ�"] = 1,
    ["���ƺ"] = 1,
    ["ɯ��ƺ"] = 1,
    ["��ɽ����"] = 1,
    ["��ȪԺ"] = 1
  }
  prototype._delay = 1
  prototype.regexp = {
    ASK_YUE = "^[ >]*��������ɺ�����йء�job������Ϣ��$",
    GOT_JOB="^[ >]*����ɺ�ó�һ�ŵ�ͼ���ѻ�ɽ��ҪѲ�ߵ������ò�ͬ��ɫ��ע������������˵��һ�顣$",
    PREV_JOB_REMAINED = "^[ >]*����ɺ˵���������ϴ�����û������أ���$",
    NEXT_JOB_WAIT = "^[ >]*����ɺ˵����������æ���������Ұɡ���$",
    PATROLLING="^[ >]*����(.+?)Ѳ߮����δ���ֵ��١�$",
    GO="^[ >]*�趨����������huashan_patrol = \"go\"",
    POTENTIAL_ROOM="^[ >]*([^ ]+)$",
    REJECT_LING="^[ >]*����ɺ����Ҫ���ƣ�����Ը����Űɡ�",
    ACCEPT_LING="^[ >]*�������ɺһ�����ơ�$",
    SUBMIT_END = "^[ >]*�趨����������huashan_patrol = \"submit_end\"",
    BUSY_CHECK = "^[ >]*�����ڲ�æ��$",
    DZ_FINISH = "^[ >]*��о�������ӯ����Ȼ�ڹ����н�����$",
    DZ_NEILI_ADDED = "^[ >]*������������ˣ���$"
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
    -- ����ɺ�ڻ�ɽ����2916
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
      local line = wait.regexp("^[ >]*�����ڲ�æ��$", 3)
      if line then break end
    end
  end

  function prototype:worker()
    return coroutine.create(function()
      self:debug("����Ѳ��·��")
      self:reloadPaths()
      self:debug("��ʼѲ��")
      while #(self.paths) > 0 do
        local next = table.remove(self.paths)
        -- ������һ�����䣬�˴���ǿ���裬������һ�����䲻��ʧ��
        self:assureNotBusy()
        SendNoEcho(next.path)
        if self.rooms[next.name] and self.rooms[next.name] > 0 then
          self:debug("�״ν���Ѳ�߷��䣬�ȴ�Ѳ������")
          -- wait at most 10 seconds for the notion
          local _, wildcards = wait.regexp(self.regexp.PATROLLING, 6)
          if wildcards and wildcards[1] then
            local currRoom = wildcards[1]
            if self.rooms[currRoom] and self.rooms[currRoom] > 0 then
              self.rooms[currRoom] = self.rooms[currRoom] - 1
            end
          else
            print("�õ���Ӧ����ʾѲ����ʾ��û����ʾ��")
          end
        end
      end
      -- ���Ѳ��
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
          print("֮ǰ����û����ɣ��������")
          self:prepareWork()
          local worker = self:worker()
          coroutine.resume(worker)
        else
          helper.disableTriggerGroups("huashan_patrol_ask", "huashan_patrol_ask_result")
          print("ֹͣѲ��")
        end
      end
    }
    helper.addTrigger {
      group = "huashan_patrol_ask_result",
      regexp = self.regexp.NEXT_JOB_WAIT,
      response = function()
        if self.continuous then
          self:debug("�ȴ�5������ѯ��")
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
            print("�����з���δѲ�ߵ�", room)
            allPatrolled = false
            break
          end
        end
        if not allPatrolled then
          print("�в�������û��Ѳ�ߵ�������Ѳ��")
          if self.continuous then
            coroutine.resume(self:worker())
          end
        else
          print("Ѳ��ʱ��̫�죬���Դ����ȴ�")
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
        print("PATROL��ɽ����Ѳ�������÷����£�")
        print("patrol start", "��ʼѲ��")
        print("patrol stop", "��ɵ�ǰ�����ֹͣѲ��")
        print("patrol debug on/off", "����/�ر�Ѳ�ߵ���ģʽ")
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


