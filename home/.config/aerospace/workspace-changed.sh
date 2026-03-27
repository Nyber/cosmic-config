#!/bin/sh
# Called by AeroSpace on workspace change.
# 1. Blocks unintentional workspace switches (e.g. macOS fullscreen stealing focus)
# 2. Updates SketchyBar
# 3. Hides Zoom when leaving its workspace, unhides when arriving

AEROSPACE=/opt/homebrew/bin/aerospace
SKETCHYBAR=/opt/homebrew/bin/sketchybar
INTENT_FILE="/tmp/.aero-intent"
PREV_WS_FILE="/tmp/.aero-prev-ws"

# Check if this workspace change was intentional (flag set by keybindings/scripts)
if [ -f "$INTENT_FILE" ]; then
    rm -f "$INTENT_FILE"
else
    # Unintentional switch — e.g. macOS fullscreen or native tiling moved a window,
    # causing AeroSpace to auto-focus a different workspace. Switch back.
    PREV_WS=$(cat "$PREV_WS_FILE" 2>/dev/null)
    if [ -n "$PREV_WS" ] && [ "$PREV_WS" != "$AEROSPACE_FOCUSED_WORKSPACE" ]; then
        touch "$INTENT_FILE"  # guard against re-entry
        $AEROSPACE workspace "$PREV_WS" &
        exit 0
    fi
fi

# Normal processing — update SketchyBar
$SKETCHYBAR --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$AEROSPACE_FOCUSED_WORKSPACE"

# Save current workspace as previous
echo "$AEROSPACE_FOCUSED_WORKSPACE" > "$PREV_WS_FILE"

# Hide/unhide Zoom based on whether it's on the focused workspace
if pgrep -xq "zoom.us"; then
    case "$($AEROSPACE list-windows --workspace "$AEROSPACE_FOCUSED_WORKSPACE" --format '%{app-name}' 2>/dev/null)" in
        *zoom.us*) vis=true ;; *) vis=false ;;
    esac
    osascript -e "tell application \"System Events\" to set visible of process \"zoom.us\" to $vis" 2>/dev/null
fi
