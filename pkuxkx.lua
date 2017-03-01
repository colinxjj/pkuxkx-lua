--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/2/25
-- Time: 12:26
-- To change this template use File | Settings | File Templates.
--

require "travel"
require "tprint"

local paths = travel:shortestpath(1, 5)

tprint(paths)
