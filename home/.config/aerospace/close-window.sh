#!/bin/sh
# After closing a window, if the workspace is now empty, go back to the previous workspace.
# Then refresh SketchyBar.
sleep 0.1
if [ -z "$(/opt/homebrew/bin/aerospace list-windows --workspace focused)" ]; then
  /opt/homebrew/bin/aerospace workspace-back-and-forth
fi
/opt/homebrew/bin/sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$(/opt/homebrew/bin/aerospace list-workspaces --focused)"
