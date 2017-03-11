require  "world"
require "tprint"

local cstr = "ÄãºÃ"

local define_gb2312 = function()
  local gb2312 = {}
  gb2312.len = function(s)
    if not s or type(s) ~= "string" then error("string required", 2) end
    return string.len(s) / 2
  end

  gb2312.code = function(s, ci)
    local first = ci * 2 - 1
    return string.byte(s, first, first) * 256 + string.byte(s, first + 1, first + 1)
  end

  gb2312.char = function(chrcode)
    local first = math.floor(chrcode / 256)
    local second = chrcode - first * 256
    return string.char(first) .. string.char(second)
  end

  return gb2312
end
local gb2312 = define_gb2312()

print(cstr, string.len(cstr), gb2312.len(cstr), gb2312.code(cstr, 1), gb2312.code(cstr,2))

print(gb2312.char(47811), gb2312.code(gb2312.char(47811), 1))

