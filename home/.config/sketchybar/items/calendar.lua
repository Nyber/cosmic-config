local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local cal = sbar.add("item", {
  icon = { drawing = false },
  label = {
    color = colors.white,
    padding_left = 8,
    padding_right = 8,
    font = { family = settings.font.numbers, size = 12.0 },
  },
  position = "right",
  update_freq = 30,
  padding_left = 1,
  padding_right = 1,
  background = {
    color = colors.bg1,
  },
  click_script = "open -a 'Calendar'"
})

sbar.add("bracket", "widgets.calendar.bracket", { cal.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.calendar.padding", {
  position = "right",
  width = settings.group_paddings
})

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
  local month = tonumber(os.date("%m"))
  local day = tonumber(os.date("%d"))
  local hour = tonumber(os.date("%I"))
  cal:set({
    label = month .. "/" .. day .. os.date("/%y") .. " " .. hour .. os.date(":%M %p"),
  })
end)
