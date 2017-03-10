--require "tprint"
--local iconv = require 'luaiconv'
--local toUTF16 = iconv.open("utf-16le", "utf-8")
--local utf8 = require 'utf8'
--
--local str = "hello"
--print(str)
--print(string.len(str))
--print(utf8.len(str))
--local cstr = "你好"
--print(str)
--print(string.len(cstr))
--print(utf8.len(cstr))
--print("after 1", utf8.next_raw(cstr, 1))
--local result = utf8.next_raw(cstr, 4)
--print("after 4", result)
--
--local ustr = toUTF16:iconv(cstr)
--print(string.len(ustr))
--local c = 0
--for i=1,string.len(ustr) do
--  if i - math.floor(i/2)*2 == 0 then
--    c = c * 256 + string.byte(ustr, i)
--    print(c)
--  else
--    c = string.byte(ustr, i)
--  end
--end

require 'world'
local cstr = "你好，中国"
local unicodes = utils.utf8decode(cstr)
print(#unicodes)
for i = 1, #unicodes do
  local c = utils.utf8sub(cstr, i, i)
  print(c)
end

