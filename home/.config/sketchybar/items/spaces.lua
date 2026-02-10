local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}
local space_brackets = {}
local space_paddings = {}

sbar.add("event", "aerospace_workspace_change")

for i = 1, 5, 1 do
  local space = sbar.add("item", "space." .. i, {
    icon = {
      font = { family = settings.font.numbers },
      string = i,
      padding_left = 15,
      padding_right = 8,
      color = colors.white,
      highlight_color = colors.red,
    },
    label = {
      padding_right = 20,
      color = colors.blue,
      highlight_color = colors.white,
      font = "sketchybar-app-font:Regular:16.0",
      y_offset = -1,
    },
    padding_right = 1,
    padding_left = 1,
    background = {
      color = colors.bg1,
      border_width = 1,
      height = 26,
      border_color = colors.bg2,
    },
  })

  spaces[i] = space

  local space_bracket = sbar.add("bracket", { space.name }, {
    background = {
      color = colors.transparent,
      border_color = colors.bg2,
      height = 28,
      border_width = 2
    }
  })
  space_brackets[i] = space_bracket

  local space_padding = sbar.add("item", "space.padding." .. i, {
    script = "",
    width = settings.group_paddings,
  })
  space_paddings[i] = space_padding

  space:subscribe("aerospace_workspace_change", function(env)
    local focused = env.FOCUSED_WORKSPACE == tostring(i)
    space:set({
      icon = { highlight = focused },
      label = { highlight = focused },
      background = { border_color = focused and colors.black or colors.bg2 }
    })
    space_bracket:set({
      background = { border_color = focused and colors.grey or colors.bg2 }
    })
  end)

  space:subscribe("mouse.clicked", function(env)
    sbar.exec("aerospace workspace " .. i)
  end)
end

-- Observer to update app icons in each workspace
local space_window_observer = sbar.add("item", {
  drawing = false,
  updates = true,
})

local function update_space_icons()
  sbar.exec("aerospace list-workspaces --focused", function(focused_ws)
    focused_ws = focused_ws:gsub("%s+", "")
    for i = 1, 5, 1 do
      sbar.exec(
        "aerospace list-windows --workspace " .. i .. " --format '%{app-name}'",
        function(result)
          local icon_line = ""
          local has_app = false
          local seen = {}
          for app in result:gmatch("[^\r\n]+") do
            if not seen[app] then
              seen[app] = true
              has_app = true
              local lookup = app_icons[app]
              local icon = ((lookup == nil) and app_icons["Default"] or lookup)
              icon_line = icon_line .. icon
            end
          end

          local is_focused = focused_ws == tostring(i)
          local visible = has_app or is_focused

          sbar.animate("tanh", 10, function()
            spaces[i]:set({
              drawing = visible,
              label = has_app and icon_line or "",
            })
          end)
          space_brackets[i]:set({ drawing = visible })
          space_paddings[i]:set({ drawing = visible })
        end
      )
    end
  end)
end

space_window_observer:subscribe("aerospace_workspace_change", update_space_icons)
space_window_observer:subscribe("front_app_switched", update_space_icons)
space_window_observer:subscribe("space_windows_change", update_space_icons)

-- Trigger initial workspace highlight
sbar.exec("aerospace list-workspaces --focused", function(focused)
  focused = focused:gsub("%s+", "")
  sbar.trigger("aerospace_workspace_change",
    { FOCUSED_WORKSPACE = focused })
end)

-- Spaces/menus toggle indicator
local spaces_indicator = sbar.add("item", {
  padding_left = -3,
  padding_right = 0,
  icon = {
    padding_left = 8,
    padding_right = 9,
    color = colors.grey,
    string = icons.switch.on,
  },
  label = {
    width = 0,
    padding_left = 0,
    padding_right = 8,
    string = "Spaces",
    color = colors.bg1,
  },
  background = {
    color = colors.with_alpha(colors.grey, 0.0),
    border_color = colors.with_alpha(colors.bg1, 0.0),
  }
})

spaces_indicator:subscribe("swap_menus_and_spaces", function(env)
  local currently_on = spaces_indicator:query().icon.value == icons.switch.on
  spaces_indicator:set({
    icon = currently_on and icons.switch.off or icons.switch.on
  })
end)

spaces_indicator:subscribe("mouse.entered", function(env)
  sbar.animate("tanh", 30, function()
    spaces_indicator:set({
      background = {
        color = { alpha = 1.0 },
        border_color = { alpha = 1.0 },
      },
      icon = { color = colors.bg1 },
      label = { width = "dynamic" }
    })
  end)
end)

spaces_indicator:subscribe("mouse.exited", function(env)
  sbar.animate("tanh", 30, function()
    spaces_indicator:set({
      background = {
        color = { alpha = 0.0 },
        border_color = { alpha = 0.0 },
      },
      icon = { color = colors.grey },
      label = { width = 0, }
    })
  end)
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
  sbar.trigger("swap_menus_and_spaces")
end)
