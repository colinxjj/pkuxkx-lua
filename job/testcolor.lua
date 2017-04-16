--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/4/16
-- Time: 7:59
-- To change this template use File | Settings | File Templates.
--
helper = require "pkuxkx.helper"

helper.addTrigger {
  group ="testcolor",
  regexp = "^(.*)$",
  response = function(name, line, wildcards, styles)
    for _, style in ipairs(styles) do
      print(RGBColourToName(style.textcolour), RGBColourToName(style.backcolour), style.text)
    end
  end
}
