local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")
local json = require("helpers.json")

-- Approximate pixel width per character at size 13 monospace
local CHAR_WIDTH = 8.0
local ICON_PAD = 42   -- app icon width + padding
local SIDE_PAD = 20   -- popup side padding

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
  update_freq = 5,
  popup = { align = "center" },
})

local notif_script = "/usr/bin/python3 /Users/"
    .. os.getenv("USER")
    .. "/.config/sketchybar/helpers/notification_reader.py"
local notif_cache = "/Users/"
    .. os.getenv("USER")
    .. "/.config/sketchybar/helpers/.notif_cache.json"

local wal_path = "/Users/" .. os.getenv("USER")
    .. "/Library/Group Containers/group.com.apple.usernoted/db2/db-wal"
local last_wal_size = -1

-- Track created popup items for cleanup
local popup_items = {}

-- Read cache file and return all notifications
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

-- Update bell icon/count based on notification count
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

-- Build popup items from badged notifications
local function build_popup_items(badged_notifs)
  -- Remove previously created popup items
  for _, name in ipairs(popup_items) do
    pcall(sbar.remove, name)
  end
  popup_items = {}

  if #badged_notifs == 0 then return end

  -- Compute auto-sized width
  local max_len = 0
  for _, notif in ipairs(badged_notifs) do
    local title_len = #(notif.title or "")
    local body_len = #(notif.body or "")
    if title_len > max_len then max_len = title_len end
    if body_len > max_len then max_len = body_len end
  end
  local popup_width = math.floor(max_len * CHAR_WIDTH + ICON_PAD + SIDE_PAD)
  if popup_width < 300 then popup_width = 300 end
  if popup_width > 800 then popup_width = 800 end

  for i, notif in ipairs(badged_notifs) do
    local lookup = app_icons[notif.app]
    local icon = ((lookup == nil) and app_icons["Default"] or lookup)
    local title = notif.title or ""
    local body = notif.body or ""
    local rec_id = notif.id

    -- Dismiss handler for this notification
    local function on_dismiss()
      sbar.exec(notif_script .. " dismiss " .. rec_id, function()
        -- Re-read cache after dismiss and refresh immediately
        local remaining = read_notifs()
        update_bell(#remaining)
        build_popup_items(remaining)
        if #remaining > 0 then
          bell:set({ popup = { drawing = true } })
        end
        -- Update WAL size to prevent redundant rebuild on next routine tick
        local wf = io.open(wal_path, "rb")
        if wf then
          last_wal_size = wf:seek("end")
          wf:close()
        end
      end)
    end

    -- App icon + sender name + dismiss hint
    local header_name = "widgets.notifications.app." .. i .. ".h"
    local header = sbar.add("item", header_name, {
      position = "popup." .. bell.name,
      width = popup_width,
      icon = {
        string = icon,
        font = "sketchybar-app-font:Regular:16.0",
        color = colors.blue,
        width = 28,
        align = "center",
      },
      label = {
        string = title .. "  ✕",
        color = colors.white,
        font = {
          family = settings.font.text,
          style = settings.font.style_map["Bold"],
          size = 13.0,
        },
      },
    })
    popup_items[#popup_items + 1] = header_name

    if rec_id then
      header:subscribe("mouse.clicked", on_dismiss)
    end

    -- Message body
    if body ~= "" then
      local body_name = "widgets.notifications.app." .. i .. ".b"
      local body_item = sbar.add("item", body_name, {
        position = "popup." .. bell.name,
        width = popup_width,
        icon = { drawing = false },
        label = {
          string = body,
          color = colors.white,
          padding_left = 38,
          font = {
            family = settings.font.text,
            style = settings.font.style_map["Regular"],
            size = 13.0,
          },
        },
      })
      popup_items[#popup_items + 1] = body_name

      if rec_id then
        body_item:subscribe("mouse.clicked", on_dismiss)
      end
    end
  end

  -- "Clear All" button
  local clear_name = "widgets.notifications.app.clear"
  local clear_btn = sbar.add("item", clear_name, {
    position = "popup." .. bell.name,
    width = popup_width,
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
  popup_items[#popup_items + 1] = clear_name

  clear_btn:subscribe("mouse.clicked", function()
    sbar.exec(notif_script .. " dismiss all", function()
      bell:set({ popup = { drawing = false } })
      local remaining = read_notifs()
      update_bell(#remaining)
      build_popup_items(remaining)
      -- Update WAL size to prevent redundant rebuild on next routine tick
      local wf = io.open(wal_path, "rb")
      if wf then
        last_wal_size = wf:seek("end")
        wf:close()
      end
    end)
  end)
end

-- Full refresh: run reader script, update cache, rebuild popup
local function rebuild_popup()
  sbar.exec(notif_script, function()
    local notifs = read_notifs()
    update_bell(#notifs)
    build_popup_items(notifs)
  end)
end

bell:subscribe("routine", function()
  local f = io.open(wal_path, "rb")
  if not f then return end
  local size = f:seek("end")
  f:close()
  if size ~= last_wal_size then
    last_wal_size = size
    rebuild_popup()
  end
end)

bell:subscribe("badge_update", function()
  rebuild_popup()
end)

bell:subscribe("mouse.clicked", function()
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

-- Initial refresh on startup
rebuild_popup()
