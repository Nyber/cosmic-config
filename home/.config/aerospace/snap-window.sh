#!/bin/bash
# snap-window.sh — Snap focused window to halves/quarters with double-tap cycling.
# Usage: snap-window.sh <left|right|up|down>
#
# Cycling (repeat same direction within 2s):
#   left:  left half → top-left quarter → bottom-left quarter → left half …
#   right: right half → top-right quarter → bottom-right quarter → right half …
#   up:    top half → top-left quarter → top-right quarter → top half …
#   down:  bottom half → bottom-left quarter → bottom-right quarter → bottom half …

set -euo pipefail

DIRECTION="$1"
STATE_FILE="/tmp/aerospace-snap-state"
CYCLE_TIMEOUT=3

# --- Screen dimensions (usable area accounting for SketchyBar + gaps) ---
# outer gaps: top=10, left=2, right=2, bottom=2  (matches .aerospace.toml)
# inner gap between quarter splits: 5px (matches inner.horizontal/vertical)
GAP_TOP=44
GAP_LEFT=2
GAP_RIGHT=2
GAP_BOTTOM=2
GAP_INNER=5

# Get screen dimensions (cached for 60s to avoid slow Finder osascript on every call)
SCREEN_CACHE="/tmp/aerospace-screen-dims"
CACHE_MAX_AGE=60

if [[ -f "$SCREEN_CACHE" ]]; then
    CACHE_AGE=$(( $(date +%s) - $(stat -f %m "$SCREEN_CACHE") ))
else
    CACHE_AGE=$((CACHE_MAX_AGE + 1))
fi

if (( CACHE_AGE > CACHE_MAX_AGE )); then
    osascript -e 'tell application "Finder" to get bounds of window of desktop' 2>/dev/null \
        | tr ',' ' ' | awk '{print $3, $4}' > "$SCREEN_CACHE" || echo "1512 982" > "$SCREEN_CACHE"
fi

read -r SCREEN_W SCREEN_H < "$SCREEN_CACHE"

# Usable area after outer gaps
X_MIN=$GAP_LEFT
Y_MIN=$GAP_TOP
USABLE_W=$((SCREEN_W - GAP_LEFT - GAP_RIGHT))
USABLE_H=$((SCREEN_H - GAP_TOP - GAP_BOTTOM))

# Half dimensions (with inner gap for quarter splits)
HALF_W=$(( (USABLE_W - GAP_INNER) / 2 ))
HALF_H=$(( (USABLE_H - GAP_INNER) / 2 ))

# --- Cycle state ---
NOW=$(date +%s)
STEP=0

if [[ -f "$STATE_FILE" ]]; then
    read -r PREV_DIR PREV_TIME PREV_STEP < "$STATE_FILE" 2>/dev/null || true
    if [[ "$PREV_DIR" == "$DIRECTION" ]] && (( NOW - PREV_TIME < CYCLE_TIMEOUT )); then
        STEP=$(( (PREV_STEP + 1) % 3 ))
    fi
fi

echo "$DIRECTION $NOW $STEP" > "$STATE_FILE"

# --- Compute position and size ---
case "${DIRECTION}:${STEP}" in
    # Left: half → top-left → bottom-left
    left:0)  X=$X_MIN;                        Y=$Y_MIN;                        W=$HALF_W;  H=$USABLE_H ;;
    left:1)  X=$X_MIN;                        Y=$Y_MIN;                        W=$HALF_W;  H=$HALF_H ;;
    left:2)  X=$X_MIN;                        Y=$((Y_MIN + HALF_H + GAP_INNER)); W=$HALF_W;  H=$HALF_H ;;

    # Right: half → top-right → bottom-right
    right:0) X=$((X_MIN + HALF_W + GAP_INNER)); Y=$Y_MIN;                        W=$HALF_W;  H=$USABLE_H ;;
    right:1) X=$((X_MIN + HALF_W + GAP_INNER)); Y=$Y_MIN;                        W=$HALF_W;  H=$HALF_H ;;
    right:2) X=$((X_MIN + HALF_W + GAP_INNER)); Y=$((Y_MIN + HALF_H + GAP_INNER)); W=$HALF_W;  H=$HALF_H ;;

    # Up: half → top-left → top-right
    up:0)    X=$X_MIN;                        Y=$Y_MIN;                        W=$USABLE_W; H=$HALF_H ;;
    up:1)    X=$X_MIN;                        Y=$Y_MIN;                        W=$HALF_W;  H=$HALF_H ;;
    up:2)    X=$((X_MIN + HALF_W + GAP_INNER)); Y=$Y_MIN;                        W=$HALF_W;  H=$HALF_H ;;

    # Down: half → bottom-left → bottom-right
    down:0)  X=$X_MIN;                        Y=$((Y_MIN + HALF_H + GAP_INNER)); W=$USABLE_W; H=$HALF_H ;;
    down:1)  X=$X_MIN;                        Y=$((Y_MIN + HALF_H + GAP_INNER)); W=$HALF_W;  H=$HALF_H ;;
    down:2)  X=$((X_MIN + HALF_W + GAP_INNER)); Y=$((Y_MIN + HALF_H + GAP_INNER)); W=$HALF_W;  H=$HALF_H ;;
esac

# --- Move and resize window via osascript ---
# Find the largest window of the front app (avoids targeting Zoom's floating
# toolbar/overlay instead of the actual meeting window).
osascript -e "
    tell application \"System Events\"
        set frontApp to first application process whose frontmost is true
        set wins to every window of frontApp
        if (count of wins) = 0 then return

        set bestWin to item 1 of wins
        set bestArea to 0
        repeat with w in wins
            try
                set {w_, h_} to size of w
                set a to w_ * h_
                if a > bestArea then
                    set bestArea to a
                    set bestWin to w
                end if
            end try
        end repeat

        set position of bestWin to {${X}, ${Y}}
        set size of bestWin to {${W}, ${H}}
    end tell
"
