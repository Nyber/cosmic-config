local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local json = require("helpers.json")
local app_icons = require("helpers.app_icons")

local CACHE_DIR = os.getenv("HOME") .. "/.cache/sketchybar"
local LAST_SEEN_FILE = CACHE_DIR .. "/notifications_last_seen"
local DISMISSED_FILE = CACHE_DIR .. "/notifications_dismissed"
local MAX_POPUP_ITEMS = 4
local MAX_BODY_LINES = 2
local CHARS_PER_LINE = 42
local POPUP_WIDTH = 350
local SKETCHYBAR = "/opt/homebrew/bin/sketchybar"

-- State
local popup_open = false
local custom_notifications = {}
local all_notifications = {}
local last_seen_timestamp = 0
local dismissed = {} -- set of dismissed timestamp strings

-- Read last-seen timestamp
os.execute("mkdir -p " .. CACHE_DIR)
local f = io.open(LAST_SEEN_FILE, "r")
if f then
  last_seen_timestamp = tonumber(f:read("*a")) or 0
  f:close()
end

-- Read dismissed notifications
local function load_dismissed()
  dismissed = {}
  local fh = io.open(DISMISSED_FILE, "r")
  if fh then
    for line in fh:lines() do
      if line ~= "" then dismissed[line] = true end
    end
    fh:close()
  end
end

local function save_dismissed()
  local fh = io.open(DISMISSED_FILE, "w")
  if fh then
    for ts, _ in pairs(dismissed) do
      fh:write(ts .. "\n")
    end
    fh:close()
  end
end

load_dismissed()

local function write_last_seen(ts)
  local fh = io.open(LAST_SEEN_FILE, "w")
  if fh then
    fh:write(tostring(ts))
    fh:close()
  end
end

local function format_age(unix_ts)
  local diff = os.time() - unix_ts
  if diff < 60 then return "now"
  elseif diff < 3600 then return math.floor(diff / 60) .. "m"
  elseif diff < 86400 then return math.floor(diff / 3600) .. "h"
  else return math.floor(diff / 86400) .. "d" end
end

-- Register custom events
sbar.add("event", "notification_push")
sbar.add("event", "notification_clear")
sbar.add("event", "notification_dismiss")

-- Bell icon
local notif_icon = sbar.add("item", "widgets.notifications.icon", {
  position = "right",
  icon = {
    string = icons.notification.bell,
    font = {
      style = settings.font.style_map["Regular"],
      size = 17.0,
    },
    color = colors.grey,
  },
  label = { drawing = false },
  update_freq = 30,
})

local notif_bracket = sbar.add("bracket", "widgets.notifications.bracket", {
  notif_icon.name,
}, {
  background = { color = colors.bg1 },
  popup = { align = "center", height = 26 },
})

sbar.add("item", "widgets.notifications.padding", {
  position = "right",
  width = settings.group_paddings,
})

-- Word-wrap text into lines of max_chars, breaking at word boundaries
local function word_wrap(text, max_chars)
  local lines = {}
  local remaining = text
  while #remaining > max_chars do
    -- Find last space within limit
    local break_at = max_chars
    local space = remaining:sub(1, max_chars):match(".*()%s")
    if space and space > 1 then
      break_at = space
    end
    table.insert(lines, remaining:sub(1, break_at):match("^(.-)%s*$"))
    remaining = remaining:sub(break_at + 1):match("^%s*(.*)$") or ""
  end
  if #remaining > 0 then
    table.insert(lines, remaining)
  end
  return lines
end

