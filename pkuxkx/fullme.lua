--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/28
-- Time: 15:53
-- To change this template use File | Settings | File Templates.
--
local helper = require "pkuxkx.helper"
local http = require "socket.http"
assert(package.loadlib("luagd.dll", "luaopen_gd"))()
require "movewindow"

local define_fullme = function()
  local prototype = {}
  prototype.__index = prototype

  local REGEXP = {
    URL = "^(http://pkuxkx.net/antirobot/.+)$"
  }
--  local WINDOW_WIDTH = 306
--  local WINDOW_HEIGHT = 146
  local EDGE_WIDTH = 3
  local WINDOW_POSITION = 6
  --[[
  Useful positions:
  0 = stretch to output view size
  1 = stretch with aspect ratio
  2 = strech to owner size
  3 = stretch with aspect ratio
  4 = top left
  5 = center left-right at top
  6 = top right
  7 = on right, center top-bottom
  8 = on right, at bottom
  9 = center left-right at bottom
  10 = on left, at bottom
  11 = on left, center top-bottom
  12 = centre all
  13 = tile
  --]]
  local WINDOW_BACKGROUND_COLOUR = ColourNameToRGB ("darkgray")
  local BOX_COLOUR = ColourNameToRGB ("royalblue") -- Box boarder's colour
  local WINDOW_TEXT_COLOUR = ColourNameToRGB ("black")
  local TEXT_INSET = 5

  function prototype:new()
    local obj = {}
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    -- create folder first
    self.pngs = {}
    self.pngDir = "png-fullme"
    os.execute("md " .. self.pngDir)
    self.win = GetUniqueID()
    self.windowInfo = movewindow.install(self.win, WINDOW_POSITION, 0)
    self.windowWidth = 300
    self.windowHeight = 150
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("fullme")
    helper.addTrigger {
      group = "fullme",
      regexp = REGEXP.URL,
      response = function(name, line, wildcards)
        local url = wildcards[1]
      end
    }
  end

  function prototype:initAliases()

  end

  function prototype:doGetHTML(url)
    http.TIMEOUT = 1
    return http.request(url)
  end

  function prototype:doGetJpgUrl(htmlText)
    if not htmlText or htmlText == "" then return nil end
    if string.len(htmlText) >= 25 then
      local jpgUrl = string.match(htmlText, "/b2evo_captcha_tmp.-jpg")
      if not jpgUrl then return nil end
      return "http://pkuxkx.net:9999/antirobot" .. jpgUrl
    else
      return nil
    end
  end

  function prototype:doDownloadJpg(jpgUrl)
    return http.request(jpgUrl)
  end

  function prototype:doConvertJpgToPng(jpg, filename)
    local img = gd.createFromJpegStr(jpg)
    if not img then return nil end
    local pngStr = img:pngStr()
    if not pngStr then return nil end
    table.insert(self.pngs, filename)
    local file = assert(io.open(filename, "wb"))
    file:write(pngStr)
    file:close()
    return pngStr
  end

  function prototype:doDrawMiniWin(png)
    WindowCreate(
      self.win,
      self.windowInfo.window_left,
      self.windowInfo.window_top,
      self.windowWidth,
      self.windowHeight,
      self.windowInfo.window_mode,
      self.windowInfo.window_flags,
      WINDOW_BACKGROUND_COLOUR)
    WindowLoadImageMemory(self.win, "png-fullme", png)
    self.windowWidth = WindowImageInfo(self.win, "png-fullme", 2)
    self.windowHeight = WindowImageInfo(self.win, "png-fullme", 3)
    -- recreate window
    WindowCreate(
      self.win,
      self.windowInfo.window_left,
      self.windowInfo.window_top,
      self.windowWidth + 6,
      self.windowHeight + 46,
      self.windowInfo.window_mode,
      self.windowInfo.window_flags,
      WINDOW_BACKGROUND_COLOUR)
    -- show on top z-index
    WindowSetZOrder(self.win, 999)
    movewindow.add_drag_handler(self.win, 0, 0, 0, 0)
    WindowCircleOp(self.win, 2, 0, 0, 0, 0, BOX_COLOUR, 6, EDGE_WIDTH, 0x000000, 1)
    WindowDrawImage(self.win, "png-fullme", 3, 3, -3, -43, 1)
    -- inner border
    WindowRectOp(self.win, 1, 3, 3, self.windowWidth + 3, self.windowHeight + 3, ColourNameToRGB("gray"))
    -- refresh once clicked
    --WindowAddHotspot(self.win, "png-fullme", )
  end

  return prototype
end
-- return define_fullme():new()



