--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/2/27
-- Time: 23:38
-- To change this template use File | Settings | File Templates.
--

local _nums = {
  ["一"] = 1,
  ["二"] = 2,
  ["三"] = 3,
  ["四"] = 4,
  ["五"] = 5,
  ["六"] = 6,
  ["七"] = 7,
  ["八"] = 8,
  ["九"] = 9
}
ch2number = function (str)
  if (#str % 2) == 1 then
    return 0
  end
  local result = 0
  local _10k = 1
  local unit = 1
  for i = #str - 2, 0, -2 do
    local char = string.sub(str, i + 1, i + 2)
    if char == "十" then
      unit = 10 * _10k
      if i == 0 then
        result = result + unit
      elseif _nums[string.sub(str, i - 1, i)] == nil then
        result = result + unit
      end
    elseif char == "百" then
      unit = 100 * _10k
    elseif char == "千" then
      unit = 1000 * _10k
    elseif char == "万" then
      unit = 10000 * _10k
      _10k = 10000
    else
      if _nums[char] ~= nil then
        result = result + _nums[char] * unit
      end
    end
  end
  return result
end

local _dirs = {
  ["上"] = "up",
  ["下"] = "down",
  ["南"] = "south",
  ["东"] = "east",
  ["西"] = "west",
  ["北"] = "north",
  ["南上"] = "southup",
  ["南下"] = "southdown",
  ["西上"] = "westup",
  ["西下"] = "westdown",
  ["东上"] = "eastup",
  ["东下"] = "eastdown",
  ["北上"] = "northup",
  ["北下"] = "northdown",
  ["西北"] = "northwest",
  ["东北"] = "northeast",
  ["西南"] = "southwest",
  ["东南"] = "southeast",
  ["小道"] = "xiaodao",
  ["小路"] = "xiaolu"
}
ch2direction = function (str) return _dirs(str) end

local areas = {
  {
  },
  {
    ["中原"] = true,
    ["曲阜"] = true,
    ["信阳"] = true,
    ["泰山"] = true,
    ["长江"] = true,
    ["嘉兴"] = true,
    ["泉州"] = true,
    ["江州"] = true,
    ["牙山"] = true,
    ["西湖"] = true,
    ["福州"] = true,
    ["南昌"] = true,
    ["镇江"] = true,
    ["苏州"] = true,
    ["昆明"] = true,
    ["桃源"] = true,
    ["岳阳"] = true,
    ["成都"] = true,
    ["北京"] = true,
    ["天坛"] = true,
    ["洛阳"] = true,
    ["灵州"] = true,
    ["晋阳"] = true,
    ["襄阳"] = true,
    ["长安"] = true,
    ["扬州"] = true,
    ["丐帮"] = true,
    ["峨嵋"] = true,
    ["华山"] = true,
    ["全真"] = true,
    ["古墓"] = true,
    ["星宿"] = true,
    ["明教"] = true,
    ["灵鹫"] = true,
    ["兰州"] = true
  },
  {
    ["临安府"] = true,
    ["归云庄"] = true,
    ["小山村"] = true,
    ["张家口"] = true,
    ["麒麟村"] = true,
    ["紫禁城"] = true,
    ["神龙岛"] = true,
    ["杀手帮"] = true,
    ["岳王墓"] = true,
    ["桃花岛"] = true,
    ["天龙寺"] = true,
    ["武当山"] = true,
    ["少林寺"] = true,
    ["白驼山"] = true,
    ["凌霄城"] = true,
    ["大轮寺"] = true,
    ["无量山"] = true,
    ["天地会"] = true
  },
  {
    ["西湖梅庄"] = true,
    ["长江南岸"] = true,
    ["长江北岸"] = true,
    ["黄河南岸"] = true,
    ["黄河北岸"] = true,
    ["大理城中"] = true,
    ["平西王府"] = true,
    ["康亲王府"] = true,
    ["日月神教"] = true,
    ["丝绸之路"] = true,
    ["姑苏慕容"] = true,
    ["峨眉后山"] = true
  },
  {
    ["建康府南城"] = true,
    ["建康府北城"] = true,
    ["杭州提督府"] = true
  }
}
function ch2place(str)
  local place = {}
  for i = 5, 2, -1 do
    if string.len(str) >= i then
      local prefix = string.sub(str, 1, i)
      if areas[i][prefix] then
        place.area = prefix
        place.room = string.sub(str, i + 1, string.len(str))
        break
      end
    end
  end
  return place
end
