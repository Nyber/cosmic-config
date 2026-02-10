local colors = require("colors")
local settings = require("settings")

local vpn = sbar.add("item", "widgets.vpn", {
  position = "right",
  update_freq = 5,
  icon = {
    string = "󰌿",
    color = colors.grey,
    font = {
      style = settings.font.style_map["Regular"],
      size = 16.0,
    },
  },
  label = { drawing = false },
})

vpn:subscribe({ "routine", "forced" }, function()
  sbar.exec("pgrep -x svpn", function(result)
    local connected = result ~= ""
    vpn:set({
      icon = {
        string = connected and "󰌾" or "󰌿",
        color = connected and colors.blue or colors.grey,
      },
      label = {
        drawing = connected,
        string = "VPN",
        color = connected and colors.blue or colors.grey,
      },
    })
  end)
end)

vpn:subscribe("mouse.clicked", function()
  sbar.exec("$CONFIG_DIR/helpers/vpn_toggle.sh")
end)

sbar.add("bracket", "widgets.vpn.bracket", { vpn.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.vpn.padding", {
  position = "right",
  width = settings.group_paddings
})
