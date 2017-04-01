--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/4/1
-- Time: 8:33
-- To change this template use File | Settings | File Templates.
--

local p1 = [[
突然间，你被积雪闪耀着的刺眼的光芒灼伤，只觉头痛欲裂，眼前什么也看不到了！

慢慢的，你发现自己可以睁开眼了，只是眼睛似有砂子，疼痛流泪。

你突然发现在路旁的一片积雪上行走\\(walk\\)似乎可以用来练习轻功。

你提一口气，在积雪上小心的走了起来。

你一路走下来，看着脚印回想方才的步法，轻功水平提高了！

]]

local helper = require "pkuxkx.helper"
local travel = require "pkuxkx.travel"

local define_looksnow = function()
  local prototype = {}
  prototype.__index = prototype

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

  end

  return prototype
end
return define_looksnow():new()