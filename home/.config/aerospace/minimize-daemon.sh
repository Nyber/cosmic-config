#!/bin/sh
# Persistent daemon: detects minimized windows and restores them to their
# original workspace when unminimized from the Dock.
# Managed by LaunchAgent (com.aerospace.minimize-daemon).

PREV_FILE=$(mktemp)
CURR_FILE=$(mktemp)
trap 'rm -f "$PREV_FILE" "$CURR_FILE"' EXIT

: > "$PREV_FILE"

while true; do
  aerospace list-windows --all --format '%{window-id} %{workspace}' > "$CURR_FILE"

  # Single awk pass: find windows in prev but not curr (just minimized).
  # PREV is already NULL-filtered, so workspaces are always valid.
  awk 'NR==FNR {curr[$1]; next} !($1 in curr)' "$CURR_FILE" "$PREV_FILE" |
  while IFS=' ' read -r wid ws; do
    echo "$ws" > "$HOME/.config/aerospace/.minimized-$wid"
  done

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

  # Save curr as prev, filtering NULL-WOKRSPACE transitional entries
  grep -v NULL "$CURR_FILE" > "$PREV_FILE"
  sleep 0.5
done
