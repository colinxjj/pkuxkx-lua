--local iconv = require "luaiconv"
--local utf8encoder = iconv.new("utf-8", "gbk")
--local utf8decoder = iconv.new("gbk", "utf-8")

local codec = require "pkuxkx.codec"

local str = "��ʱһ��ܴ��ʯ����ʯ������������һ��ľ�����������������ӣ����������ˡ�ľ�����Ϸ�����һ���������ϻ���һ���������ˣ���ϡ���Կ������������Թ֮ɫ�����ǽ��Ҳ����һ������������һ���������ӣ�˫Ŀ������������������֪ʲôԭ�򣬻����������Һ."
print(string.len(str))

local output = codec:utf8(str)
print(string.len(output))
--local rev = utf8decoder:iconv(string.sub(output, 1, 253))
--local match = string.sub(str, 1, string.len(rev)) == rev
--print(match)

