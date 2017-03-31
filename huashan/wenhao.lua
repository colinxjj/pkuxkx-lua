--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/31
-- Time: 10:38
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local WenhaoPlayer = require "huashan.WenhaoPlayer"
local status = require "pkuxkx.status"
local Player = require "pkuxkx.Player"

local define_wenhao = function()
  local prototype = FSM.inheritedMeta()

  local SpecialZone = {

  }

  local States = {
    stop = "stop",
    helpme = "helpme",
    wenhao = "wenhao",
    submit = "submit",
  }
  local Events = {
    STOP = "stop",
    START = "start",  --  -> helpme
    PLAYER_PERCEIVED = "player_perceived",  --  -> wenhao
    PLAYER_NOT_PERCEIVED = "play_not_perceived",  --  -> helpme
    GO_NEXT_ROOM = "go_next_room",  --  -> wenhao
    ROOM_NOT_EXISTS = "room_not_exists", --  --> helpme
    WENHAO_DONE = "wenhao_done", --  -> submit
    PLAYERS_NOT_EXIST = "players_not_exist", --  --> stop
    FINISHED = "finished", --  --> stop
  }
  local REGEXP = {
    HELPME_WHISPER = "^[ >]*.*告诉你：【.*】目前在【(.*?)的(.*?)】.*$",
    WENHAO_DESC = "^[ >]*你对着.*深深一揖.*",
    SUBMITTED = "^[ >]*完成任务后，你被奖励了：$",
    ALIAS_START = "^wenhao\\s+start\\s+(.*?)\\s*$",
    ALIAS_STOP = "^wenhao\\s+stop\\s*$",
    ALIAS_DEBUG = "^wenhao\\s+debug\\s+(on|off)\\s*$",
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
    self.players = {}
    self.locatedPlayer = nil
    self.searchRooms = {}
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups("wenhao_submit_start", "wenhao_submit_done")
    helper.removeTriggerGroups("wenhao_one_shot")
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
        -- clear all players
        self.players = {}
        self.locatedPlayers = nil
        self.searchRooms = {}
        -- for wait api!
        SendNoEcho("set wenhao done")
      end,
      exit = function() end
    }
    self:addState {
      state = States.helpme,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.wenhao,
      enter = function() end,
      exit = function() end
    }
    self:addState {
      state = States.submit,
      enter = function()
        helper.enableTriggerGroups("wenhao_submit_start")
      end,
      exit = function()
        helper.disableTriggerGroups("wenhao_submit_start", "wenhao_submit_done")
      end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.helpme,
      event = Events.START,
      action = function()
        assert(self.players and #(self.players) > 0, "players cannot be empty when starting")
        return self:doHelpme()
      end
    }
    self:addTransitionToStop(States.stop)
    -- transition from state<helpme>
    self:addTransition {
      oldState = States.helpme,
      newState = States.wenhao,
      event = Events.PLAYER_PERCEIVED,
      action = function()
        -- 需要定位到准确的房间列表
        return self:doSearchRooms()
      end
    }
    self:addTransition {
      oldState = States.helpme,
      newState = States.helpme,
      event = Events.PLAYER_NOT_PERCEIVED,
      action = function()
        return self:doHelpme()
      end
    }
    self:addTransition {
      oldState = States.helpme,
      newState = States.stop,
      event = Events.PLAYERS_NOT_EXIST,
      action = function()
        return self:doAbandon()
      end
    }
    self:addTransitionToStop(States.helpme)
    -- transition from state<wenhao>
    self:addTransition {
      oldState = States.wenhao,
      newState = States.helpme,
      event = Events.ROOM_NOT_EXISTS,
      action = function()
        return self:doHelpme()
      end
    }
    self:addTransition {
      oldState = States.wenhao,
      newState = States.wenhao,
      event = Events.GO_NEXT_ROOM,
      action = function()
        return self:doWenhao()
      end
    }
    self:addTransition {
      oldState = States.wenhao,
      newState = States.submit,
      event = Events.WENHAO_DONE,
      action = function()
        return self:doSubmit()
      end
    }
    self:addTransitionToStop(States.wenhao)
    -- transition from state<submit>
    self:addTransitionToStop(States.submit)
  end

  function prototype:initTriggers()

  end

  function prototype:initAliases()
    helper.removeAliasGroups("wenhao")
    helper.addAlias {
      group = "wenhao",
      regexp = REGEXP.ALIAS_START,
      response = function(name, line, wildcards)
        -- players are delimted by comma,
        -- each player is composite of name and id, separated by semi-colon
        local ss = utils.split(wildcards[1], ",")
        local players = {}
        for _, s in pairs(ss) do
          local p = utils.split(s, ":")
          local player = Player:decorate {
            name = p[1],
            id = p[2]
          }
          table.insert(players, player)
        end
        self:setPlayers(players)
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "wenhao",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.stop)
      end
    }
    helper.addAlias {
      group = "wenhao",
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

  function prototype:doHelpme()
    if #(self.players) > 0 then
      local player = table.remove(self.players)
      self:debug("尝试请求帮助并等待20秒，定位玩家：", player.name, player.id)
      SendNoEcho("helpme find " .. player.id)
      local line, wildcards = wait.regexp(REGEXP.HELPME_WHISPER, 20)
      if line then
        self.locatedPlayer = WenhaoPlayer:decorate {
          id = player.id,
          name = player.name,
          zone = wildcards[1],
          location = wildcards[2]
        }
        return self:fire(Events.PLAYER_PERCEIVED)
      else
        return self:fire(Events.PLAYER_NOT_PERCEIVED)
      end
    else
      return self:fire(Events.PLAYERS_NOT_EXIST)  -- job fail
    end
  end

  function prototype:doSearchRooms()
    -- todo 有可能需要转换区域名称
    local adjustedZoneName = SpecialZone[self.locatedPlayer.zone] or self.locatedPlayer.zone

    local zone = travel.zonesByName[self.locatedPlayer.zone]
    if not zone then
      print("无法找到区域", self.locatedPlayer.zone)
      return self:fire(Events.ROOM_NOT_EXISTS)
    else
      -- clear the search Rooms
      self.searchRooms = {}
      for _, room in pairs(zone.rooms) do
        if room.name == self.locatedPlayer.location then
          table.insert(self.searchRooms, room)
        end
      end
      if #(self.searchRooms) > 5 then
        print("需要到达的房间数大于5，放弃问好该玩家")
        return self:fire(Events.ROOM_NOT_EXISTS)
      elseif #(self.searchRooms) > 0 then
        self:debug("准备前往问好玩家", self.locatedPlayer.id, "该玩家可能的地点数", #(self.searchRooms))
        return self:fire(Events.GO_NEXT_ROOM)
      else
        print("在区域", zone.name, "无法查找到房间", self.locatedPlayer.location)
        return self:fire(Events.ROOM_NOT_EXISTS)
      end
    end
  end

  function prototype:doAbandon()
    print("等待3秒后放弃")
    wait.time(3)
    helper.assureNotBusy();
    travel:walkto(66)
    travel:waitUntilArrived()
    -- SendNoEcho("fail")
  end

  function prototype:doWenhao()
    if #(self.searchRooms) > 0 then
      local room = table.remove(self.searchRooms)
      return travel:walkto(room.id, function()
        helper.assureNotBusy()
        SendNoEcho("wenhao " .. self.locatedPlayer.id)
        local line = wait.regexp(REGEXP.WENHAO_DESC, 3)
        if line then
          print("问好成功！等待1秒返回提交任务。")
          wait.time(1)
          return self:fire(Events.WENHAO_DONE)
        else
          print("找不到该玩家！尝试下一地点")
          return self:fire(Events.GO_NEXT_ROOM)
        end
      end)
    else
      return self:fire(Events.ROOM_NOT_EXISTS)
    end
  end

  function prototype:doSubmit()
    helper.assureNotBusy()
    travel:walkto(66, function()
      SendNoEcho("finish")
      local line = wait.regexp(REGEXP.SUBMITTED, 3)
      if not line then
        print("没有完成任务？尝试取消任务！")
        -- SendNoEcho("fail")
      end
      return self:fire(Events.STOP)
    end)
  end

  function prototype:setPlayers(players)
    self.players = players
  end

  function prototype:waitUntilDone()
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
      group = "wenhao_one_shot",
      regexp = helper.settingRegexp("wenhao", "done"),
      response = resumeCo
    }
    return coroutine.yield()
  end

  return prototype
end
return define_wenhao():FSM()





