local colors = require("colors")
local settings = require("settings")

local orbstack = sbar.add("item", "widgets.orbstack", {
  position = "right",
  update_freq = 30,
  icon = {
    string = "󰡨",
    drawing = false,
    font = {
      style = settings.font.style_map["Regular"],
      size = 16.0,
    },
    color = colors.white,
  },
  label = { drawing = false },
  padding_left = 0,
  padding_right = 0,
  click_script = "open -a OrbStack",
})

local orbstack_bracket = sbar.add("bracket", "widgets.orbstack.bracket", {
  orbstack.name,
}, {
  background = { color = colors.bg1, drawing = false },
})

local orbstack_padding = sbar.add("item", "widgets.orbstack.padding", {
  position = "right",
  width = 0,
})

orbstack:subscribe({ "routine", "front_app_switched", "forced" }, function()
  sbar.exec("pgrep -x OrbStack", function(result)
    if type(result) ~= "string" then result = tostring(result) end
    local running = result ~= ""
    orbstack:set({
      icon = { drawing = running },
      padding_left = running and 5 or 0,
      padding_right = running and 5 or 0,
    })
    orbstack_bracket:set({
      background = { drawing = running },
    })
    orbstack_padding:set({
      width = running and settings.group_paddings or 0,
    })
  end)
end)
