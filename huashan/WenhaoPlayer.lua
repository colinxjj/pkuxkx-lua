--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/31
-- Time: 10:40
-- To change this template use File | Settings | File Templates.
--

local Player = require "pkuxkx.Player"

local define_WenhaoPlayer = function()
  -- only inherite methods
  local prototype = {__index = Player}
  prototype.__index = prototype

  function prototype:new(args)
    local obj = Player:new(args)
    obj.id = assert(args.id, "id of wenhao player cannot be nil")
    obj.name = assert(args.name, "name of wenhao player cannot be nil")
    obj.zone = assert(args.zone, "zone of wenhao player cannot be nil") -- chinese name
    obj.location = assert(args.location, "location of wenhao player cannot be nil")  -- chinese name
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    Player:decorate(obj)
    assert(obj.id, "id of wenhao player cannot be nil")
    assert(obj.name, "name of wenhao player cannot be nil")
    assert(obj.zone, "zone of wenhao player cannot be nil") -- chinese name
    assert(obj.location, "location of wenhao player cannot be nil")  -- chinese name
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
return define_WenhaoPlayer()

