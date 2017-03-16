--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:36
-- To change this template use File | Settings | File Templates.
--

--------------------------------------------------------------
-- travel.lua
-- �ṩ��λ�����߹��ܣ��û�����ʹ��loc
-- ��ģ�������FSM���ģʽ��Ŀ�����ȶ������ݴ�
-- FSM״̬�У�
-- 1. stop ֹͣ״̬
-- 2. locating ��λ��
-- 3. located �Ѷ�λ
-- 4. walking ������
-- 5. lost ��·��
-- 6. blocked ���赲�У�busy, boat, etc��
-- ״̬ת����
-- ��stop״̬����ͨ������STOP��Ϣ��ת��Ϊstop״̬
-- stop -> locating (event: START)
-- locating -> located (event: LOCATION_CONFIRMED, LOCATION_CONFIRMED_ONLY)
-- locating -> stop (event: MAX_RETRIES, ROOM_NO_EXITS)
-- located -> walking (event: WALK_PLAN_GENERATED)
-- located -> stop (event: WALK_PLAN_NOT_EXISTS)
-- walking -> located (event: ARRIVED)
-- walking -> lost (event: GET_LOST)
-- walking -> blocked (event: BOAT, BUSY)
-- lost -> locating (event: START_RELOCATE)
-- blocked -> walking (event: BLOCKING_SOLVED)
--
-- ����API��
-- travel:reset() ��ʼ��״̬������ʱ���ȶ�λ��ǰ���䣬�����ڴ��������
-- travel:setMode(mode) ��������ģʽ���ṩ"quick", "normal", "slow"����ģʽ
-- ~~ quickģʽ��ÿ12��ͣ��1�룬ͨ��travel:setInterval(steps)�޸�
-- ~~ normalģʽ��ÿ������ͣ��
-- ~~ slowģʽ��ÿ��ͣ��1�룬ͨ��travel:setDelay(seconds)�޸�
-- travel:relocate() �ض�λ��������coroutine�е���
-- travel:walkto(roomId, action)
-- ָ��Ŀ�ĵ�(roomId)���ߣ������Ҫ���ȶ�λ��ǰ���䣬actionΪ�������ִ�к�����
-- �ɰ���Э�̷���(��wait.lua�ṩ��time, regexp����)
-- travel:waitUntilArrived() ���walkto�����д���callback������������Ҫ��
-- �ṩ�ú�������������wait.regexp�����÷���yieldֱ������Ŀ�ĵء�
-- todo
-- travel:traverseUntil(roomId, range, untilCheck)
-- ָ��Ŀ�귿���뷶Χ��Ĭ��ÿ�������ڷ������Ϊ1�������б�����dfs�㷨����untilCheckΪ
-- travel:traverseEach(roomId, range, eachAction)
--
-- also provide non-FSM aliases to assist map generation
--
--------------------------------------------------------------

require "pkuxkx.predefines"
local helper = require "pkuxkx.helper"
local gb2312 = require "pkuxkx.gb2312"
local FSM = require "pkuxkx.FSM"
local Algo = require "pkuxkx.Algo"
local dbDef = require "pkuxkx.db"
local db = dbDef.open("data/pkuxkx-gb2312.db")
local dalDef = require "pkuxkx.dal"
local dal = dalDef.open(db)
local ZonePath = require "pkuxkx.ZonePath"

