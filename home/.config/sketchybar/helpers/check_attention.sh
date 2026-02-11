#!/bin/sh
# Output space-separated workspace numbers containing apps with dock badges.
# Badge = non-empty StatusLabel in lsappinfo.

ws_map=$(aerospace list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null)
[ -z "$ws_map" ] && exit 0

# Find unique app names with non-empty badges
badged=""
while IFS= read -r app; do
  [ -z "$app" ] && continue
  sl=$(lsappinfo info -only StatusLabel "$app" 2>/dev/null)
  label=$(echo "$sl" | sed -n 's/.*"label"="\([^"]*\)".*/\1/p')
  [ -n "$label" ] && badged="$badged|$app|"
done <<EOF
$(echo "$ws_map" | cut -d'|' -f2 | sort -u)
EOF

# Map badged apps back to their workspace numbers
[ -z "$badged" ] && exit 0
echo "$ws_map" | while IFS='|' read -r ws app; do
  case "$badged" in *"|$app|"*) echo "$ws" ;; esac
done | sort -nu | tr '\n' ' '
