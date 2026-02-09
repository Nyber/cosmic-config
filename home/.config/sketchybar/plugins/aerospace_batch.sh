#!/bin/bash

# Batch-update all workspace indicators in a single sketchybar call.
# Called directly by AeroSpace's exec-on-workspace-change.

FOCUSED="${AEROSPACE_FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
NON_EMPTY="$(aerospace list-workspaces --monitor all --empty no)"

args=()
for sid in 1 2 3 4 5; do
  if [ "$FOCUSED" = "$sid" ]; then
    # Always show the focused workspace, even if empty
    args+=(--set "workspace.$sid" drawing=on icon.highlight=on background.drawing=on)
  elif echo "$NON_EMPTY" | grep -qx "$sid"; then
    args+=(--set "workspace.$sid" drawing=on icon.highlight=off background.drawing=off)
  else
    args+=(--set "workspace.$sid" drawing=off)
  fi
done

sketchybar "${args[@]}"
