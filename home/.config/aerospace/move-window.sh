#!/bin/sh
# After moving a window, follow it if source is empty, then compact.
TARGET="$1"
sleep 0.1
if [ -z "$(/opt/homebrew/bin/aerospace list-windows --workspace focused)" ]; then
  /opt/homebrew/bin/aerospace workspace "$TARGET"
fi
$HOME/.config/aerospace/compact-workspaces.sh
