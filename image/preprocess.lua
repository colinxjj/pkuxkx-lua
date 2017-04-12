--
-- preprocess.lua
-- User: zhe.jiang
-- Date: 2017/4/12
-- Desc:
-- Change:
-- 2017/4/12 - created

-- 注意！！！gd库中的图像像素数组下标遵循c和java惯例，[0, size)
local gd = require "gd"
local Deque = require "pkuxkx.deque"

local define_preprocess = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new()
    local obj = {}
    setmetatable(obj, self or prototype)
    return obj
  end

  -- 将红字去除，并进行灰度化
  function prototype:grayProcessing(oldIm)
    local newIm = gd.createFromPngStr(oldIm:pngStr())
    for x = 0, oldIm:sizeX() - 1 do
      for y = 0, oldIm:sizeY() - 1 do
        local color = oldIm:getPixel(x, y)
        local red = oldIm:red(color)
        -- 仅以R替代RGB去除红字
        local avg = math.floor(red)
        local newColor = oldIm:colorAllocate(avg, avg, avg)
        newIm:setPixel(x, y, newColor)
      end
    end
    return newIm
  end

  -- 高斯模糊
  function prototype:smooth(oldIm)
    local newIm = gd.createFromPngStr(oldIm:pngStr())
    local template = {
      {1, 2, 1},
      {2, 4, 2},
      {1, 2, 1}
    }
    for x = 1, oldIm:sizeX() - 2 do
      for y = 1, oldIm:sizeY() - 2 do
        local sum = 0
        local templateIdxX = 0
        for i = x - 1, x + 1 do
          templateIdxX = templateIdxX + 1
          local templateIdxY = 0
          for j = y - 1, y + 1 do
            templateIdxY = templateIdxY + 1
            local red = oldIm:red(oldIm:getPixel(i, j))
            sum = sum + red * template[templateIdxY][templateIdxX]
          end
        end
        sum = sum / 16
        if sum > 255 then sum = 255 end
        newIm:setPixel(x, y, newIm:colorAllocate(sum, sum, sum))
      end
    end
    return newIm
  end

  -- 锐化图像
  function prototype:sharpen(oldIm, smoothIm)
    local newIm = gd.createFromPngStr(oldIm:pngStr())
    for x = 0, oldIm:sizeX() - 1 do
      for y = 0, oldIm:sizeY() - 1 do
        local old = oldIm:red(oldIm:getPixel(x, y))
        local smooth = smoothIm:red(smoothIm:getPixel(x, y))
        local newRed = math.floor(old + old - smooth)
        if newRed > 255 then
          newRed = 255
        elseif newRed < 0 then
          newRed = 0
        end
        local newColor = newIm:colorAllocate(newRed, newRed, newRed)
        newIm:setPixel(x, y, newColor)
      end
    end
    return newIm
  end


  -- 寻找像素分布，其中最高峰为背景色，最低峰为前景色，以前景色为阈值，转换为bitmap
  function prototype:clearBackground(oldIm)
    local newIm = gd.createFromPngStr(oldIm:pngStr())
    local distribution = {}
    for x = 0, oldIm:sizeX() - 1 do
      for y = 0, oldIm:sizeY() - 1 do
        local red = oldIm:red(oldIm:getPixel(x, y))
        local c = distribution[red]
        if c then
          c.count = c.count + 1
        else
          distribution[red] = {red = red, count = 1}
        end
      end
    end
    local colors = {}
    for _, c in pairs(distribution) do
      table.insert(colors, c)
    end
    table.sort(colors, function(a, b) return a.red < b.red end)
    -- 平滑分布，查找最高峰，高于前后连续5个
    local prevList = colors
    for i = 1, 100 do
      local currList = {}
      table.insert(currList, prevList[1])
      for i = 2, #prevList - 1 do
        local avg = {red = prevList[i].red, count = (prevList[i-1].count + prevList[i].count + prevList[i+1].count) / 3}
        table.insert(currList, avg)
      end
      table.insert(currList, prevList[#prevList])
      prevList = currList
    end
    local peek = {}
    for i = 1 + 5, #prevList - 5 do
      local c = prevList[i].count
      if c >= prevList[i-5].count
        and c >= prevList[i-4].count
        and c >= prevList[i-3].count
        and c >= prevList[i-2].count
        and c >= prevList[i-1].count
        and c >= prevList[i+1].count
        and c >= prevList[i+2].count
        and c >= prevList[i+3].count
        and c >= prevList[i+4].count
        and c >= prevList[i+5].count then
        table.insert(peek, prevList[i])
      end
    end
    local frontColor = peek[1]
--    local backColor = peek[#peek]
    local threshold = frontColor.red + 5
    -- 转化为bitmap

    local black = newIm:colorAllocate(0, 0, 0)
    local white = newIm:colorAllocate(255, 255, 255)
    for x = 0, newIm:sizeX() - 1 do
      for y = 0, newIm:sizeY() - 1 do
        -- 将最外沿设置为白色
        if x == 0 or y == 0 then
          newIm:setPixel(x, y, white)
        else
          local red = newIm:red(newIm:getPixel(x, y))
          if red < threshold then
            newIm:setPixel(x, y, black)
          else
            newIm:setPixel(x, y, white)
          end
        end
      end
    end
    return newIm
  end

  -- 清除干扰 - 中值滤波
  local midValueFiltering = function(oldIm)
    local marginX, marginY = 1, 1
    local newIm = gd.createFromPngStr(oldIm:pngStr())
    for x = marginX, oldIm:sizeX() - marginX - 1 do
      for y = marginY, oldIm:sizeY() - marginY - 1 do
        local pixels = {}
        for i = x - marginX, x + marginX do
          for j = y - marginY, y + marginY do
            table.insert(pixels, oldIm:red(oldIm:getPixel(i, j)))
          end
        end
        table.sort(pixels)
        local mid = pixels[5]
        local color = newIm:colorAllocate(mid, mid, mid)
        newIm:setPixel(x, y, color)
      end
    end
    return newIm
  end

  local isNearby = function(x1, y1, x2, y2, distanceThreshold)
    local diffX = x1 - x2
    local diffY = y1 - y2
    return diffX * diffX + diffY * diffY <= distanceThreshold * distanceThreshold
  end

  -- 清除干扰 - bfs
  local bfsFiltering = function(oldIm)
    local lenX = oldIm:sizeX()
    local lenY = oldIm:sizeY()
    local threshold = 5

    local newIm = gd.createFromPngStr(oldIm:pngStr())
    local white = newIm:colorAllocate(255, 255, 255)

    local positionValue = function(x, y)
      return y * lenX + x
    end

    local visited = {}
    local shapes = {}
    local queue = Deque:new()
    for y = 0, oldIm:sizeY() - 1 do
      local prevBlack = false
      for x = 0, oldIm:sizeX() - 1 do
        local red = oldIm:red(oldIm:getPixel(x, y))
        if red == 0 then  -- is black
          if not prevBlack then -- prev is not black
            queue:addLast {x = x, y = y}
          end
          prevBlack = true
        else  -- is white
          prevBlack = false
        end
      end
    end

    while queue:size() > 0 do
      local point = queue:removeFirst()
      local posValue = positionValue(point.x, point.y)
      if not visited[posValue] then
        -- bfs to see the connected part
        local points = 0
        local singleLine = true
        local bfsQueue = Deque:new()
        local bfsVisited = {}
        bfsQueue:addLast(point)

        while bfsQueue:size() > 0 do
          local p = bfsQueue:removeFirst()
          local pv = positionValue(p.x, p.y)
          if not visited[pv] then
            visited[pv] = true
            table.insert(bfsVisited, p)
            points = points + 1
            local horizontal, vertical
            -- left
            if p.x > 0 and oldIm:red(oldIm:getPixel(p.x - 1, p.y)) == 0 then
              bfsQueue:addLast { x = p.x - 1, y = p.y }
              horizontal = true
            end
            -- right
            if p.x < lenX - 1 and oldIm:red(oldIm:getPixel(p.x + 1, p.y)) == 0 then
              bfsQueue:addLast { x = p.x + 1, y = p.y }
              horizontal = true
            end
            -- top
            if p.y > 0 and oldIm:red(oldIm:getPixel(p.x, p.y - 1)) == 0 then
              bfsQueue:addLast { x = p.x, y = p.y - 1 }
              vertical = true
            end
            -- bottom
            if p.y < lenY - 1 and oldIm:red(oldIm:getPixel(p.x, p.y + 1)) == 0 then
              bfsQueue:addLast { x = p.x, y = p.y + 1 }
              vertical = true
            end

            if horizontal and vertical then
              singleLine = false
            end
          end
        end
        -- 去除小于个数阈值的连通区域，去除细线
        if points < threshold or singleLine or #(bfsVisited) < 12 then
          for _, p in ipairs(bfsVisited) do
            newIm:setPixel(p.x, p.y, white)
          end
        else
          local xSum, ySum, count = 0, 0, 0
          for _, p in ipairs(bfsVisited) do
            xSum = xSum + p.x
            ySum = ySum + p.y
            count = count + 1
          end
          local shape = {
            centerX = math.floor(xSum / count),
            centerY = math.floor(ySum / count),
            points = bfsVisited
          }
          table.insert(shapes, shape)
        end
      end
    end

    local shapeThreashold = 100
    local distanceThreshold = 30
    local bigShapes = {}
    local smallShapes = {}
    local shapeGroups = {}  -- 存储形状组，每一组代表一个字
    for _, shape in ipairs(shapes) do
      if #(shape.points) < shapeThreashold then
        table.insert(smallShapes, shape)
      else
        table.insert(bigShapes, shape)
      end
    end

    -- 对于大的形状，插入形状组，如果有非常临近的，合并为一个组
    local groupId = 1
    for i = 1, #bigShapes do
      local s1 = bigShapes[i]
      local nearbyGroupId
      for j = 1, #shapeGroups do
        local group = shapeGroups[j]
        if isNearby(s1.centerX, s1.centerY, group.centerX, group.centerY, distanceThreshold) then
          nearbyGroupId = j
          break
        end
        -- 只合并第一个近的
        if nearbyGroupId then break end
      end
      if nearbyGroupId then
        local group = shapeGroups[nearbyGroupId]
        local _sumCenterX = group._sumCenterX
        local _sumCenterY = group._sumCenterY
        local _sumCount = group._sumCount
        for _, p in ipairs(s1.points) do
          _sumCenterX = _sumCenterX + p.x
          _sumCenterY = _sumCenterY + p.y
          _sumCount = _sumCount + 1
        end
        group._sumCenterX = _sumCenterX
        group._sumCenterY = _sumCenterY
        group._sumCount = _sumCount
        group.centerX = math.floor(_sumCenterX / _sumCount)
        group.centerY = math.floor(_sumCenterY / _sumCount)
        table.insert(group.shapes, s1)
      else
        local _sumCenterX = 0
        local _sumCenterY = 0
        local _sumCount = 0
        for _, p in ipairs(s1.points) do
          _sumCenterX = _sumCenterX + p.x
          _sumCenterY = _sumCenterY + p.y
          _sumCount = _sumCount + 1
        end
        local group = {}
        group._sumCenterX = _sumCenterX
        group._sumCenterY = _sumCenterY
        group._sumCount = _sumCount
        group.centerX = math.floor(_sumCenterX / _sumCount)
        group.centerY = math.floor(_sumCenterY / _sumCount)
        group.shapes = {s1 }
        table.insert(shapeGroups, group)
      end
    end

    -- 对较小的块，如果距离大块的组较远，直接删除
    for _, ss in ipairs(smallShapes) do
      local nearbyGroupId
      for j = 1, #(shapeGroups) do
        local group = shapeGroups[j]
        if isNearby(ss.centerX, ss.centerY, group.centerX, group.centerY, distanceThreshold) then
          nearbyGroupId = j
          break
        end
      end
      if nearbyGroupId then
        table.insert(shapeGroups[nearbyGroupId].shapes, ss)
      else
        -- 删除
        for _, p in ipairs(ss.points) do
          newIm:setPixel(p.x, p.y, white)
        end
      end
    end

    return newIm, shapeGroups
  end

  -- 清除干扰先和杂点
  function prototype:clearInterference(oldIm)
    return bfsFiltering(oldIm)
  end

  -- 分隔字符
--  function prototype:split(oldIm)
--    local histogram = {}
--    for i = 0,
--  end

  return prototype
end

return define_preprocess():new()
