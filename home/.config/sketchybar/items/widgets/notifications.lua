local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")
local json = require("helpers.json")

local CHAR_WIDTH = 8.0
local ICON_PAD = 42
local SIDE_PAD = 20
local MAX_VISIBLE = 5

sbar.add("event", "wal_changed")

local bell = sbar.add("item", "widgets.notifications", {
  position = "right",
  icon = {
    string = icons.bell.off,
    color = colors.grey,
    font = {
      style = settings.font.style_map["Regular"],
      size = 16.0,
    },
  },
  label = {
    string = "",
    font = { family = settings.font.numbers, size = 12.0 },
    color = colors.red,
    padding_left = 0,
  },
  drawing = false,
  updates = true,
  popup = { align = "center" },
})

local helpers_dir = "/Users/" .. os.getenv("USER") .. "/.config/sketchybar/helpers"
local notif_script = "/usr/bin/python3 " .. helpers_dir .. "/notification_reader.py"
local notif_cache = helpers_dir .. "/.notif_cache.json"

-- State
local current_page = 0
local cached_notifs = {}
local cached_popup_width = 300

-- Pre-create all popup slots (never removed, just shown/hidden)
local slots = {}
for i = 1, MAX_VISIBLE do
  local h = sbar.add("item", "widgets.notifications.slot." .. i .. ".h", {
    position = "popup." .. bell.name,
    drawing = false,
    icon = {
      font = "sketchybar-app-font:Regular:16.0",
      color = colors.blue,
      width = 28,
      align = "center",
    },
    label = {
      color = colors.white,
      font = {
        family = settings.font.text,
        style = settings.font.style_map["Bold"],
        size = 13.0,
      },
    },
  })
  local b = sbar.add("item", "widgets.notifications.slot." .. i .. ".b", {
    position = "popup." .. bell.name,
    drawing = false,
    icon = { drawing = false },
    label = {
      color = colors.white,
      padding_left = 38,
      font = {
        family = settings.font.text,
        style = settings.font.style_map["Regular"],
        size = 13.0,
      },
    },
  })
  slots[i] = { header = h, body = b }
end

local nav_item = sbar.add("item", "widgets.notifications.nav", {
  position = "popup." .. bell.name,
  drawing = false,
  icon = { drawing = false },
  label = {
    color = colors.white,
    align = "center",
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = 13.0,
    },
  },
  background = {
    color = colors.bg2,
    corner_radius = 5,
    height = 24,
  },
})

local clear_item = sbar.add("item", "widgets.notifications.clear", {
  position = "popup." .. bell.name,
  drawing = false,
  icon = { drawing = false },
  label = {
    string = "Clear All",
    color = colors.red,
    align = "center",
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = 13.0,
    },
  },
  background = {
    color = colors.bg2,
    corner_radius = 5,
    height = 24,
  },
})

local function read_notifs()
  local f = io.open(notif_cache, "r")
  if not f then return {} end
  local result = f:read("*a")
  f:close()
  if not result or result == "" then return {} end
  local ok, notifications = pcall(json.decode, result)
  if not ok or type(notifications) ~= "table" then return {} end
  return notifications
end

local function update_bell(count)
  if count > 0 then
    bell:set({
      drawing = true,
      icon = { string = icons.bell.on, color = colors.red },
      label = { string = tostring(count) },
    })
  else
    bell:set({
      drawing = false,
      icon = { string = icons.bell.off, color = colors.grey },
      label = { string = "" },
      popup = { drawing = false },
    })
  end
end

-- Update popup slot content without removing/adding items
local function update_popup()
  local total = #cached_notifs
  if total == 0 then
    for i = 1, MAX_VISIBLE do
      slots[i].header:set({ drawing = false })
      slots[i].body:set({ drawing = false })
    end
    nav_item:set({ drawing = false })
    clear_item:set({ drawing = false })
    return
  end

  local total_pages = math.ceil(total / MAX_VISIBLE)
  if current_page >= total_pages then current_page = total_pages - 1 end
  if current_page < 0 then current_page = 0 end

  local start_idx = current_page * MAX_VISIBLE + 1
  local end_idx = math.min(start_idx + MAX_VISIBLE - 1, total)

  local popup_width = cached_popup_width

  -- Fill visible slots
  for i = 1, MAX_VISIBLE do
    local idx = start_idx + i - 1
    if idx <= end_idx then
      local notif = cached_notifs[idx]
      local icon = app_icons[notif.app] or app_icons["Default"]
      local title = notif.title or ""
      local body = notif.body or ""

      slots[i].header:set({
        drawing = true,
        width = popup_width,
        icon = { string = icon },
        label = { string = title .. "  ✕" },
      })

      if body ~= "" then
        slots[i].body:set({
          drawing = true,
          width = popup_width,
          label = { string = body },
        })
      else
        slots[i].body:set({ drawing = false })
      end
    else
      slots[i].header:set({ drawing = false })
      slots[i].body:set({ drawing = false })
    end
  end

  -- Nav row
  if total_pages > 1 then
    local up_arrow = current_page > 0 and "▲" or "△"
    local down_arrow = current_page < total_pages - 1 and "▼" or "▽"
    nav_item:set({
      drawing = true,
      width = popup_width,
      label = { string = up_arrow .. "  " .. (current_page + 1) .. " / " .. total_pages .. "  " .. down_arrow },
    })
  else
    nav_item:set({ drawing = false })
  end

  clear_item:set({ drawing = true, width = popup_width })
