#!/bin/bash
# Always open a new Ghostty window on the current workspace
if pgrep -x ghostty > /dev/null; then
    window_count=$(osascript -e 'tell application "System Events" to return count of windows of process "Ghostty"' 2>/dev/null)
    if [ "${window_count:-0}" -gt 0 ]; then
        osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "New Window" of menu "File" of menu bar 1'
    else
        open -a Ghostty
    fi
else
    open -a Ghostty
fi
