#!/bin/sh
# Minimize the focused window via fn+m. Writes the .minimized tracking file
# directly (guaranteed workspace capture) and wakes the daemon from slow sleep.

MDIR="$HOME/.config/aerospace"
WINDOW_ID=$(/opt/homebrew/bin/aerospace list-windows --focused --format '%{window-id}')

if [ -z "$WINDOW_ID" ]; then
  exit 0
fi

WORKSPACE=$(/opt/homebrew/bin/aerospace list-workspaces --focused)

/opt/homebrew/bin/aerospace macos-native-minimize --window-id "$WINDOW_ID"

# Write tracking file AFTER minimize to avoid false-restore race condition
echo "$WORKSPACE" > "$MDIR/.minimized-$WINDOW_ID"

# Wake daemon from slow sleep
PIDFILE="$MDIR/.minimize-daemon.pid"
if [ -f "$PIDFILE" ]; then
  kill -USR1 "$(cat "$PIDFILE")" 2>/dev/null
fi

# If workspace is now empty, switch away
sleep 0.1
if [ -z "$(/opt/homebrew/bin/aerospace list-windows --workspace focused)" ]; then
  /opt/homebrew/bin/aerospace workspace-back-and-forth
fi

/opt/homebrew/bin/sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$(/opt/homebrew/bin/aerospace list-workspaces --focused)"
