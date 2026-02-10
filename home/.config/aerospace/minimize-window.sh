#!/bin/sh
# Minimize the focused window via fn+m. The minimize-daemon handles tracking
# and restoring to the original workspace — this script just minimizes and
# handles the empty-workspace auto-switch.

WINDOW_ID=$(aerospace list-windows --focused --format '%{window-id}')

if [ -z "$WINDOW_ID" ]; then
  exit 0
fi

aerospace macos-native-minimize --window-id "$WINDOW_ID"

# If workspace is now empty, switch away
sleep 0.1
if [ -z "$(aerospace list-windows --workspace focused)" ]; then
  aerospace workspace-back-and-forth
fi

sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)"
