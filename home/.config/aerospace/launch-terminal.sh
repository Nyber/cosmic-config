#!/bin/bash
# Always open a new Ghostty window on the current workspace
if pgrep -x ghostty > /dev/null; then
    osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "New Window" of menu "File" of menu bar 1'
else
    open -a Ghostty
fi
