--local iconv = require "luaiconv"
--local utf8encoder = iconv.new("utf-8", "gbk")
--local utf8decoder = iconv.new("gbk", "utf-8")

local codec = require "pkuxkx.codec"

local str = "这时一间很大的石厅，石厅的正北方是一个木桌，桌旁有两个椅子，坐着两个人。木桌的上方挂着一幅画，画上画着一个绝代佳人，依稀可以看见她眼里的幽怨之色。左边墙上也挂了一幅画，画的是一个中年男子，双目炯炯，威武神气。不知什么原因，画上有许多唾液."
print(string.len(str))

local output = codec:utf8(str)
print(string.len(output))
--local rev = utf8decoder:iconv(string.sub(output, 1, 253))
--local match = string.sub(str, 1, string.len(rev)) == rev
--print(match)

