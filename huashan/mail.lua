--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/20
-- Time: 22:24
-- To change this template use File | Settings | File Templates.
--

local helper = require "pkuxkx.helper"


local patterns = [[
你伸手向怀中一摸，发现密函已经不翼而飞！

]]

local define_mail = function()
  local prototype = FSM.inheritedMeta()
end
return define_mail():FSM()