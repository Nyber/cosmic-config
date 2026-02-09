#!/bin/sh
# After closing a window, if the workspace is now empty, go back to the previous workspace.
# Then refresh SketchyBar.
sleep 0.1
if [ -z "$(aerospace list-windows --workspace focused)" ]; then
  aerospace workspace-back-and-forth
fi
AEROSPACE_FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)" \
  /Users/wyoung5/.config/sketchybar/plugins/aerospace_batch.sh
