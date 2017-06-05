----------------------------------------
-- �Ի�����������ƣ�������jobs���
-- ������ģ������ҪӰ�죬������������
-- ���˼·��
-- ��Ϊ����ȫ������Ҳ�ڲ���ս��������ʹ��ս��ģ�����ս��
-- ����ģ��Ҳ���ݻ���������и�д
--
----------------------------------------

-- ����ȫ����������
ExcludedBlockZones = {
  "dali", "emei", "jiaxing",
  "lingjiu", "lingzhou", "mingjiao",
  "pingxiwangfu", "riyue",
  "shaolin", "tiantan",
  "wudang", "xihu",
  "xingxiu"
}
ExcludedZones = {
  "gaibang",
  "miaoling"
}
local travel = require "pkuxkx.travel"

local patterns = {[[
һƬŨ���У�ʲôҲ�����塣

]]}

local ZonePath = require "pkuxkx.ZonePath"
local RoomPath = require "pkuxkx.RoomPath"
local PathCategory = RoomPath.Category
local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local status = require "pkuxkx.status"
local recover = require "pkuxkx.recover"
local combat = require "pkuxkx.combat"
-- enable combat by default
coroutine.wrap(function() combat:start() end)()
local captcha = require "pkuxkx.captcha"

local define_hubiao = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",  -- ��ֹ״̬����jobsģ�����ϣ��ṩwaitDone����
    prepare = "prepare",  -- ׼�����񣬲鿴����
    prefetch = "prefetch",  -- Ԥ��ǰ������Ŀ�ĵ�
    transfer = "transfer",  -- ������
    lost = "lost",  -- ��·�У��ܴ���ܱ�ǿ���������ڷ��䣩
    submit = "submit",  -- �ύ
    mixin = "mixin",  -- ����
  }
  local Events = {
    STOP = "stop",  -- �κ�״̬��ֹͣ
    START = "start",  -- stop -> prepare
    NO_JOB_AVAILABLE = "no_job_available",  -- prepare -> stop
    ACCEPT_SUCCESS = "accept_success",  -- prepare -> prefetch
    ACCEPT_FAIL = "accept_fail",  -- prepare -> prepare
    NEXT_PREFETCH = "next_prefetch",  -- prefetch -> prefetch
    PREFETCH_SUCCESS = "prefetch_success",  -- prefetch -> transfer
    TRANSFER_STEP = "transfer_step",  -- transfer -> step
    STEP_SUCCESS = "step_success",  -- ����һ���ɹ� transfer -> transfer
    STEP_FAIL = "step_fail",  -- ����һ��ʧ�� transfer -> transfer
    GET_LOST = "get_lost",  -- ��· transfer -> lost
    RELOCATED = "relocated",  -- �ض�λ�ɹ� lost -> transfer
    TRANSFER_SUCCESS = "transfer_success",  -- ����ɹ� transfer -> submit
    MIXIN_FOUND = "mixin_found",  -- �������� submit -> mixin
    CONTINUE = "continue",  -- submit -> prepare
  }
  local REGEXP = {
    ALIAS_START = "^hubiao\\s+start\\s*$",
    ALIAS_STOP = "^hubiao\\s+stop\\s*$",
    ALIAS_DEBUG = "^hubiao\\s+debug\\s+(on|off)\\s*$",
    ALIAS_MIXIN = "^hubiao\\s+mixin\\s+(.*?)\\s*$",
    JOB_INFO = "^(\\d+)\\s+(.*?)\\s+(\\d+)��\\s+(.*?)\\s+(.*)$",
    ACCEPT_INFO = "^.*����������͵�(.*?)������Ѿ����˸��������(.*?)��(.*?)�������㣬���ڳ��͵�����������ˡ�$",
    ACCEPT_FAIL = "^[ >]*��������ʧ�ܣ���ѡ����������$",
    TRANSFER_SUCCESS = "^[ >]*�����˸����������ڰ����˵��˵�ͷ��$",
    ROBBER_MOVE = "^[ >]*�ٷ˳��㲻ע�⣬�����ڳ����ܣ���Ͻ�׷����ȥ��$",
    TRANSFER_BUSY = "^[ >]*(�ٷ�����һ�����������ܣ�û��ô���ף���|�㻹���ȰѶ��ֽ������˵�ɣ�|��������æ������|�ڳ���û�и�������,������.*)$",
    STEP_SUCCESS = "^[ >]*������ڳ�ʻ�˹�����$",
    REWARDED = "^[ >]*��һ���������ˣ�$",
    MIXIN_DESC = "^[ >]*����һ��.*?��������ţ���Ҫ�������ҩˮ��������\\(xian\\)��$",
    MIXIN_NPC_DISPLAY = "^[ >]*\\s*����.*?����Ļ�� .*?\\((.*?)\\)$",
    MIXIN_NPC_FOUND = "^[ >]*һ��������ű�ʺ���˳���������������ɶ�£�$",
    MIXIN_YAO_SUCCESS = "^[ >]*.*��һ�����������㣬һת�۲����ˡ�$",
    POWERUP_EXPIRE = "^[ >]*���(��ϼ��|��ɽ�ڹ�)������ϣ��������ջص��$",
    POWERUP_ENABLE = "^[ >]*(��������ϼ�񹦣�����������������������ϼ��|�㰵�˻�ɽ�ڹ��������Լ���ս������|���Ѿ����˹����ˡ�)$",
    QI_EXPIRE = "^[ >]*������������У�����Ѫ���лָ�������$",
    QI_ENABLE = "^[ >]*(���������������������Ѫ�ָ���|���Ѿ������ڹ�����ȫ����Ѫ�ָ���)$",
    ROBBER_ESCAPE = "^[ >]*�ٷ˽е����������֣�������$",
    ROBBER_APPEAR = "^[ >]*�ٷ�ͻȻ�Ӱ������˳�������Ц������������������������ɣ�����$",
    ROBBER_ASSIST = "^[ >]*�ٷ˴󺰣�����צ��Ӳ���Ͻ�����æ��$",
    -- ROBBER_ASKED = "^[ >]*����ٷ˴����йء�ȥ��������Ϣ��$",
    ROBBER_CHECKED = helper.settingRegexp("hubiao", "check_robber"),
    ROBBER_NOT_EXISTS = "^[ >]*����û������ˡ�$",
    WEAPON_REMOVED = "^[ >]*(.*ж������ı���.*|�ñ������ڻ��޷�װ����)$",
    WEAPON_WIELDED = "^[ >]*(���Ѿ�װ�����ˡ�|��ӳ¾ɵĽ����аγ�һ���������������С�)$",
    WEAPON_ID = "^\\( *(\\d+)\\)(.*?)\\([a-zA-Z0-9_ ]*\\) *������:.*�˺���:.*$",
    WEAPON_DURABILITY = "^ *�;ö�:(\\d+)/(\\d+)",
    GARBAGE = "^[ >]*������.*��(ʯ̿|����|����)��.*?����$",
    GRADUATED = "^[ >]*���Ѿ��������ھֻ���㹻�����ˣ��쵽�����ȥ����һ���ɡ�$",
    PFM_NOT_IN_COMBAT = "^[ >]*(.*?ֻ�ܶ�ս���еĶ���ʹ�á�|δ�ж��ֻ�����ͶԷ�δ����ս���У�����ʹ��.*)$",
    HEAL_IN_COMBAT = "^[ >]* ս�����˹����ˣ�������$",
    BOAT_ARRIVED = "^[> ]*(����˵���������ϰ��ɡ�.*|�������˵����������.*|�㳯������˻���.*|С�����ڻ�������.*|.*����ϰ�ȥ��.*|һ����ɮ��ɳ�Ƶ����������������µ����������ɡ�����.*|�ٿ������Խ��Խ���������ڵ�һ�����˵أ����˶����˿ڳ���.*)$",
    BOAT_FORCED_DEPART = "^[ >]*����Ҫ�����������ˣ������˱������˶ɴ���$",
    BOAT_OFFSHORE = "^[ >]*(������̤�Ű�������.*|�����̤�Ű�������.*|С���ں���ź��֮���ˮ·.*|��Ծ��С�ۣ����ͻ���������.*|�����𴬽���������������.*|��ɮ����һ�ƣ����ٿ�����ƽ̨�����̸����������ɣ��ٿ�һ����������ȥ��|����һ�����ٿ�����ҡ�����˼��£�ȽȽ��������������)$",
  }

  local SpecialRenameRooms = {
    ["����Ǯׯ"] = "���˼���Ǯׯ",
    ["Ȫ�ݵ���"] = "Ȫ��Ȫ�ݵ���",
    ["������������"] = "����������������",
    ["����������"] = "��������������",
  }
  local ExcludedJobRooms = {
    ["������¬��"] = true
  }

  local SpecialRelocateRooms = {
    ["����"] = {
      -- ���ݽ�ͤ
      ["��ͤ"] = 785,
      -- ��������
      ["����"] = 494,
    },
    ["������"] = {
      ["�����ɿ�"] = 864
    },
    ["����"] = {
      ["��������"] = 1095
    }
  }

  -- ���ݸ����ھ�
