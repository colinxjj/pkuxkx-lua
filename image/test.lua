--
-- test.lua
-- User: zhe.jiang
-- Date: 2017/4/12
-- Desc:
-- Change:
-- 2017/4/12 - created

local gd = require "gd"
local preprocess = require "image.preprocess"

local im = gd.createFromJpeg("b2evo_captcha_3FD4626B78460D1ED51A1D66878A0C24.jpg")
print("image loaded. Size: ", im:sizeXY())

-- print(im:getPixel(im:sizeX(),im:sizeY()))

local file1 = "pre1.png"
local grayImg = preprocess:grayProcessing(im)
local f1 = io.open(file1, "wb")
f1:write(grayImg:pngStr())
f1:close()
print("gray processing. Saved to ", file1)

local file1_2 = "pre1_2.png"
local smoothImg = preprocess:smooth(grayImg)
local f1_2 = io.open(file1_2, "wb")
f1_2:write(smoothImg:pngStr())
f1_2:close()
print("smooth. Saved as ", file1_2)

local file1_3 = "pre1_3.png"
local sharpImg = preprocess:sharpen(grayImg, smoothImg)
local f1_3 = io.open(file1_3, "wb")
f1_3:write(sharpImg:pngStr())
f1_3:close()
print("sharp. Saved as ", file1_3)

local file2 = "pre2.png"
local bitImg = preprocess:clearBackground(grayImg)
local f2 = io.open(file2, "wb")
f2:write(bitImg:pngStr())
f2:close()
print("remove background. Saved to ", file2)

local file3 = "pre3.png"
local cleanImg, shapeGroups = preprocess:clearInterference(bitImg)
print("shapes filtered on picture:")
for _, group in ipairs(shapeGroups) do
    print("shape group center:", string.format("(%d,%d)", group.centerX, group.centerY), "group size:", #(group.shapes))
end

local f3 = io.open(file3, "wb")
f3:write(cleanImg:pngStr())
f3:close()
print("remove interference. Saved as ", file3)