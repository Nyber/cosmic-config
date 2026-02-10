#!/bin/sh
# Move focused window to target workspace.
# If the source workspace is now empty, follow the window.
# Then refresh SketchyBar.
TARGET="$1"
sleep 0.1
if [ -z "$(aerospace list-windows --workspace focused)" ]; then
  aerospace workspace "$TARGET"
fi
AEROSPACE_FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)" \
  $HOME/.config/sketchybar/plugins/aerospace_batch.sh
