#!/bin/sh
# Persistent daemon: detects minimized windows and restores them to their
# original workspace when unminimized from the Dock.
# Managed by LaunchAgent (com.aerospace.minimize-daemon).
#
# Adaptive polling: 2s when .minimized-* files exist, 15s when idle.
# minimize-window.sh sends USR1 to wake from slow sleep immediately.

PREV_FILE=$(mktemp)
CURR_FILE=$(mktemp)
MDIR="$HOME/.config/aerospace"
PIDFILE="$MDIR/.minimize-daemon.pid"
FAST_POLLS=0

echo $$ > "$PIDFILE"
trap 'rm -f "$PREV_FILE" "$CURR_FILE" "$PIDFILE"' EXIT
trap 'FAST_POLLS=3' USR1

: > "$PREV_FILE"
CLEANUP=0

while true; do
  aerospace list-windows --all --format '%{window-id} %{workspace}' > "$CURR_FILE"

  # Single awk pass: find windows in prev but not curr (just minimized).
  # PREV is already NULL-filtered, so workspaces are always valid.
  awk 'NR==FNR {curr[$1]; next} !($1 in curr)' "$CURR_FILE" "$PREV_FILE" |
  while IFS=' ' read -r wid ws; do
    echo "$ws" > "$MDIR/.minimized-$wid"
  done

  # Windows in curr that have a .minimized file → just restored
  while IFS=' ' read -r wid ws; do
    [ -z "$wid" ] && continue
    mfile="$MDIR/.minimized-$wid"
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

  # Every ~60s, purge .minimized files older than 10 min (orphaned windows)
  CLEANUP=$((CLEANUP + 1))
  if [ "$CLEANUP" -ge 30 ]; then
    CLEANUP=0
    find "$MDIR" -name ".minimized-*" -mmin +10 -delete 2>/dev/null
  fi

  # Save curr as prev, filtering NULL-WOKRSPACE transitional entries
  grep -v NULL "$CURR_FILE" > "$PREV_FILE"

  # Trigger badge check for workspace attention indicators
  sketchybar --trigger badge_check

  # Adaptive sleep: fast after USR1 signal or when tracking minimized windows
  if [ "$FAST_POLLS" -gt 0 ]; then
    FAST_POLLS=$((FAST_POLLS - 1))
    sleep 2
  elif ls "$MDIR"/.minimized-* >/dev/null 2>&1; then
    sleep 2
  else
    sleep 15 &
    wait $!
  fi
done
