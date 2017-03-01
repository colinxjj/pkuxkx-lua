--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/2/26
-- Time: 16:07
-- Desc: Impementation of minimum heap
-- Note: 1. The element in heap must have natrual comparable property,
--       That means __eq, __le, __lt functions defined in
--       its metatable
--       2. The element also must have 'id' property, so we can identify
--       the position in heap by its id
--

minheap = {}

-- args:
function minheap:new()
  local obj = {}
  -- store the actual heap in array
  obj.array = {}
  -- store the position of element, id -> pos
  obj.map = {}
  obj.size = 0
  setmetatable(obj, {__index = self})
  return obj
end

function minheap:updatePos(pos)
  self.map[self.array[pos].id] = pos
end

function minheap:insert(elem)
  local pos = self.size + 1
  self.array[pos] = elem
  self:updatePos(pos)
  local parent = math.ceil(pos / 2)
  while pos > 1 do
    if self.array[pos] < self.array[parent] then
      self.array[pos], self.array[parent] = self.array[parent], self.array[pos]
      -- after the swap, we need to update the position map
      self:updatePos(parent)
      self:updatePos(pos)
      pos, parent = parent, math.ceil(parent / 2)
    else
      break
    end
  end
  self.size = self.size + 1
end

function minheap:removeMin()
  if self.size == 0 then error("heap is empty") end
  if self.size == 1 then
    self.size = 0
    return table.remove(self.array)
  end
  local first = self.array[1]
  local last = table.remove(self.array)
  -- move last to position of first and fix the structure
  local pos, c1, c2 = 1, 2, 3
  self.array[pos] = last
  self:updatePos(pos)
  while true do
    -- find the minimum element
    local minPos = pos
    if self.array[c1] and self.array[c1] < self.array[minPos] then
      minPos = c1
    end
    if self.array[c2] and self.array[c2] < self.array[minPos] then
      minPos = c2
    end
    if minPos ~= pos then
      self.array[pos], self.array[minPos] = self.array[minPos], self.array[pos]
      -- update pos map
      self:updatePos(pos)
      self:updatePos(minPos)
      pos, c1, c2 = minPos, minPos * 2, minPos * 2 + 1
    else
      break
    end
  end
  self.size = self.size - 1
  return first
end

-- adjust elem value and fix the heap again
-- the second argument is required and must be a function that modify the elem internally
-- this is useful when we implement path algorithm
function minheap:decreaseElem(id, decrease)
  local pos = self.map[id]
  local elem = self.array[pos]
  decrease(elem)
  local parent = math.floor(pos / 2)
  while pos > 1 do
    print(pos, self.array[pos].id, parent, self.array[parent].id)
    if self.array[pos] < self.array[parent] then
      self.array[pos], self.array[parent] = self.array[parent], self.array[pos]
      -- after the swap, we need to update the position map
      self:updatePos(parent)
      self:updatePos(pos)
      pos, parent = parent, math.ceil(parent / 2)
    else
      break
    end
  end
end

return minheap
