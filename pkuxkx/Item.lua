--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/31
-- Time: 11:09
-- To change this template use File | Settings | File Templates.
--

local define_Item = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    local obj = {}
    obj.id = assert(args.id, "id of item cannot be nil")
    obj.name = assert(args.name, "name of item cannot be nil")
    obj.ids = assert(args.ids, "ids of item cannot be nil")
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.id, "id of item cannot be nil")
    assert(obj.name, "name of item cannot be nil")
    assert(obj.ids, "ids of item cannot be nil")
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
return define_Item()
