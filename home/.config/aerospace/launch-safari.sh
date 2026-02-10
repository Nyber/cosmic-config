#!/bin/bash
# Always open a new Safari window on the current workspace
if pgrep -x Safari > /dev/null; then
    window_count=$(osascript -e 'tell application "System Events" to return count of windows of process "Safari"' 2>/dev/null)
    if [ "${window_count:-0}" -gt 0 ]; then
        osascript -e 'tell application "Safari" to make new document'
    else
        open -a Safari
    fi
else
    open -a Safari
fi
