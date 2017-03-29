require  "world"
require "tprint"

--local cstr = "ÄãºÃ"
--
--local define_gb2312 = function()
--  local gb2312 = {}
--  gb2312.len = function(s)
--    if not s or type(s) ~= "string" then error("string required", 2) end
--    return string.len(s) / 2
--  end
--
--  gb2312.code = function(s, ci)
--    local first = ci * 2 - 1
--    return string.byte(s, first, first) * 256 + string.byte(s, first + 1, first + 1)
--  end
--
--  gb2312.char = function(chrcode)
--    local first = math.floor(chrcode / 256)
--    local second = chrcode - first * 256
--    return string.char(first) .. string.char(second)
--  end
--
--  return gb2312
--end
--local gb2312 = define_gb2312()
--
--print(cstr, string.len(cstr), gb2312.len(cstr), gb2312.code(cstr, 1), gb2312.code(cstr,2))
--
--print(gb2312.char(47811), gb2312.code(gb2312.char(47811), 1))
--
--
--local define_A = function()
--  local prototype = {
--    __eq = function(a, b) return a.value == b.value end,
--    __lt = function(a, b) return a.value < b.value end,
--    __le = function(a, b) return a.value <= b.value end
--  }
--  prototype.__index = prototype
--
--  function prototype:new(args)
--    local obj = {}
--    obj.value = args.value
--    setmetatable(obj, prototype)
--    return obj
--  end
--
--  return prototype
--end
--local A = define_A()
--
--local a1 = A:new {value = 100}
--local a2 = A:new {value = 200}
--print (a1 < a2)
--
--local define_B = function()
--  local prototype = {
--    __eq = A.__eq,
--    __lt = A.__lt,
--    __le = A.__le
--  }
--  setmetatable(prototype, {
--    __index = A
--  })
--
--  function prototype:new(args)
--    local obj = A:new(args)
--    obj.code = args.code
--    setmetatable(obj, self or prototype)
--    return obj
--  end
--
--  return prototype
--end
--local B = define_B()
--local b1 = B:new {value = 100, code = 'B1'}
--local b2 = B:new {value = 200, code = 'B2'}
--print(b1 < b2)

local http = require "socket.http"

http.TIMEOUT = 1
local responseText = http.request("http://www.baidu.com")
print(responseText)
