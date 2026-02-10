#!/bin/sh
# Called by AeroSpace on workspace change.
# 1. Updates SketchyBar
# 2. Hides Zoom when leaving its workspace, unhides when arriving

sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$AEROSPACE_FOCUSED_WORKSPACE"

# Hide/unhide Zoom based on whether it's on the focused workspace
if pgrep -xq "zoom.us"; then
    case "$(aerospace list-windows --workspace focused --format '%{app-name}' 2>/dev/null)" in
        *zoom.us*) vis=true ;; *) vis=false ;;
    esac
    osascript -e "tell application \"System Events\" to set visible of process \"zoom.us\" to $vis" 2>/dev/null
fi
