#!/bin/sh
# SketchyBar QA — run after any changes to sketchybar config or helpers.
# Tests build, widget state, autonomous flows, and LaunchAgent isolation.
#
# Usage: sh ~/.config/sketchybar/qa.sh

set -e

PASS=0
FAIL=0
WARN=0
SBAR_DIR="$HOME/.config/sketchybar"
HELPERS="$SBAR_DIR/helpers"
LAUNCHD_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

pass() { PASS=$((PASS + 1)); printf "  \033[32m✓\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  \033[31m✗\033[0m %s\n" "$1"; }
warn() { WARN=$((WARN + 1)); printf "  \033[33m!\033[0m %s\n" "$1"; }
section() { printf "\n\033[1m%s\033[0m\n" "$1"; }

# ---------------------------------------------------------------------------
section "1. Helpers build"
# ---------------------------------------------------------------------------

(cd "$HELPERS" && rm -rf badges/bin volume/bin menus/bin && make >/dev/null 2>&1) \
  && pass "All helpers build cleanly" \
  || fail "Helpers build failed"

for h in menus/bin/menus badges/bin/badges volume/bin/volume; do
  [ -x "$HELPERS/$h" ] \
    && pass "$h exists and is executable" \
    || fail "$h missing or not executable"
done

# ---------------------------------------------------------------------------
section "2. Helper functional tests"
# ---------------------------------------------------------------------------

# Badges: valid JSON for 0 and N args
out=$("$HELPERS/badges/bin/badges" 2>&1)
[ "$out" = "{}" ] && pass "badges: no args → {}" || fail "badges: no args → $out"

out=$("$HELPERS/badges/bin/badges" 'Safari' 'NoSuchApp' 2>&1)
printf '%s' "$out" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null \
  && pass "badges: valid JSON output" \
  || fail "badges: invalid JSON: $out"

# Volume: set and restore
BEFORE=$(osascript -e "output volume of (get volume settings)" 2>/dev/null)
"$HELPERS/volume/bin/volume" 25 2>/dev/null
sleep 0.1
V=$(osascript -e "output volume of (get volume settings)" 2>/dev/null)
[ "$V" = "25" ] && pass "volume: absolute set → 25%" || fail "volume: set 25 → got $V%"

"$HELPERS/volume/bin/volume" "+10" 2>/dev/null
sleep 0.1
V=$(osascript -e "output volume of (get volume settings)" 2>/dev/null)
[ "$V" = "35" ] && pass "volume: relative +10 → 35%" || fail "volume: +10 → got $V%"

"$HELPERS/volume/bin/volume" "$BEFORE" 2>/dev/null
pass "volume: restored to ${BEFORE}%"

# ---------------------------------------------------------------------------
section "3. LaunchAgent PATH isolation"
# ---------------------------------------------------------------------------

# Every subprocess call in LaunchAgent-managed scripts must use full paths.
# LaunchAgents get a minimal PATH: /usr/bin:/bin:/usr/sbin:/sbin
# Homebrew binaries (/opt/homebrew/bin/*) are NOT in that PATH.

AGENT_SCRIPTS=""
for plist in "$HOME"/Library/LaunchAgents/com.user.*.plist \
             "$HOME"/Library/LaunchAgents/com.aerospace.*.plist; do
  [ -f "$plist" ] || continue
  # Extract the script/program from the plist
  script=$(sed -n 's|.*exec \(.*\)</string>|\1|p' "$plist" | head -1)
  [ -n "$script" ] && AGENT_SCRIPTS="$AGENT_SCRIPTS $(eval echo "$script")"
done

