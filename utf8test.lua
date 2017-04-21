
local gd = require "gd"

--local http = require "socket.http"
--
--local pngStr = http.request("http://i3.sinaimg.cn/home/2013/0331/U586P30DT20130331093840.png")
--
--print(gd.createFromPngStr(pngStr))

local filename = "b2evo_captcha_800BADCA351CB69D1565AA40BB66838B.jpg"

local file = assert(io.open(filename, "rb"))
local jpgStr = file:read("*a")
file:close()
local im = gd.createFromJpegStr(jpgStr)

local distribution = {}

for x = 1, im:sizeX() do
  for y = 1, im:sizeY() do
    local color = im:getPixel(x, y)
    local red = im:red(color)
    -- 仅以R替代RGB去除红字
    local avg = math.floor(red)
    local newColor = im:colorAllocate(avg, avg, avg)
    im:setPixel(x, y, newColor)

    local c = distribution[newColor]
    if c then
      c.count = c.count + 1
    else
      distribution[newColor] = {red = avg, count = 1}
    end
  end
end

local newIm = gd.createFromPngStr(im:pngStr())
--
---- 中值滤波去噪
--local margin = {
--  x = 1, y = 1
--}
--
--local clearNoise = function(im, newIm)
--  for x = 1 + margin.x, im:sizeX() - margin.x do
--    for y = 1 + margin.y, im:sizeY() - margin.y do
--      local pixels = {}
--      for i = x - margin.x, x + margin.x do
--        for j = y - margin.y, y + margin.y do
--          table.insert(pixels, im:red(im:getPixel(i, j)))
--        end
--      end
--      table.sort(pixels)
--      local mid = pixels[5]
--      local color = newIm:colorAllocate(mid, mid, mid)
--      newIm:setPixel(x, y, color)
--    end
--  end
--end
--clearNoise(im, newIm)


local smoothList = {}
for _, c in pairs(distribution) do
  table.insert(smoothList, c)
end
table.sort(smoothList, function(a, b) return a.red < b.red end)

local prevList = smoothList

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


local black = im:colorAllocate(0, 0, 0)
local white = im:colorAllocate(255, 255, 255)

for x = 1, im:sizeX() do
  for y = 1, im:sizeY() do
    local red = im:red(im:getPixel(x, y))
    if red < 110 then
      im:setPixel(x, y, black)
    else
      im:setPixel(x, y, white)
    end
  end
end


local newFile = io.open("new1.png", "wb")
newFile:write(im:pngStr())
newFile:close()


-- 正则为 ^gopaths (.*?)$
--local directions = {
--  ["东"] = "east",
--  ["南"] = "south",
--  ["西"] = "west",
--  ["北"] = "north",
--  ["上"] = "up",
--  ["下"] = "down",
--  ["东上"] = "eastup",
--  ["东下"] = "eastdown",
--  ["南上"] = "southup",
--  ["南下"] = "southdown",
--  ["西上"] = "westup",
--  ["西下"] = "westdown",
--  ["北上"] = "northup",
--  ["北下"] = "northdown",
--  ["东南"] = "southeast",
--  ["西南"] = "southwest",
--  ["东北"] = "northeast",
--  ["西北"] = "northwest",
--}
--local cmd = "%1"
--Note("接收到路径为：", cmd)
--local paths = utils.split(cmd, " ")
--for _, path in ipairs(paths) do
--  local fullPath = directions[path]
--  if fullPath then
--    Send(fullPath)
--  else
--    ColourNote("red", "", "无法识别方向：" .. path)
--    break
--  end
--end





--83	31.757328647138
--144	89.593528277346
--202	858.16509116016
