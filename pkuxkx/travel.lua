--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:36
-- To change this template use File | Settings | File Templates.
--

--------------------------------------------------------------
-- travel.lua
-- �ṩ��λ�����߹��ܣ�ʹ��travel�鿴����ʹ��
-- history:
-- 2017/3/15 ����
-- 2017/3/24 �޸ģ����busy�¼���ͬʱ����flood�¼������׽������������
-- �Կ��ܷ���map change��·����ǲ�����quickģʽ��ͬʱ����floodʱ���ȶ�
-- ��ǰ�������ֱ�����ڷ����仯���ٽ��к������ߡ�
-- 2017/5/9 �޸ģ���ӱ����������ȡ���������б������Ƿ���Ӳ���
-- 2017/5/9 ��ͬһ������Ȼ���ܳ����޷��ӷ���A���﷿��B���������������ɽ��ɽ���ڶ���
-- 2017/5/24 ���ȫ�ֲ����жϣ����ڶԻ��������ṩ�������������֧��
-- 2017/5/26 ���specialMode��֧�����飬��Ԫ��
--
-- ��ģ�������FSM���ģʽ��Ŀ�����ȶ������ã��ݴ�
-- FSM״̬�У�
-- 1. stop ֹͣ״̬
-- 2. locating ��λ��
-- 3. located �Ѷ�λ
-- 4. walking ������
-- 5. lost ��·��
-- 6. boat �˴�
-- 7. busy�������ظ���ͬ���������ɽ·�ȣ�
-- 8. flood (��ˮ���·�����ڷ����仯)
-- 9. blocked ���赲�У�Ŀǰ��ûʵ�֣�
-- ״̬ת����
-- ��stop״̬����ͨ������STOP��Ϣ��ת��Ϊstop״̬
-- stop -> locating (event: START)
-- locating -> locating (event: TRY_RELOCATE)
-- locating -> located (event: LOCATION_CONFIRMED, LOCATION_CONFIRMED_ONLY)
-- locating -> stop (event: MAX_RETRIES, ROOM_NO_EXITS)
-- located -> located (event: START)
-- located -> walking (event: WALK_PLAN_GENERATED)
-- located -> stop (event: WALK_PLAN_NOT_EXISTS)
-- walking -> located (event: ARRIVED)
-- walking -> lost (event: GET_LOST)
-- walking -> boat (event: BOAT)
-- walking -> busy (event: BUSY)
-- walking -> flood (event: FLOOD)
-- walking -> blocked (event: BLOCKED)
-- lost -> locating (event: TRY_RELOCATE)
-- boat -> walking (event: LEAVE_BOAT)
-- busy -> walking (event: EASE)
-- busy -> busy (event: BUSY)
-- flood -> walkting (event: EXITS_CHANGE_BACK)
-- blocked -> walking (event: CLEARED)
--
-- ����API��
-- travel:stop() ��ʼ��״̬������ʱ���ȶ�λ��ǰ���䣬�����ڴ��������
-- travel:setMode(mode) ��������ģʽ���ṩ"quick", "normal", "slow"����ģʽ
-- ~ quickģʽ��ÿ12��ͣ��1�룬ͨ��travel:setInterval(steps)�޸�
--   ��Ҫע�⣬��quickģʽ�£���·�ض���ֻ����Ϣ���ʱ���жϣ������ڶ̾��������
--   ����·���п��ܻᵽ�����ص㡣
-- ~ normalģʽ��ÿ������ͣ��
-- ~ slowģʽ��ÿ��ͣ��1�룬ͨ��travel:setDelay(seconds)�޸��ӳ�ʱ��
-- travel:relocate() �ض�λ��������coroutine�е���
-- travel:walkto(roomId, action)
-- ָ��Ŀ�ĵ�(roomId)���ߣ������Ҫ���ȶ�λ��ǰ���䣬actionΪ�������ִ�к�����
-- �ɰ���Э�̷���(��wait.lua�ṩ��time, regexp����)
-- travel:waitUntilArrived() ���walkto�����д���callback������������Ҫ��
-- �ṩ�ú�������������wait.regexp�����÷���yieldֱ������Ŀ�ĵء�
-- travel:generateWalkPlan(fromRoomId, toRoomId) ��ȡָ�����ص���·��ջ
--
-- ���⣬�ṩ�ɱ�̵Ľӿڣ���ֱ�ӱ�����
-- travel:setTraverse(args)
-- ָ��Ŀ�귿���뷶Χ��Ĭ��ÿ�������ڷ������Ϊ1�������б�����dfs�㷨����checkΪ
-- ������ÿһ��ǰִ�еļ�飬���뷵��true��false�������Ϊtrueʱ��walk��ֱ����Ծ���
-- ������Ҫ�����ķ��䣬���뵽��״̬����ִ��action��
-- ע�⣬��ǰ������뱻��λΪrooms�еķ��䣬����ֱ��ʧ�ܣ�����walkto��ָ�������ٵ���
-- traverse������ͬʱ�����traverse��������·�������±������з��䣬���Դ���ͬwalking
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
local db = dbDef.open("data/pkuxkx-utf8.db")
local dalDef = require "pkuxkx.dal"
local dal = dalDef.open(db)
local Room = require "pkuxkx.Room"
local ZonePath = require "pkuxkx.ZonePath"
local RoomPath = require "pkuxkx.RoomPath"
local PathCategory = RoomPath.Category
local Deque = require "pkuxkx.deque"
local boat = require "pkuxkx.boat"

-- inherit global excluded zones
local ExcludedBlockZones = ExcludedBlockZones
local ExcludedZones = ExcludedZones