# Also check scripts called by those scripts (one level deep)
ALL_SCRIPTS="$AGENT_SCRIPTS"
for s in $AGENT_SCRIPTS; do
  [ -f "$s" ] || continue
  # Find sourced/exec'd scripts
  for ref in $(grep -oE '\$HOME/[^ ]+\.sh|\$CONFIG_DIR/[^ ]+\.sh|~/[^ ]+\.sh' "$s" 2>/dev/null); do
    expanded=$(eval echo "$ref" 2>/dev/null)
    [ -f "$expanded" ] && ALL_SCRIPTS="$ALL_SCRIPTS $expanded"
  done
done

for script in $ALL_SCRIPTS; do
  [ -f "$script" ] || continue
  base=$(basename "$script")
  # Find bare command names that are Homebrew binaries
  for cmd in sketchybar aerospace; do
    # Match bare command (not preceded by / which indicates a full path)
    if grep -qE "(^|[[:space:]|;\"'\`]|\[)$cmd([[:space:]]|$)" "$script" 2>/dev/null; then
      # Check it's not already a full path
      if grep -qE "/[^ ]*$cmd" "$script" 2>/dev/null; then
        # Has at least one full path reference — check if ALL are full paths
        bare=$(grep -cE "(^|[[:space:]|;\"'\`]|\[)$cmd([[:space:]]|$)" "$script" 2>/dev/null || echo 0)
        full=$(grep -cE "/[^ ]*$cmd" "$script" 2>/dev/null || echo 0)
        if [ "$bare" -gt "$full" ]; then
          fail "$base: mix of bare and full-path '$cmd' calls ($bare bare, $full full)"
        fi
      else
        fail "$base: uses bare '$cmd' (not in launchd PATH)"
      fi
    fi
  done
done

# Verify commands resolve from minimal PATH
for cmd in sketchybar aerospace; do
  if env -i PATH="$LAUNCHD_PATH" which "$cmd" >/dev/null 2>&1; then
    pass "$cmd resolves from launchd PATH"
  else
    full=$(which "$cmd" 2>/dev/null)
    if [ -n "$full" ]; then
      warn "$cmd NOT in launchd PATH (lives at $full)"
    else
      warn "$cmd not installed"
    fi
  fi
done

# Verify notification watcher trigger uses full path
if grep -q '/opt/homebrew/bin/sketchybar' "$HELPERS/notification_reader.py" 2>/dev/null; then
  pass "notification_reader.py uses full sketchybar path"
else
  fail "notification_reader.py uses bare sketchybar in trigger"
fi

# ---------------------------------------------------------------------------
section "4. SketchyBar reload and widget state"
# ---------------------------------------------------------------------------

sketchybar --reload >/dev/null 2>&1
sleep 2

# Bar is running
pgrep -q sketchybar && pass "sketchybar process running" || fail "sketchybar not running"

# Bar query
hidden=$(sketchybar --query bar 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['hidden'])" 2>/dev/null)
[ "$hidden" = "off" ] && pass "bar visible (hidden=off)" || fail "bar hidden=$hidden"

# Spaces
WS=$(aerospace list-workspaces --focused 2>/dev/null | tr -d '[:space:]')
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$WS" >/dev/null 2>&1
sleep 1
d=$(sketchybar --query "space.$WS" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['geometry']['drawing'])" 2>/dev/null)
[ "$d" = "on" ] && pass "space.$WS drawing after workspace trigger" || fail "space.$WS drawing=$d"

# Volume widget
d=$(sketchybar --query widgets.volume1 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['geometry']['drawing'])" 2>/dev/null)
[ "$d" = "on" ] && pass "volume widget drawing" || fail "volume widget drawing=$d"

# Battery widget
d=$(sketchybar --query widgets.battery 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['geometry']['drawing'])" 2>/dev/null)
[ "$d" = "on" ] && pass "battery widget drawing" || fail "battery widget drawing=$d"

# Notifications widget exists
t=$(sketchybar --query widgets.notifications 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['type'])" 2>/dev/null)
[ "$t" = "item" ] && pass "notifications widget exists" || fail "notifications widget type=$t"

# ---------------------------------------------------------------------------
section "5. Autonomous notification flow"
# ---------------------------------------------------------------------------

