#!/bin/bash

source "$CONFIG_DIR/plugins/icon_map.sh"

# If triggered by front_app_switched, do a full batch update
if [ "$SENDER" = "front_app_switched" ]; then
  AEROSPACE_FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)" \
    "$CONFIG_DIR/plugins/aerospace_batch.sh"
  exit 0
fi

# Per-item update (initial load via sketchybar --update)
SID="${NAME##*.}"
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
NON_EMPTY="$(aerospace list-workspaces --monitor all --empty no)"

APPS=""
while IFS= read -r app; do
  [ -z "$app" ] && continue
  __icon_map "$app"
  APPS+="${icon_result} "
done < <(aerospace list-windows --workspace "$SID" --format '%{app-name}' 2>/dev/null | sort -u)

if echo "$NON_EMPTY" | grep -qx "$SID"; then
  if [ "$FOCUSED" = "$SID" ]; then
    sketchybar --set "$NAME" drawing=on icon.highlight=on label.highlight=on background.drawing=on label="$APPS"
  else
    sketchybar --set "$NAME" drawing=on icon.highlight=off label.highlight=off background.drawing=off label="$APPS"
  fi
else
  sketchybar --set "$NAME" drawing=off
fi
