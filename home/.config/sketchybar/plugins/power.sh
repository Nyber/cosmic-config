#!/bin/bash

HIGHLIGHT=0xff7aa2f7
ICON_COLOR=0xffc0caf5

# Highlight the power icon while the menu is open
sketchybar --set power icon.color=$ICON_COLOR \
                       background.drawing=on \
                       background.color=$HIGHLIGHT \
                       background.corner_radius=5 \
                       background.height=22

# Launch native power menu window
rm -f /tmp/.sketchybar_power_choice
"$CONFIG_DIR/plugins/power-menu"
choice=$(cat /tmp/.sketchybar_power_choice 2>/dev/null)
rm -f /tmp/.sketchybar_power_choice

# Revert highlight
sketchybar --set power icon.color=$HIGHLIGHT \
                       background.drawing=off

case "$choice" in
  "Shut Down")   osascript -e 'tell application "System Events" to shut down' ;;
  "Restart")     osascript -e 'tell application "System Events" to restart' ;;
  "Sleep")       pmset sleepnow ;;
  "Lock Screen") osascript -e 'tell application "System Events" to key code 12 using {control down, command down}' ;;
  "Log Out")     osascript -e 'tell application "System Events" to log out' ;;
esac
