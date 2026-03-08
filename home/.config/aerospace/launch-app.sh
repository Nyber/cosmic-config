#!/bin/sh
# Generic launcher: open a new window if the app is running, otherwise launch it.
# Usage: launch-app.sh <AppName>  (e.g., Safari, Obsidian, Ghostty)
app="$1"
[ -z "$app" ] && exit 1
current_ws=$(/opt/homebrew/bin/aerospace list-workspaces --focused)

if pgrep -xi "$app" > /dev/null; then
    window_count=$(osascript -e "tell application \"System Events\" to return count of windows of process \"$app\"" 2>/dev/null)
    if [ "${window_count:-0}" -gt 0 ]; then
        osascript -e "
            tell application \"$app\" to activate
            delay 0.3
            tell application \"System Events\"
                keystroke \"n\" using command down
            end tell
        "
        sleep 0.5
        /opt/homebrew/bin/aerospace move-node-to-workspace "$current_ws"
        /opt/homebrew/bin/aerospace workspace "$current_ws"
    else
        open -a "$app"
    fi
else
    open -a "$app"
fi
