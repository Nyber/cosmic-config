local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}
local space_brackets = {}
local space_paddings = {}

sbar.add("event", "aerospace_workspace_change")
sbar.add("event", "badge_check")

local focused_workspace = 0
local attention = {}

local function update_space_appearance(i)
  local is_focused = (focused_workspace == i)
  local has_attention = attention[i] or false

  spaces[i]:set({
    icon = { highlight = is_focused },
    label = {
      highlight = is_focused,
      color = (not is_focused and has_attention) and colors.red or colors.blue,
    },
    background = { border_color = is_focused and colors.black or colors.bg2 }
  })
  space_brackets[i]:set({
    background = { border_color = is_focused and colors.grey or colors.bg2 }
  })
end

local function shell_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function parse_window_list(result)
  local ws_apps = {}
  for i = 1, 5 do ws_apps[i] = {} end
  for line in result:gmatch("[^\r\n]+") do
    local ws, app = line:match("^(%d+)|(.+)$")
    if ws and app then
      local n = tonumber(ws)
      if n and n >= 1 and n <= 5 then
        ws_apps[n][app] = true
      end
    end
  end
  return ws_apps
end

local function check_badges(ws_apps)
  local unique_apps = {}
  for i = 1, 5 do
    for app in pairs(ws_apps[i]) do
      unique_apps[app] = true
    end
  end

  local app_list = {}
  for app in pairs(unique_apps) do
    app_list[#app_list + 1] = app
  end

  if #app_list == 0 then
    for j = 1, 5 do attention[j] = false end
    for j = 1, 5 do update_space_appearance(j) end
    return
  end

  local badged = {}
  local remaining = #app_list
  for _, app in ipairs(app_list) do
    sbar.exec("lsappinfo info -only StatusLabel " .. shell_quote(app), function(sl)
      local label = sl:match('"label"="([^"]*)"')
      if label and label ~= "" then badged[app] = true end
      remaining = remaining - 1
      if remaining == 0 then
        for j = 1, 5 do attention[j] = false end
        for j = 1, 5 do
          for a in pairs(ws_apps[j]) do
            if badged[a] then attention[j] = true; break end
          end
        end
        for j = 1, 5 do update_space_appearance(j) end
      end
    end)
  end
end

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
    focused_workspace = tonumber(env.FOCUSED_WORKSPACE) or 0
    update_space_appearance(i)
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

local function update_space_icons(env)
  sbar.exec("aerospace list-windows --all --format '%{workspace}|%{app-name}'", function(result)
    local apply = function(focused_ws)
      focused_ws = focused_ws:gsub("%s+", "")
      local ws_apps = parse_window_list(result)

      for i = 1, 5 do
        local icon_line = ""
        local has_app = false
        for app, _ in pairs(ws_apps[i]) do
          has_app = true
          local lookup = app_icons[app]
          local icon = ((lookup == nil) and app_icons["Default"] or lookup)
          icon_line = icon_line .. icon
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

      check_badges(ws_apps)
    end

    if env and env.FOCUSED_WORKSPACE and env.FOCUSED_WORKSPACE ~= "" then
      apply(env.FOCUSED_WORKSPACE)
    else
      sbar.exec("aerospace list-workspaces --focused", apply)
    end
  end)
end

space_window_observer:subscribe("aerospace_workspace_change", update_space_icons)
space_window_observer:subscribe("front_app_switched", update_space_icons)
space_window_observer:subscribe("space_windows_change", update_space_icons)

space_window_observer:subscribe("badge_check", function()
  sbar.exec("aerospace list-windows --all --format '%{workspace}|%{app-name}'", function(result)
    check_badges(parse_window_list(result))
  end)
end)

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
})

spaces_indicator:subscribe("swap_menus_and_spaces", function(env)
  local currently_on = spaces_indicator:query().icon.value == icons.switch.on
  spaces_indicator:set({
    icon = currently_on and icons.switch.off or icons.switch.on
  })
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
  sbar.trigger("swap_menus_and_spaces")
end)
