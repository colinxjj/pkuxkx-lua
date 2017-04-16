--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/4/5
-- Time: 12:00
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"

-- add nanjue job
require "job.nanjue"

local define_fsm = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    find = "find",
    move = "move",
  }
  local Events = {
    STOP = "stop",
    START = "start",
    ROOM_REACHABLE = "room_reachable",
    ROOM_NOT_REACHABLE = "room_not_reachable",
    FIND_FAIL = "find_fail",
    FIND_SUCCESS = "find_success",
    MOVE_CONTINUE = "move_continue",
    MOVE_FINISH = "move_finish",
  }
  local REGEXP = {
    ALIAS_START = "^banghui\\s+start\\s+(.+?)\\s*$",
    ALIAS_STOP = "^banghui\\s+stop\\s*$",
    ALIAS_DEBUG = "^banghui\\s+debug\\s+(on|off)\\s*$",
    ALIAS_MOVE = "^banghui\\s+move\\s*$",
    TARGET_LINE = "^(.*?)��.*$",
    SOURCE_LINE = "^(.*?)��.*$",
    EMPTY_LINE = "^[^ ]+$",
    NOT_FOUND = "^[ >]*���ﲻ����ҪѰ�Ұ����ʲĵĵط���$",
    MOVE_FINISH = "^[ >]*������������λ���ƺ���Щ�����ʲģ�������bhgather����ɼ���$",
    MOVE_BUSY = "^[ >]*������æ���ҵģ�������ô�ż��ġ�$",
    NEILI_DOUBLE = "^[ >]*�����������ӽ�Բ��״̬��$",
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
    self.targetRoomId = nil
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
      "banghui_find_start", "banghui_find_done",
      "banghui_move_start", "banghui_move_done")
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
        self.targetRoomId = nil
      end,
      exit = function() end
    }
    self:addState {
      state = States.find,
      enter = function()
        self.notFound = false
        helper.enableTriggerGroups("banghui_find_start")
      end,
      exit = function()
        helper.disableTriggerGroups("banghui_find_start", "banghui_find_done")
      end
    }
    self:addState {
      state = States.move,
      enter = function()
        helper.enableTriggerGroups("banghui_move_start")
      end,
      exit = function()
        helper.disableTriggerGroups("banghui_move_start", "banghui_move_done")
      end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.find,
      event = Events.START,
      action = function()
        assert(self.targetRoomId, "target room id cannot be nil")
        return travel:walkto(self.targetRoomId, function()
            self.moveDirection = nil
            return self:doFind()
        end)
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<find>
    self:addTransition {
      oldState = States.find,
      newState = States.stop,
      event = Events.FIND_FAIL,
      action = function()
        print("����ʧ��")
        return self:fire(Events.STOP)
      end
    }
    self:addTransition {
      oldState = States.find,
      newState = States.move,
      event = Events.FIND_SUCCESS,
      action = function()
        self:debug("�ȴ�2���bhmove")
        wait.time(2)
        self:clearMoveInfo()
        return self:doBeginMove()
      end
    }
    self:addTransitionToStop(States.find)
    -- transition from state<move>
    self:addTransition {
      oldState = States.move,
      newState = States.move,
      event = Events.MOVE_CONTINUE,
      action = function()
        self:debug("�ȴ�1���bhmove")
        wait.time(1)
        self:clearMoveInfo()
        return self:doMove()
      end
    }
    self:addTransition {
      oldState = States.move,
      newState = States.stop,
      event = Events.MOVE_FINISH,
      action = function()
        self:debug("�ȴ�1���bhgather")
        wait.time(1)
        return self:doGather()
      end
    }
    self:addTransitionToStop(States.move)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "banghui_find_start", "banghui_find_done",
      "banghui_move_start", "banghui_move_done")
    -- triggers for bhfind
    helper.addTrigger {
      group = "banghui_find_start",
      regexp = helper.settingRegexp("banghui", "find_start"),
      response = function()
        helper.enableTriggerGroups("banghui_find_done")
      end
    }
    helper.addTrigger {
      group = "banghui_find_done",
      regexp = helper.settingRegexp("banghui", "find_done"),
      response = function()
        helper.disableTriggerGroups("banghui_find_done")
        if self.notFound then
          return self:fire(Events.FIND_FAIL)
        else
          return self:fire(Events.FIND_SUCCESS)
        end
      end
    }
    helper.addTrigger {
      group = "banghui_find_done",
      regexp = REGEXP.NOT_FOUND,
      response = function()
        self.notFound = true
      end
    }
    -- triggers for bhmove
    helper.addTrigger {
      group = "banghui_move_start",
      regexp = helper.settingRegexp("banghui", "move_start"),
      response = function()
        helper.enableTriggerGroups("banghui_move_done")
      end
    }
    helper.addTrigger {
      group = "banghui_move_done",
      regexp = helper.settingRegexp("banghui", "move_done"),
      response = function()
        helper.disableTriggerGroups("banghui_move_done")
        if self.moveFinish then
          return self:fire(Events.MOVE_FINISH)
        elseif self.moveBusy then
          -- �ȴ�2�������
          self:debug("hbmove busy���ȴ�2�������")
          wait.time(2)
          return self:fire(Events.MOVE_CONTINUE)
        else  -- ��������ƶ�
          -- �������ң�Ȼ������
          self:adjustDirection()
          if self.moveDirection then
            return self:fire(Events.MOVE_CONTINUE)
          else
            print("�����޷�������λ��")
            return self:fire(Events.STOP)
          end
        end
      end
    }
    helper.addTrigger {
      group = "banghui_move_done",
      regexp = REGEXP.MOVE_BUSY,
      response = function()
        self.moveBusy = true
      end
    }
    -- ��ͼ��׽
    helper.addTrigger {
      group = "banghui_move_done",
      regexp = REGEXP.EMPTY_LINE,
      response = function()
        self:debug("EMPTY_LINE triggered")
        if not self.srcCaught then
          self.srcTop = self.srcTop + 1
        end
        if not self.tgtCaught then
          self.tgtTop = self.tgtTop + 1
        end
      end,
      sequence = 100,  -- lower priority
    }
    helper.addTrigger {
      group = "banghui_move_done",
      regexp = REGEXP.SOURCE_LINE,
      response = function(name, line, wildcards)
        if not self.srcCaught then
          self:debug("SOURCE_LINE triggered")
          self.srcLeft = string.len(wildcards[1])
          self:debug(self.srcLeft)
          self.srcCaught = true
        end
      end
    }
    helper.addTrigger {
      group = "banghui_move_done",
      regexp = REGEXP.TARGET_LINE,
      response = function(name, line, wildcards)
        if not self.tgtCaught then
          self:debug("TARGET_LINE triggered")
          self.tgtLeft = string.len(wildcards[1])
          self:debug(self.tgtLeft)
          self.tgtCaught = true
        end
      end
    }
    helper.addTrigger {
      group = "banghui_move_done",
      regexp = REGEXP.MOVE_FINISH,
      response = function(name, line, wildcards)
        self.moveFinish = true
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("banghui")
    helper.addAlias {
      group = "banghui",
      regexp = REGEXP.ALIAS_START,
      response = function(name, line, wildcards)
        local location = wildcards[1]
        local rooms = travel:getMatchedRooms {
          fullname = location
        }
        if rooms and #rooms > 0 then
          local room = rooms[1]
          print("���Ŀ�귿����Ϣ��", room.id, room.name, room.zone)
          self.targetRoomId = room.id
          return self:fire(Events.START)
        else
          ColourNote("red", "", "�޷���ȡĿ�귿����Ϣ")
          return self:fire(Events.STOP)
        end
      end
    }
    helper.addAlias {
      group = "banghui",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "banghui",
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
    -- �����ֶ���ʼmove�ı���
    helper.addAlias {
      group = "banghui",
      regexp = REGEXP.ALIAS_MOVE,
      response = function()
        self:setState(States.find)
        return self:fire(Events.FIND_SUCCESS)
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

  function prototype:doFind()
    SendNoEcho("set banghui find_start")
    SendNoEcho("bhfind")
    SendNoEcho("set banghui find_done")
  end

  function prototype:doMove()
    SendNoEcho("set banghui move_start")
    if self.moveDirection then
      SendNoEcho("bhmove " .. self.moveDirection)
    else
      SendNoEcho("bhfind")
    end
    SendNoEcho("set banghui move_done")
  end

  function prototype:doBeginMove()
    SendNoEcho("dazuo max")
    SendNoEcho("set banghui move_start")
    SendNoEcho("bhfind")
    SendNoEcho("set banghui move_done")
  end

  function prototype:clearMoveInfo()
    self.moveFinish = false
    self.moveBusy = false
    self.srcTop = 0
    self.srcLeft = 0
    self.tgtTop = 0
    self.tgtLeft = 0
    self.srcCaught = false
    self.tgtCaught = false
  end

  function prototype:adjustDirection()
    self:debug("Դ���꣺", string.format("(%d, %d)", self.srcTop, self.srcLeft))
    self:debug("Ŀ�����꣺", string.format("(%d, %d)", self.tgtTop, self.tgtLeft))
    -- �������ң�Ȼ������
    if self.srcLeft < self.tgtLeft then
      self.moveDirection = "e"
    elseif self.srcLeft > self.tgtLeft then
      self.moveDirection = "w"
    elseif self.srcTop < self.tgtTop then
      self.moveDirection = "s"
    elseif self.srcTop > self.tgtTop then
      self.moveDirection = "n"
    else
      self.moveDirection = nil
    end
    self:debug("��������Ϊ��", self.moveDirection)
  end

  function prototype:doGather()
    SendNoEcho("bhgather")
  end

  return prototype
end
return define_fsm():FSM()

