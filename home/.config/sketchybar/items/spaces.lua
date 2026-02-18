local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")
local badge_data = require("helpers.badge_data")
local json = require("helpers.json")

local spaces = {}
local space_badges = {}
local space_brackets = {}
local space_paddings = {}

sbar.add("event", "aerospace_workspace_change")
sbar.add("event", "badge_check")

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
    return
  end

  local args = {}
  for _, app in ipairs(app_list) do
    args[#args + 1] = shell_quote(app)
  end
  sbar.exec("$CONFIG_DIR/helpers/badges/bin/badges " .. table.concat(args, " "), function(result)
    local badged_counts
    if type(result) == "table" then
      badged_counts = result
    else
      local ok, decoded = pcall(json.decode, result)
      badged_counts = (ok and type(decoded) == "table") and decoded or {}
    end

    -- Quick diff: skip badge_data recomputation if badges unchanged
    local changed = false
    for k, v in pairs(badged_counts) do
      if badge_data.counts[k] ~= v then changed = true; break end
    end
    if not changed then
      for k in pairs(badge_data.counts) do
        if not badged_counts[k] then changed = true; break end
      end
    end

    if changed then
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
    end

    update_badge_icons(ws_apps)
    for j = 1, 5 do update_space_appearance(j) end
  end)
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

local update_pending = false
local recheck_needed = false
local last_window_update_time = 0
local function update_space_icons(env)
  if update_pending then
    recheck_needed = true
    return
  end
  update_pending = true
  sbar.exec("aerospace list-windows --all --format '%{workspace}|%{app-name}'", function(result)
    update_pending = false
    local focused_ws = tostring(focused_workspace)

    local ws_apps = parse_window_list(result)
    last_window_update_time = os.time()

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

    if recheck_needed then
      recheck_needed = false
      update_space_icons()
    end
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
  if last_ws_apps then
    check_badges(last_ws_apps)
  end
end)

-- Fallback poller for badge changes (primary detection is lsappinfo listener below)
local badge_poller = sbar.add("item", {
  drawing = false,
  update_freq = 60,
})

badge_poller:subscribe("routine", function()
  if os.time() - last_window_update_time < 10 and last_ws_apps then
    check_badges(last_ws_apps)
  else
    sbar.exec("aerospace list-windows --all --format '%{workspace}|%{app-name}'", function(result)
      last_window_update_time = os.time()
      check_badges(parse_window_list(result))
    end)
  end
end)

-- Event-driven badge detection: listen for StatusLabel (dock badge) changes
-- Kill any stale listener from a previous config reload before starting a new one
sbar.exec(
  "pkill -f 'lsappinfo listen' 2>/dev/null; "
  .. "lsappinfo listen +appInfoKeyChanged +appInfoKeyAdded +appInfoKeyRemoved forever"
  .. " | grep --line-buffered StatusLabel"
  .. " | while read -r _; do /opt/homebrew/bin/sketchybar --trigger badge_check; done"
)

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
