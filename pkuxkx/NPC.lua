--
-- NPC.lua
-- User: zhe.jiang
-- Date: 2017/6/27
-- Desc:
-- Change:
-- 2017/6/27 - created

local define_NPC = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    local obj = {}
    obj.id = assert(args.id, "id of npc cannot be nil")
    obj.name = assert(args.name, "name of npc cannot be nil")
    obj.roomid = assert(args.roomid, "roomid of npc cannot be nil")
    obj.zone = args.zone  -- optional
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.id, "id of npc cannot be nil")
    assert(obj.name, "name of npc cannot be nil")
    assert(obj.roomid, "roomid of npc cannot be nil")
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
return define_NPC()