local define_travel = function()
  local prototype = FSM.inheritedMeta()
  -- ״̬�б�
  local States = {
    stop = "stop",  -- ֹͣ״̬
    walking = "walking",  -- ������
    lost = "lost",  -- ��·��
    blocked = "blocked", -- ���赲
    locating = "locating",  -- ��λ��
    located = "located", -- �Ѷ�λ
    busy = "busy",    -- ����æµ��
    boat = "boat",    -- �˴���
    flood = "flood",    -- ��ˮ
  }
  -- �¼��б�
  local Events = {
    START = "start",    -- ��ʼ�źţ���ֹͣ״̬��ʼ�������ض�λ�����Ѷ�λ״̬��ʼ����������
    STOP = "stop",    -- ֹͣ�źţ��κ�״̬�յ����źŶ���ת����stop״̬
    LOCATION_CONFIRMED = "location_confirmed",    -- ȷ����λ��Ϣ
    LOCATION_CONFIRMED_ONLY = "location_confirmed_only",    -- ��ȷ����λ��Ϣ
    ARRIVED = "arrived",    -- ����Ŀ�ĵ��ź�
    GET_LOST = "get_lost",    -- ��·�ź�
    MAX_RELOC_RETRIES = "max_reloc_retries",    -- �����ض�λ����������
    MAX_RELOC_MOVES = "max_reloc_moves",    -- �����ض�λ�ƶ��������ÿ�Σ�
    ROOM_NO_EXITS = "room_no_exits",    -- ����û�г���
    WALK_PLAN_NOT_EXISTS = "walk_plan_not_exists",    -- ���߼ƻ��޷�����
    WALK_PLAN_GENERATED = "walk_plan_generated",    -- ���߼ƻ�����
    BOAT = "boat",    -- �˴��ź�
    LEAVE_BOAT = "leave_boat",    -- �´��ź�
    BUSY = "busy",    -- busy�ź�
    EASE = "ease",    -- ���busy�ź�
    BLOCKED = "blocked",    -- �����ź�
    CLEARED = "cleared",    -- ��������ź�
    TRY_RELOCATE = "try_relocate",    -- �����ض�λ
    ROOM_INFO_UNKNOWN = "room_info_unknown",    -- û�л�ȡ��������Ϣ
    WALK_NEXT_STEP = "walk_next_step",    -- ����һ��
    FLOOD = "flood",    -- ��ˮ������ͼ�仯
    FLOOD_OVER = "flood_over",    -- ��ˮ��������ͼ�ָ�ԭ��
    FLOOD_CONTINUED = "flood_continued",    -- ��ˮ����
  }
  -- �����б�
  local REGEXP = {
    -- aliases
    ALIAS_TRAVEL = "^travel\\s*$",
    ALIAS_STOP = "^travel\\s+stop\\s*$",
    ALIAS_DEBUG = "^travel\\s+debug\\s+(on|off)\\s*$",
    ALIAS_RELOC = "^reloc\\s*$",
    ALIAS_WALKTO = "^walkto\\s*$",
    ALIAS_WALKTO_ID = "^walkto\\s+(\\d+)\\s*$",
    ALIAS_WALKTO_CODE = "^walkto\\s+([a-z][a-z0-9]+)\\s*$",
    ALIAS_WALKTO_LIST = "^walkto\\s+listzone\\s+([a-z]+)\\s*$",
    ALIAS_WALKTO_MODE = "^walkto\\s+mode\\s+(quick|normal|slow)$",
    ALIAS_WALKTO_FIRST = "^walkf\\s+(.*?)\\s*$",
    ALIAS_WALKTO_BEFORE_FIRST = "^walkbf\\s+(.*?)\\s*$",
    ALIAS_WALK_NPC = "^walknpc\\s+(.*?)\\s*$",
    ALIAS_TRAVERSE = "^traverse\\s+(\\d+)\\s*([^ ]*)$",
    ALIAS_TRAVERSE_ZONE = "^traverse\\s+([a-z][a-z0-9]+)\\s*([^ ]*)$",
    ALIAS_LOC_HERE = "^loc\\s+here\\s*$",
    ALIAS_LOC_ID = "^loc\\s+(\\d+)$",
    ALIAS_LOC_GUESS = "^loc\\s+guess\\s*$",
    ALIAS_LOC_MATCH_ID = "^loc\\s+match\\s+(\\d+)\\s*$",
    ALIAS_LOC_UPDATE_ID = "^loc\\s+update\\s+(\\d+)\\s*$",
    ALIAS_LOC_MU_ID = "^loc\\s+mu\\s+(\\d+)\\s*$",
    ALIAS_LOC_SHOW = "^loc\\s+show\\s*$",
    ALIAS_LOC_LMU_ID = "^loc\\s+lmu\\s+(\\d+)\\s*$",
    ALIAS_LOC_TASK = "^loctask\\s+(.+?)\\s+(.+?)\\s*$",
    ALIAS_LOC_NPC = "^locnpc\\s+(.+?)\\s*$",
    ALIAS_ADD_NPC = "^addnpc\\s+(.+?)\\s+(.+?)\\s*$",
    -- triggers
    ROOM_NAME_WITH_AREA = "^[ >]*(.{0,14}) {1,2}\\- \\[[^ ]+\\]$",
    ROOM_NAME_WITHOUT_AREA = "^[ >]*(.{0,14}) {1,2}\\- $",
    ROOM_DESC = "^ {0,14}([^ ].*?) *$",
    SEASON_TIME_DESC = "^    ��([^\\\\x00-\\\\xff]+?)��: (.*)$",
    EXITS_DESC = "^\\s{0,12}����(����|Ψһ)�ĳ�����(.*)$|^\\s*����û���κ����Եĳ�·\\w*",
    BUSY_LOOK = "^[> ]*�羰Ҫ�����Ŀ���$",
    NOT_BUSY = "^[ >]*�����ڲ�æ��$",
    WALK_LOST = "^[> ]*(��Ӵ����һͷײ��ǽ�ϣ��ŷ����������û�г�·��|�������û�г�·��|��һ��С�Ľ���̤�˸��գ�... ��...��|�㷴ӦѸ�٣���æ˫�ֱ�ͷ��������������ǰ����ڵأ�˳��ɽ·ֱ������ȥ��)$",
    WALK_LOST_SPECIAL = "^[ >]*��Ƥһ����ס�㣺Ҫ��Ӵ˹���������·�ƣ���Ƥһ����ס���㡣$",
    WALK_RESUME =  table.concat({
      "^[ >]*(", -- ƥ�俪ͷ
      table.concat({
        "�����������˶��棬�����ʯͷ�������",
        "ͻȻ����һ����ƨ��ײ����ʲô���£�",
        "������һ���������ڰ�������ͷ",
        "��֪���˶�ã������ڿ����ˣ����۵���ͷ��",
        "С�����ڻ�����������Ӵ������˳���",
        "������̤��������ȥ",
        "������Ů��С��ϵ����֦֮�ϣ�����ϰ�ȥ",
        "ͻȻ��ͻȻ����̤�˸��գ�����һ�������ӵ�ʱ������ȥ",
        "�㳯������˻��ֱ���ϰ�ȥ",
        "������������������·������ˣ�������ʮ���Ǳ�",
        "������������������·������ˣ�������ʮ���Ǳ�",
      }, "|"), -- ��·����
      ").*$", -- ƥ�����
    }, ""),
    -- ����䵱����busy
    WALK_BUSY =  table.concat({
      "^[ >]*(", -- ƥ�俪ͷ
      table.concat({
        "���ߵ���ǰ������ؿ��������Ż�",  -- dalunsi
        "���Ż�û��������������������ˣ����ܻ����пɳ�֮����",  -- lingxiao
        "��С��������ǰŲ���������������д���ֻ�÷����Ų�",  -- chengdu
        "�㻹��ɽ�а��棬һʱ�������߲���",  -- huizuxiaozhen
        "�ຣ��������ʤ�գ��㲻��ͣ�½Ų����������˷羰",  -- dalunsi
        "�㲻С�ı�ʲô��������һ��",  -- unknown
        "��Ķ�����û����ɣ������ƶ�",  -- busy
        "ɳʯ�ؼ���û��·�ˣ����߲�����ô��",  -- huangzhong
        "��·����û��·�ˣ����߲�����ô��",  -- huangzhong
        "ɳĮ�м���û��·�ˣ����߲�����ô��",  -- huangzhong
        "��ѻ�������ԭλ�����ڱ���ס��",  -- baituo
      }, "|"), -- ��·����
      ").*$", -- ƥ�����
    }, ""),
    WALK_BLOCK = "^[> ]*��Ķ�����û����ɣ������ƶ�.*$",
    WALK_STEP = helper.settingRegexp("travel", "walk_step"),
    ARRIVED = helper.settingRegexp("travel", "arrived"),
    LOOK_DONE = helper.settingRegexp("travel", "look_done"),
    strange = "�㲻С�ı�ʲô��������һ�£����ˤ�����ͷ��",
    FLOOD_OCCURRED = "^[ >]*(���Ҫǰ�У���Ȼ���ֽ�ˮ���̣����ɰ������ң�����û��ȥ��|����Ҫǰ�У����˴�ȣ��ƺӾ����������ܰ���)$",
    -- ���е�·npc����
    BLOCKED = table.concat({
      "^[ >]*(", -- ƥ�俪ͷ
      table.concat({
        "����ʤ������ס��˵��",  -- taishan
        "�컨����˵���������²��Ǻ컨�����",  -- xihu
        "��������������ס�����ȥ·",  -- xingxiu
        "��������һ�Բ�����������������ǰ",  -- xingxiu
        "��ɽ����˵: �����ɵ��Ӳ����϶���ɽ",  -- emei
        "ʦ̫��ס�����ȥ·",  -- emei
        "�ٱ���ס�����ȥ·",  -- kangqinwangfu
        "���������ס��˵���������Ǳ����صأ��㲻���䵱����",  -- wudang
        "С��ͯ��ס��˵����ʦ�����ھ���",  -- wudang
        "���˰�·һ������Ц������ô�����û��ô����", -- wudang
        "����ͷ�ֿ�������Цһ�����ٺ٣���Ȼ��������ͱ�������",  -- wudang
        "������������С���֣���Ҳ�������ĵط�",  -- pingxiwangfu
        "ׯ����ס���㣺ι�����ܸ���˼��˼",  -- mingjiao(lvliushanzhuang)
        "��ԫ˵����������ҽ̵��ӣ�������ɽ",  -- mingjiao
        "������ȵ��������˵ȣ���������",  -- dali
        "÷��������ס�㣬˵�����������չ��������",  -- lingjiu
        "����������ס�㣬˵�����������չ��������",  -- lingjiu
        "���˵�����Ͽ������������ͣ���ĵط���",  -- tidufu
        "��ʿ������һ����վס����ʲô��",  -- lingzhou
        "��������ǰ��ס��˵��������ûʲô�ÿ��ģ������뿪����",  -- tiantan
        "�����̵��Ӵ����ȵ��������صأ����˲�������",  -- shenlongdao
        "�����̵��Ӵ��һ���������ǽ����ͷ�����Ϣ",  -- shenlongdao
        "����¡˵�������������Ҽң�û�±�Ϲת��",  -- tidufu
        "ͯ����˵�������㲻����������̵��ӣ����ҽ̸�ʲô",  -- riyue
        "��������һ���������������������һ���Ͷ��ģ����",  -- baituo
        "��������һ������������ν���������ﲻ�ܽ�ȥ",  -- baituo
      }, "|"), -- ��·����
      ").*$", -- ƥ�����
    }, ""),
    -- ������
    BUS_ARRIVED = "^[ >]*��ͣ����������������³�\\(xia\\)�ˡ�$",
  }
  -- �ض�λ������Դ�����������located��stop״̬ʱ���ã�������locatingʱ��һ
  local RELOC_MAX_RETRIES = 4
  -- ÿ���ض�λ����ƶ�����(ÿ��������1��)��������locating״̬ʱ����
  local RELOC_MAX_MOVES = 50
  -- ����������ʾÿ������
  local DESC_DISPLAY_LINE_WIDTH = 30
  -- quickģʽ����Ϣ�������
  local INTERVAL = 12

  local SpecialRoomDesc = "���������ɹű���ϴ�ٺ��Ѿ��Ҳ��̶á�ʬ���Ұ�����յľ����Ѿ���Ȼ�޴�...."

  local SpecialRenamedZones = {
    ["����������"] = "������",
    ["�������ϳ�"] = "������",
    ["����"] = "�����ϰ�",
    ["�������"] = "����",
    ["�䵱ɽ"] = "�䵱",
    ["����"] = "��ü",
    ["���Һ�ɽ"] = "��ü��ɽ",
  }
  local SpecialRenamedRooms = {
    ["½��ׯ����"] = "����",
    ["����Ĺ"] = "��  ��  Ĺ",
  }
  local TraverseZoneExcludedRooms = {
    [1479] = true,
    [1480] = true,
    [1481] = true,
    [1482] = true,  -- �ᶽ������
  }

  -- room 3185 has 2-line exits descriptions

  -- �������·�������㷨
  local zonesearch = Algo.dijkstra
  -- �������·�������㷨
  local roomsearch = Algo.astar
  -- �����㷨
  local traversal = Algo.traversal

  ---------------- API ----------------
  -- below functions are exposed APIs
  -- for other modules to call
  -------------------------------------

  local SINGLETON
  -- ��ȡʵ����������ÿworld��һ����
  function prototype:FSM()
    if SINGLETON then return SINGLETON end
    SINGLETON = FSM:new()
    setmetatable(SINGLETON, self or prototype)
    SINGLETON:postConstruct()
    return SINGLETON
  end

  -- ����ģʽ
  function prototype:setMode(mode)
    assert(mode == "quick" or mode == "normal" or mode == "slow",
      "ģʽ������Ϊ�������֣�quick, normal, slow")
    self.mode = mode
  end

  -- ������Ϣ�������
  function prototype:setInterval(interval)
    assert(type(interval) == "number", "quickģʽ��Ϣ�����������Ϊ����")
  end

  -- �����ӳ�ʱ��
  function prototype:setDelay(delay)
    assert(type(delay) == "number", "slowģʽÿ���ӳٱ���Ϊ����")
    self.delay = delay
  end

  -- ֹͣ�Զ�����
  function prototype:stop()
    return self:fire(Events.STOP)
  end

  -- ���ñ�������
  function prototype:setTraverse(args)
    local rooms = assert(type(args.rooms) == "table" and args.rooms, "rooms must be a table")
    local check = assert(type(args.check) == "function" and args.check, "check must be a function or thread")
    -- no defensive copy, user should make sure immutable :)
    self.traverseRooms = rooms
    self.traverseCheck = check
  end

  function prototype:traverseZone(zone, check, action)
    assert(zone, "zone cannot be nil")
    assert(action == nil or type(action) == "function", "action can only nil or function")
    if not self.zonesByCode[zone] then
      print("���Ҳ�������", zone)
    else
      local filtered = {}
      local excludedCnt = 0
      for id, room in pairs(self.zonesByCode[zone].rooms) do
        if not TraverseZoneExcludedRooms[id] then
          filtered[id] = room
        else
          excludedCnt = excludedCnt + 1
        end
      end
      if excludedCnt > 0 then
        self:debug("�ų��������Ե���ڵ㣺", excludedCnt)
      end
      self:setTraverse {
        rooms = filtered,
        check = check or function() return false end
      }
      self:fire(Events.START)
      if action then
        self:waitUntilArrived()
        action()
      end
    end
  end

  -- �Զ�����
  function prototype:walkto(targetRoomId)
    assert(type(targetRoomId) == "number", "target room id must be number")
    self.targetRoomId = targetRoomId
    return self:fire(Events.START)
  end

  function prototype:walktoFirst(args)
    local rooms = self:getMatchedRooms(args)
    if not rooms or #(rooms) == 0 then
      ColourNote("red", "", "��ѯ����Ŀ�귿��")
    else
      self.targetRoomId = rooms[1].id
      self.specialMode = "first"
      return self:fire(Events.START)
    end
  end

  function prototype:walktoBeforeFirst(args)
    local rooms = self:getMatchedRooms(args)
    if not rooms or #(rooms) == 0 then
      ColourNote("red", "", "��ѯ����Ŀ�귿��")
    else
      self.targetRoomId = rooms[1].id
      self.specialMode = "beforeFirst"
      return self:fire(Events.START)
    end
  end

  -- �ȴ�ֱ������Ŀ�ĵأ�������coroutine��ʹ��
  -- ע�⣬�������walkto��������action������
  -- �п��ܲ����������⣬���鲻Ҫͬʱʹ�ø÷�����walkto�е�action
  function prototype:waitUntilArrived(timer)
    local currCo = assert(coroutine.running(), "Must be in coroutine")
    local waitPattern = REGEXP.ARRIVED
    if timer then
      -- timer means we need to check the status periodically
      local interval = assert(timer.interval, "interval of timer cannot be nil")
      local check = assert(type(timer.check) == "function" and timer.check, "check of timer must be function")
      while true do
        local line = wait.regexp(waitPattern, interval)
        if line then break end
        if check() then break end
      end
    else
      helper.addOneShotTrigger {
        group = "travel_one_shot",
        regexp = waitPattern,
        response = helper.resumeCoRunnable(currCo)
      }
      return coroutine.yield()
    end
  end

  -- ĳ�������Ƿ�ɱ������޸ĸ÷�����������ĳЩΣ������
  function prototype:isZoneTraversable(zone)
    if self.zonesByCode[zone] then
      return true
    else
      return false
    end
  end

  -- ��ȡָ�������غ�Ŀ�ĵ�֮���·��ջ
  function prototype:generateWalkPlan(fromRoomId, toRoomId)
    local fromid = fromRoomId or self.currRoomId
    local toid = toRoomId or self.targetRoomId
    self:debug("������ʼ�����Ŀ�귿��", fromid, toid)
    local startRoom = self.roomsById[fromid]
    local endRoom = self.roomsById[toid]
    if not startRoom then
      self:debug("��ǰ���䲻���Զ������б���")
      return nil
    elseif not endRoom then
      self:debug("Ŀ�귿�䲻���Զ������б���")
      return nil
    else
      local startZone = self.zonesByCode[startRoom.zone]
      local endZone = self.zonesByCode[endRoom.zone]
      if not startZone then
        self:debug("��ǰ�������Զ������б���", startRoom.zone)
        return nil
      elseif not endZone then
        self:debug("Ŀ���������Զ������б���", endRoom.zone)
        return nil
      elseif startZone == endZone then
        if self.DEBUG then
          local roomCnt = 0
          for _, room in pairs(startZone.rooms) do
            roomCnt = roomCnt + 1
          end
          self:debug("��������Ŀ�ĵش���ͬһ���򣬹�" .. roomCnt .. "������")
        end
        local plan = roomsearch {
          rooms = startZone.rooms,
          startid = fromid,
          targetid = toid
        }
        self:printPlan(plan, "ֱ��")
        if plan then
          return plan
        end
        -- �޸ģ���ͬһ�����޷�����ʱ��ʹ�ñ���ȫͼ������
        ColourNote("yellow", "", "ע�⣬��ǰ�����޷��ӷ���" .. fromid .. "���﷿��" .. toid .. "������ȫ������")
        local fallbackPlan = roomsearch {
          rooms = self.roomsById,
          startid = fromid,
          targetid = toid
        }
        self:printPlan(fallbackPlan, "ֱ��")
        return fallbackPlan
      else
        -- zone search for shortest path
        local zoneStack = zonesearch {
          rooms = self.zonesById,
          startid = startZone.id,
          targetid = endZone.id
        }
        if not zoneStack then
          self:debug("��������·��ʧ�ܣ����� " .. startZone.name .. " ������ " .. endZone.name .. " ���ɴ�")
          return nil
        else
          table.insert(zoneStack, ZonePath:decorate {startid=startZone.id, endid=startZone.id, weight=0})
          -- only for debug
          if self.DEBUG then
            local zones = {}
            for i=1,#zoneStack do
              table.insert(zones, zoneStack[i].name)
            end
            self:debug("������" .. #zoneStack .. "������", table.concat(zones, ", "))
          end

          local zoneCnt = #zoneStack
          local zoneNames = {}
          local rooms = {}
          local roomCnt = 0
          while #zoneStack > 0 do
            local zonePath = table.remove(zoneStack)
            table.insert(zoneNames, self.zonesById[zonePath.endid].code)
            for _, room in pairs(self.zonesById[zonePath.endid].rooms) do
              rooms[room.id] = room
              roomCnt = roomCnt + 1
            end
          end
          self:debug("����·�������" .. zoneCnt .. "������" .. table.concat(zoneNames, ",") .. "����" .. roomCnt .. "������")
          local plan = roomsearch {
            rooms = rooms,
            startid = fromid,
            targetid = toid
          }
          self:printPlan(plan, "ֱ��")
          return plan
        end
      end
    end
  end

  -- ��ȡָ��������Χָ�������ڵı���·��ջ
  function prototype:generateNearbyTraversePlan(centerRoomId, depth, skipStart, crossRiver)
    local rooms = self:getNearbyRooms(centerRoomId, depth, crossRiver)
    return self:generateTraversePlan(rooms, centerRoomId, skipStart)
  end

  -- �����������ĳ����б��Ƿ�һ��
  function prototype:checkExitsIdentical(exits1, exits2)
    if exits1 == nil or exits2 == nil then
      return false
    end
    local ls1 = utils.split(exits1, ";")
    local ls2 = utils.split(exits2, ";")
    if #ls1 ~= #ls2 then
      return false
    end
    local map1 = {}
    for i = 1, #ls1 do
      map1[ls1[i]] = true
    end
    for i = 1, #ls2 do
      if not map1[ls2[i]] then
        return false
      end
    end
    return true
  end

  ----------- Alias-only API ----------
  -- below functions are only used
  -- in alias
  -------------------------------------

  -- ����-ƥ��
  function prototype:match(roomId, performUpdate)
    local performUpdate = performUpdate or false
    local room = dal:getRoomById(roomId)
    if not room then
      ColourNote("red", "", "��ѯ����ָ����ŵķ��䣺" .. roomId)
      return
    end
    -- �ȽϷ�������
    if not self.currRoomName then
      ColourNote("red", "", "��ǰ�����޿�ȷ�������ƣ�����ʹ��LOC��λ���׽")
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
      if not currExits[helper.expandDirection(tgtPath.path)] then
        self:debug("·��" .. tgtPath.path .. "δ�ҵ�")
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
        ColourNote("yellow", "", "����ƥ�䵫·����ƥ�䣬������������ݿ⣬����Ҫ���ֶ�update")
      else
        ColourNote("yellow", "", "����ƥ�䵫·����ƥ��")
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
        ColourNote("yellow", "", "������·������ƥ�䣬������������ݿ⣬����Ҫ���ֶ�update")
      else
        ColourNote("yellow", "", "������·������ƥ��")
      end
    end
    print(table.concat(pathDisplay, ", "))
  end

  -- ����-����
  function prototype:update(roomId)
    local room = Room:new {
      id = roomId,
      name = self.currRoomName,
      code = "",
      description = table.concat(self.currRoomDesc, ""),
      exits = self.currRoomExits
    }
    dal:updateRoom(room)
  end

  -- ����-�ض�λ
  function prototype:reloc()
    self:fire(Events.STOP)
    self:fire(Events.START)
  end

  function prototype:showDesc(roomDesc)
    if type(roomDesc) == "string" then
      for i = 1, string.len(roomDesc), DESC_DISPLAY_LINE_WIDTH do
        print(string.sub(roomDesc, i, i + DESC_DISPLAY_LINE_WIDTH - 1))
      end
    elseif type(roomDesc) == "table" then
      for _, d in ipairs(roomDesc) do
        print(d)
      end
    end
  end

  -- ����-��ʾ
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
      if not self.currRoomName then
        return
      end
      local potentialRooms = dal:getRoomsByName(self.currRoomName)
      if #(potentialRooms) >= 1 then
        local ids = {}
        for _, room in pairs(potentialRooms) do
          table.insert(ids, room.id)
        end
        print("ͬ�����䣺", table.concat(ids, ","))
      else
        print("��ͬ������")
      end

      self:debug("��ǰ�������ƣ�", self.currRoomName, "���ȣ�", string.len(self.currRoomName))
      if gb2312.len(self.currRoomName) > 10 then
        print("��ǰ�汾��֧��10�����ֳ����ڵ����Ʋ�ѯ")
      end
      local pinyins = dal:getPinyinListByWord(self.currRoomName)
      self:debug("����ƴ���б�", pinyins and table.concat(pinyins, ", "))
      local candidates = {}
      for _, pinyin in ipairs(pinyins) do
        local results = dal:getRoomsLikeCode(pinyin)
        for id, room in pairs(results) do
          table.insert(candidates, room.id)
        end
      end
      if #candidates > 0 then
        print("ƴ��ͬ�����䣺", table.concat(candidates, ","))
      else
        print("��ƴ��ͬ������")
      end
    end
  end

  -- ����-�²�
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

  function prototype:loctask(args)
    local words = args.words
    local exits = args.exits
    local results = {}
    for _, room in pairs(self.roomsById) do
      local wordsMatched = true
      for _, word in ipairs(words) do
        if not string.find(room.description, word) then
          wordsMatched = false
          break
        end
      end
      if wordsMatched then
        local exitsMatched = true
        local roomExits = {}
        if room.exits and room.exits ~= "" then
          for _, e in ipairs(utils.split(room.exits, ";")) do
            roomExits[e] = true
          end
          for _, e in pairs(exits) do
            if not roomExits[e] then
              exitsMatched = false
              break
            end
          end
        elseif #(exits) > 0 then
          exitsMatched = false
        end
        if exitsMatched then
          table.insert(results, room)
        end
      end
    end
    if #(results) == 0 then
      print("û���ҵ�ƥ�䷿��")
    elseif #(results) == 1 then
      print("ƥ�䵽Ψһ���䣺", results[1].id, results[1].name, results[1].code)
    else
      print("���ڶ������ƥ�䣺")
      for _, room in ipairs(results) do
        print(room.id, room.name, room.code)
      end
    end
  end

  -- �������޵��Զ�����
  -- ������ǰ���䷶ΧΪdepth�ڵ����з���
  function prototype:traverseNearby(depth, check, action, crossRiver)
    if not self.currRoomId then
      print("ʧ�ܡ���ǰ����δ��λ���޷����з�Χ���Զ�����")
    else
      local traverseRooms = self:getNearbyRooms(self.currRoomId, depth, crossRiver)
    -- todo need to consider situation that rooms in maze may not be bi-directional reachable
--      local RoomsInZone = self.zonesByCode[self.roomsById[self.currRoomId].zone].rooms
      if not traverseRooms then
        print("ʧ�ܡ��޷���ȡ���������б�")
      else
        self:setTraverse {
          rooms = traverseRooms,
          check = check or function() return false end
        }
        self:fire(Events.START)
        if action then
          self:waitUntilArrived()
          action()
        end
      end
    end
  end

  -- ͨ���������Ʋ��ҷ����б�
  -- 1. ͨ��ȫ������
  -- 2. ͨ��������������������
  function prototype:getMatchedRooms(args)
    if args.fullname then
      -- check if the fullname match pattern <zone>��<room>
      local delimStart, delimEnd = string.find(args.fullname, "��")
      -- bug fix 2017/5/15: ������� �������д���"��"
      if delimStart and args.fullname ~= "��������ɽׯ�Ĵ���" then
        local zone = string.sub(args.fullname, 1, delimStart - 1)
        local name = string.sub(args.fullname, delimEnd + 1)
        self:debug("��������������", zone)
        self:debug("�����󷿼�����", name)
        return self:getMatchedRooms {
          zone = zone,
          name = name
        }
      end
      local fullname = args.fullname
      -- �ȼ���Ƿ�Ϊ����������
      for roomName, renamed in pairs(SpecialRenamedRooms) do
        local idxStart, idxEnd = string.find(fullname, roomName)
        -- ����ƥ���β
        if idxEnd == string.len(fullname) then
          self:debug("���ַ���Ϊ����������", fullname)
          fullname = string.sub(fullname, 1, idxStart - 1) .. renamed
          break
        end
      end

      local results = {}
      for zoneName, zone in pairs(self.zonesByName) do
        local idxStart, idxEnd = string.find(fullname, zoneName)
        -- ���ַ�ƥ��
        if idxStart == 1 then
          local roomName = string.sub(fullname, idxEnd + 1)
          for _, room in pairs(zone.rooms) do
            if room.name == roomName then
              table.insert(results, room)
            end
          end
          -- �����ٲ�����������
          break
        end
      end
      -- ���β�ѯ�����������������б�
      if #results == 0 then
        -- check renamed zone
        local zoneRenameMatch = false
        for zoneName, renamed in pairs(SpecialRenamedZones) do
          local idxStart, idxEnd = string.find(fullname, zoneName)
          if idxStart == 1 then
            self:debug("����������ƥ��ɹ�")
            zoneRenameMatch = true
            local zone = self.zonesByName[renamed]
            local roomName = string.sub(fullname, idxEnd + 1)
            for _, room in pairs(zone.rooms) do
              if room.name == roomName then
                table.insert(results, room)
              end
            end
            break
          end
        end
      end
      return results
    else
      assert(args.name, "name cannot be nil")
      assert(args.zone, "zone cannot be nil")
      -- �ȼ�鷿���Ƿ�Ϊ����������
      local name = SpecialRenamedRooms[args.name] or args.name

      local results = {}
      local zoneName = SpecialRenamedZones[args.zone] or args.zone
      local zone = self.zonesByName[zoneName]
      if not zone then
        return results
      end
      for _, room in pairs(zone.rooms) do
        if room.name == name then
          table.insert(results, room)
        end
      end
      return results
    end
  end

  -- ͨ���������Ʋ�������
  function prototype:getMatchedZone(name)
    local name = SpecialRenamedZones[name] or name
    return self.zonesByName[name]
  end

  -------- Internal Functions ---------
  -- below functions should not be
  -- called outside this module
  -------------------------------------

  -- ʵ��������ʼ��
  -- ����״̬��ת���������뷿���б����������������ڲ�����
  function prototype:postConstruct()
    self:initStates()
    self:initTransitions()
    self:initZonesAndRooms()
    self:initTriggers()
    self:initAliases()
    -- this should be the only place to set state
    -- and only once after construct
    -- all state transition should be handled by FSM
    -- built in finctions
    self:setState(States.stop)
    self.blockUsedWeapon = "sword"
    self:resetOnStop()
  end

  -- ��ʼ��״̬�б�
  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        -- must clean the user defined triggers
        helper.removeTriggerGroups("travel_one_shot")
        self:disableAllTriggers()
        self:resetOnStop()
      end,
      exit = function()
      end
    }
    self:addState {
      state = States.locating,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.located,
      enter = function()
        self.relocMoves = 0
        self.walkLost = false
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
        helper.enableTriggerGroups("travel_block_start")
      end,
      exit = function()
        helper.disableTriggerGroups("travel_block_start", "travel_block_done")
      end
    }
    self:addState {
      state = States.busy,
      enter = function()
        self.walkBusy = false
        helper.enableTriggerGroups("travel_walk_busy_start")
      end,
      exit = function()
        helper.disableTriggerGroups(
          "travel_walk_busy_start",
          "travel_walk_busy_done")
      end
    }
    self:addState {
      state = States.boat,
      enter = function()
        assert(self.boatCmd, "boatCmd cannot be nil when entering boat status")
      end,
      exit = function()
        self.boatCmd = nil
      end
    }
    self:addState {
      state = States.flood,
      enter = function()
      end,
      exit = function()
      end
    }
  end

  -- ��ʼ��ת���б�
  -- ת�������������¼�������״̬��ת
  -- ���в����б��ڵ�ת����Ϊ�Ƿ�ת��
  function prototype:initTransitions()
    -- transtions from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.locating,
      event = Events.START,
      action = function()
        return self:relocate()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transitions from state<locating>
    self:addTransition {
      oldState = States.locating,
      newState = States.locating,
      event = Events.TRY_RELOCATE,
      action = function()
        return self:relocate()
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.located,
      event = Events.LOCATION_CONFIRMED,
      action = function()
        self:prepareWalkPlan()
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.located,
      event = Events.LOCATION_CONFIRMED_ONLY,
      action = function()
        self.relocRetries = 0
        print("������¶�λ���������ƣ�", self.currRoomName, "�����ţ�", self.currRoomId)
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.MAX_RELOC_RETRIES,
      action = function()
        print("�ﵽ�ض�λ���Դ�������", self.currState)
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.MAX_RELOC_MOVES,
      action = function()
        print("�ﵽ�����ض�λ�ƶ���������", self.currState)
      end
    }
    self:addTransition {
      oldState = States.locating,
      newState = States.stop,
      event = Events.ROOM_NO_EXITS,
      action = function()
        print("���䲻����")
      end
    }
    self:addTransitionToStop(States.locating)
    -- transitions from state<located>
    self:addTransition {
      oldState = States.located,
      newState = States.located,
      event = Events.START,
      action = function()
        self:prepareWalkPlan()
      end
    }
    self:addTransition {
      oldState = States.located,
      newState = States.walking,
      event = Events.WALK_PLAN_GENERATED,
      action = function()
        -- ���ǿ�ʼ���ߵ�Ψһ��ڣ���ʼ��prevMove������
        -- �ñ�������ǰһ����·����Ϣ������Ӧ�Ժ�ˮ�¼�
        helper.checkUntilNotBusy()
        SendNoEcho("halt")  -- the halt command is required in case in combat
        self.prevMove = nil
        self.prevCheck = false
        return self:walking()
      end
    }
    self:addTransition {
      oldState = States.located,
      newState = States.stop,
      event = Events.WALK_PLAN_NOT_EXISTS,
      action = {
        beforeExit = function()
          if self.traverseCheck then
            ColourNote("red", "", "�Զ�����ʧ�ܣ��޷����������б�")
          else
            ColourNote("red", "", "�Զ�����ʧ�ܣ����䲻�ɴ� " .. self.currRoomId .. " -> " .. self.targetRoomId)
          end
        end,
        afterEnter = function() end
      }
    }
    self:addTransitionToStop(States.located)
    -- transitions from state<walking>
    self:addTransition {
      oldState = States.walking,
      newState = States.walking,
      event = Events.WALK_NEXT_STEP,
      action = function()
        return self:walking()
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.located,
      event = Events.ARRIVED,
      action = function()
        self.specialMode = nil
        self.walkPlan = nil
        self.prevMove = nil
        self.prevCheck = false
        self.relocRetries = 0
        -- ����ֱ�������
        if self.traverseCheck then
          self.currRoomId = self.traverseRoomId
          self:refreshRoomInfo()
          self:clearTraverseInfo()
        else
          self.currRoomId = self.targetRoomId
          self:refreshRoomInfo()
        end
        SendNoEcho("set travel arrived")  -- this is for other callbacks
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.blocked,
      event = Events.BLOCKED,
      action = function()
        assert(self.blockCmd, "blockCmd cannot be nil when blocked")
        assert(self.blockers, "blockers cannot be nil when blocked")
        return self:clearBlockers()
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.lost,
      event = Events.GET_LOST,
      action = function()
        print("��·���������ض�λ" .. self.relocRetries .. "��", self.currState)
        return self:fire(Events.TRY_RELOCATE)
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.busy,
      event = Events.BUSY,
      action = function()
        assert(self.walkBusyCmd, "����busy״̬walkBusyCmd��������Ϊ��")
        self:debug("�ȴ�2��ִ��walkBusyCmd:", self.walkBusyCmd)
        wait.time(2)
        return self:walkingBusy()
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.boat,
      event = Events.BOAT,
      action = function()
        self:debug("�ȴ�����", self.boatCmd)
        boat:restart(self.boatCmd)
        boat:waitUntilArrived {
          interval = 2,
          check = function()
            return self.currState == States.stop
          end
        }
        return self:fire(Events.LEAVE_BOAT)
      end
    }
    self:addTransition {
      oldState = States.walking,
      newState = States.flood,
      event = Events.FLOOD,
      action = function()
        -- ��ȡ��ǰ������Ϣ
        self:lookUntilNotBusy()
        self.snapshotExits = self.currRoomExits
        return self:fire(Events.FLOOD_CONTINUED)
      end
    }
    self:addTransitionToStop(States.walking)
    -- transitions from state<blocked>
    self:addTransition {
      oldState = States.blocked,
      newState = States.walking,
      event = Events.CLEARED,
      action = function()
        return self:walking()
      end
    }
    self:addTransitionToStop(States.blocked)
    -- transitions from state<lost>
    self:addTransition {
      oldState = States.lost,
      newState = States.locating,
      event = Events.TRY_RELOCATE, -- always try relocate and the retries threshold is checked when locating
      action = function()
        self.relocRetries = self.relocRetries + 1
        return self:relocate()
      end
    }
    self:addTransitionToStop(States.lost)
    -- transitions from state<busy>
    self:addTransition {
      oldState = States.busy,
      newState = States.walking,
      event = Events.EASE,
      action = function()
        if self.walkBusyResumeCmd then
          self:sendPath(self.walkBusyResumeCmd)
        end
        -- ����busy����
        self.walkBusyCmd = nil
        self.walkBusyResumeCmd = nil
        return self:walking()
      end
    }
    self:addTransition {
      oldState = States.busy,
      newState = States.busy,
      event = Events.BUSY,
      action = function()
        assert(self.walkBusyCmd, "busy״̬walkBusyCmd��������Ϊ��")
        self:debug("�ȴ�2��ִ��walkBusyCmd:", self.walkBusyCmd)
        wait.time(2)
        return self:walkingBusy()
      end
    }
    self:addTransitionToStop(States.busy)
    -- transition from state<boat>
    self:addTransition {
      oldState = States.boat,
      newState = States.walking,
      event = Events.LEAVE_BOAT,
      action = function()
        return self:walking()
      end
    }
    self:addTransitionToStop(States.boat)
    -- transition from state<flood>
    self:addTransition {
      oldState = States.flood,
      newState = States.walking,
      event = Events.FLOOD_OVER,
      action = function()
        self.floodOccurred = false
        self.snapshotExits = nil
        self:debug("��ˮ�������������ں�ˮ���ߵ�һ��������ǰ��")
        table.insert(self.walkPlan, self.prevMove)
        SendNoEcho("halt")
        return self:walking()
      end
    }
    self:addTransition {
      oldState = States.flood,
      newState = States.flood,
      event = Events.FLOOD_CONTINUED,
      action = function()
        self:debug("�ȴ�10������»�ȡ��ǰ���������Ϣ������նԱ�")
        wait.time(10)
        self:lookUntilNotBusy()
        if self.currRoomExits == self.snapshotExits then
          self:debug("����û�б仯��������ˮû�����ˣ������ȵ�")
          return self:fire(Events.FLOOD_CONTINUED)
        else
          return self:fire(Events.FLOOD_OVER)
        end
      end
    }
  end

  -- ���������б�ͷ����б�
  function prototype:initZonesAndRooms()
    -- initialize zones
    local zonesById
    if ExcludedZones then
      zonesById = dal:getAllZonesExcludedZones(ExcludedZones)
    else
      zonesById = dal:getAllZones()
    end
