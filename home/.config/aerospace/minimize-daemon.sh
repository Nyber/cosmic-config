#!/bin/sh
# Persistent daemon: detects minimized windows and restores them to their
# original workspace when unminimized from the Dock.
# Managed by LaunchAgent (com.aerospace.minimize-daemon).
#
# Adaptive polling: 2s when .minimized-* files exist, 15s when idle.

MDIR="$HOME/.config/aerospace"
PREV_FILE="$MDIR/.daemon-prev"
CURR_FILE="$MDIR/.daemon-curr"
PIDFILE="$MDIR/.minimize-daemon.pid"
AEROSPACE=/opt/homebrew/bin/aerospace

echo $$ > "$PIDFILE"
trap 'rm -f "$PREV_FILE" "$PREV_FILE.new" "$CURR_FILE" "$PIDFILE"' EXIT

: > "$PREV_FILE"
CLEANUP=0

while true; do
  $AEROSPACE list-windows --all --format '%{window-id} %{workspace}' > "$CURR_FILE"

  # Detect windows that just disappeared (in prev but not curr = just minimized).
  # Only write .minimized if it doesn't already exist — minimize-window.sh writes
  # the authoritative value (daemon PREV can be stale if window moved recently).
  JUST_MINIMIZED=0
  awk 'NR==FNR {curr[$1]; next} !($1 in curr)' "$CURR_FILE" "$PREV_FILE" |
  while IFS=' ' read -r wid ws; do
    mfile="$MDIR/.minimized-$wid"
    if [ ! -f "$mfile" ]; then
      echo "$ws" > "$mfile"
    fi
  done
  # Check if any .minimized files were just created (< 3s old) — means windows
  # were minimized this cycle, not closed/quit.
  now_min=$(date +%s)
  for mfile in "$MDIR"/.minimized-*; do
    [ -f "$mfile" ] || continue
    fb=$(stat -f %B "$mfile" 2>/dev/null || echo 0)
    if [ $((now_min - fb)) -lt 3 ]; then
      JUST_MINIMIZED=1
      break
    fi
  done

  # Restore: scan all .minimized files for windows that are visible in CURR.
  # Use file birth time to avoid false restores — if the file is < 3s old,
  # the window may still be disappearing from list-windows (async minimize).
  # This handles minimize+restore within one poll cycle (the awk "appeared"
  # approach missed this since the window stayed in both PREV and CURR).
  now=$(date +%s)
  for mfile in "$MDIR"/.minimized-*; do
    [ -f "$mfile" ] || continue
    wid="${mfile##*.minimized-}"

    # Is window currently visible?
    ws=$(awk -v w="$wid" '$1 == w {print $2}' "$CURR_FILE")
    if [ -z "$ws" ]; then
      continue
    fi

    # Is file old enough to rule out async minimize delay?
    file_birth=$(stat -f %B "$mfile" 2>/dev/null || echo "$now")
    age=$((now - file_birth))
    if [ "$age" -lt 3 ]; then
      continue
    fi

    mdata=$(cat "$mfile")
    orig_ws=$(echo "$mdata" | awk '{print $1}')
    compacted=$(echo "$mdata" | awk '{print $2}')
    rm -f "$mfile"

    # Determine target workspace.
    # If compact marked this as "compacted" (original ws was emptied and refilled
    # by different content), restore to the end instead of mixing with wrong content.
    target_ws="$orig_ws"
    if [ "$compacted" = "compacted" ]; then
      max_ws=$($AEROSPACE list-windows --all --format '%{workspace}' | sort -n | tail -1)
      target_ws=$((max_ws + 1))
    fi

    if [ "$ws" != "$target_ws" ]; then
      $AEROSPACE move-node-to-workspace "$target_ws" --window-id "$wid"
      touch /tmp/.aero-intent
      $AEROSPACE workspace "$target_ws"
    fi
    # Re-tile: macOS restores minimized windows as floating
    # Skip for apps that should stay floating (e.g. Zoom)
    app_name=$($AEROSPACE list-windows --all --format '%{window-id}|%{app-bundle-id}' | awk -F'|' -v w="$wid" '$1 == w {print $2}')
    case "$app_name" in
      us.zoom.xos) ;;
      *) $AEROSPACE layout tiling --window-id "$wid" 2>/dev/null
         $AEROSPACE flatten-workspace-tree 2>/dev/null ;;
    esac
    # Compact in case restore created gaps
    "$MDIR/compact-workspaces.sh"
  done

  # Every ~60s, purge .minimized files for windows that no longer exist.
  # Only purge files older than 120s to avoid race with async restore detection.
  CLEANUP=$((CLEANUP + 1))
  if [ "$CLEANUP" -ge 30 ]; then
    CLEANUP=0
    now_cleanup=$(date +%s)
    for mfile in "$MDIR"/.minimized-*; do
      [ -f "$mfile" ] || continue
      wid="${mfile##*.minimized-}"
      file_birth=$(stat -f %B "$mfile" 2>/dev/null || echo "$now_cleanup")
      age=$((now_cleanup - file_birth))
      [ "$age" -lt 120 ] && continue
      # Window gone from both lists = closed while minimized — safe to delete
      if ! grep -q "^$wid " "$CURR_FILE" && ! grep -q "^$wid " "$PREV_FILE"; then
        rm -f "$mfile"
      fi
    done
  fi

  # Save curr as prev, triggering badge check only if window list changed
  grep -v NULL "$CURR_FILE" > "$PREV_FILE.new"
  if ! cmp -s "$PREV_FILE" "$PREV_FILE.new"; then
    /opt/homebrew/bin/sketchybar --trigger badge_check
    # Skip compact when a window was just minimized — minimized windows are
    # temporary (will be restored later), so compacting is premature and would
    # yank the user to a different workspace. The alt+m keybinding handles its
    # own compact via minimize-window.sh.
    if [ "$JUST_MINIMIZED" = "0" ]; then
      "$MDIR/compact-workspaces.sh"
    fi
  fi
  mv "$PREV_FILE.new" "$PREV_FILE"

  # Adaptive sleep: 2s when tracking minimized windows, 15s when idle
  if ls "$MDIR"/.minimized-* >/dev/null 2>&1; then
    sleep 2
  else
    sleep 15
  fi
done
