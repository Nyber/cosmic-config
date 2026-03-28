#!/bin/sh
# Generic launcher: open a new window if the app is running, otherwise launch it.
# Usage: launch-app.sh <AppName>  (e.g., Safari, Obsidian, Ghostty)
app="$1"
[ -z "$app" ] && exit 1
current_ws=$(/opt/homebrew/bin/aerospace list-workspaces --focused)

if osascript -e "application \"$app\" is running" 2>/dev/null | grep -q true; then
    # Get window IDs before opening a new one
    before=$(/opt/homebrew/bin/aerospace list-windows --monitor all --format '%{app-name}|%{window-id}' \
        | grep "^${app}|" | cut -d'|' -f2 | sort)

    # Create new window — try scriptable API first, fall back to Cmd+N
    osascript -e "tell application \"$app\" to make new document" 2>/dev/null \
        || osascript -e "
            tell application \"$app\" to activate
            delay 0.3
            tell application \"System Events\"
                keystroke \"n\" using command down
            end tell
        "
    sleep 0.5

    # Find the new window and move it to the current workspace
    after=$(/opt/homebrew/bin/aerospace list-windows --monitor all --format '%{app-name}|%{window-id}' \
        | grep "^${app}|" | cut -d'|' -f2 | sort)
    new_id=$(comm -13 <(echo "$before") <(echo "$after") | head -1)

    if [ -n "$new_id" ]; then
        /opt/homebrew/bin/aerospace move-node-to-workspace "$current_ws" --window-id "$new_id"
        /opt/homebrew/bin/aerospace focus --window-id "$new_id"
    else
        # No new window detected — just focus the app on current workspace
        /opt/homebrew/bin/aerospace workspace "$current_ws"
    fi
else
    open -a "$app"
fi
