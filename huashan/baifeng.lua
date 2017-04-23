--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/4/5
-- Time: 16:59
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

local define_module = function()
  local prototype = {}
  prototype.__index = prototype

  local REGEXP = {
    ALIAS_START = "^baifeng\\s+start\\s*$",
    ALIAS_STOP = "^baifeng\\s+stop\\s*$",
    ALIAS_DEBUG = "^baifeng\\s+stop\\s*$",
  }

  function prototype:new()
    local obj = {}
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self:initTriggers()
    self:initAliases()
  end

  function prototype:initTriggers()

  end

  function prototype:initAliases()
    helper.removeAliasGroups("baifeng")
    helper.addAlias {
      group = "baifeng",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return travel:walkto(2916, function()
          SendNoEcho("ask yue about Áîºü³å")
          SendNoEcho("ask yue about Ë¼¹ýÑÂ")
          SendNoEcho("n")
          SendNoEcho("northwest")
          SendNoEcho("w")
          SendNoEcho("wu")
          SendNoEcho("sd")
          SendNoEcho("eu")
          helper.addTimer {
            group = "baifeng",
            interval = 10,
            response = function()
              self:keepTryingBaiFeng()
            end
          }
        end)
      end
    }
    helper.addAlias {
      group = "baifeng",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        helper.removeTimerGroups("baifeng")
      end
    }
  end

  function prototype:keepTryingBaiFeng()
    status:hpbrief()
    if status.food < 150 then
      SendNoEcho("do 2 eat ganliang")
    end
    if status.drink < 150 then
      SendNoEcho("do 2 drink jiudai")
    end
    if status.currQi > 1000 and status.currNeili > 500 then
      SendNoEcho("lian dodge 2")
      SendNoEcho("lian sword 2")
    end
    SendNoEcho("ask linghu about ÔÀÁéÉº")
    SendNoEcho("ask linghu about ·çÌ«Ê¦Êå")
    SendNoEcho("enter dong")
    SendNoEcho("south")
    SendNoEcho("bai feng")
    SendNoEcho("n")
    SendNoEcho("out")
  end

  return prototype
end
return define_module():new()