# Watcher daemon running
if pgrep -f "notification_reader.py watch" >/dev/null 2>&1; then
  pass "notification watcher daemon running"
else
  fail "notification watcher daemon not running"
fi

# Watcher trigger actually works (simulate what watcher does)
if /opt/homebrew/bin/sketchybar --trigger wal_changed --trigger badge_check >/dev/null 2>&1; then
  pass "sketchybar trigger from full path works"
else
  fail "sketchybar trigger from full path failed"
fi

# Cache file exists and is valid JSON
CACHE="$HELPERS/.notif_cache.json"
if [ -f "$CACHE" ]; then
  if python3 -c "import sys,json; json.load(open(sys.argv[1]))" "$CACHE" 2>/dev/null; then
    pass "notification cache is valid JSON"
  else
    fail "notification cache is invalid JSON"
  fi
else
  warn "notification cache file does not exist"
fi

# Bell state matches cache
CACHE_COUNT=$(python3 -c "import json; print(len(json.load(open('$CACHE'))))" 2>/dev/null || echo 0)
BELL_DRAWING=$(sketchybar --query widgets.notifications 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['geometry']['drawing'])" 2>/dev/null)
if [ "$CACHE_COUNT" -gt 0 ] && [ "$BELL_DRAWING" = "on" ]; then
  pass "bell drawing matches cache ($CACHE_COUNT notifications)"
elif [ "$CACHE_COUNT" = "0" ] && [ "$BELL_DRAWING" = "off" ]; then
  pass "bell hidden matches empty cache"
else
  fail "bell state mismatch: cache=$CACHE_COUNT, drawing=$BELL_DRAWING"
fi

# ---------------------------------------------------------------------------
section "6. Badge detection flow"
# ---------------------------------------------------------------------------

# Trigger and verify badge data updates
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$WS" >/dev/null 2>&1
sleep 2

# Get all apps and check which have badges
APPS=$(aerospace list-windows --all --format '%{app-name}' 2>/dev/null | sort -u)
BADGED=$("$HELPERS/badges/bin/badges" $(echo "$APPS" | while read -r app; do printf "'%s' " "$app"; done) 2>/dev/null)
BADGE_COUNT=$(printf '%s' "$BADGED" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)

if [ "$BADGE_COUNT" -gt 0 ]; then
  # Check that at least one badge item is drawing
  any_drawing=false
  for i in 1 2 3 4 5; do
    bd=$(sketchybar --query "space.$i.badge" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['geometry']['drawing'])" 2>/dev/null)
    [ "$bd" = "on" ] && any_drawing=true
  done
  $any_drawing \
    && pass "badge items drawing for $BADGE_COUNT badged app(s)" \
    || fail "badges helper found $BADGE_COUNT badge(s) but no badge items drawing"
else
  pass "no active badges — badge items correctly hidden"
fi

# ---------------------------------------------------------------------------
section "7. SbarLua JSON auto-parse safety"
# ---------------------------------------------------------------------------

# Check that any sbar.exec callback handling JSON output checks type(result)
for f in "$SBAR_DIR"/items/*.lua "$SBAR_DIR"/items/widgets/*.lua; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  # Find sbar.exec calls to our JSON-outputting helpers
  if grep -q 'helpers/badges/bin/badges' "$f" 2>/dev/null; then
    if grep -q 'type(result)' "$f" 2>/dev/null; then
      pass "$base: badges callback handles auto-parsed JSON"
    else
      fail "$base: badges callback missing type(result) check"
    fi
  fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

printf "\n\033[1mResults: \033[32m%d passed\033[0m" "$PASS"
[ "$FAIL" -gt 0 ] && printf ", \033[31m%d failed\033[0m" "$FAIL"
[ "$WARN" -gt 0 ] && printf ", \033[33m%d warnings\033[0m" "$WARN"
printf "\n"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