local define_travel = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",  -- ֹͣ״̬
    walking = "walking",  -- ������
    lost = "lost",  -- ��·��
    blocked = "blocked", -- ���赲
    locating = "locating",  -- ��λ��
    located = "located" -- �Ѷ�λ
  }

  local Events = {
    START = "start",    -- ��ʼ�źţ���ֹͣ״̬��ʼ�������ض�λ�����Ѷ�λ״̬��ʼ����������
    STOP = "stop",    -- ֹͣ�źţ��κ�״̬�յ����źŶ���ת����stop״̬
    LOCATION_CONFIRMED = "location_confirmed",    -- ȷ����λ��Ϣ
    LOCATION_CONFIRMED_ONLY = "location_confirmed_only",    -- ��ȷ����λ��Ϣ
    ARRIVED = "arrived",    -- ����Ŀ�ĵ��ź�
    GET_LOST = "get_lost",    -- ��·�ź�
    START_RELOCATE = "start_relocate",    -- ���¶�λ�ź�
    -- FAIL_RELOCATE = "fail_relocate",    -- ���¶�λʧ��
    MAX_RELOC_RETRIES = "max_reloc_retries",    -- �����ض�λ����������
    MAX_RELOC_MOVES = "max_reloc_moves",    -- �����ض�λ�ƶ��������ÿ�Σ�
    ROOM_NO_EXITS = "room_no_exits",    -- ����û�г���
    WALK_PLAN_NOT_EXISTS = "walk_plan_not_exists",    -- ���߼ƻ��޷�����
    WALK_PLAN_GENERATED = "walk_plan_generated",    -- ���߼ƻ�����
    BOAT = "boat",    -- �˴��ź�
    BUSY = "busy",    -- busy�ź�
    BLOCKING_SOLVED = "blocking_solved",    -- ��������ź�
    TRY_RELOCATE = "try_relocate",    -- �����ض�λ
    ROOM_INFO_UNKNOWN = "room_info_unknown",    -- û�л�ȡ��������Ϣ
  }
  local RELOC_MAX_RETRIES = 4    -- �ض�λ������Դ�����������located��stop״̬ʱ���ã�������locatingʱ��һ
  local RELOC_MAX_MOVES = 50    -- ÿ���ض�λ����ƶ�����(ÿ��������1��)��������locating״̬ʱ����


  prototype.regexp = {
    --SET_LOCATE_START = "^[ >]*�趨����������locate = \"start\"$",
    --SET_LOCATE_STOP = "^[ >]*�趨����������locate = \"stop\"$",
    ROOM_NAME_WITH_AREA = "^[ >]{0,12}([^ ]+) \\- \\[[^ ]+\\]$",
    ROOM_NAME_WITHOUT_AREA = "^[ >]{0,12}([^ ]+) \\- $",
    ROOM_DESC = "^ {0,12}([^ ].*?) *$",
    SEASON_TIME_DESC = "^    ��([^\\\\x00-\\\\xff]+?)��: (.*)$",
    EXITS_DESC = "^\\s{0,12}����(����|Ψһ)�ĳ�����(.*)$|^\\s*����û���κ����Եĳ�·\\w*",
    BUSY_LOOK = "^[> ]*�羰Ҫ�����Ŀ���$",
    NOT_BUSY = "^[ >]*�����ڲ�æ��$",
    LOOK_START = "^[ >]*�趨����������travel_look = \"start\"$",
    LOOK_DONE = "^[ >]*�趨����������travel_look = \"done\"$",
    ARRIVED = "^[ >]*�趨����������travel_walk = \"arrived\"$",
    WALK_LOST = "^[> ]*(�������û�г�·��|��һ��С�Ľ���̤�˸��գ�... ��...��|��С��������ǰŲ���������������д���ֻ�÷����Ų���|�㻹��ɽ�а��棬һʱ�������߲���.*|�ຣ��������ʤ�գ��㲻��ͣ�½Ų����������˷羰��|�㲻С�ı�ʲô��������һ��.*)$",
    WALK_LOST_SPECIAL = "^[ >]*��Ƥһ����ס�㣺Ҫ��Ӵ˹���������·�ƣ���Ƥһ����ס���㡣$",
    WALK_BLOCK = "^[> ]*��Ķ�����û����ɣ������ƶ�.*$",
    WALK_BREAK = "^[ >]*�趨����������travel_walk = \"break\"$",
    WALK_STEP = "^[ >]*�趨����������travel_walk = \"step\"$",
  }
  prototype.zonesearch = Algo.dijkstra
  prototype.roomsearch = Algo.astar
  prototype.traverse = Algo.traversal

  function prototype:FSM()
    local obj = FSM:new()
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:setMode(mode)
    self.mode = mode
  end

  function prototype:setDelay(delay)
    self.delay = delay
  end

  function prototype:reset()
    -- locating
    self.currRoomId = nil
    self.currRoomName = nil
    self.targetRoomId = nil -- if target room id is nil, means locating only
    self.targetAction = nil
    self.relocMaxRetries = RELOC_MAX_RETRIES
    self.relocMaxMoves = RELOC_MAX_MOVES
    self.busyLook = false  -- used when relocating, system might tell you too busy to look around
    -- walking
    self.walkPlan = nil
    self.walkLost = false
  end

  function prototype:walkto(targetRoomId, action)
    assert(type(targetRoomId) == "number", "target room id must be number")
    assert(not action or type(action) == "function", "action must be function or nil")
    self.targetRoomId = targetRoomId
    self.targetAction = action
    self:fire(Events.START)
  end

  function prototype:reloc()
    -- ǿ���ض�λ
    self:reset()
    self:fire(Events.START)
  end

  function prototype:postConstruct()
    self:initStates()
    self:initTransitions()
    self:initZonesAndRooms()
    self:initTriggers()
    self:initAliases()
    self:setState(States.stop)
    self:reset()
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
    -- locating
      "travel_look_start",
      "travel_look_name",
      "travel_look_desc",
      "travel_look_season",
      "travel_look_exits"
    )
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        -- must clean the user defined triggers
        helper.removeTriggerGroups("travel_one_shot")
        self:disableAllTriggers()
      end,
      exit = function()

      end
    }
    self:addState {
      state = States.locating,
      enter = function()

      end,
      exit = function()
        helper.disableTriggerGroups(
          "travel_look_start",
          "travel_look_name",
          "travel_look_desc",
          "travel_look_season",
          "travel_look_exits",
          "travel_walk"
        )
      end
    }
    self:addState {
      state = States.located,
      enter = function()
        self.relocMaxRetries = RELOC_MAX_RETRIES
      end,
      exit = function()

      end
    }
    self:addState {
      state = States.walking,
      enter = function()
        helper.enableTriggerGroups("travel_walk")
      end,
      exit = function()
        helper.disableTriggerGroups("travel_walk")
      end
    }
    self:addState {
      state = States.lost,
      enter = function()

      end,
      exit = function()

      end
    }
    self:addState {
      state = States.blocked,
      enter = function()

      end,
      exit = function()

      end
    }
  end

  local addTransitionToStop = function(self, fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function()
        print("ֹͣ - ��ǰ״̬", self.currState)
      end
    }
  end

  function prototype:generateWalkPlan()
    local fromid = self.currRoomId
    local toid = self.targetRoomId
    self:debug("������ʼ�����Ŀ�귿��", fromid, toid)
    local startRoom = self.roomsById[fromid]
    local endRoom = self.roomsById[toid]
    if not startRoom then
      print("��ǰ���䲻���Զ������б���")
      return nil
    elseif not endRoom then
      print("Ŀ�귿�䲻���Զ������б���")
      return nil
    else
      local startZone = self.zonesByCode[startRoom.zone]
      local endZone = self.zonesByCode[endRoom.zone]
      if not startZone then
        print("��ǰ�������Զ������б���", startRoom.zone)
        return nil
      elseif not endZone then
        print("Ŀ���������Զ������б���", endRoom.zone)
        return nil
      elseif startZone == endZone then
        if self.DEBUG then
          local roomCnt = 0
          for _, room in pairs(startZone.rooms) do
            roomCnt = roomCnt + 1
          end
          print("��������Ŀ�ĵش���ͬһ���򣬹�" .. roomCnt .. "������")
        end
        return self.roomsearch(startZone.rooms, fromid, toid)
      else
        -- zone search for shortest path
        local zoneStack = self.zonesearch {
          rooms = self.zonesById,
          startid = startZone.id,
          targetid = endZone.id
        }
        if not zoneStack then
          print("��������·��ʧ�ܣ����� " .. startZone.name .. " ������ " .. endZone.name .. " ���ɴ�")
          return false
        else
          table.insert(zoneStack, ZonePath:decorate {startid=startZone.id, endid=startZone.id, weight=0})
          local zoneCnt = #zoneStack
          local rooms = {}
          local roomCnt = 0
          while #zoneStack > 0 do
            local zonePath = table.remove(zoneStack)
            for _, room in pairs(self.zonesById[zonePath.endid].rooms) do
              rooms[room.id] = room
              roomCnt = roomCnt + 1
            end
          end
          self:debug("����·�������" .. zoneCnt .. "�����򣬹�" .. roomCnt .. "������")
          return self.roomsearch(startZone.rooms, fromid, toid)
        end
      end
    end
  end

  function prototype:initTransitions()
    -- transtions from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.locating,
      event = Events.START,
      action = function()
        self:relocate()
      end
    }
    -- transitions from state<locating>
    self:addTransition {
      oldState = States.locating,
      newState = States.located,
      event = Events.LOCATION_CONFIRMED,
      action = function()
        local walkPlan = self:generateWalkPlan()
        if not walkPlan then
          return self:fire(Events.WALK_PLAN_NOT_EXISTS)
        else
          self:debug("�����Զ����߹�" .. #walkPlan .. "��")
          -- this is the only place to store walk plan
          self.walkPlan = walkPlan
          return self:fire(Events.WALK_PLAN_GENERATED)
        end
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.located,
      event = Events.LOCATION_CONFIRMED_ONLY,
      action = function()
        print("������¶�λ���������ƣ�", self.currRoomName, "�����ţ�", self.currRoomId)
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.MAX_RELOC_RETRIES,
      action = function()

      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.MAX_RELOC_MOVES,
      action = function()

      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.ROOM_NO_EXITS,
      action = function()

      end
    }
    addTransitionToStop(self, States.locating)
    -- transitions from state<located>
    self:addTransition {
      oldState = States.located,
      newState = States.walking,
      event = Events.WALK_PLAN_GENERATED,
      action = function()
        self:walking()
      end
    }
    self:addTransition {
      oldState = States.located,
      newState = States.stop,
      event = Events.WALK_PLAN_NOT_EXISTS,
      action = function()
        print("�Զ�����ʧ�ܣ��޷���ȡ�ӷ���" .. self.currRoomId .. "���﷿��" .. self.targetRoomId .. "�����߼ƻ�")
      end
    }
    addTransitionToStop(self, States.located)
    -- transitions from state<walking>
    self:addTransition {
      oldState = States.walking,
      newState = States.located,
      event = Events.ARRIVED,
      action = function()
        self.walkPlan = nil
        self.currRoomId = self.targetRoomId
        SendNoEcho("set travel_walk arrived")  -- this is for
        if self.targetAction then
          self.targetAction()
        end
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.blocked,
      event = Events.BOAT,
      action = function()

      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.blocked,
      event = Events.BUSY,
      action = function()

      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.lost,
      event = Events.GET_LOST,
      action = function()

      end
    }
    addTransitionToStop(self, States.walking)
    -- transitions from state<blocked>
    self:addTransition {
      oldState = States.blocked,
      newState = States.walking,
      event = Events.BLOCKING_SOLVED,
      action = function()

      end
    }
    addTransitionToStop(self, States.blocked)
    -- transitions from state<lost>
    self:addTransition {
      oldState = States.lost,
      newState = States.locating,
      event = Events.TRY_RELOCATE, -- always try relocate and the retries threshold is checked when locating
      action = function()

      end
    }
    addTransitionToStop(self, States.lost)
  end

  -- ���������б�ͷ����б�
  function prototype:initZonesAndRooms()
    -- initialize zones
    local zonesById = dal:getAllZones()
    local zonePaths = dal:getAllZonePaths()
    for i = 1, #zonePaths do
      local zonePath = zonePaths[i]
      local zone = zonesById[zonePath.startid]
      if zone then
        zone:addPath(zonePath)
      end
    end
    -- create code map
    local zonesByCode = {}
    for _, zone in pairs(zonesById) do
      zonesByCode[zone.code] = zone
    end
    -- initialize rooms
    local roomsById = dal:getAllAvailableRooms()
    local roomsByCode = {}
    local paths = dal:getAllAvailablePaths()
    for i = 1, #paths do
      local path = paths[i]
      local room = roomsById[path.startid]
      if room then
        room:addPath(path)
      end
    end
    -- add rooms to zones
    for _, room in pairs(roomsById) do
      roomsByCode[room.code] = room
      local zone = zonesByCode[room.zone]
      if zone then
        zone.rooms[room.id] = room
      end
    end
    -- assign to prototype
    self.zonesById = zonesById
    self.zonesByCode = zonesByCode
    self.roomsById = roomsById
    self.roomsByCode = roomsByCode
  end

  local formatExits = function(raw)
    local exits = raw
    exits = string.gsub(exits,"��","")
    exits = string.gsub(exits," ","")
    exits = string.gsub(exits,"��", ";")
    exits = string.gsub(exits, "��", ";")
    local tb = {}
    for _, str in ipairs(utils.split(exits,";")) do
      local t = Trim(str)
      if t ~= "" then table.insert(tb, t) end
    end
    return table.concat(tb, ";")
  end

  function prototype:initTriggers()

    helper.removeTriggerGroups(
      "travel_look_start",
      "travel_look_name",
      "travel_look_desc",
      "travel_look_season",
      "travel_look_exits",
      "travel_walk"
    )

    -- ��ʼ����
    helper.addTrigger {
      group = "travel_look_start",
      regexp = self.regexp.LOOK_START,
      response = function()
        self:debug("LOOK_START triggered")
        self:clearRoomInfo()
        helper.enableTriggerGroups("travel_look_name")
      end
    }
    -- ץȡ��������
    local roomNameCaught = function(name, line, wildcards)
      self:debug("ROOM_NAME triggered")
      local roomName = wildcards[1]
      self:debug("room name:", roomName)
      self.currRoomName = roomName
      -- only get the first name, discard all below possible names
      helper.disableTriggerGroups("travel_look_name")
      helper.enableTriggerGroups("travel_look_desc", "travel_look_season", "travel_look_exits")
      self._roomDescInline = true
      self._roomExitsInline = true
    end
    helper.addTrigger {
      group = "travel_look_name",
      regexp = self.regexp.ROOM_NAME_WITH_AREA,
      response = roomNameCaught,
      sequence = 15 -- lower than desc
    }
    helper.addTrigger {
      group = "travel_look_name",
      regexp = self.regexp.ROOM_NAME_WITHOUT_AREA,
      response = roomNameCaught,
      sequence = 15 -- lower than desc
    }
    -- ��Ƶ��ʹ��lookʱ��ϵͳ��������羰����ʾ����ʱ�޷���ȡ���������ƺ�����
    helper.addTrigger {
      group = "travel_look_name",
      regexp = self.regexp.BUSY_LOOK,
      response = function()
        self:debug("BUSY_LOOK triggered")
        self:debug("Ƶ��ʹ��look�����ʾ�����ˣ�")
        self.busyLook = true
      end
    }
    -- ץȡ��������
    helper.addTrigger {
      group = "travel_look_desc",
      regexp = self.regexp.ROOM_DESC,
      response = function(name, line, wildcards)
        self:debug("ROOM_DESC triggered")
        if self._roomDescInline then
          table.insert(self.currRoomDesc, wildcards[1])
        end
      end
    }
    -- ���ں�ʱ������
    helper.addTrigger {
      group = "travel_look_season",
      regexp = self.regexp.SEASON_TIME_DESC,
      response = function(name, line, wildcards)
        self:debug("SEASON_TIME_DESC triggered")
        if self._roomDescInline then
          helper.disableTriggerGroups("travel_look_desc")    -- ��ֹ���ץȡ����
        end
        self.currSeason = wildcards[1]
        self.currDatetime = wildcards[2]
      end,
      sequence = 5 -- higher than room desc
    }
    -- ץȡ������Ϣ
    helper.addTrigger {
      group = "travel_look_exits",
      regexp = self.regexp.EXITS_DESC,
      response = function(name, line, wildcards)
        self:debug("EXITS_DESC triggered")
        if self._roomDescInline then
          self._roomDescInline = false
          helper.disableTriggerGroups("travel_look_desc")    -- ��ֹ���ץȡ����
        end
        if self._roomExitsInline then
          self._roomExitsInline = false
          self.currRoomExits = formatExits(wildcards[2] or "look")
        end
      end,
      sequence = 5 -- higher than room desc
    }
    -- ��·����
    local lostWay = function()
      self.walkLost = true
      self:debug("�ƺ���·�ˣ�")
    end
    helper.addTrigger {
      group = "travel_walk",
      regexp = self.regexp.WALK_LOST,
      response = lostWay
    }
    helper.addTrigger {
      group = "travel_walk",
      regexp = self.regexp.WALK_LOST_SPECIAL,
      response = lostWay
    }
    helper.addTrigger {
      group = "travel_walk",
      regexp = self.regexp.WALK_BLOCK,
      response = lostWay
    }
  end

  function prototype:clearRoomInfo()
    self.currRoomId = nil
    self.currRoomName = nil
    self.currRoomDesc = {}    -- use table to store description (avoiding string concat)
    self.currRoomExits = nil
    self.currSeason = nil
    self.currDatetime = nil
    self._roomDescInline = false    -- only use when locating current room
    self._roomExitsInline = false    -- only use when locating current room
  end

  function prototype:initAliases()
    helper.removeAliasGroups("travel")

    helper.addAlias {
      group = "travel",
      regexp = "^loc\\s*$",
      response = function()
        print("TRAVEL�Զ�����ָ�ʹ�÷�����")
        print("travel debug on/off", "����/�رյ���ģʽ������ʱ������ʾ���д���������־��Ϣ")
        print("reloc", "���¶�λֱ����ǰ�����Ψһȷ��")



        print("ͬʱ�ṩ��ͼ¼�빦�ܣ�")
        print("loc here", "���Զ�λ��ǰ���䣬��׽��ǰ������Ϣ����ʾ")
        print("loc <number>", "��ʾ���ݿ���ָ����ŷ������Ϣ")
        print("loc match <number>", "����ǰ������Ŀ�귿����жԱȣ�����Ա����")
        print("loc update <number>", "����ǰ�������Ϣ���½����ݿ⣬��ȷ����Ϣ����ȷ��")
        print("loc show", "����ʾ��ǰ������Ϣ������look��λ")
        print("loc guess", "ͨ���������Ƶ�ƴ���������Ƶķ���")
        print("loc mu <number>", "����ǰ������Ŀ�귿��Աȣ������Ϣƥ�䣬�����")
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc here$",
      response = function()
        local co = coroutine.create(function()
          self:lookUntilNotBusy()
          self:show()
        end)
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+(\\d+)$",
      response = function(name, line, wildcards)
        local roomId = tonumber(wildcards[1])
        local room = dal:getRoomById(roomId)
        if room then
          self:show(room)
          local paths = dal:getPathsByStartId(room.id)
          local pathDisplay = {}
          for _, path in pairs(paths) do
            table.insert(pathDisplay, path.endid .. " " .. path.path)
          end
          print("�ɵ���·����", table.concat(pathDisplay, ", "))
        else
          print("�޷���ѯ����Ӧ����")
        end
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+debug\\s+(on|off)$",
      response = function(name, line, wildcards)
        local option = wildcards[1]
        if option == "on" then
          self:debugOn()
          print("�򿪶�λ����ģʽ")
        elseif option == "off" then
          self:debugOff()
          print("�رն�λ����ģʽ")
        end
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+guess\\s*$",
      response = function()
        self:guess()
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+match\\s+(\\d+)\\s*$",
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:match(targetRoomId)
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+update\\s+(\\d+)\\s*$",
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:update(targetRoomId)
      end
    }
    -- match and update
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+mu\\s+(\\d+)\\s*$",
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:match(targetRoomId, true)
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^reloc\\s*$",
      response = function()
        self:reloc()
      end
    }
    helper.addAlias {
      group = "locate",
      regexp = "^loc\\s+show\\s*$",
      response = function()
        self:show()
      end
    }
  end

  function prototype:waitUntilArrived()
    local currCo = assert(coroutine.running(), "Must be in coroutine")
    local resumeCo = function()
      local ok, err = coroutine.resume(currCo)
      if not ok then
        ColourNote ("deeppink", "black", "Error raised in timer function (in wait module).")
        ColourNote ("darkorange", "black", debug.traceback(currCo))
        error (err)
      end -- if
    end

    helper.addOneShotTrigger {
      group = "travel_one_shot",
      regexp = self.regexp.ARRIVED,
      response = resumeCo
    }
    return coroutine.yield()
  end

  function prototype:show(room)
    if room then
      print("Ŀ�귿���ţ�", room.id)
      print("Ŀ�귿�����ƣ�", room.name)
      print("Ŀ�귿����룺", room.code)
      print("Ŀ�귿����ڣ�", room.exits)
      if room.description then
        print("Ŀ�귿��������")
        self:showDesc(room.description)
      else
        print("Ŀ�귿������", room.description)
      end
    else
      print("��ǰ�����ţ�", self.currRoomId)
      print("��ǰ�������ƣ�", self.currRoomName)
      print("��ǰ������ڣ�", self.currRoomExits)
      print("��ǰ����������")
      self:showDesc(self.currRoomDesc)
      local potentialRooms = dal:getRoomsByName(self.currRoomName)
      if #(potentialRooms) > 1 then
        local ids = {}
        for _, room in pairs(potentialRooms) do table.insert(ids, room) end
        print("ͬ�����䣺", table.concat(room.id, ","))
      else
        print("��ͬ������")
      end
    end
  end

  function prototype:showDesc(roomDesc)
    if type(roomDesc) == "string" then
      for i = 1, string.len(roomDesc), self.DESC_DISPLAY_LINE_WIDTH do
        print(string.sub(roomDesc, i, i + self.DESC_DISPLAY_LINE_WIDTH - 1))
      end
    elseif type(roomDesc) == "table" then
      for _, d in ipairs(roomDesc) do
        print(d)
      end
    end
  end

  function prototype:guess()
    -- after locate, we can guess which record it
    -- belongs to according to pinyin of its room name
    local roomName = self.currRoomName
    if not roomName then
      print("��ǰ��������Ϊ�գ�����ʹ��LOC��λ����")
      return
    end
    self:debug("��ǰ�������ƣ�", roomName, "���ȣ�", string.len(roomName))
    if gb2312.len(roomName) > 10 then
      print("��ǰ�汾��֧��10�����ֳ����ڵ����Ʋ�ѯ")
    end
    local pinyins = dal:getPinyinListByWord(roomName)
    self:debug("����ƴ���б�", pinyins and table.concat(pinyins, ", "))
    local candidates = {}
    for _, pinyin in ipairs(pinyins) do
      local results = dal:getRoomsLikeCode(pinyin)
      for id, room in pairs(results) do
        candidates[id] = room
      end
    end
    print("ͨ��������ƴ��ƥ��õ���ѡ�б�")
    print("----------------------------")
    for _, c in pairs(candidates) do
      print("Room Id:", c.id)
      print("Room Code:", c.code)
      print("Room Name:", c.name)
      print("Room exits:", c.exits)
      print("Room Desc:", c.description and string.sub(c.description, 1, 30))
      print("----------------------------")
    end
  end

  local directions = {
    s="south",
    n="north",
    w="west",
    e="east",
    ne="northeast",
    se="southeast",
    sw="southwest",
    nw="northwest",
    su="southup",
    nu="northup",
    eu="eastup",
    wu="westup",
    sd="southdown",
    nd="northdown",
    wd="westdown",
    ed="eastdown",
    u="up",
    d="down"
  }
  local expandDirection = function(path)
    return directions[path] or path
  end


  function prototype:match(roomId, performUpdate)
    local performUpdate = performUpdate or false
    local room = dal:getRoomById(roomId)
    if not room then
      print("��ѯ����ָ����ŵķ��䣺" .. roomId)
      return
    end
    -- �ȽϷ�������
    if not self.currRoomName then
      print("��ǰ�����޿�ȷ�������ƣ�����ʹ��LOC��λ���׽")
      return
    end
    if self.currRoomName == room.name then
      self:debug("����ƥ��")
    else
      print("���Ʋ�ƥ�䣺", "��ǰ", self.currRoomName, "Ŀ��", room.name)
    end
    local currRoomDesc = table.concat(self.currRoomDesc)
    if currRoomDesc == room.description then
      self:debug("����ƥ��")
    else
      print("������ƥ�䣺")
      print("��ǰ", currRoomDesc)
      print("Ŀ��", room.description)
    end
    local currExits = {}
    local currExitCnt = 0
    if self.currRoomExits and self.currRoomExits ~= "" then
      for _, e in ipairs(utils.split(self.currRoomExits, ";")) do
        currExits[e] = true
        currExitCnt = currExitCnt + 1
      end
    end
    local tgtExits = {}
    local tgtExitCnt = 0
    if room.exits and room.exits ~= "" then
      for _, e in ipairs(utils.split(room.exits, ";")) do
        tgtExits[e] = true
        tgtExitCnt = tgtExitCnt + 1
      end
    end
    local exitsIdentical = true
    if currExitCnt ~= tgtExitCnt then
      exitsIdentical = false
    else
      for curr in pairs(currExits) do
        if not tgtExits[curr] then
          exitsIdentical = false
          break
        end
      end
    end
    -- furthur check on paths
    local pathIdentical = true
    local tgtPaths = dal:getPathsByStartId(roomId)
    local tgtPathCnt = 0
    for _, tgtPath in pairs(tgtPaths) do
      tgtPathCnt = tgtPathCnt + 1
      if not currExits[expandDirection(tgtPath.path)] then
        pathIdentical = false
        break
      end
    end
    if tgtPathCnt ~= currExitCnt then
      pathIdentical = false
    end
    local pathDisplay = {}
    for _, tgtPath in pairs(tgtPaths) do
      table.insert(pathDisplay, tgtPath.endid .. " " .. tgtPath.path)
    end
    if exitsIdentical and pathIdentical then
      if performUpdate then
        self:update(roomId)
        print("������·����ƥ�䣬���ݿ��¼�Ѹ���")
      else
        print("������·����ƥ��")
      end
    elseif exitsIdentical and not pathIdentical then
      if performUpdate then
        print("����ƥ�䵫·����ƥ�䣬������������ݿ⣬����Ҫ���ֶ�update")
      else
        print("����ƥ�䵫·����ƥ��")
      end
    elseif pathIdentical then
      if performUpdate then
        self:update(roomId)
        print("���ڲ�ƥ�䵫·��ƥ�䣬���ݿ��¼�Ѹ���")
      else
        print("���ڲ�ƥ�䵫·��ƥ��")
      end
    else
      if performUpdate then
        print("������·������ƥ�䣬������������ݿ⣬����Ҫ���ֶ�update")
      else
        print("������·������ƥ��")
      end
    end
    print(table.concat(pathDisplay, ", "))
  end

  function prototype:update(roomId)
    local room = Room:new {
      id = roomId,
      name = self.currRoomName,
      code = "",
      description = table.concat(self.currRoomDesc),
      exits = self.currRoomExits
    }
    dal:updateRoom(room)
  end


  function prototype:relocate()
    local moves = 0
    repeat
      self:lookUntilNotBusy()
      -- ����ƥ�䵱ǰ����
      if not self.currRoomName then
        if not self.currRoomExits then
          return self:fire(Events.ROOM_INFO_UNKNOWN)
        else
          -- ����������ߣ����¶�λ
          self:randomGo(self.currRoomExits)
        end
      else
        local potentialRooms = dal:getRoomsByName(self.currRoomName)
        local matched = self:matchPotentialRooms(table.concat(self.currRoomDesc), self.currRoomExits, self._potentialRooms)
        if #matched == 1 then
          self:debug("�ɹ�ƥ��Ψһ����", matched[1])
          self.currRoomId = matched[1]
          if self.targetRoomId then
            return self:fire(Events.LOCATION_CONFIRMED)
          else
            return self:fire(Events.LOCATION_CONFIRMED_ONLY)
          end
        else
          if #matched == 0 then
            self:debug("û�п�ƥ��ķ��䣬������", self.currRoomName)
          else
            self:debug("���ҵ����ƥ��ɹ��ķ���", table.concat(matched, ","))
          end
          -- ����������ߣ����¶�λ
          self:randomGo(self.currRoomExits)
        end
      end
      wait.time(1)
      moves = moves + 1
      if self.currState == States.stop then return end
    until moves > RELOC_MAX_MOVES
    -- ���Զ�����޷���λ��ǰ����
    return self:fire(Events.MAX_RELOC_MOVES)
  end

  function prototype:walking()
    local interval = self.interval or 12
    local restTime = self.restTime or 1
    local mode = self:getMode() or "quick"    -- the default walkto mode
    self:debug("����ģʽ", mode)
    local delay = self.delay or 1    -- the default walkto delay in slow mode

    local steps = 0
    while #(self.walkPlan) > 0 do
      local move = table.remove(self.walkPlan)
      -- here should be refined, the state may change
      -- due to the path
      -- evaluate the move and may be transit to other state
      if mode ~= "quick" then
        SendNoEcho("halt")
      end
      if move.category == "busy" then
        SendNoEcho(move.path)
        return self:fire(Events.BUSY)
      elseif move.category == "boat" then
        SendNoEcho(move.path)
        return self:fire(Events.BOAT)
      else
        SendNoEcho(move.path)
      end

      steps = steps + 1
      if mode == "quick" and steps >= interval then
        steps = 0
        while true do
          SendNoEcho("set travel_walk break")
          local line = wait.regexp(self.regexp.WALK_BREAK, 5)
          if not line then
            print("ϵͳ��Ӧ��ʱ���ȴ�5������")
            wait.time(5)
          elseif self.walkLost then
            return self:fire(Events.GET_LOST)
          else
            wait.time(1)
            SendNoEcho("halt")
            break
          end
        end
      end
      if mode == "normal" then
        while true do
          SendNoEcho("set travel_walk step")
          local line = wait.regexp(self.regexp.WALK_STEP, 5)
          if not line then
            print("ϵͳ��Ӧ��ʱ���ȴ�5������")
            wait.time(5)
          elseif self.walkLost then
            return self:fire(Events.GET_LOST)
          else
            SendNoEcho("halt")
            break
          end
        end
      elseif mode == "slow" then
        while true do
          SendNoEcho("set travel_walk step")
          local line = wait.regexp(self.regexp.WALK_STEP, 5)
          if not line then
            print("ϵͳ��Ӧ��ʱ���ȴ�5������")
            wait.time(5)
          elseif self.walkLost then
            return self:fire(Events.GET_LOST)
          else
            wait.time(1)
            SendNoEcho("halt")
            break
          end
        end
      end
      if self.currState == States.stop then return end
    end
    return self:fire(Events.ARRIVED)
  end

  ---------------------------------------------------

  function prototype:lookUntilNotBusy()
    while true do
      helper.enableTriggerGroups("travel_look_start")
      self.busyLook = false
      SendNoEcho("set travel_look start")
      SendNoEcho("look")
      SendNoEcho("set travel_look done")
      local line = wait.regexp(self.regexp.LOOK_DONE, 3)
      helper.disableTriggerGroups(
        "travel_look_start",
        "travel_look_name",
        "travel_look_desc",
        "travel_look_season",
        "travel_look_exits")
      if not line then
        print("ϵͳ��ʱ��5�������")
        wait.time(5)
      elseif self.busyLook then
        wait.time(2)
      else
        break
      end
    end
  end

  function prototype:randomGo(currExits)
    if not currExits or currExits == "" then return nil end
    local exits = utils.split(currExits, ";")
    local exit = exits[math.random(#(exits))]
    self:debug("���ѡ����ڲ�ִ�����¶�λ", exit)
    check(SendNoEcho("halt"))
    check(SendNoEcho(exit))
  end

  function prototype:matchPotentialRooms(currRoomDesc, currRoomExits, potentialRooms)
    local matched = {}
    for i = 1, #potentialRooms do
      local room = potentialRooms[i]
      if room.exits == currRoomExits and room.description == currRoomDesc then
        table.insert(matched, room.id)
      end
    end
    return matched
  end

  return prototype
end
-- ���������Ҫ�ȵ���ͼ���ƺ��ٿ���
local travel = define_travel().FSM()
