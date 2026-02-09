#!/bin/sh

# Show only in-use workspaces, highlight the focused one.
# Used for initial load via sketchybar --update. Not subscribed to events.

SID="${NAME##*.}"
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
NON_EMPTY="$(aerospace list-workspaces --monitor all --empty no)"

if echo "$NON_EMPTY" | grep -qx "$SID"; then
  if [ "$FOCUSED" = "$SID" ]; then
    sketchybar --set "$NAME" drawing=on icon.highlight=on background.drawing=on
  else
    sketchybar --set "$NAME" drawing=on icon.highlight=off background.drawing=off
  fi
else
  sketchybar --set "$NAME" drawing=off
fi
