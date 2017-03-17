--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/17
-- Time: 14:13
-- To change this template use File | Settings | File Templates.
--

local define_deque = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new()
    local obj = {}
    obj.head = 0    -- minus 1 before add, direct get
    obj.tail = 0    -- direct add, minus 1 before get
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:addFirst(elem)
    self.head = self.head - 1
    self[self.head] = elem
  end

  function prototype:addLast(elem)
    self[self.tail] = elem
    self.tail = self.tail + 1
  end

  function prototype:removeFirst()
    if self.head >= self.tail then error("deque is empty", 2) end
    local elem = self[self.head]
    self[self.head] = nil
    self.head = self.head + 1
    return elem
  end

  function prototype:removeLast()
    if self.head >= self.tail then error("deque is empty", 2) end
    self.tail = self.tail - 1
    local elem = self[self.tail]
    self[self.tail] = nil
    return elem
  end

  function prototype:size()
    return self.tail - self.head
  end

  return prototype
end
return define_deque()