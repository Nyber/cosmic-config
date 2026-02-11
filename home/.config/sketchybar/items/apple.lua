local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Padding item required because of bracket
sbar.add("item", { width = 5 })

local apple = sbar.add("item", {
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Regular"],
      size = 16.0
    },
    string = icons.apple,
    padding_right = 8,
    padding_left = 8,
  },
  label = { drawing = false },
  background = {
    color = colors.bg2,
    border_color = colors.black,
    border_width = 1
  },
  padding_left = 1,
  padding_right = 1,
  popup = { align = "left", height = 30 }
})

local function popup_item(icon_str, label_str, click)
  sbar.add("item", {
    position = "popup." .. apple.name,
    icon = { string = icon_str, font = { family = settings.font.text, size = 14.0 }, padding_left = 8, padding_right = 4 },
    label = { string = label_str, padding_right = 8 },
    click_script = "sketchybar --set " .. apple.name .. " popup.drawing=off && " .. click .. " ; sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)"
  })
end

popup_item("󰌢", "About This Mac",   "open 'x-apple.systempreferences:com.apple.SystemProfiler.AboutExtension'")
popup_item("󰀻", "Applications",     "osascript -e 'tell application \"System Events\" to key code 49 using command down' && sleep 0.3 && osascript -e 'tell application \"System Events\" to key code 18 using command down'")
popup_item("󰏌", "App Store",        "open -a 'App Store'")
popup_item("󰖲", "Force Quit…",      "osascript -e 'tell application \"System Events\" to key code 12 using {command down, option down}'")
popup_item("󰒲", "Sleep",            "pmset sleepnow")
popup_item("󰜉", "Restart…",         "osascript -e 'tell application \"System Events\" to restart'")
popup_item("󰐥", "Shut Down…",       "osascript -e 'tell application \"System Events\" to shut down'")
popup_item("󰌾", "Lock Screen",      "osascript -e 'tell application \"System Events\" to key code 12 using {command down, control down}'")
popup_item("󰍃", "Log Out…",         "osascript -e 'tell application \"System Events\" to key code 12 using {command down, shift down}'")

apple:subscribe("mouse.clicked", function()
  apple:set({ popup = { drawing = "toggle" } })
end)

-- Double border for apple using a single item bracket
sbar.add("bracket", { apple.name }, {
  background = {
    color = colors.transparent,
    height = 30,
    border_color = colors.grey,
  }
})

-- Padding item required because of bracket
sbar.add("item", { width = 7 })
