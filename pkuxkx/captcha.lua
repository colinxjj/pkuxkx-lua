--
-- captcha.lua
-- User: zhe.jiang
-- Date: 2017/5/10
-- Desc:
-- Change:
-- 2017/5/10 - created

local helper = require "pkuxkx.helper"
local http = require "socket.http"
--assert(package.loadlib("luagd.dll", "luaopen_gd"))()
local gd = require "gd"
require "movewindow"

local define_captcha = function()
  local prototype = {}
  prototype.__index = prototype

  local REGEXP = {
    ALIAS_START = "^captcha\\s+start\\s*$",
    ALIAS_STOP = "^captcha\\s+stop\\s*$",
    ALIAS_DEBUG = "^captcha\\s+debug\\s+(on|off)\\s*$",
    ALIAS_SHOW = "^captcha\\s+show\\s*$",
    ALIAS_HIDE = "^captcha\\s+hide\\s*$",
    URL = "^(http://pkuxkx.net/antirobot/.+)$"
  }
  --  local WINDOW_WIDTH = 306
  --  local WINDOW_HEIGHT = 146
  local EDGE_WIDTH = 3
  --[[
  Useful positions:
  0	Stretch to output view size	      miniwin.pos_stretch_to_view
  1	Stretch with aspect ratio	        miniwin.pos_stretch_to_view_with_aspect
  2	Strech to owner size	            miniwin.pos_stretch_to_owner
  3	Stretch with aspect ratio	        miniwin.pos_stretch_to_owner_with_aspect
  4	Top left	                        miniwin.pos_top_left
  5	Center left-right at top	        miniwin.pos_top_center
  6	Top right	                        miniwin.pos_top_right
  7	On right, center top-bottom	      miniwin.pos_center_right
  8	On right, at bottom	              miniwin.pos_bottom_right
  9	Center left-right at bottom	      miniwin.pos_bottom_center
  10	On left, at bottom	            miniwin.pos_bottom_left
  11	On left, center top-bottom	    miniwin.pos_center_left
  12	Centre all	                    miniwin.pos_center_all
  13	Tile	                          miniwin.pos_tile
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
    self:initTriggers()
    self:initAliases()
    self.DEBUG = true
    -- create folder first
    self.pngs = {}
    self.pngDir = "png-captcha"
    os.execute("md " .. self.pngDir)
    self.windowWidth = 300
    self.windowHeight = 150
    self.windowName = "mini_captcha"
    self.imageName = "captcha"
    self.scriptName = "captcha_hotspot_callback"
    self.picThread = nil
    self.url = nil
    self.pngStr = nil
    self.baseUrl = "http://pkuxkx.net"

    world[self.scriptName] = function()
      self:refreshWindow()
    end

    -- initialize
    local im = gd.createFromJpeg(self.pngDir .. "\\" .. "empty.jpg")
    self.pngStr = im:pngStr()
    self:drawWindow()

  end

  function prototype:debug(...)
    if self.DEBUG then
      print(...)
    end
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups("captcha")
    helper.addTrigger {
      group = "captcha",
      regexp = REGEXP.URL,
      response = function(name, line, wildcards)
        self:debug("URL triggered")
        if self.picThread then
          ColourNote("red", "", "已有线程在获取验证码，忽略当前url")
        else
          self.url = wildcards[1]
          self:refreshWindow()
        end
      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("captcha")
    helper.addAlias {
      group = "captcha",
      regexp = REGEXP.ALIAS_START,
      response = function()
        self:start()
      end
    }
    helper.addAlias {
      group = "captcha",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        self:stop()
      end
    }
    helper.addAlias {
      group = "captcha",
      regexp = REGEXP.ALIAS_DEBUG,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self.DEBUG = true
        else
          self.DEBUG = false
        end
      end
    }
    helper.addAlias {
      group = "captcha",
      regexp = REGEXP.ALIAS_HIDE,
      response = function()
        WindowShow(self.windowName, false)
      end
    }
    helper.addAlias {
      group = "captcha",
      regexp = REGEXP.ALIAS_SHOW,
      response = function()
        WindowShow(self.windowName, true)
      end
    }
  end

  function prototype:refreshWindow()
    if not self.url then
      ColourNote("red", "", "没有可以搜索的captcha url")
    elseif self.picThread then
      ColourNote("red", "", "正在执行刷新操作，无法并行运行")
    else
      self.picThread = coroutine.create(function()
        local html = self:doGetHTML(self.url)
        if not html then
          ColourNote("yellow", "", "无法获取到网页信息")
        else
          local jpgUrl = self:doGetJpgUrl(html)
          self:debug("jpgUrl:", jpgUrl)
          if not jpgUrl then
            ColourNote("yellow", "", "无法从网页中查找到图片url")
          else
            local jpgStr = self:doDownloadJpg(jpgUrl)
            if not jpgStr then
              ColourNote("yellow", "", "无法获取到图片实体")
            else
              local filename = self.pngDir .. "\\" .. os.time() .. ".jpg"
              self.pngStr = self:doConvertJpgToPng(jpgStr, filename)
              if self.pngStr then
                ColourNote("green", "", "Captcha file saved as [" .. filename .. "]")
                self:drawWindow()
                WindowShow(self.windowName, true)
              else
                ColourNote("red", "", "Failed to get captcha")
                WindowShow(self.windowName, false)
              end
            end
          end
        end
        self.picThread = nil
      end)
      coroutine.resume(self.picThread)
    end
  end

  function prototype:doGetHTML(url)
    http.TIMEOUT = 2
    local result
    if string.find(url, self.baseUrl) then
      result = http.request(url)
      if not result then
        -- 官网可能遭到攻击了，使用备用网址
        self.baseUrl = "http://pkuxkx.com"
        local fallbackUrl = string.gsub(url, "pkuxkx.net", "pkuxkx.com")
        result = http.request(fallbackUrl)
      end
    else
      result = http.request(url)
    end
    return result
  end

  function prototype:doGetJpgUrl(htmlText)
    if not htmlText or htmlText == "" then return nil end
    if string.len(htmlText) >= 25 then
      local jpgUrl = string.match(htmlText, "/b2evo_captcha_tmp.-jpg")
      if not jpgUrl then return nil end
      return self.baseUrl .. "/antirobot" .. jpgUrl
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

  function prototype:createWindow()
    WindowCreate(
      self.windowName,
      0,
      0,
      self.windowWidth,
      self.windowHeight,
      miniwin.pos_top_right,
      0,
      WINDOW_BACKGROUND_COLOUR)
  end

  function prototype:drawWindow()
    self:createWindow()
    WindowLoadImageMemory(self.windowName, self.imageName, self.pngStr)
    self.windowWidth = WindowImageInfo(self.windowName, self.imageName, 2) + 6
    self.windowHeight = WindowImageInfo(self.windowName, self.imageName, 3) + 6
    -- recreate table
    self:createWindow()
    -- show on top z-index
    WindowSetZOrder(self.windowName, 999)
    WindowCircleOp(self.windowName, 2, 0, 0, 0, 0, BOX_COLOUR, 6, EDGE_WIDTH, 0x000000, 1)
    WindowDrawImage(self.windowName, self.imageName, EDGE_WIDTH, EDGE_WIDTH, -EDGE_WIDTH, -EDGE_WIDTH, 1)
    -- inner border
    WindowRectOp(self.windowName, 1, EDGE_WIDTH, EDGE_WIDTH, self.windowWidth + EDGE_WIDTH, self.windowHeight + EDGE_WIDTH, ColourNameToRGB("gray"))
    -- add hot spot
    WindowDeleteAllHotspots(self.windowName)
    WindowAddHotspot(self.windowName, "captcha_hotspot", EDGE_WIDTH, EDGE_WIDTH, -EDGE_WIDTH, -EDGE_WIDTH,
      nil,
      nil,
      nil,
      nil,
      self.scriptName,
      "click to refresh captcha",
      miniwin.cursor_hand,
      0)
    WindowShow(self.windowName, true)
  end

  function prototype:start()
    print("开启捕捉captcha")
    helper.enableTriggerGroups("captcha")
  end

  function prototype:stop()
    print("关闭捕捉captcha")
    helper.disableTriggerGroups("captcha")
    WindowDelete(self.windowName)
  end

  return prototype
end
local captcha = define_captcha():new()
captcha:start()
return captcha