--  local StartRoomId = 26
--  local JobNpcId = "lin"
  -- �����ھ�
  local StartRoomId = 456
  local JobNpcId = "zuo"
  local PrefetchDepth = 5
  local DoubleSearchDepth = 3
  local WeaponFixRoomId = 2167

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
    self.maxRounds = 10
    self.rounds = 0
    -- special variable
    self.playerName = "ߣ��"
    self.playerId = "luar"
    self.robbersPresent = 0
    self.qiPresent = false
    self.powerupPresent = false
    self.jingUpperBound = 1
    self.jingLowerBound = 0.9
    self.qiUpperBound = 1
    self.qiLowerBound = 0.9
    self.neiliUpperBound = 1.8
    self.neiliLowerBound = 1
    self.jingliUpperBound = 1.2
    self.jingliLowerBound = 1
    -- ������
    self.robberMoves = 0
    -- �˴�״̬
    self.boatStatus = "yelling"
    -- ����
    self.weaponName = "�ٺ� ׷��֮��"
    self.weaponId = nil
    self.needWield = true
    self.wieldCmd = "wield sword"
    self.weaponDurability = 500
    -- ��������
    self:debugOn()
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
      "hubiao_info_start", "hubiao_info_done",
      "hubiao_accept_start", "hubiao_accept_done",
      "hubiao_step_start", "hubiao_step_done",
      "hubiao_submit_start", "hubiao_submit_done",
      "hubiao_mixin_start", "hubiao_mixin_done",
      "hubiao_transfer",
      "hubiao_robber",
      "hubiao_force")
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
        helper.removeTriggerGroups("hubiao_prefetch_traverse", "hubiao_transfer_traverse")
        SendNoEcho("set jobs job_done")  -- Ϊjobs�ṩ��������
      end,
      exit = function()
        helper.enableTriggerGroups("hubiao_robber", "hubiao_force")
      end
    }
    self:addState {
      state = States.prepare,
      enter = function()
        helper.enableTriggerGroups(
          "hubiao_info_start", "hubiao_accept_start",
          "hubiao_weapon_id_start", "hubiao_weapon_dura_start")
      end,
      exit = function()
        helper.disableTriggerGroups(
          "hubiao_info_start", "hubiao_info_done",
          "hubiao_accept_start", "hubiao_accept_done",
          "hubiao_weapon_id_start", "hubiao_weapon_id_done",
          "hubiao_weapon_dura_start", "hubiao_weapon_dura_done")
      end
    }
    self:addState {
      state = States.prefetch,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.transfer,
      enter = function()
        helper.enableTriggerGroups(
          "hubiao_step_start",
          "hubiao_transfer")
      end,
      exit = function()
        helper.disableTriggerGroups(
          "hubiao_step_start", "hubiao_step_done",
          "hubiao_transfer")
      end
    }
    self:addState {
      state = States.submit,
      enter = function()
        helper.enableTriggerGroups("hubiao_submit_start", "hubiao_mixin_start")
      end,
      exit = function()
        helper.enableTriggerGroups("hubiao_submit_start", "hubiao_submit_done",
          "hubiao_mixin_start", "hubiao_mixin_done")
      end
    }
    self:addState {
      state = States.lost,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.mixin,
      enter = function() end,
      exit = function() end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.prepare,
      event = Events.START,
      action = function()
        return self:doGetJob()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<prepare>
    self:addTransition {
      oldState = States.prepare,
      newState = States.prepare,
      event = Events.ACCEPT_FAIL,
      action = function()
        self:debug("�ȴ�3������½�����")
        wait.time(3)
        return self:doGetJob()
      end
    }
    self:addTransition {
      oldState = States.prepare,
      newState = States.prefetch,
      event = Events.ACCEPT_SUCCESS,
      action = function()
        self:debug("�ȴ�3���ʼԤȡ")
        wait.time(3)
        self.transferVisitedRoomIds = {}
        return self:doConfirmSearchRooms()
      end
    }
    self:addTransition {
      oldState = States.prepare,
      newState = States.prepare,
      event = Events.NO_JOB_AVAILABLE,
      action = function()
        self:debug("Ŀǰ�޿������񣬵ȴ�5������ѯ��")
        wait.time(5)
        return self:doGetJob()
      end
    }
    self:addTransitionToStop(States.prepare)
    -- transition from state<prefetch>
    self:addTransition {
      oldState = States.prefetch,
      newState = States.prefetch,
      event = Events.NEXT_PREFETCH,
      action = function()
        return self:doPrefetch()
      end
    }
    self:addTransition {
      oldState = States.prefetch,
      newState = States.transfer,
      event = Events.PREFETCH_SUCCESS,
      action = function()
        -- back to start
        travel:walkto(StartRoomId)
        travel:waitUntilArrived()
        self:debug("�ȴ�2����������")
        wait.time(2)
        return self:doPrepareTransfer()
      end
    }
    self:addTransitionToStop(States.prefetch)
    -- transition from state<transfer>
    self:addTransition {
      oldState = States.transfer,
      newState = States.transfer,
      event = Events.STEP_SUCCESS,
      action = function()
        -- ������һ����·��Ϊ��ǰ·��
        if #(self.transferPlan) > 0 then
          -- �˴�����
          if self.currStep and self.currStep.category == PathCategory.boat then
            -- �˴�ǰ
            if self.boatStatus == "yelling" then
              self:debug("�Ǵ��ɹ����ȴ�5������봬")
              self.boatStatus = "boating"
              wait.time(5)
              return self:doStep()
            -- �˴���
            elseif self.boatStatus == "boating" then
              self:debug("��boating����²�Ӧ�����߳ɹ����������©��")
              wait.time(2)
              return self:doStep()
            elseif self.boatStatus == "leaving" then
              self:debug("�봬�ɹ�")
              self.boatStatus = "yelling"
              self.currStep = table.remove(self.transferPlan)
              return self:doStep()
            end
          else
            self.currStep = table.remove(self.transferPlan)
            return self:doStep()
          end
        else
          ColourNote("yellow", "", "������ȫ��·��")
          wait.time(4)
          helper.checkUntilNotBusy()
          if self.transferSuccess then
            self:debug("�����͵��������ύ����")
            return self:doSubmit()
          else
            ColourNote("red", "", "û���ҵ���ƣ�����ʧ�ܣ�")
            return self:doCancel()
          end
        end
      end
    }
    self:addTransition {
      oldState = States.transfer,
      newState = States.transfer,
      event = Events.STEP_FAIL,
      action = function()
        -- ʧ��ʱ�����µ�ǰ·��������
        return self:doStep()
      end
    }
    self:addTransition {
      oldState = States.transfer,
      newState = States.lost,
      event = Events.GET_LOST,
      action = function()
        return self:doRelocate()
      end
    }
    self:addTransition {
      oldState = States.transfer,
      newState = States.submit,
      event = Events.TRANSFER_SUCCESS,
      action = function()
        local tick = 0 -- ����12 tick��Ϊ�޷���
        while true do
          helper.checkUntilNotBusy()
          if tick <= 12 and self.robbersPresent > 0 then
            tick = tick + 1
            wait.time(3)
          else
            break
          end
        end
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.transfer)
    -- transition from state<lost>
    self:addTransition {
      oldState = States.lost,
      newState = States.transfer,
      event = Events.RELOCATED,
      action = function()
        return self:doPrepareTransfer()
      end
    }
    self:addTransitionToStop(States.lost)
    -- transition from state<submit>
    self:addTransition {
      oldState = States.submit,
      newState = States.mixin,
      event = Events.MIXIN_FOUND,
      action = function()
        ColourNote("yellow", "", "�������ţ����ֶ��������ŵص�hubiao mixin <�ص�>")
      end
    }
    self:addTransition {
      oldState = States.submit,
      newState = States.prepare,
      event = Events.CONTINUE,
      action = function()
        self:debug("�ȴ�3�����ȡ������")
        wait.time(3)
        return self:doGetJob()
      end
    }
    self:addTransitionToStop(States.submit)
    -- transition from state<mixin>
    self:addTransition {
      oldState = States.mixin,
      newState = States.prepare,
      event = Events.CONTINUE,
      action = function()
        self:debug("�ȴ�3�����ȡ������")
        wait.time(3)
        return self:doGetJob()
      end
    }
    self:addTransitionToStop(States.mixin)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "hubiao_info_start", "hubiao_info_done",
      "hubiao_accept_start", "hubiao_accept_done",
      "hubiao_step_start", "hubiao_step_done",
      "hubiao_submit_start", "hubiao_submit_done",
      "hubiao_mixin_start", "hubiao_mixin_done",
      "hubiao_transfer",
      "hubiao_robber",
      "hubiao_force"
    )
    -- info
    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "info_start",
      done = "info_done"
    }
    helper.addTrigger {
      group = "hubiao_info_done",
      regexp = REGEXP.JOB_INFO,
      response = function(name, line, wildcards)
        self:debug("JOB_INFO triggered")
        local jobId = wildcards[1]
        local jobLocation = wildcards[2]
        local jobRemainedTime = wildcards[3]
        local jobStatus = wildcards[4]
        local jobPlayer = wildcards[5]
        if jobStatus == "������" and not ExcludedJobRooms[jobLocation] then
          table.insert(self.jobs, {id = jobId, location = SpecialRenameRooms[jobLocation] or jobLocation})
        end
      end
    }
    -- accept
    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "accept_start",
      done = "accept_done"
    }
    helper.addTrigger {
      group = "hubiao_accept_done",
      regexp = REGEXP.ACCEPT_FAIL,
      response = function()
        self:debug("ACCEPT_FAIL triggered")
      end
    }
    helper.addTrigger {
      group = "hubiao_accept_done",
      regexp = REGEXP.ACCEPT_INFO,
      response = function(name, line, wildcards)
        self.acceptSuccess = true
        self.employer = wildcards[1]
        self.dudeName = wildcards[2]
        self.searchRoomName = wildcards[3]
      end
    }
    -- weapon
    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "weapon_id_start",
      done = "weapon_id_done",
    }
    helper.addTrigger {
      group = "hubiao_weapon_id_done",
      regexp = REGEXP.WEAPON_ID,
      response = function(name, line, wildcards)
        self:debug("WEAPON_ID triggered")
        print(wildcards[1])
        print(wildcards[2])
        local weaponId = tonumber(wildcards[1])
        local weaponName = wildcards[2]
        if string.find(weaponName, self.weaponName) then
          self.weaponId = "sword " .. weaponId
          self.wieldCmd = "wield " .. self.weaponId
          if string.find(weaponName, "(װ)") then
            self.needWield = false
          else
            self.needWield = true
          end
        end
      end
    }
    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "weapon_dura_start",
      done = "weapon_dura_done",
    }
    helper.addTrigger {
      group = "hubiao_weapon_dura_done",
      regexp = REGEXP.WEAPON_DURABILITY,
      response = function(name, line, wildcards)
        self.weaponDurability = tonumber(wildcards[1])
      end
    }

    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "weapon_dura_start",
      done = "weapon_dura_done"
    }
    -- step
    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "step_start",
      done = "step_done"
    }
    -- ���߳ɹ�
    helper.addTrigger {
      group = "hubiao_step_done",
      regexp = REGEXP.STEP_SUCCESS,
      response = function()
        self.stepSuccess = true
        -- ���÷�ͽ��Ϊ0
        self.robbersPresent = 0
        if self.currStep then
          -- �ڴ�����������ʱ�������䷿����
          self.transferRoomId = self.currStep.endid
          self:debug("�������䷿����Ϊ", self.currStep.endid)
        end
      end
    }
    -- submit
    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "submit_start",
      done = "submit_done"
    }
    helper.addTrigger {
      group = "hubiao_submit_done",
      regexp = REGEXP.REWARDED,
      response = function()
        self.submitSuccess = true
        self:debug("������ɣ���ý���")
      end
    }
    helper.addTrigger {
      group = "hubiao_submit_done",
      regexp = REGEXP.GARBAGE,
      response = function(name, line, wildcards)
        local item = wildcards[1]
        if item == "ʯ̿" then
          SendNoEcho("drop shi tan")
        elseif item == "����" then
          SendNoEcho("drop xuan bing")
        elseif item == "����" then
          SendNoEcho("drop yun tie")
        end
      end
    }
    -- mixin
    helper.addTriggerSettingsPair {
      group = "hubiao",
      start = "mixin_start",
      done = "mixin_done"
    }
    helper.addTrigger {
      group = "hubiao_mixin_done",
      regexp = REGEXP.MIXIN_DESC,
      response = function()
        self.findMixin = true
      end
    }
    -- transfer
    helper.addTrigger {
      group = "hubiao_transfer",
      regexp = REGEXP.TRANSFER_SUCCESS,
      response = function()
        self.transferSuccess = true
      end
    }
    helper.addTrigger {
      group = "hubiao_transfer",
      regexp = REGEXP.ROBBER_MOVE,
      response = function()
--        self.transferLost = true
        self.robberMoves = self.robberMoves + 1
      end
    }
    helper.addTrigger {
      group = "hubiao_transfer",
      regexp = REGEXP.WEAPON_REMOVED,
      response = function()
        self.weaponRemoved = true
      end
    }
    helper.addTrigger {
      group = "hubiao_transfer",
      regexp = REGEXP.WEAPON_WIELDED,
      response = function()
        self.weaponRemoved = false
      end
    }
    helper.addTrigger {
      group = "hubiao_transfer",
      regexp = REGEXP.ROBBER_NOT_EXISTS,
      response = function()
        self.robberExists = false
      end
    }
    helper.addTrigger {
      group = "hubiao_transfer",
      regexp = REGEXP.BOAT_FORCED_DEPART,
      response = function()
        if self.currStep.category == PathCategory.boat and self.boatStatus == "boating" then
          self:debug("�˴��У������´���ȥ����ǰ�������ó˴�״̬")
          self.boatStatus = "yelling"
          self.currStep = table.remove(self.transferPlan)
        end
      end
    }
    helper.addTrigger {
      group = "hubiao_transfer",
      regexp = REGEXP.BOAT_OFFSHORE,
      response = function()
        self:debug("BOAT_OFFSHORE triggered")
        if self.boatStatus == "boating" then
          self:debug("���밶�������뿪��")
          self.boatStatus = "leaving"
        end
      end
    }
    -- robber
    helper.addTrigger {
      group = "hubiao_robber",
      regexp = REGEXP.ROBBER_APPEAR,
      response = function()
        self.robbersPresent = self.robbersPresent + 1
        self:debug("��ǰ��ͽ����", self.robbersPresent)
      end
    }
    helper.addTrigger {
      group = "hubiao_robber",
      regexp = REGEXP.ROBBER_ASSIST,
      response = function()
        self.robbersPresent = self.robbersPresent + 1
        self:debug("��ǰ��ͽ����", self.robbersPresent)
      end
    }
    helper.addTrigger {
      group = "hubiao_robber",
      regexp = REGEXP.ROBBER_ESCAPE,
      response = function()
        self.robbersPresent = self.robbersPresent - 1
        self:debug("��ǰ��ͽ����", self.robbersPresent)
      end
    }
    -- force
    helper.addTrigger {
      group = "hubiao_force",
      regexp = REGEXP.POWERUP_EXPIRE,
      response = function()
        self:debug("powerup���ڣ���Ҫ�����˹�")
        self.powerupPresent = false
      end
    }
    helper.addTrigger {
      group = "hubiao_force",
      regexp = REGEXP.QI_EXPIRE,
      response = function()
        self:debug("qi���ڣ���Ҫ�����˹�")
        self.qiPresent = false
      end
    }
    helper.addTrigger {
      group = "hubiao_force",
      regexp = REGEXP.POWERUP_ENABLE,
      response = function()
        self.powerupPresent = true
      end
    }
    helper.addTrigger {
      group = "hubiao_force",
      regexp = REGEXP.QI_ENABLE,
      response = function()
        self.qiPresent = true
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("hubiao")
    helper.addAlias {
      group = "hubiao",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "hubiao",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "hubiao",
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
      group = "hubiao",
      regexp = REGEXP.ALIAS_MIXIN,
      response = function(name, line, wildcards)
        local location = wildcards[1]
        local rooms = travel:getMatchedRooms {
          fullname = location
        }
        if #(rooms) == 0 then
          ColourNote("red", "", "�����ѯ�����򲻿ɴ� " .. location)
        else
          self.mixinRoomId = rooms[1].id
          travel:walkto(self.mixinRoomId)
          travel:waitUntilArrived()
          self:debug("�ȴ�2���ʼִ����������")
          wait.time(2)
          while true do
            SendNoEcho("zhao")
            local line = wait.regexp(REGEXP.MIXIN_NPC_FOUND, 5)
            if line then break end
          end

          self.mixinNpcId = nil
          helper.addOneShotTrigger {
            group = "hubiao_mixin_one_shot",
            regexp = REGEXP.MIXIN_NPC_DISPLAY,
            response = function(name, line, wildcards)
              self.mixinNpcId = string.lower(wildcards[1])
            end
          }
          travel:lookUntilNotBusy()  --
          helper.removeTriggerGroups("hubiao_mixin_one_shot")
          while true do
            SendNoEcho("ask " .. self.mixinNpcId .. " about yao")
            local line = wait.regexp(REGEXP.MIXIN_YAO_SUCCESS, 5)
            if line then break end
          end
          self:debug("��ò������")
          wait.time(2)
          helper.checkUntilNotBusy()
          return self:doSubmitCaiwu()
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
        print("ֹͣ - ��ǰ״̬", self.currState)
      end
    }
  end

  function prototype:doStart()
    return self:fire(Events.START)
  end

  function prototype:doSubmitCaiwu()
    travel:stop()
    travel:walkto(StartRoomId)
    travel:waitUntilArrived()
    helper.checkUntilNotBusy()
    SendNoEcho("give cai wu to " .. JobNpcId)
--    return self:fire(Events.STOP)
    return self:fire(Events.CONTINUE)
  end

  function prototype:doGetJob()
    -- �������
    self.weaponId = nil
    self.wieldCmd = nil
    self.needWield = false
    SendNoEcho("set hubiao weapon_id_start")
    SendNoEcho("i sword")
    SendNoEcho("set hubiao weapon_id_done")
    helper.checkUntilNotBusy()
    if not self.weaponId then
      error("�������ʧ��")
    end
    if self.needWield then
      SendNoEcho("unwield all")
      SendNoEcho(self.wieldCmd)
    end

    SendNoEcho("set hubiao weapon_dura_start")
    SendNoEcho("look " .. self.weaponId)
    SendNoEcho("set hubiao weapon_dura_done")
    helper.checkUntilNotBusy()
    if self.weaponDurability <= 100 then
      travel:walkto(WeaponFixRoomId)
      travel:waitUntilArrived()
      wait.time(1)
      SendNoEcho("fix " .. self.weaponId)
      wait.time(1)
    end
    travel:walkto(StartRoomId)
    travel:waitUntilArrived()
    self:debug(
      "�ָ����� ��" .. self.jingLowerBound .. "/" .. self.jingUpperBound ..
      ", ��" .. self.qiLowerBound .. "/" .. self.qiUpperBound ..
      ", ����" .. self.neiliLowerBound .. "/" .. self.neiliUpperBound ..
      ", ����" .. self.jingliLowerBound .. "/" .. self.jingliUpperBound)
    -- ����ǰ�ָ����ã�ʹ�ûָ�����
    recover:settings {
      jingLowerBound = self.jingUpperBound,
      jingUpperBound = self.jingUpperBound,
      qiLowerBound = self.qiUpperBound,
      qiUpperBound = self.qiUpperBound,
      neiliThreshold = self.neiliUpperBound,
      jingliThreshold = self.jingliUpperBound,
    }
    recover:start()
    recover:waitUntilRecovered()
    -- �����лָ����ã�ʹ�ûָ�����
    recover:settings {
      jingLowerBound = self.jingLowerBound,
      jingUpperBound = self.jingUpperBound,
      qiLowerBound = self.qiLowerBound,
      qiUpperBound = self.qiUpperBound,
      neiliThreshold = self.neiliLowerBound,
      jingliThreshold = self.jingliLowerBound,
    }
    self:debug("�ȴ�1����ѯ����")
    wait.time(1)
    self.jobs = {}
    SendNoEcho("set hubiao info_start")
    SendNoEcho("listesc")
    SendNoEcho("set hubiao info_done")
    -- �ȴ����������
    wait.time(2)
    helper.assureNotBusy()
    if #(self.jobs) > 0 then
      return self:doAcceptJob()
    else
      return self:fire(Events.NO_JOB_AVAILABLE)
    end
  end

  function prototype:doAcceptJob()
    -- ���õ�ǰ����
    local _, job = next(self.jobs)
    self.currJob = job
    self.acceptSuccess = false
    self.employer = nil
    self.dudeName = nil
    self.searchRoomName = nil
    SendNoEcho("set hubiao accept_start")
    SendNoEcho("getesc " .. self.currJob.id)
    SendNoEcho("set hubiao accept_done")
    helper.assureNotBusy()
    if self.acceptSuccess then
      return self:fire(Events.ACCEPT_SUCCESS)
    else
      return self:fire(Events.ACCEPT_FAIL)
    end
  end

  function prototype:doConfirmSearchRooms()
    local targets = travel:getMatchedRooms {
      fullname = self.currJob.location
    }
    if #(targets) == 0 then
      self:debug("�������򲻿ɴ�ȴ�2������")
      wait.time(2)
      return self:doCancel()
    else
      local zone = targets[1].zone
      local searchRooms = {}
      local rooms = travel.zonesByCode[zone].rooms
      for _, room in pairs(rooms) do
        if room.name == self.searchRoomName then
          table.insert(searchRooms, room)
        end
      end
      if #(searchRooms) == 0 then
        ColourNote("yellow", "", "������ڵص㲻�ɴ�", zone, self.searchRoomName, "�޷�ִ��Ԥȡ���ȴ�2������")
        self:debug("�������ⶨλ����")
        local zoneName = travel.zonesByCode[zone].name
        local relocZone = SpecialRelocateRooms[zoneName]
        local specialRelocateId
        if relocZone then
          specialRelocateId = relocZone[self.searchRoomName]
        end
        -- local specialRelocateId = SpecialRelocateRooms[self.searchRoomName]
        if not specialRelocateId then
          ColourNote("red", "", "�޷�ִ��Ԥȡ��ȡ��������")
          wait.time(2)
          return self:doCancel()
        end
        ColourNote("green", "", "���ⷿ��ƥ�䣬���¶�λ�����䣺" .. specialRelocateId)
        table.insert(searchRooms, travel.roomsById[specialRelocateId])
      elseif #(searchRooms) == 1 then
        self.targetRoomId = searchRooms[1].id
        self:debug("Ŀ�귿�����1�����Թ�Ԥȡ��ֱ�����䣬�����ţ�", self.targetRoomId)
        wait.time(1)
        return self:fire(Events.PREFETCH_SUCCESS)
      end
      self.searchedRoomIds = {}
      self.searchRooms = searchRooms
      return self:fire(Events.NEXT_PREFETCH)
    end
  end

  function prototype:doPrefetch()
    if #(self.searchRooms) > 0 then
      local searchStartRoom = table.remove(self.searchRooms)
      if self.searchedRoomIds[searchStartRoom.id] then
        self:debug("������������������", searchStartRoom.id)
        return self:doPrefetch()
      else
        helper.assureNotBusy()
        travel:walkto(searchStartRoom.id)
        travel:waitUntilArrived()
        self:debug("����������ʼ�ص�", searchStartRoom.id)
        self:debug("��ʼ���������Ϊ", PrefetchDepth, "Ѱ�һ����Ϊ��", self.dudeName)

        self.targetRoomId = nil
        helper.addTrigger {
          group = "hubiao_prefetch_traverse",
          regexp = self:dudeNameRegexp(),
          response = function()
            --�ҵ���ƣ�������Ŀ��ص�Ϊ��ǰ������
            self:debug("���ֻ��", self.dudeName)
            self.targetRoomId = travel.traverseRoomId
          end
        }
        helper.enableTriggerGroups("hubiao_prefetch_traverse")
        local onStep = function()
          return self.targetRoomId ~= nil  -- ֹͣ�������ҵ����
        end
        local onArrive = function()
          helper.removeTriggerGroups("hubiao_prefetch_traverse")
          if self.targetRoomId then
            self:debug("�����������Ѿ����ֻ�ƣ���ȷ��Ŀ�귿�䣺", self.targetRoomId)
            return self:fire(Events.PREFETCH_SUCCESS)
          else
            self:debug("û�з��ֻ�ƣ�������һ���ص�")
            wait.time(1)
            return self:fire(Events.NEXT_PREFETCH)
          end
        end
        return travel:traverseNearby(PrefetchDepth, onStep, onArrive)
      end
    else
      self:debug("û�и�����������䣬Ԥȡʧ�ܣ�����������")
      wait.time(2)
      return self:doCancel()
    end
  end

  function prototype:dudeNameRegexp()
    return "^\\s*�����̻�ơ�" .. self.dudeName .. "\\(.*?\\)$";
  end

  function prototype:doCancel()
    -- for debug purpose
    ColourNote("red", "", "����ģʽ����������ȡ�������ֶ���ɺ������¼���")
--    helper.assureNotBusy()
--    travel:stop()
--    travel:walkto(StartRoomId)
--    travel:waitUntilArrived()
--    helper.assureNotBusy()
--    SendNoEcho("ask " .. JobNpcId .. " about fail")
--    return self:fire(Events.STOP)
  end

  function prototype:doPrepareTransfer()
    local walkPlan = travel:generateWalkPlan(travel.currRoomId, self.targetRoomId)
    if not walkPlan then
      ColourNote("red", "", "����ֱ��·��ʧ�ܣ�����������")
      return self:doCancel()
    end
    local traversePlan = travel:generateNearbyTraversePlan(self.targetRoomId, DoubleSearchDepth, true)
    if not traversePlan then
      ColourNote("red", "", "��������·��ʧ�ܣ�����������")
      return self:doCancel()
    end
    -- �ϲ��������߼ƻ�ջ��ע��˳��
    local transferPlan = {}
    for _, path in ipairs(traversePlan) do
      table.insert(transferPlan, path)
    end
    for _, path in ipairs(walkPlan) do
      table.insert(transferPlan, path)
    end
    self.transferRoomId = travel.currRoomId
    self.transferPlan = transferPlan
    -- self.transferLost = false
    self.robberMoves = 0
    self.findDude = false
    self.transferSuccess = false
    helper.removeTriggerGroups("hubiao_transfer_traverse")
    -- �ҵ���ƴ���
    helper.addTrigger {
      group = "hubiao_transfer_traverse",
      regexp = self:dudeNameRegexp(),
      response = function()
        self:debug("DUDE_NAME triggered")
        self.findDude = true
      end
    }
    helper.enableTriggerGroups("hubiao_transfer_traverse")
    -- ���ʱװ�����˹�
    self.powerupPresent = false
    self.qiPresent = false
    SendNoEcho("wield sword")
    return self:fire(Events.STEP_SUCCESS)
  end

  function prototype:doStep()
    while true do
      self.robberExists = true
      SendNoEcho("ask " .. self.playerId .. "'s robber about ȥ��")
      SendNoEcho("set hubiao check_robber")
      local line = wait.regexp(REGEXP.ROBBER_CHECKED, 2)
      if not line then
        self:debug("ϵͳ��ʱ������")
        wait.time(5)
      else
        break
      end
    end
    self:debug("�ٷ˴��ڣ�", self.robberExists)
    if self.robberExists then
      wait.time(3)
      return self:fire(Events.STEP_FAIL)
    else
      helper.checkUntilNotBusy()
      helper.assureNotBusy(6)
      -- �����ڣ������Ѫ���ָ�
      recover:start()
      recover:waitUntilRecovered()
      -- ��������
      self:debug("��ǰ���߷���", self.currStep.path)
      self.stepSuccess = false
      if not self.powerupPresent then
        SendNoEcho("yun powerup")
      end

      -- ���ж��Ƿ���·
      if self.robberMoves > 0 then
        return self:fire(Events.GET_LOST)
      end

      SendNoEcho("set hubiao step_start")
      if self.currStep.category == PathCategory.normal then
        local direction, isExpanded = helper.expandDirection(self.currStep.path)
        if isExpanded then
          SendNoEcho("gan che to " .. direction)
        else
          ColourNote("red", "", "���ڲ�֧������·��" .. self.currStep.path)
          return self:doCancel()
        end
      elseif self.currStep.category == PathCategory.multiple then
        -- self:sendPath(move.path)
        local cmds = utils.split(self.currStep.path, ";")
        if #cmds == 2 then
          local direction, isExpanded = helper.expandDirection(cmds[2])
          if isExpanded then
            SendNoEcho(cmds[1])
            SendNoEcho("gan che to " .. direction)
          else
            ColourNote("yellow", "", "���ڲ�֧�ֶ�����·��" .. self.currStep.path)
            return self:doCancel()
          end
        else
          ColourNote("yellow", "", "���ڲ�֧�ֶ�����·��" .. self.currStep.path)
          return self:doCancel()
        end
      elseif self.currStep.category == PathCategory.busy then
        local direction, isExpanded = helper.expandDirection(self.currStep.path)
        if isExpanded then
          SendNoEcho("gan che to " .. direction)
        else
          ColourNote("red", "", "���ڲ�֧������·��" .. self.currStep.path)
          return self:doCancel()
        end
      elseif self.currStep.category == PathCategory.boat then
        self:debug("boatStatus?", self.boatStatus)
        if self.boatStatus == "yelling" then
          -- �д�
          SendNoEcho(self.currStep.path)
          SendNoEcho("gan che to enter")
        elseif self.boatStatus == "boating" then
          self:debug("��δ�������ȴ�")
        elseif self.boatStatus == "leaving" then
          SendNoEcho("gan che to out")
        else
          error("Unexpected boat status")
        end
      elseif self.currStep.category == PathCategory.pause then
        ColourNote("red", "", "���ڲ�֧��pause·��")
        return self:doCancel()
      elseif self.currStep.category == PathCategory.block then
        ColourNote("red", "", "���ڲ�֧��block·��")
        return self:doCancel()
      else
        error("current version does not support this path category:" .. self.currStep.category, 2)
      end
      SendNoEcho("set hubiao step_done")
      wait.time(2)
      helper.checkUntilNotBusy()
      self:debug("����һ�����Ƿ�ɹ�", self.stepSuccess)
      if self.transferSuccess then
        self:debug("�����ѳɹ���׼������")
        wait.time(2)
        helper.checkUntilNotBusy()
        return self:fire(Events.TRANSFER_SUCCESS)
      elseif self.stepSuccess then
        return self:fire(Events.STEP_SUCCESS)
      else
        return self:fire(Events.STEP_FAIL)
      end
    end
  end

  function prototype:doRelocate()
    wait.time(2)
    helper.checkUntilNotBusy()
    self:debug("�ض�λ����ȡ������䲢ƥ�䣬��ǰ���������", self.robberMoves)
    -- ��ȡ���һ�񷿼�
    local rooms1 = travel:getNearbyRooms(self.transferRoomId, self.robberMoves)
    if self.DEBUG then
      local roomIds = helper.copyKeys(rooms1)
      print("���1�񷿼��б�", table.concat(roomIds, ","))
    end
    self:debug("��ȡ��ǰ������Ϣ")
    travel:lookUntilNotBusy()
    local currRoomName = travel.currRoomName
    local currRoomDesc = table.concat(travel.currRoomDesc)
    local currRoomExits = travel.currRoomExits
    self:debug(currRoomName)
    self:debug(currRoomDesc)
    self:debug(currRoomExits)
    local matchedRooms = {}
    for _, room in pairs(rooms1) do
      if currRoomName == room.name
        and currRoomDesc == room.description
        and travel:checkExitsIdentical(currRoomExits, room.exits)
        and (self.transferRoomId ~= room.id or self.robberMoves > 1)
      then
        table.insert(matchedRooms, room)
      end
    end
    if #(matchedRooms) > 1 then
      -- ��Ӷ�������Ϣ��ƥ�䣬����ƥ��Ŀ���
      local zoneCode = travel.roomsById[self.transferRoomId].zone
      self:debug("���ֶ������ƥ�䣬������������ƥ��", zoneCode)
      local matchedRoomsWithZone = {}
      for _, room in ipairs(matchedRooms) do
        if room.zone == zoneCode then
          table.insert(matchedRoomsWithZone, room)
        end
      end
      if #matchedRoomsWithZone == 0 then
        ColourNote("red", "", "������ͬ���򷿼�ƥ�䣬��������")
        return self:doCancel()
      elseif #matchedRoomsWithZone > 1 then
        ColourNote("red", "", "����ͬ����������ƥ�䣬��������")
        return self:doCancel()
      else
        ColourNote("yellow", "", "ƥ�䵽ͬ����Ψһ���䣬���¼���")
        travel.currRoomId = matchedRoomsWithZone[1].id
        travel:refreshRoomInfo()
        self.transferRoomId = travel.currRoomId
        return self:fire(Events.RELOCATED)
      end
    elseif #(matchedRooms) == 1 then
      ColourNote("green", "", "��ƥ��Ψһ���䣬���¼�������ƻ�")
      travel.currRoomId = matchedRooms[1].id
      travel:refreshRoomInfo()
      self.transferRoomId = travel.currRoomId
      return self:fire(Events.RELOCATED)
    else
      ColourNote("red", "", "�޷����ƥ�䣬����������")
      return self:doCancel()
    end
  end

  function prototype:doSubmit()
    travel:stop()
    travel:walkto(StartRoomId)
    travel:waitUntilArrived()
    self.submitSuccess = false
    SendNoEcho("set hubiao submit_start")
    SendNoEcho("ask " .. JobNpcId .. " about finish")
    SendNoEcho("set hubiao submit_done")
    wait.time(2)
    helper.checkUntilNotBusy()
    if self.submitSuccess then
      self.rounds = self.rounds + 1
      self:debug("�ѳɹ����" .. self.rounds .. "�ֻ���")
      if self.rounds > self.maxRounds then
        self:debug("�ѳ�����������ִ����ޣ���������")
        SendNoEcho("ask " .. JobNpcId .. " about ��������")
        self.rounds = 0
      end
      self.findMixin = false
      SendNoEcho("set hubiao mixin_start")
      SendNoEcho("look mixin")
      SendNoEcho("set hubiao mixin_done")
      wait.time(2)
      helper.checkUntilNotBusy()
      if self.findMixin then
        return self:fire(Events.MIXIN_FOUND)
      else
        self:debug("�ɹ����һ������")
        return self:fire(Events.CONTINUE)
      end
    else
      self:debug("�����ύ���ɹ���ȡ��֮")
      return self:doCancel()
    end
  end

  return prototype
end
return define_hubiao():FSM()

