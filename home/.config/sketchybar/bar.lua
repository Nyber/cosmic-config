local colors = require("colors")

sbar.bar({
  height = 32,
  color = colors.bar.bg,
  border_color = colors.bar.border,
  padding_right = 2,
  padding_left = 2,
  topmost = "on",
  sticky = true,
})