-- Pre-create popup items: each notification = header + up to MAX_BODY_LINES body rows
local popup_headers = {}
local popup_bodies = {} -- popup_bodies[i] = { line1, line2, line3 }
for i = 1, MAX_POPUP_ITEMS do
  local header = sbar.add("item", "notification.hdr." .. i, {
    position = "popup." .. notif_bracket.name,
    drawing = false,
    width = POPUP_WIDTH,
    icon = {
      font = "sketchybar-app-font:Regular:14.0",
      color = colors.white,
      padding_left = 10,
      padding_right = 6,
    },
    label = {
      font = {
        family = settings.font.text,
        style = settings.font.style_map["Bold"],
        size = 12.0,
      },
      color = colors.blue,
      padding_right = 10,
    },
  })
  popup_headers[i] = header

  popup_bodies[i] = {}
  for j = 1, MAX_BODY_LINES do
    local body_line = sbar.add("item", "notification.body." .. i .. "." .. j, {
      position = "popup." .. notif_bracket.name,
      drawing = false,
      width = POPUP_WIDTH,
      icon = { drawing = false },
      label = {
        font = {
          family = settings.font.text,
          style = settings.font.style_map["Regular"],
          size = 12.0,
        },
        color = colors.white,
        padding_left = 34,
        padding_right = 10,
      },
    })
    popup_bodies[i][j] = body_line
  end
end

-- Empty state item
local empty_item = sbar.add("item", "notification.item.empty", {
  position = "popup." .. notif_bracket.name,
  drawing = false,
  width = POPUP_WIDTH,
  icon = {
    string = icons.notification.bell,
    font = { family = settings.font.text, size = 14.0 },
    padding_left = 10,
    padding_right = 6,
    color = colors.grey,
  },
  label = {
    string = "No notifications",
    padding_right = 10,
  },
})

-- Clear All button
local clear_item = sbar.add("item", "notification.item.clearall", {
  position = "popup." .. notif_bracket.name,
  drawing = false,
  width = POPUP_WIDTH,
  icon = { drawing = false },
  label = {
    string = "Clear All",
    align = "center",
    padding_left = 10,
    padding_right = 10,
    color = colors.grey,
  },
  click_script = SKETCHYBAR .. " --trigger notification_clear",
})

