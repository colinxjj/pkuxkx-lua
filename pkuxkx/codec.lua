--
-- codec.lua
-- User: zhe.jiang
-- Date: 2017/7/6
-- Desc:
-- Change:
-- 2017/7/6 - created

local iconv = require "luaiconv"
local utf8encoder = iconv.new("utf-8", "gbk")
local utf8decoder = iconv.new("gbk", "utf-8")

local define_codec = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new()
    local obj = {}
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self.DEBUG = true
  end

  function prototype:debug(...)
    if self.DEBUG then
      print(...)
    end
  end

  -- convert gbk-encoded string to utf8
  function prototype:utf8(src)
    -- utf8 can only decoded in 255-char array, so we need to loop to concate every result
    local results = {}
    local idx = 1
    while true do
      local result = utf8encoder:iconv(string.sub(src, idx))
      table.insert(results, result)
      if string.len(result) < 253 then
        return table.concat(results, "")
      end
      local rev = utf8decoder:iconv(result)
      idx = idx + string.len(rev)
    end
    error("Unexpected error when encoding utf8 string", 2)
  end

  -- convert utf8-encoded string to gbk
  function prototype:gbk(src)
    return utf8decoder:iconv(src)
  end

  return prototype
end
return define_codec():new()
