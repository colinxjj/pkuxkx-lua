--
-- idgen.lua
-- User: zhe.jiang
-- Date: 2017/6/26
-- Desc:
-- Change:
-- 2017/6/26 - created

local define_idgen = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new()
    local obj = {}
    setmetatable(obj, self or prototype)
    self.id = 0
    return obj
  end

  function prototype:decorate(obj)
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:next()
    self.id = self.id + 1
    return self.id
  end

  return prototype
end
return define_idgen()


