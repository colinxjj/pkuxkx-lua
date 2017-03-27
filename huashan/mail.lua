--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/20
-- Time: 22:24
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"

local patterns = [[
你伸手向怀中一摸，发现密函已经不翼而飞！

]]

local define_mail = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop",
    prepare = "prepare",

  }
  local Events = {
    START = "start",

  }
  local REGEXP = {

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
  end

  function prototype:initStates() end

  function prototype:initTransitions() end

  function prototype:initTriggers() end

  function prototype:initAliases() end

  function prototype:doGetGear()
    travel:walkto(183)
    travel:waitUntilArrived()
    SendNoEcho("do 2 draw sword")
    SendNoEcho("draw armor")
    SendNoEcho("draw surcoat")
    SendNoEcho("draw head")
    SendNoEcho("draw boots")
    SendNoEcho("draw cloth")
    SendNoEcho("remove all")
    SendNoEcho("wear all")
    SendNoEcho("wield all")
  end

  return prototype
end
return define_mail():FSM()