-- Merge, filter dismissed, sort
local function merged_sorted()
  local merged = {}
  for _, n in ipairs(all_notifications) do
    local key = tostring(n.unix_timestamp)
    if not dismissed[key] then
      table.insert(merged, n)
    end
  end
  for _, n in ipairs(custom_notifications) do
    table.insert(merged, n)
  end
  table.sort(merged, function(a, b) return a.unix_timestamp > b.unix_timestamp end)
  local result = {}
  for i = 1, math.min(#merged, MAX_POPUP_ITEMS) do
    result[i] = merged[i]
  end
  return result
end

local function count_unread()
  local count = 0
  for _, n in ipairs(all_notifications) do
    local key = tostring(n.unix_timestamp)
    if not dismissed[key] and n.unix_timestamp > last_seen_timestamp then
      count = count + 1
    end
  end
  for _, n in ipairs(custom_notifications) do
    if n.unix_timestamp > last_seen_timestamp then
      count = count + 1
    end
  end
  return count
end

local function update_icon()
  local unread = count_unread()
  notif_icon:set({
    icon = {
      string = unread > 0 and icons.notification.bell_badge or icons.notification.bell,
      color = unread > 0 and colors.green or colors.grey,
    },
  })
end

local display_notifications = {}

local function update_popup()
  display_notifications = merged_sorted()

  if #display_notifications == 0 then
    for i = 1, MAX_POPUP_ITEMS do
      popup_headers[i]:set({ drawing = false })
      for j = 1, MAX_BODY_LINES do
        popup_bodies[i][j]:set({ drawing = false })
      end
    end
    empty_item:set({ drawing = false })
    clear_item:set({ drawing = false })
    close_popup()
    return
  end

  empty_item:set({ drawing = false })

  for i = 1, MAX_POPUP_ITEMS do
    local notif = display_notifications[i]
    if notif then
      local age = format_age(math.floor(notif.unix_timestamp))
      local title = notif.title or ""
      local app = notif.app or "Unknown"
      local ts_key = tostring(notif.unix_timestamp)

      local app_icon = app_icons[app] or app_icons["Default"]

      local click = SKETCHYBAR .. " --trigger notification_dismiss INFO='" .. ts_key .. "'"

      popup_headers[i]:set({
        drawing = true,
        icon = { string = app_icon },
        label = { string = app .. "  " .. age },
        click_script = click,
      })

      local lines = word_wrap(title, CHARS_PER_LINE)
      for j = 1, MAX_BODY_LINES do
        if lines[j] then
          local text = lines[j]
          -- Add ellipsis if there are more lines we can't show
          if j == MAX_BODY_LINES and lines[j + 1] then
            text = text .. "…"
          end
          popup_bodies[i][j]:set({
            drawing = true,
            label = { string = text },
            click_script = click,
          })
        else
          popup_bodies[i][j]:set({ drawing = false })
        end
      end
    else
      popup_headers[i]:set({ drawing = false })
      for j = 1, MAX_BODY_LINES do
        popup_bodies[i][j]:set({ drawing = false })
      end
    end
  end

  clear_item:set({ drawing = true })
end

local function close_popup()
  if popup_open then
    popup_open = false
    notif_bracket:set({ popup = { drawing = false } })
  end
end

-- Poll for notifications
local last_poll_time = 0
local function poll_notifications()
  local now = os.time()
  if now - last_poll_time < 3 then return end
  last_poll_time = now
  sbar.exec("$CONFIG_DIR/helpers/notifications/bin/notifications", function(result)
    if type(result) == "string" then
      result = json.decode(result)
    end
    if result and result.notifications then
      all_notifications = result.notifications
    else
      all_notifications = {}
    end
    -- Prune dismissed entries that are no longer in DB
    local valid = {}
    for _, n in ipairs(all_notifications) do
      valid[tostring(n.unix_timestamp)] = true
    end
    local pruned = false
    for ts, _ in pairs(dismissed) do
      if not valid[ts] then
        dismissed[ts] = nil
        pruned = true
      end
    end
    if pruned then save_dismissed() end

    update_icon()
    if popup_open then update_popup() end
  end)
end

notif_icon:subscribe({ "routine", "forced", "system_woke" }, poll_notifications)
notif_icon:subscribe("badge_check", poll_notifications)

-- Custom notification push
notif_icon:subscribe("notification_push", function(env)
  local info = env.INFO
  if type(info) == "string" then
    info = json.decode(info)
  end
  if info then
    table.insert(custom_notifications, {
      app = info.app or "Custom",
      title = info.title or "",
      body = info.body or "",
      subtitle = info.subtitle or "",
      unix_timestamp = os.time(),
    })
    while #custom_notifications > 20 do
      table.remove(custom_notifications, 1)
    end
    update_icon()
    if popup_open then update_popup() end
    -- Auto-dismiss after 5 minutes
    sbar.delay(300, function()
      if #custom_notifications > 0 then
        table.remove(custom_notifications, 1)
        update_icon()
        if popup_open then update_popup() end
      end
    end)
  end
end)

-- Dismiss single notification
notif_icon:subscribe("notification_dismiss", function(env)
  local ts_key = env.INFO
  if not ts_key then return end

  -- Check if it's a custom notification
  for idx, n in ipairs(custom_notifications) do
    if tostring(n.unix_timestamp) == ts_key then
      table.remove(custom_notifications, idx)
      update_icon()
      if popup_open then update_popup() end
      return
    end
  end

  -- Otherwise it's a DB notification — add to dismissed set
  dismissed[ts_key] = true
  save_dismissed()
  update_icon()
  if popup_open then update_popup() end
end)

-- Clear All handler
notif_icon:subscribe("notification_clear", function()
  -- Dismiss all current DB notifications
  for _, n in ipairs(all_notifications) do
    dismissed[tostring(n.unix_timestamp)] = true
  end
  save_dismissed()
  custom_notifications = {}
  last_seen_timestamp = os.time()
  write_last_seen(last_seen_timestamp)
  update_icon()
  close_popup()
end)

-- Toggle popup
notif_icon:subscribe("mouse.clicked", function()
  popup_open = not popup_open
  if popup_open then
    last_seen_timestamp = os.time()
    write_last_seen(last_seen_timestamp)
    update_icon()
    update_popup()
  end
  notif_bracket:set({ popup = { drawing = popup_open } })
end)

-- Close popup on global exit
notif_icon:subscribe("mouse.exited.global", close_popup)
