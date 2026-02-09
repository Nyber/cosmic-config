#!/bin/bash
# Always open a new Obsidian window on the current workspace
if pgrep -x Obsidian > /dev/null; then
    osascript -e 'tell application "System Events" to tell process "Obsidian" to click menu item "New window" of menu "File" of menu bar 1'
else
    open -a Obsidian
fi
