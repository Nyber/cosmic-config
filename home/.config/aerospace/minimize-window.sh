#!/bin/sh
# Minimize the focused window via opt+m. Writes the .minimized tracking file
# directly (guaranteed workspace capture). The daemon detects the minimize
# on its next poll and switches to fast polling while .minimized files exist.

MDIR="$HOME/.config/aerospace"
WINDOW_ID=$(/opt/homebrew/bin/aerospace list-windows --focused --format '%{window-id}')

if [ -z "$WINDOW_ID" ]; then
  exit 0
fi

WORKSPACE=$(/opt/homebrew/bin/aerospace list-workspaces --focused)

/opt/homebrew/bin/aerospace macos-native-minimize --window-id "$WINDOW_ID"

# Write tracking file AFTER minimize to avoid false-restore race condition
echo "$WORKSPACE" > "$MDIR/.minimized-$WINDOW_ID"

# Compact workspaces after minimize
sleep 0.1
$HOME/.config/aerospace/compact-workspaces.sh
