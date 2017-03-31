--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/31
-- Time: 10:50
-- To change this template use File | Settings | File Templates.
--


local define_Player = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    local obj = {}
    obj.id = assert(args.id, "id of player cannot be nil")
    obj.name = assert(args.name, "name of player cannot be nil")
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.id, "id of player cannot be nil")
    assert(obj.name, "name of player cannot be nil")
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
return define_Player()
