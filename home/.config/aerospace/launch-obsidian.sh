#!/bin/bash
# Always open a new Obsidian window on the current workspace
if pgrep -x Obsidian > /dev/null; then
    window_count=$(osascript -e 'tell application "System Events" to return count of windows of process "Obsidian"' 2>/dev/null)
    if [ "${window_count:-0}" -gt 0 ]; then
        osascript -e 'tell application "System Events" to tell process "Obsidian" to click menu item "New window" of menu "File" of menu bar 1'
    else
        open -a Obsidian
    fi
else
    open -a Obsidian
fi
