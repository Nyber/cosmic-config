local colors = require("colors")
local settings = require("settings")

local screenshot = sbar.add("item", "widgets.screenshot", {
  position = "right",
  icon = {
    string = "󰄀",
    font = {
      style = settings.font.style_map["Regular"],
      size = 16.0,
    },
  },
  label = { drawing = false },
  click_script = "open -a 'Screenshot'",
})

sbar.add("bracket", "widgets.screenshot.bracket", { screenshot.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.screenshot.padding", {
  position = "right",
  width = settings.group_paddings
})
