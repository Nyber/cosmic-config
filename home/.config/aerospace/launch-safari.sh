#!/bin/bash
# Always open a new Safari window on the current workspace
if pgrep -x Safari > /dev/null; then
    osascript -e 'tell application "Safari" to make new document'
fi
osascript -e 'tell application "Safari" to activate'
