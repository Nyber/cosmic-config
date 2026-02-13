local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")
local badge_data = require("helpers.badge_data")
local json = require("helpers.json")

local notif_cache = "/Users/" .. os.getenv("USER") .. "/.config/sketchybar/helpers/.notif_cache.json"

local cached_notified_apps = {}

local function reload_notified_apps()
  local f = io.open(notif_cache, "r")
  if not f then cached_notified_apps = {}; return end
  local result = f:read("*a")
  f:close()
  if not result or result == "" then cached_notified_apps = {}; return end
  local ok, notifications = pcall(json.decode, result)
  if not ok or type(notifications) ~= "table" then cached_notified_apps = {}; return end
  local apps = {}
  for _, n in ipairs(notifications) do
    if n.app then apps[n.app] = true end
  end
  cached_notified_apps = apps
end

local spaces = {}
local space_badges = {}
local space_brackets = {}
local space_paddings = {}

sbar.add("event", "aerospace_workspace_change")
sbar.add("event", "badge_check")
sbar.add("event", "badge_update")

reload_notified_apps()

local focused_workspace = 0

local function update_space_appearance(i)
  local is_focused = (focused_workspace == i)

  spaces[i]:set({
    icon = { highlight = is_focused },
    label = { highlight = is_focused },
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

-- Cache for last known ws_apps so badge poll can split icons
local last_ws_apps = nil

local function update_badge_icons(ws_apps)
  for i = 1, 5 do
    local normal_icons = ""
    local badge_icons = ""
    local has_app = false
    local has_badge = false

    for app, _ in pairs(ws_apps[i]) do
      has_app = true
      local icon = app_icons[app] or app_icons["Default"]
      if badge_data.counts[app] then
        badge_icons = badge_icons .. icon
        has_badge = true
      else
        normal_icons = normal_icons .. icon
      end
    end

    spaces[i]:set({
      label = {
        string = has_app and normal_icons or "",
        padding_right = has_badge and 0 or 20,
      },
    })
    space_badges[i]:set({
      label = { string = badge_icons },
      drawing = has_badge,
    })
  end
end

local function check_badges(ws_apps)
  last_ws_apps = ws_apps

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
    badge_data.counts = {}
    badge_data.by_workspace = {}
    badge_data.total = 0
    update_badge_icons(ws_apps)
    for j = 1, 5 do update_space_appearance(j) end
    sbar.trigger("badge_update")
    return
  end

  local badged_counts = {}
  local remaining = #app_list
  for _, app in ipairs(app_list) do
    sbar.exec("lsappinfo info -only StatusLabel " .. shell_quote(app), function(sl)
      local label = sl:match('"label"="([^"]*)"')
      if label and label ~= "" then
        badged_counts[app] = label
      end
      remaining = remaining - 1
      if remaining == 0 then
        -- Only badge apps that also have a notification in the bell
        for a in pairs(badged_counts) do
          if not cached_notified_apps[a] then badged_counts[a] = nil end
        end
        -- Update shared badge_data
        badge_data.counts = badged_counts
        badge_data.by_workspace = {}
        badge_data.total = 0
        for j = 1, 5 do
          badge_data.by_workspace[j] = {}
          for a in pairs(ws_apps[j]) do
            if badged_counts[a] then
              badge_data.by_workspace[j][#badge_data.by_workspace[j] + 1] = a
              local n = tonumber(badged_counts[a])
              if n then
                badge_data.total = badge_data.total + n
              else
                badge_data.total = badge_data.total + 1
              end
            end
          end
        end

        update_badge_icons(ws_apps)
        for j = 1, 5 do update_space_appearance(j) end
        sbar.trigger("badge_update")
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

  local space_badge = sbar.add("item", "space." .. i .. ".badge", {
    label = {
      font = "sketchybar-app-font:Regular:16.0",
      color = colors.red,
      padding_left = 0,
      padding_right = 20,
      y_offset = -1,
    },
    padding_left = 0,
    padding_right = 0,
    background = {
      color = colors.bg1,
      border_width = 0,
      height = 26,
    },
    drawing = false,
  })
  space_badges[i] = space_badge

  local space_bracket = sbar.add("bracket", { space.name, space_badge.name }, {
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
    -- Use env, or fall back to cached focused_workspace (avoids extra subprocess)
    local focused_ws
    if env and env.FOCUSED_WORKSPACE and env.FOCUSED_WORKSPACE ~= "" then
      focused_ws = env.FOCUSED_WORKSPACE:gsub("%s+", "")
    else
      focused_ws = tostring(focused_workspace)
    end

    local ws_apps = parse_window_list(result)

    for i = 1, 5 do
      local has_app = false
      for _, _ in pairs(ws_apps[i]) do
        has_app = true
        break
      end

      local is_focused = focused_ws == tostring(i)
      local visible = has_app or is_focused

      sbar.animate("tanh", 10, function()
        spaces[i]:set({ drawing = visible })
      end)
      space_brackets[i]:set({ drawing = visible })
      space_paddings[i]:set({ drawing = visible })
    end

    check_badges(ws_apps)
  end)
end

space_window_observer:subscribe("aerospace_workspace_change", update_space_icons)
space_window_observer:subscribe("front_app_switched", update_space_icons)
space_window_observer:subscribe("space_windows_change", update_space_icons)

local last_badge_check_time = 0
space_window_observer:subscribe("badge_check", function()
  local now = os.time()
  if now - last_badge_check_time < 2 then return end
  last_badge_check_time = now
  reload_notified_apps()
  if last_ws_apps then
    check_badges(last_ws_apps)
  end
end)

space_window_observer:subscribe("wal_changed", reload_notified_apps)

-- Poll for badge changes every 30 seconds (workspace/app-switch events also trigger checks)
local badge_poller = sbar.add("item", {
  drawing = false,
  update_freq = 30,
})

badge_poller:subscribe("routine", function()
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
