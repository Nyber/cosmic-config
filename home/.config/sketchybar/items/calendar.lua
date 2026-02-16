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
  update_freq = 60,
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
  local now = os.date("*t")
  if not now then return end
  local h = now.hour % 12
  if h == 0 then h = 12 end
  cal:set({
    label = string.format("%d/%d/%02d %d:%02d %s",
      now.month, now.day, now.year % 100,
      h, now.min, now.hour >= 12 and "PM" or "AM"),
  })
end)
