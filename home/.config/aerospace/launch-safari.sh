#!/bin/bash
# Always open a new Safari window on the current workspace
if pgrep -x Safari > /dev/null; then
    osascript -e 'tell application "Safari" to make new document'
else
    open -a Safari
fi
