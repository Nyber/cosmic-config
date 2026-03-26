#!/bin/sh
# Compact AeroSpace workspaces to fill gaps.
# Workspaces 1,2,4,5 → 1,2,3,4 (windows shift down to fill gaps).
# Called by close-window.sh, move-window.sh, minimize-window.sh.

MDIR="$HOME/.config/aerospace"
LOCKDIR="$MDIR/.compact-lock"
AEROSPACE=/opt/homebrew/bin/aerospace
SKETCHYBAR=/opt/homebrew/bin/sketchybar

# Non-blocking lock — skip if another compact is already running
mkdir "$LOCKDIR" 2>/dev/null || exit 0
trap 'rmdir "$LOCKDIR"' EXIT

FOCUSED=$($AEROSPACE list-workspaces --focused)
OCCUPIED=$($AEROSPACE list-windows --all --format '%{workspace}' | sort -un)

# No windows anywhere
if [ -z "$OCCUPIED" ]; then
  $SKETCHYBAR --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$FOCUSED"
  exit 0
fi

COUNT=$(echo "$OCCUPIED" | wc -l | tr -d ' ')
IDEAL=$(seq 1 "$COUNT")

# No gaps — just ensure user isn't stranded on an empty workspace
if [ "$OCCUPIED" = "$IDEAL" ]; then
  if [ "$FOCUSED" -gt "$COUNT" ]; then
    FOCUSED="$COUNT"
    $AEROSPACE workspace "$FOCUSED"
  fi
  $SKETCHYBAR --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$FOCUSED"
  exit 0
fi

# Compact: move windows from each occupied workspace to its target position.
# Process ascending — targets are always ≤ sources, so no collisions.
TARGET=1
NEW_FOCUSED="$FOCUSED"

for OLD_WS in $OCCUPIED; do
  if [ "$OLD_WS" != "$TARGET" ]; then
    $AEROSPACE list-windows --workspace "$OLD_WS" --format '%{window-id}' | while read -r WID; do
      [ -z "$WID" ] && continue
      $AEROSPACE move-node-to-workspace "$TARGET" --window-id "$WID"
    done
  fi

  # Track where the user's workspace moved
  if [ "$FOCUSED" = "$OLD_WS" ]; then
    NEW_FOCUSED="$TARGET"
  fi

  TARGET=$((TARGET + 1))
done

# If user was on an empty workspace (not in OCCUPIED), pick nearest valid
FOUND=0
for ws in $OCCUPIED; do
  [ "$FOCUSED" = "$ws" ] && FOUND=1 && break
done
if [ "$FOUND" = "0" ]; then
  if [ "$FOCUSED" -le "$COUNT" ]; then
    NEW_FOCUSED="$FOCUSED"
  else
    NEW_FOCUSED="$COUNT"
  fi
fi

# Update .minimized-* tracking files for workspaces that were renumbered.
# Format: "WORKSPACE" or "WORKSPACE compacted"
# "compacted" flag means the original workspace was emptied and other content
# slid into that position — daemon should restore to end, not orig_ws.
for mfile in "$MDIR"/.minimized-*; do
  [ -f "$mfile" ] || continue
  mdata=$(cat "$mfile")
  old_ws=$(echo "$mdata" | awk '{print $1}')
  old_flag=$(echo "$mdata" | awk '{print $2}')

  ws_found=0
  t=1
  for ows in $OCCUPIED; do
    if [ "$ows" = "$old_ws" ]; then
      ws_found=1
      if [ "$t" != "$old_ws" ]; then
        # Workspace remapped — preserve compacted flag if set
        if [ -n "$old_flag" ]; then
          echo "$t $old_flag" > "$mfile"
        else
          echo "$t" > "$mfile"
        fi
      fi
      break
    fi
    t=$((t + 1))
  done

  # Workspace not in OCCUPIED but within compacted range (1..COUNT):
  # content from a higher workspace slid into this position.
  if [ "$ws_found" = "0" ] && [ "$old_ws" -le "$COUNT" ]; then
    echo "$old_ws compacted" > "$mfile"
  fi
done

$AEROSPACE workspace "$NEW_FOCUSED"
$SKETCHYBAR --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$NEW_FOCUSED"
