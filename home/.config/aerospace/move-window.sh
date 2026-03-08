#!/bin/sh
# Move focused window to target workspace.
# If the source workspace is now empty, follow the window.
# Then refresh SketchyBar.
TARGET="$1"
sleep 0.1
if [ -z "$(/opt/homebrew/bin/aerospace list-windows --workspace focused)" ]; then
  /opt/homebrew/bin/aerospace workspace "$TARGET"
fi
/opt/homebrew/bin/sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$(/opt/homebrew/bin/aerospace list-workspaces --focused)"