--    local zonesById = dal:getAllZones()
    local zonePaths = dal:getAllZonePaths()
    for i = 1, #zonePaths do
      local zonePath = zonePaths[i]
      local zone = zonesById[zonePath.startid]
      local toZone = zonesById[zonePath.endid]
      if zone and toZone then
        zone:addPath(zonePath)
      end
    end
    -- create code map
    local zonesByCode = {}
    for _, zone in pairs(zonesById) do
      zonesByCode[zone.code] = zone
    end
    local zonesByName = {}
    for _, zone in pairs(zonesById) do
      zonesByName[zone.name] = zone
    end
    -- initialize rooms
    local roomsById
    if ExcludedBlockZones then
      roomsById = dal:getAllAvailableRoomsExcludedBlockZones(ExcludedBlockZones)
    else
      roomsById = dal:getAllAvailableRooms()
    end
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
    self.zonesByName = zonesByName
    self.roomsById = roomsById
    self.roomsByCode = roomsByCode
    print("��ͼ���ݼ�����ϣ���" .. helper.countElements(self.zonesByCode) .. "������" ..
      helper.countElements(self.roomsByCode) .. "������")
    if ExcludedZones then
      print("��������", table.concat(ExcludedZones, ", "))
    end
    if ExcludedBlockZones then
      print("���β����谭����", table.concat(ExcludedBlockZones, ", "))
    end
  end

  -- ��ʼ��������
  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "travel_look_start",
      "travel_look_name",
      "travel_look_desc",
      "travel_look_season",
      "travel_look_exits",
      "travel_walk",
      "travel_block_start",
      "travel_block_done",
      "travel_walk_busy_start",
      "travel_walk_busy_done"
    )

    -- ��ʼ����
    helper.addTrigger {
      group = "travel_look_start",
      regexp = helper.settingRegexp("travel", "look_start"),
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
      regexp = REGEXP.ROOM_NAME_WITH_AREA,
      response = roomNameCaught,
      sequence = 15 -- lower than desc
    }
    helper.addTrigger {
      group = "travel_look_name",
      regexp = REGEXP.ROOM_NAME_WITHOUT_AREA,
      response = roomNameCaught,
      sequence = 15 -- lower than desc
    }
    -- ��Ƶ��ʹ��lookʱ��ϵͳ��������羰����ʾ����ʱ�޷���ȡ���������ƺ�����
    helper.addTrigger {
      group = "travel_look_name",
      regexp = REGEXP.BUSY_LOOK,
      response = function()
        self:debug("BUSY_LOOK triggered")
        self:debug("Ƶ��ʹ��look�����ʾ�����ˣ�")
        self.busyLook = true
      end
    }
    -- ץȡ��������
    helper.addTrigger {
      group = "travel_look_desc",
      regexp = REGEXP.ROOM_DESC,
      response = function(name, line, wildcards)
        self:debug("ROOM_DESC triggered")
        if string.find(line, "travel = \"look_done\"") or string.find(line, "һƬŨ���У�ʲôҲ�����塣") then
          self._roomDescInline = false
        end
        if self._roomDescInline then
          table.insert(self.currRoomDesc, wildcards[1])
        end
      end
    }
    -- ���ں�ʱ������
    helper.addTrigger {
      group = "travel_look_season",
      regexp = REGEXP.SEASON_TIME_DESC,
      response = function(name, line, wildcards)
        self:debug("SEASON_TIME_DESC triggered")
        if self._roomDescInline then
          self._roomDescInline = false
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
      regexp = REGEXP.EXITS_DESC,
      response = function(name, line, wildcards)
        self:debug("EXITS_DESC triggered")
        if self._roomDescInline then
          self._roomDescInline = false
          helper.disableTriggerGroups("travel_look_desc")    -- ��ֹ���ץȡ����
        end
        if self._roomExitsInline then
          self._roomExitsInline = false
          self.currRoomExits = self:formatExits(wildcards[2] or "look")
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
      regexp = REGEXP.WALK_LOST,
      response = lostWay
    }
    helper.addTrigger {
      group = "travel_walk",
      regexp = REGEXP.WALK_LOST_SPECIAL,
      response = lostWay
    }
    helper.addTrigger {
      group = "travel_walk",
      regexp = REGEXP.WALK_BLOCK,
      response = lostWay
    }
    helper.addTrigger {
      group = "travel_walk",
      regexp = REGEXP.FLOOD_OCCURRED,
      response = function()
        self.floodOccurred = true
        self.snapshotExits = nil
        self:debug("��ˮ���ģ�������ڸı�")
      end
    }
    helper.addTrigger {
      group = "travel_walk",
      regexp = REGEXP.BUS_ARRIVED,
      response = function()
        self.busArrived = true
      end
    }
    -- busy����
    helper.addTrigger {
      group = "travel_walk_busy_start",
      regexp = helper.settingRegexp("travel", "walkbusy_start"),
      response = function()
        helper.enableTriggerGroups("travel_walk_busy_done")
      end
    }
    helper.addTrigger {
      group = "travel_walk_busy_done",
      regexp = helper.settingRegexp("travel", "walkbusy_done"),
      response = function()
        if self.walkBusy then
          return self:fire(Events.BUSY)
        else
          return self:fire(Events.EASE)
        end
      end
    }
    helper.addTrigger {
      group = "travel_walk_busy_done",
      regexp = REGEXP.WALK_BUSY,
      response = function()
        self.walkBusy = true
      end
    }
    -- �赲����
    helper.addTriggerSettingsPair {
      group = "travel",
      start = "block_start",
      done = "block_done"
    }
    helper.addTrigger {
      group = "travel_block_done",
      regexp = REGEXP.BLOCKED,
      response = function()
        self:debug("BLOCKED triggered")
        self.blocked = true
      end
    }
  end

  -- ��ʼ������
  function prototype:initAliases()
    helper.removeAliasGroups("travel")
    -- ˵��
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_TRAVEL,
      response = function()
        print("TRAVEL�Զ�����ָ�ʹ�÷�����")
        print("travel debug on/off", "����/�رյ���ģʽ������ʱ������ʾ���д���������־��Ϣ")
        print("travel stop", "ֹͣ�Զ����߻��ض�λ")
        print("reloc", "���¶�λֱ����ǰ�����Ψһȷ��")
        print("walkto mode quick/normal/slow", "�����Զ�����ģʽ��quick���������ߣ�ÿ12����Ϣ1�룻normal��ÿ������ͣ�٣�slow��ÿ��ͣ��1��")
        print("walkto <number>", "����Ŀ�귿���Ž����Զ����ߣ������ǰ����δ֪���Ƚ������¶�λ")
        print("walkto <room_code>", "����Ŀ�귿����Ž����Զ����ߣ��������Ϊ�������������ߵ���������Ľڵ�")
        print("walkto showzone", "��ʾ�Զ�����֧�ֵ������б�")
        print("walkto listzone <zone_code>", "��ʾ��Ӧ�������пɴ�ķ���")
        print("ͬʱ�ṩ��ͼ¼�빦�ܣ�")
        print("loc here", "���Զ�λ��ǰ���䣬��׽��ǰ������Ϣ����ʾ")
        print("loc <number>", "��ʾ���ݿ���ָ����ŷ������Ϣ")
        print("loc match <number>", "����ǰ������Ŀ�귿����жԱȣ�����Ա����")
        print("loc update <number>", "����ǰ�������Ϣ���½����ݿ⣬��ȷ����Ϣ����ȷ��")
        print("loc show", "����ʾ��ǰ������Ϣ������look��λ")
        print("loc guess", "ͨ���������Ƶ�ƴ���������Ƶķ���")
        print("loc mu <number>", "����ǰ������Ŀ�귿��Աȣ������Ϣƥ�䣬�����")
        print("loc lmu <number>", "�鿴��ǰ���䣬��Ŀ�귿��ԱȲ����и��£��ò�����Ҫ����Ϊ��ͼ��ӻ���½ڵ�")
        print("�ṩnpc��λ�������Լ�¼�빦�ܣ�")
        print("locnpc <npc name or id>", "��λͬ����ͬid��npc����")
        print("walknpc <npc name or id>", "������ͬ����ͬid��npc����")
        print("addnpc <npc name> <npc id>", "���npc�����ݿ⣬npc��������(�����пո�ָ�)Ϊ����1��npc��Ӣ��id�����пո�ָ���������ȫ����Ϊ����2")
      end
    }
    -- ����ģʽ
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_DEBUG,
      response = function(name, line, wildcards)
        local option = wildcards[1]
        if option == "on" then
          self:debugOn()
        elseif option == "off" then
          self:debugOff()
        end
      end
    }
    -- ֹͣ����
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_STOP,
      response = function ()
        self:stop()
      end
    }
    -- �ض�λ
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_RELOC,
      response = function()
        self:reloc()
      end
    }
    -- �Զ�����(������)
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_WALKTO_ID,
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:walkto(targetRoomId)
        self:waitUntilArrived()
        self:debug("����Ŀ�ĵ�")
      end
    }
    -- �Զ�����(�������)
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_WALKTO_CODE,
      response = function(name, line, wildcards)
        local target = wildcards[1]
        if target == "showzone" then
          print(string.format("%16s%16s%16s", "�������", "��������", "��������"))
          for _, zone in pairs(self.zonesById) do
            print(string.format("%12s%16s%20s", zone.code, zone.name, zone.centercode))
          end
        elseif self.zonesByCode[target] then
          local targetRoomCode = self.zonesByCode[target].centercode
          local targetRoomId = self.roomsByCode[targetRoomCode].id
          self:stop()
          self:walkto(targetRoomId)
          self:waitUntilArrived()
          self:debug("����Ŀ�ĵ�")
        elseif self.roomsByCode[target] then
          local targetRoomId = self.roomsByCode[target].id
          self:stop()
          self:walkto(targetRoomId)
          self:waitUntilArrived()
          self:debug("����Ŀ�ĵ�")
        else
          print("��ѯ������Ӧ����")
          return false
        end
      end
    }
    -- �����б�
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_WALKTO_LIST,
      response = function(name, line, wildcards)
        local zoneCode = wildcards[1]
        if self.zonesByCode[zoneCode] then
          local zone = self.zonesByCode[zoneCode]
          print(string.format("%s(%s)�����б�", zone.name, zone.code))
          print(string.format("%4s%20s%40s", "���", "����", "����"))
          for _, room in pairs(zone.rooms) do
            print(string.format("%4d%20s%40s", room.id, room.name, room.code))
          end
        else
          print("��ѯ������Ӧ����")
        end
      end
    }
    -- ����ģʽ
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_WALKTO_MODE,
      response = function(name, line, wildcards)
        local mode = wildcards[1]
        self:setMode(mode)
      end
    }
    -- ������Χ
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_TRAVERSE,
      response = function(name, line, wildcards)
        local depth = tonumber(wildcards[1])
        local checkName = wildcards[2]
        if checkName ~= "" then
          self:debug("������ʱ��������ƥ��", checkName)
          local checked = false
          helper.addOneShotTrigger {
            group = "travel_one_shot",
            regexp = checkName,
            response = function()
              checked = true
            end
          }
          local onStep = function()
            return checked
          end
          local onArrive = function()
            helper.removeTriggerGroups("travel_one_shot")
            if checked then
              ColourNote("green", "", "�ѷ���Ŀ�ֹ꣬ͣ����")
            else
              ColourNote("yellow", "", "δ����Ŀ�꣬��������")
            end
          end
          return self:traverseNearby(depth, onStep, onArrive)
        end
        return self:traverseNearby(depth)
      end
    }
    -- ��������
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_TRAVERSE_ZONE,
      response = function(name, line, wildcards)
        local zone = wildcards[1]
        local checkName = wildcards[2]
        if checkName ~= "" then
          print("������ʱ��������ƥ��", checkName)
          local checked = false
          helper.addOneShotTrigger {
            group = "travel_one_shot",
            regexp = checkName,
            response = function()
              checked = true
            end
          }
          local onStep = function()
            return checked
          end
          local onArrive = function()
            helper.removeTriggerGroups("travel_one_shot")
            if checked then
              ColourNote("green", "", "�ѷ���Ŀ�ֹ꣬ͣ����")
            else
              ColourNote("yellow", "", "δ����Ŀ�꣬��������")
            end
          end
          return self:traverseZone(zone, onStep, onArrive)
        end
        return self:traverseZone(zone)
      end
    }
    -- ���µ�ͼ��鿴����
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_HERE,
      response = function()
        self:lookUntilNotBusy()
        self:show()
      end
    }
    -- ��ѯ����
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_ID,
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
    -- �²ⷿ��
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_GUESS,
      response = function()
        self:guess()
      end
    }
    -- ƥ�䷿��
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_MATCH_ID,
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:match(targetRoomId)
      end
    }
    -- ���·���
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_UPDATE_ID,
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:update(targetRoomId)
      end
    }
    -- ƥ�䲢���·���
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_MU_ID,
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:match(targetRoomId, true)
      end
    }
    -- ��ʾ����
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_SHOW,
      response = function()
        self:show()
      end
    }
    -- �鿴ƥ�䲢���·���
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_LMU_ID,
      response = function(name, line, wildcards)
        local targetRoomId = tonumber(wildcards[1])
        self:lookUntilNotBusy()
        self:show()
        self:match(targetRoomId, true)
      end
    }
    -- task��ز�ѯ����
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_TASK,
      response = function(name, line, wildcards)
        local words = utils.split(wildcards[1], ",")
        local exits = utils.split(wildcards[2], ",")
        return self:loctask {
          words = words,
          exits = exits
        }
      end
    }
    -- ���ߵ���һ������
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_WALKTO_FIRST,
      response = function(name, line, wildcards)
        local location = wildcards[1]
        return self:walktoFirst {
          fullname = location
        }
      end
    }
    -- ���ߵ���һ������ǰ��һ������
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_WALKTO_BEFORE_FIRST,
      response = function(name, line, wildcards)
        local location = wildcards[1]
        return self:walktoBeforeFirst {
          fullname = location
        }
      end
    }
    -- ��λnpc
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_LOC_NPC,
      response = function(name, line, wildcards)
        local searchPattern = wildcards[1]
        local npcs
        npcs = dal:getNpcsByName(searchPattern)
        if not npcs or #npcs == 0 then
          npcs = dal:getNpcsById(searchPattern)
        end

        if not npcs or #npcs == 0 then
          ColourNote("yellow", "", "�޷���ѯ��NPC��" .. searchPattern)
        else
          print(string.format("%20s %20s %10s %20s", "����", "ID", "����", "����"))
          for _, npc in ipairs(npcs) do
            print(string.format("%20s %20s %10d %20s", npc.name, npc.id, npc.roomid, npc.zone))
          end
        end
      end
    }
    -- ���ߵ�ָ��npc
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_WALK_NPC,
      response = function(name, line, wildcards)
        local searchPattern = wildcards[1]
        local npcs
        npcs = dal:getNpcsByName(searchPattern)
        if not npcs or #npcs == 0 then
          npcs = dal:getNpcsById(searchPattern)
        end

        if not npcs or #npcs == 0 then
          ColourNote("yellow", "", "�޷���ѯ��NPC: " .. searchPattern)
        else
          if #npcs > 1 then
            print("���ֶ��ͬ��npc��")
            for _, npc in ipairs(npcs) do
              print(string.format("%20s %20s %10d %20s", npc.name, npc.id, npc.roomid, npc.zone))
            end
          end
          return self:walkto(npcs[1].roomid)
        end
      end
    }
    -- ���npc
    helper.addAlias {
      group = "travel",
      regexp = REGEXP.ALIAS_ADD_NPC,
      response = function(name, line, wildcards)
        local npcName = wildcards[1]
        local npcId = wildcards[2]
        if self.currState ~= States.located then
          ColourNote("yellow", "", "��ǰ����δ��λ���������NPC")
        else
          local roomId = self.currRoomId
          dal:insertNpc {
            id = npcId,
            name = npcName,
            roomid = roomId
          }
          local npcs = dal:getNpcsByName(npcName)
          -- ��ӡ���
          Note("���³ɹ���ͬ��npc�б�:")
          for _, npc in ipairs(npcs) do
            Note(string.format("%20s %20s %10d %20s", npc.name, npc.id, npc.roomid, npc.zone))
          end
        end
      end
    }
  end

  -- ����������������ʼֵ
  function prototype:resetOnStop()
    -- locating
    self.currRoomId = nil
    self.currRoomName = nil
    self.targetRoomId = nil -- ���ñ�����Ϊ��ʱ��Ϊֱ������
    self.busyLook = false  -- �ض�λʱ�ñ�����¼��ǰlook�Ƿ�ϵͳ�ж�ΪƵ��
    self.relocMoves = 0  -- ����located״̬ʱ����
    self.relocRetries = 0  -- STOP, ARRIVED, LOCATION_CONFIRMED_ONLY ʱ����
    -- walking
    self.walkPlan = nil
    self.walkLost = false
    self.walkSteps = 0
    self.walkInterval = self.walkInterval or INTERVAL
    self.mode = self.mode or "quick"
    self.delay = self.delay or 1
    -- busy
    self.walkBusyCmd = nil
    self.walkBusyResumeCmd = nil
    self.walkBusy = false
    -- flood
    self.prevMove = nil
    self.prevCheck = false
    self.floodOccurred = false
    self.snapshotExits = nil
    -- traversing
    self.traverseCheck = nil
    self.traverseRoomId = nil    -- ����ʱ��ÿ����ִ�и÷�����Ϊtrueʱֹͣ����
    self.traverseRooms = nil    -- ��Ҫ�����ķ����б�LOCATION_CONFIRMED_TRAVERSEʱˢ�£�STOP, ARRIVED����
    -- block
    self.blockCmd = nil
    self.blockers = nil
    -- special mode
    self.specialMode = nil
  end

  -- �������д�����
  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
    -- locating
      "travel_look_start",
      "travel_look_name",
      "travel_look_desc",
      "travel_look_season",
      "travel_look_exits",
      "travel_walk"
    )
  end

  -- �������״̬��stop״̬��ת��
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

  -- ��ʽ��ԭʼ�����ַ���
  function prototype:formatExits(rawExits)
    local exits = rawExits
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

  -- ��յ�ǰ������Ϣ
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

  -- ��ձ�����Ϣ
  function prototype:clearTraverseInfo()
    self.traverseRoomId = nil
    self.traverseCheck = nil
    self.traverseRooms = nil
  end

  -- ���ĺ�������׽��ǰ������Ϣ
  function prototype:lookUntilNotBusy()
    while true do
      helper.enableTriggerGroups("travel_look_start")
      self.busyLook = false
      SendNoEcho("set travel look_start")
      SendNoEcho("look")
      SendNoEcho("set travel look_done")
      local line = wait.regexp(REGEXP.LOOK_DONE, 3)
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

  -- ���ĺ�����ִ���ض�λ
  function prototype:relocate()
    if self.relocRetries > RELOC_MAX_RETRIES then
      return self:fire(Events.MAX_RELOC_RETRIES)
    else
      self.relocMoves = self.relocMoves + 1
      if self.relocMoves > RELOC_MAX_MOVES then
        return self:fire(Events.MAX_RELOC_MOVES)
      else
        self:lookUntilNotBusy()
        -- ����ƥ�䵱ǰ����
        if not self.currRoomName then
          if not self.currRoomExits then
            return self:fire(Events.ROOM_INFO_UNKNOWN)
          else
            -- ����������ߣ����¶�λ
            wait.time(1.5)
            self:randomGo(self.currRoomExits)
            return self:fire(Events.TRY_RELOCATE)
          end
        else
          local potentialRooms = dal:getRoomsByName(self.currRoomName)
          local matched = self:matchPotentialRooms(table.concat(self.currRoomDesc), self.currRoomExits, potentialRooms)
          if #matched == 1 then
            self:debug("�ɹ�ƥ��Ψһ����", matched[1])
            self.currRoomId = matched[1]
            if self.targetRoomId then
              return self:fire(Events.LOCATION_CONFIRMED)
            elseif self.traverseCheck then
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
            wait.time(1.5)
            self:randomGo(self.currRoomExits)
            return self:fire(Events.TRY_RELOCATE)
          end
        end
      end
    end
  end

  function prototype:sendPath(path)
    local cmds = utils.split(path, ";")
    for i = 1, #cmds do
      SendNoEcho(cmds[i])
    end
  end

  -- ���ĺ�����ִ����������
  -- ���ӶԱ�����֧��
  -- ��ӶԵ�ͼ�ı��¼��Ĵ���
  -- ������Ҫ���Ǹò�����ǰ�����Ѿ��б��˴���������¼���С���ʣ�
  -- �Լ����Լ���������ִ�к󣬴����˸��¼�
  function prototype:walking()
    -- ���ȼ��ǰһ���Ƿ��п��ܴ���������ڱ仯�¼�����ˮ����
    -- ���������ת������Ӧ״̬
    if self.prevMove and not self.prevCheck and self.prevMove.mapchange == 1 then
      self:debug("���ܷ�����ˮ�¼�")
      self:assureStepResponsive()
      if self.floodOccurred then
        return self:fire(Events.FLOOD)
      elseif self.walkLost then
        return self:fire(Events.GET_LOST)
      else
        -- �Ѿ�������һ����ȷ����һ�β��ټ��
        self.prevCheck = true
        return self:fire(Events.WALK_NEXT_STEP)
      end
    end
    if #(self.walkPlan) > 0 then
      self.walkSteps = self.walkSteps + 1
      local move = table.remove(self.walkPlan)
      -- ��ǰ��������ܸı��ͼ�����ȼ���Ƿ��ͼ�Ѿ����ı䣨���˴�����
      if move.mapchange == 1 then
        self:debug("��ǰ�����ܸı䷿����ڣ���Ҫȷ�ϵ�ͼ�Ƿ��Ѿ����ı�")
        local origExits = self.roomsById[move.startid].exits
        self:debug("ԭʼ������Ϣ��", origExits)
        while true do
          self:lookUntilNotBusy()
          if self:checkExitsIdentical(self.currRoomExits, origExits) then
            self:debug("��ǰ������Ϣ����ԭʼ���ݣ���������")
            break
          else
            self:debug("��ǰ������Ϣ������ԭʼ���ݣ��ȴ�10����ټ��")
            wait.time(10)
          end
        end
      end
      -- ������ʱ����ִ�б�����麯��
      if self.traverseCheck then
        -- ���ñ��������Ϊ��ǰ�����
        self.traverseRoomId = move.startid
        local checked, msg = self.traverseCheck()
        self:debug("���������", checked, msg)
        if checked then
          return self:fire(Events.ARRIVED)
        else
          -- ����鲻ͨ��ʱ�����������������Ϊ��һ������ı�ţ��Ա�֤·������ʱ����������ŵ�������Ŀ�귿���
          self.traverseRoomId = move.endid
        end
      end
      -- ִ��·��
      self:debug("·��", move.startid, move.endid, move.path, move.category)
      -- �洢��ǰ�����Ա��ڵ�ͼ�仯�¼�����
      self.prevMove = move
      self.prevCheck = false
      if move.category == PathCategory.normal then
        SendNoEcho(move.path)
      elseif move.category == PathCategory.multiple then
        self:sendPath(move.path)
      elseif move.category == PathCategory.busy then
        local cmds = utils.split(move.path, ";")
        assert(#cmds <= 2, "busy path can at most have 2 commands(start and stop)")
        self.walkBusyCmd = cmds[1]
        self.walkBusyResumeCmd = cmds[2]
        return self:fire(Events.BUSY)
      elseif move.category == PathCategory.boat then
        self.boatCmd = move.path
        return self:fire(Events.BOAT)
      elseif move.category == PathCategory.pause then
        self:sendPath(move.path)
        self:debug("������ͣ���ȴ������źţ���ʱ����60��")
        local line = wait.regexp(REGEXP.WALK_RESUME, 60)
        if not line then
          error("����60�볬ʱ����")
        end
      elseif move.category == PathCategory.block then
        self.blockCmd = move.path
        self.blockers = move.blockers
        return self:fire(Events.BLOCKED)
      elseif move.category == PathCategory.checkbusy then
        self:sendPath(move.path)
        helper.checkUntilNotBusy()
      elseif move.category == PathCategory.bus then
        self.busArrived = false
        SendNoEcho("gu")
        SendNoEcho(move.path)
        local busTime = 0
        while not self.busArrived do
          wait.time(3)
          busTime = busTime + 3
          self:debug("�����ȴ�ʱ�䣺", busTime)
        end
        SendNoEcho("xia")
      else
        error("current version does not support this path category:" .. move.category, 2)
      end
      -- we cannot use quick mode to traverse, because traverse has to use callback check
      -- for each move
      if self.mode == "quick" and not self.traverseCheck then
        if (self.walkSteps % self.walkInterval) == 0 then
          self:assureStepResponsive(1)
          if self.walkLost then
            return self:fire(Events.GET_LOST)
          else
            return self:fire(Events.WALK_NEXT_STEP)
          end
        else
          return self:fire(Events.WALK_NEXT_STEP)
        end
      else
        if self.mode == "slow" then
          wait.time(1)
        elseif self.traverseCheck then
          -- for traverse, we still need to wait some time
          wait.time(0.2)
        end
        self:assureStepResponsive()
        if self.walkLost then
          return self:fire(Events.GET_LOST)
        else
          return self:fire(Events.WALK_NEXT_STEP)
        end
      end
    else
      -- here we also need to put traverse check if traversing
      if self.traverseCheck then
        -- ���ñ��������
        local checked, msg = self.traverseCheck()
        self:debug("���������", checked, msg)
        if checked then
          -- ��������������ûص�ǰ����
          return self:fire(Events.ARRIVED)
        end
      end
      return self:fire(Events.ARRIVED)
    end
  end

  function prototype:assureStepResponsive(extraWaitTime)
    while true do
      SendNoEcho("set travel walk_step")
      local line = wait.regexp(REGEXP.WALK_STEP, 5)
      if not line then
        print("ϵͳ��Ӧ��ʱ���ȴ�5������")
        wait.time(5)
      elseif self.walkLost then
        SendNoEcho("halt")
        break
      else
        if extraWaitTime and extraWaitTime > 0 then
          wait.time(extraWaitTime)
        end
        SendNoEcho("halt")
        break
      end
    end
  end

  function prototype:walkingBusy()
    SendNoEcho("set travel walkbusy_start")
    SendNoEcho(self.walkBusyCmd)
    SendNoEcho("set travel walkbusy_done")
  end

  -- ������ߣ��ض�λʧ��ʱ��
  function prototype:randomGo(currExits)
    if not currExits or currExits == "" then return nil end
    local exits = utils.split(currExits, ";")
    local exit = exits[math.random(#(exits))]
    self:debug("���ѡ����ڲ�ִ�����¶�λ", exit)
    check(SendNoEcho("halt"))
    check(SendNoEcho(exit))
  end

  -- ƥ��Ǳ�ڷ���
  function prototype:matchPotentialRooms(currRoomDesc, currRoomExits, potentialRooms)
    local matched = {}
    -- self:debug(currRoomDesc)
    for i = 1, #potentialRooms do
      local room = potentialRooms[i]
      local exitsMatched = self:checkExitsIdentical(room.exits, currRoomExits)
      local descMatched = room.description == currRoomDesc
      self:debug("������", room.id, "����ƥ�䣺", exitsMatched, "����ƥ�䣺", descMatched)
      if exitsMatched and descMatched then
        table.insert(matched, room.id)
      end
    end
    return matched
  end

  -- ���ɱ����ƻ�
  function prototype:generateTraversePlan(traverseRooms, startid, skipStart)
    local plan = traversal {
      rooms = traverseRooms or self.traverseRooms,
      fallbackRooms = self.roomsById,
      startid = startid or self.currRoomId
    }
    local skipStart = skipStart or false
    if plan and #plan > 0 and not skipStart then
      -- �����ƻ���Ҫ������ʼ�ڵ㣬������ջ�����startid -> startid������path
      table.insert(plan, dal:getPseudoPath(plan[#plan].startid))
    end
    self:printPlan(plan, "����")
    return plan
  end

  function prototype:printPlan(plan, type)
    if plan then
      local ls = {}
      for i = #(plan), 1, -1 do
        table.insert(ls, plan[i].path)
      end
      print(type, table.concat(ls, ";"))
    else
      print(type, "��·��")
    end
  end

  -- ׼�����߼ƻ���ֱ��������
  function prototype:prepareWalkPlan()
    local walkPlan
    if self.traverseCheck then
      self:debug("���ɱ����ƻ�����㣺", self.currRoomId)
      walkPlan = self:generateTraversePlan()
    else
      self:debug("����ֱ��ƻ�")
      walkPlan = self:generateWalkPlan()
    end
    if not walkPlan then
      return self:fire(Events.WALK_PLAN_NOT_EXISTS)
    else
      -- ��Ӷ�����ģʽ��֧�֣��������Ҫ�ı�Ŀ�귿����
      -- specialMode
      -- first: ͬ����ͬ������ĵ�һ������������
      -- beforeFirst: ͬ����ͬ������ĵ�һ����ǰһ�����ѻ�����
      if self.specialMode == "first" then
        local targetRoom = self.roomsById[self.targetRoomId]
        local adjustedPlan = {}
        for _, move in ipairs(walkPlan) do
          table.insert(adjustedPlan, move)
          local endRoom = self.roomsById[move.endid]
          if endRoom.id ~= targetRoom.id
            and endRoom.zone == targetRoom.zone
            and endRoom.name == targetRoom.name then
            self:debug("����ֱ��·����ͬ�����䣬�޸�Ŀ�귿���ţ�" .. targetRoom.id .. " => " .. endRoom.id)
            self.targetRoomId = endRoom.id
            adjustedPlan = {}
            table.insert(adjustedPlan, move)
          end
        end
        walkPlan = adjustedPlan
      elseif self.specialMode == "beforeFirst" then
        local targetRoom = self.roomsById[self.targetRoomId]
        local adjustedPlan = {}
        for _, move in ipairs(walkPlan) do
          local endRoom = self.roomsById[move.endid]
          if endRoom.zone == targetRoom.zone
            and endRoom.name == targetRoom.name then
            self:debug("����ֱ��·��ͬ�����䣬�޸�Ŀ�귿��Ϊǰһ�����䣺" .. targetRoom.id .. " => " .. move.startid)
            self.targetRoomId = move.startid
            adjustedPlan = {}
          else
            table.insert(adjustedPlan, move)
          end
        end
        walkPlan = adjustedPlan
      end
      self:debug("�����Զ����߹�" .. #walkPlan .. "��")
      self:debug("����" .. self.relocRetries .. "�ζ�λ����")
      -- this is the only place to store walk plan
      self.walkPlan = walkPlan
      return self:fire(Events.WALK_PLAN_GENERATED)
    end
  end

  -- ��ȡ���������б�
  function prototype:getNearbyRooms(centerRoomId, maxDepth, crossRiver)
    if maxDepth < 1 then return nil end
    local startroom = self.roomsById[centerRoomId]
    if not startroom then return nil end

    local visited = {}
    local deque = Deque:new()
    deque:addLast({room=startroom, depth=0})

    while deque:size() > 0 do
      local elem = deque:removeFirst()    -- bfs
      local room = elem.room
      local depth = elem.depth
      if not visited[room.id] then
        visited[room.id] = room
        if depth < maxDepth then
          for _, exit in pairs(room.paths) do
            local nextRoom = self.roomsById[exit.endid]
            if nextRoom then
              -- ��ӶԹ��ӵ��ж�
              if crossRiver or not string.find(exit.path, "boat") then
                deque:addLast({room=nextRoom, depth=depth+1})
              end
            end
          end
        end
      end
    end
    return visited
  end

  -- ͨ��id���·�����Ϣ
  function prototype:refreshRoomInfo()
    -- ���·�����Ϣ
    local currRoom = self.roomsById[self.currRoomId]
    self.currRoomName = currRoom and currRoom.name
    self.currRoomExits = currRoom and currRoom.exits
    self.currRoomDesc = currRoom and {currRoom.description}
  end

  -- ����赲��
  function prototype:clearBlockers()
    while true do
      self.blocked = false
      SendNoEcho("halt")
      SendNoEcho("set travel block_start")
      self:sendPath(self.blockCmd)
      SendNoEcho("set travel block_done")
      helper.checkUntilNotBusy()
      if self.blocked then
        if self.blockUsedWeapon then
          SendNoEcho("wield " .. self.blockUsedWeapon)
        end
        for _, blocker in ipairs(utils.split(self.blockers, ",")) do
          SendNoEcho("killall " .. blocker)
        end
      else
        return self:fire(Events.CLEARED)
      end
      wait.time(5)
    end
  end

  return prototype
end

return define_travel():FSM()

--local travel = define_travel():FSM()
--local rooms = travel.zonesByCode["beijing"].rooms
--print(helper.countElements(rooms))
--travel:debugOn()
--travel.currRoomId = 147
--travel.targetRoomId = 38
--local plan = travel:generateWalkPlan()
--print(#plan)
--travel.traverseRooms = rooms
--travel.currRoomId = 110
--local plan = travel:generateTraversePlan()
--print(#plan)
