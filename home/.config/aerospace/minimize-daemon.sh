#!/bin/sh
# Persistent daemon: detects minimized windows and restores them to their
# original workspace when unminimized from the Dock.
# Started automatically by workspace-changed.sh.

PREV_FILE=$(mktemp)
CURR_FILE=$(mktemp)
WS_MAP_DIR="$HOME/.config/aerospace/.ws-map"
mkdir -p "$WS_MAP_DIR"
trap 'rm -f "$PREV_FILE" "$CURR_FILE"' EXIT

: > "$PREV_FILE"

while true; do
  aerospace list-windows --all --format '%{window-id} %{workspace}' > "$CURR_FILE"

  # Update workspace map with valid entries only (skip NULL-WOKRSPACE)
  while IFS=' ' read -r wid ws; do
    [ -z "$wid" ] && continue
    case "$ws" in *NULL*) continue ;; esac
    echo "$ws" > "$WS_MAP_DIR/$wid"
  done < "$CURR_FILE"

  # Windows in prev but not curr → just minimized
  while IFS=' ' read -r wid ws; do
    [ -z "$wid" ] && continue
    if ! grep -q "^$wid " "$CURR_FILE"; then
      # Use last known good workspace from map
      [ -f "$WS_MAP_DIR/$wid" ] && cp "$WS_MAP_DIR/$wid" "$HOME/.config/aerospace/.minimized-$wid"
    fi
  done < "$PREV_FILE"

  # Windows in curr that have a .minimized file → just restored
  while IFS=' ' read -r wid ws; do
    [ -z "$wid" ] && continue
    mfile="$HOME/.config/aerospace/.minimized-$wid"
    if [ -f "$mfile" ]; then
      orig_ws=$(cat "$mfile")
      rm -f "$mfile"
      if [ "$ws" != "$orig_ws" ]; then
        aerospace move-node-to-workspace "$orig_ws" --window-id "$wid"
        aerospace workspace "$orig_ws"
        sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)"
      fi
    fi
  done < "$CURR_FILE"

  cp "$CURR_FILE" "$PREV_FILE"
  sleep 0.5
done
