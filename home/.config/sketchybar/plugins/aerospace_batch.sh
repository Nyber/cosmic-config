#!/bin/bash

# Batch-update all workspace indicators in a single sketchybar call.
# Called directly by AeroSpace's exec-on-workspace-change.

source "${0%/*}/icon_map.sh"

FOCUSED="${AEROSPACE_FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
NON_EMPTY="$(aerospace list-workspaces --monitor all --empty no)"

args=()
for sid in 1 2 3 4 5; do
  APPS=""
  while IFS= read -r app; do
    [ -z "$app" ] && continue
    __icon_map "$app"
    APPS+="${icon_result} "
  done < <(aerospace list-windows --workspace "$sid" --format '%{app-name}' 2>/dev/null | sort -u)

  if [ "$FOCUSED" = "$sid" ]; then
    args+=(--set "workspace.$sid" drawing=on icon.highlight=on label.highlight=on background.drawing=on label="$APPS")
  elif echo "$NON_EMPTY" | grep -qx "$sid"; then
    args+=(--set "workspace.$sid" drawing=on icon.highlight=off label.highlight=off background.drawing=off label="$APPS")
  else
    args+=(--set "workspace.$sid" drawing=off)
  fi
done

sketchybar "${args[@]}"
