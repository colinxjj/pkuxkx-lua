--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/4/1
-- Time: 8:33
-- To change this template use File | Settings | File Templates.
--

local p1 = [[
ͻȻ�䣬�㱻��ѩ��ҫ�ŵĴ��۵Ĺ�â���ˣ�ֻ��ͷʹ���ѣ���ǰʲôҲ�������ˣ�

�����ģ��㷢���Լ������������ˣ�ֻ���۾�����ɰ�ӣ���ʹ���ᡣ

��ͻȻ������·�Ե�һƬ��ѩ������\\(walk\\)�ƺ�����������ϰ�Ṧ��

����һ�������ڻ�ѩ��С�ĵ�����������

��һ·�����������Ž�ӡ���뷽�ŵĲ������Ṧˮƽ����ˣ�

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