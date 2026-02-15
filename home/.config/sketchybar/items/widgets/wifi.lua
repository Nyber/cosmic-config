local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local wifi = sbar.add("item", "widgets.wifi", {
  position = "right",
  icon = {
    string = icons.wifi.disconnected,
    color = colors.grey,
    font = {
      style = settings.font.style_map["Regular"],
      size = 16.0,
    },
  },
  label = { drawing = false },
  click_script = "open x-apple.systempreferences:com.apple.wifi-settings-extension",
})

wifi:subscribe({ "network_change", "system_woke", "forced" }, function()
  sbar.exec("ipconfig getifaddr en0", function(result)
    if type(result) ~= "string" then result = tostring(result) end
    local connected = result:match("%d+%.%d+%.%d+%.%d+") ~= nil

    wifi:set({
      icon = {
        string = connected and icons.wifi.connected or icons.wifi.disconnected,
        color = connected and colors.blue or colors.grey,
      },
    })
  end)
end)

sbar.add("bracket", "widgets.wifi.bracket", { wifi.name }, {
  background = { color = colors.bg1 },
})

sbar.add("item", "widgets.wifi.padding", {
  position = "right",
  width = settings.group_paddings,
})
