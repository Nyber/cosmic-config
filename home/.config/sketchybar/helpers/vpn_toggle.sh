#!/bin/sh

# Toggle F5 BIG-IP Edge Client VPN via its status bar menu

APP="BIG-IP Edge Client"

# Ensure the app is running
if ! pgrep -f "$APP" > /dev/null 2>&1; then
  open -a "$APP"
  sleep 2
fi

if pgrep -x svpn > /dev/null 2>&1; then
  action="Disconnect"
else
  action="Connect"
fi

osascript -e "
  tell application \"System Events\"
    tell process \"$APP\"
      click menu bar item 1 of menu bar 2
      delay 0.3
      click menu item \"$action\" of menu 1 of menu bar item 1 of menu bar 2
    end tell
  end tell"

# Delayed trigger lets BIG-IP finish connecting/disconnecting before we check
(sleep 3; sketchybar --trigger vpn_change) &
