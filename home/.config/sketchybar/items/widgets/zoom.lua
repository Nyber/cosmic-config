local colors = require("colors")
local settings = require("settings")
local json = require("helpers.json")

local zoom = sbar.add("item", "widgets.zoom", {
  position = "right",
  drawing = false,
  icon = {
    string = ":zoom:",
    color = colors.grey,
    font = "sketchybar-app-font:Regular:16.0",
  },
  label = {
    drawing = false,
    color = colors.red,
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = 13.0,
    },
  },
})

zoom:subscribe("mouse.clicked", function()
  sbar.exec("osascript -e 'tell application \"System Events\" to get visible of process \"zoom.us\"'", function(result)
    if result:match("true") then
      sbar.exec("osascript -e 'tell application \"System Events\" to set visible of process \"zoom.us\" to false'")
    else
      sbar.exec("open -a 'zoom.us'")
    end
  end)
end)

local zoom_bracket = sbar.add("bracket", "widgets.zoom.bracket", { zoom.name }, {
  background = { color = colors.bg1 },
})

local zoom_padding = sbar.add("item", "widgets.zoom.padding", {
  position = "right",
  width = settings.group_paddings,
})

local function update_zoom()
  sbar.exec("pgrep -x zoom.us > /dev/null 2>&1 && echo running || echo stopped", function(result)
    local running = result:match("running") ~= nil
    if not running then
      zoom:set({ drawing = false })
      zoom_bracket:set({ drawing = false })
      zoom_padding:set({ drawing = false })
      return
    end

    sbar.exec("$CONFIG_DIR/helpers/badges/bin/badges 'zoom.us'", function(badge_result)
      local badges
      if type(badge_result) == "table" then
        badges = badge_result
      else
        local ok, decoded = pcall(json.decode, badge_result)
        badges = (ok and type(decoded) == "table") and decoded or {}
      end

      local count = badges["zoom.us"]
      local has_badge = count ~= nil

      zoom:set({
        drawing = true,
        icon = {
          color = has_badge and colors.red or colors.grey,
        },
        label = {
          drawing = has_badge,
          string = has_badge and count or "",
        },
      })
      zoom_bracket:set({ drawing = true })
      zoom_padding:set({ drawing = true })
    end)
  end)
end

zoom:subscribe({ "badge_check", "front_app_switched", "space_windows_change", "system_woke", "forced" }, update_zoom)

local zoom_poller = sbar.add("item", {
  drawing = false,
  update_freq = 30,
})
zoom_poller:subscribe("routine", update_zoom)