end

-- Dismiss a notification by rec_id
local function dismiss_notif(rec_id)
  sbar.exec(notif_script .. " dismiss " .. rec_id, function()
    cached_notifs = read_notifs()
    update_bell(#cached_notifs)
    update_popup()
    if #cached_notifs > 0 then
      bell:set({ popup = { drawing = true } })
    end
  end)
end

-- Scroll handler
local function on_scroll(env)
  local delta = tonumber(env.INFO and env.INFO.delta or 0)
  if delta == 0 then return end
  local total_pages = math.ceil(#cached_notifs / MAX_VISIBLE)
  if delta > 0 and current_page > 0 then
    current_page = current_page - 1
    update_popup()
  elseif delta < 0 and current_page < total_pages - 1 then
    current_page = current_page + 1
    update_popup()
  end
end

-- Subscribe all slots to scroll and click
for i = 1, MAX_VISIBLE do
  slots[i].header:subscribe("mouse.scrolled", on_scroll)
  slots[i].body:subscribe("mouse.scrolled", on_scroll)
  -- Click on header/body dismisses (use closure to capture current index)
  local function make_click_handler(slot_idx)
    return function()
      local idx = current_page * MAX_VISIBLE + slot_idx
      if idx <= #cached_notifs then
        local rec_id = cached_notifs[idx].id
        if rec_id then dismiss_notif(rec_id) end
      end
    end
  end
  slots[i].header:subscribe("mouse.clicked", make_click_handler(i))
  slots[i].body:subscribe("mouse.clicked", make_click_handler(i))
end

-- Nav click: cycle to next page
nav_item:subscribe("mouse.clicked", function()
  local total_pages = math.ceil(#cached_notifs / MAX_VISIBLE)
  current_page = current_page + 1
  if current_page >= total_pages then current_page = 0 end
  update_popup()
end)
nav_item:subscribe("mouse.scrolled", on_scroll)

-- Clear All click
clear_item:subscribe("mouse.clicked", function()
  sbar.exec(notif_script .. " dismiss all", function()
    current_page = 0
    bell:set({ popup = { drawing = false } })
    cached_notifs = read_notifs()
    update_bell(#cached_notifs)
    update_popup()
  end)
end)
clear_item:subscribe("mouse.scrolled", on_scroll)

-- Refresh from cache
local function refresh_from_cache()
  cached_notifs = read_notifs()
  -- Recalculate popup width when notifications change
  local max_len = 0
  for _, notif in ipairs(cached_notifs) do
    local tl = #(notif.title or "")
    local bl = #(notif.body or "")
    if tl > max_len then max_len = tl end
    if bl > max_len then max_len = bl end
  end
  cached_popup_width = math.max(300, math.min(800,
    math.floor(max_len * CHAR_WIDTH + ICON_PAD + SIDE_PAD)))
  update_bell(#cached_notifs)
  update_popup()
end

bell:subscribe("wal_changed", function()
  refresh_from_cache()
end)

bell:subscribe("badge_update", function()
  sbar.exec(notif_script, function()
    refresh_from_cache()
  end)
end)

bell:subscribe("mouse.clicked", function()
  current_page = 0
  update_popup()
  bell:set({ popup = { drawing = "toggle" } })
end)

bell:subscribe("mouse.exited.global", function()
  bell:set({ popup = { drawing = false } })
end)

sbar.add("bracket", "widgets.notifications.bracket", { bell.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.notifications.padding", {
  position = "right",
  width = settings.group_paddings,
})

-- Watcher is managed by launchd (com.user.notif-watcher), not SketchyBar.
-- On forced/system_woke, just refresh the cache as a fallback sync.
bell:subscribe({"forced", "system_woke"}, function()
  sbar.exec(notif_script, function()
    refresh_from_cache()
  end)
end)
