# Computer Rebuild Notes

## Preferences

- Screen: 1512x982 (logical), menu bar height: 32px
- Prefers **maximized** windows over full screen mode (no separate Space/animation)
- Status bar should **always be visible** (SketchyBar replaces macOS menu bar)
- 10px border around maximized windows to avoid visual overlap
  - Maximize with border: position {10, 42}, size {1492, 930}

## AeroSpace (Tiling Window Manager)

Uses its own virtual workspaces, not macOS Spaces. No overlap issues with Expose/Mission Control. Chose over Amethyst — more modern, better config, avoids macOS Spaces quirks.

### Install
```bash
brew tap nikitabobko/tap
brew install --cask nikitabobko/tap/aerospace
```

### Required Permissions
Grant in **System Settings > Privacy & Security**:
- **Accessibility** — toggle on AeroSpace

### Config
Save to `~/.aerospace.toml`.

```toml
config-version = 2
start-at-login = true

# Normalization (keeps the tree clean)
enable-normalization-flatten-containers = true
enable-normalization-opposite-orientation-for-nested-containers = true

# Tiles layout by default
default-root-container-layout = 'tiles'
default-root-container-orientation = 'auto'

# Mouse follows focus when switching monitors
on-focused-monitor-changed = ['move-mouse monitor-lazy-center']

# Keep workspaces 1-5 alive
persistent-workspaces = ["1", "2", "3", "4", "5"]

exec-on-workspace-change = ['~/.config/sketchybar/plugins/aerospace_batch.sh']

[key-mapping]
    preset = 'qwerty'

# 5px gaps between windows, 2px edge padding for border visibility
[gaps]
    inner.horizontal = 5
    inner.vertical =   5
    outer.left =       2
    outer.bottom =     2
    outer.top =        2
    outer.right =      2

[mode.main.binding]

    # --- Move windows: fn + shift + arrows ---
    alt-cmd-shift-left  = 'move left'
    alt-cmd-shift-down  = 'move down'
    alt-cmd-shift-up    = 'move up'
    alt-cmd-shift-right = 'move right'

    # --- Focus (navigate): fn + arrows ---
    alt-cmd-left  = 'focus left'
    alt-cmd-down  = 'focus down'
    alt-cmd-up    = 'focus up'
    alt-cmd-right = 'focus right'

    # --- Layout ---
    alt-cmd-slash = 'layout tiles horizontal vertical'
    alt-cmd-comma = 'layout accordion horizontal vertical'
    alt-cmd-f     = 'fullscreen'
    alt-cmd-m     = ['exec-and-forget $HOME/.config/aerospace/close-window.sh', 'macos-native-minimize']
    alt-cmd-q     = ['close', 'exec-and-forget $HOME/.config/aerospace/close-window.sh']

    # --- Resize ---
    alt-cmd-equal = 'resize smart +50'
    alt-cmd-minus = 'resize smart -50'

    # --- Workspaces: fn + number ---
    alt-cmd-1 = 'workspace 1'
    alt-cmd-2 = 'workspace 2'
    alt-cmd-3 = 'workspace 3'
    alt-cmd-4 = 'workspace 4'
    alt-cmd-5 = 'workspace 5'
    alt-cmd-6 = 'workspace 6'
    alt-cmd-7 = 'workspace 7'
    alt-cmd-8 = 'workspace 8'
    alt-cmd-9 = 'workspace 9'

    # --- Move window to workspace: fn + shift + number ---
    alt-cmd-shift-1 = ['move-node-to-workspace 1', 'exec-and-forget ~/.config/aerospace/move-window.sh 1']
    alt-cmd-shift-2 = ['move-node-to-workspace 2', 'exec-and-forget ~/.config/aerospace/move-window.sh 2']
    alt-cmd-shift-3 = ['move-node-to-workspace 3', 'exec-and-forget ~/.config/aerospace/move-window.sh 3']
    alt-cmd-shift-4 = ['move-node-to-workspace 4', 'exec-and-forget ~/.config/aerospace/move-window.sh 4']
    alt-cmd-shift-5 = ['move-node-to-workspace 5', 'exec-and-forget ~/.config/aerospace/move-window.sh 5']
    alt-cmd-shift-6 = ['move-node-to-workspace 6', 'exec-and-forget ~/.config/aerospace/move-window.sh 6']
    alt-cmd-shift-7 = ['move-node-to-workspace 7', 'exec-and-forget ~/.config/aerospace/move-window.sh 7']
    alt-cmd-shift-8 = ['move-node-to-workspace 8', 'exec-and-forget ~/.config/aerospace/move-window.sh 8']
    alt-cmd-shift-9 = ['move-node-to-workspace 9', 'exec-and-forget ~/.config/aerospace/move-window.sh 9']

    # --- Quick switch ---
    alt-cmd-tab = 'workspace-back-and-forth'
    alt-cmd-shift-tab = 'move-workspace-to-monitor --wrap-around next'

    # --- Launch apps: fn + key ---
    alt-cmd-b = 'exec-and-forget $HOME/.config/aerospace/launch-app.sh Safari'
    alt-cmd-o = 'exec-and-forget $HOME/.config/aerospace/launch-app.sh Obsidian'
    alt-cmd-t = 'exec-and-forget $HOME/.config/aerospace/launch-app.sh Ghostty'

    # --- Service mode (fn+shift+;) ---
    alt-cmd-shift-semicolon = 'mode service'

[mode.service.binding]
    esc = ['reload-config', 'mode main']
    r = ['flatten-workspace-tree', 'mode main']
    f = ['layout floating tiling', 'mode main']
    backspace = ['close-all-windows-but-current', 'mode main']
    alt-cmd-shift-h = ['join-with left', 'mode main']
    alt-cmd-shift-j = ['join-with down', 'mode main']
    alt-cmd-shift-k = ['join-with up', 'mode main']
    alt-cmd-shift-l = ['join-with right', 'mode main']
```

### Launch Scripts

Create `~/.config/aerospace/` and save these scripts. `chmod +x` each one.

#### launch-app.sh
Generic launcher — takes an app name as `$1`. Opens a new window if the app is already running (activates it first so the menu click works even cross-workspace, then moves the new window back). Falls back to `open -a` if the app isn't running or has no windows.

```bash
#!/bin/bash
# Generic launcher: open a new window if the app is running, otherwise launch it.
# Usage: launch-app.sh <AppName>  (e.g., Safari, Obsidian, Ghostty)
app="$1"
current_ws=$(aerospace list-workspaces --focused)

if pgrep -xi "$app" > /dev/null; then
    window_count=$(osascript -e "tell application \"System Events\" to return count of windows of process \"$app\"" 2>/dev/null)
    if [ "${window_count:-0}" -gt 0 ]; then
        osascript -e "
            tell application \"$app\" to activate
            delay 0.3
            tell application \"System Events\" to tell process \"$app\"
                try
                    click menu item \"New Window\" of menu \"File\" of menu bar 1
                on error
                    click menu item \"New window\" of menu \"File\" of menu bar 1
                end try
            end tell
        "
        sleep 0.5
        aerospace move-node-to-workspace "$current_ws"
        aerospace workspace "$current_ws"
    else
        open -a "$app"
    fi
else
    open -a "$app"
fi
```

#### move-window.sh
```bash
#!/bin/sh
# Move focused window to target workspace.
# If the source workspace is now empty, follow the window.
# Then refresh SketchyBar.
TARGET="$1"
sleep 0.1
if [ -z "$(aerospace list-windows --workspace focused)" ]; then
  aerospace workspace "$TARGET"
fi
AEROSPACE_FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)" \
  $HOME/.config/sketchybar/plugins/aerospace_batch.sh
```

#### close-window.sh
```bash
#!/bin/sh
# After closing a window, if the workspace is now empty, go back to the previous workspace.
# Then refresh SketchyBar.
sleep 0.1
if [ -z "$(aerospace list-windows --workspace focused)" ]; then
  aerospace workspace-back-and-forth
fi
AEROSPACE_FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)" \
  $HOME/.config/sketchybar/plugins/aerospace_batch.sh
```

### Key Shortcuts

All shortcuts use `fn` as the base modifier (mapped via Karabiner-Elements to `cmd+option`, which AeroSpace binds as `alt-cmd-*`). Add `shift` to move instead of focus.

**Navigate**
| Action | Shortcut |
|--------|----------|
| Focus left | `fn + left` |
| Focus down | `fn + down` |
| Focus up | `fn + up` |
| Focus right | `fn + right` |

**Move Windows**
| Action | Shortcut |
|--------|----------|
| Move left | `fn + shift + left` |
| Move down | `fn + shift + down` |
| Move up | `fn + shift + up` |
| Move right | `fn + shift + right` |
| Move to workspace N | `fn + shift + 1-9` |

**Workspaces**
| Action | Shortcut |
|--------|----------|
| Switch to workspace N | `fn + 1-9` |
| Toggle last workspace | `fn + tab` |
| Move workspace to monitor | `fn + shift + tab` |

**Launch Apps**
| Action | Shortcut |
|--------|----------|
| Safari (new window) | `fn + b` |
| Obsidian (new window) | `fn + o` |
| Ghostty (new window) | `fn + t` |

**Layout & Resize**
| Action | Shortcut |
|--------|----------|
| Toggle tiles direction | `fn + /` |
| Toggle accordion | `fn + ,` |
| Close window | `fn + q` |
| Fullscreen | `fn + f` |
| Minimize (auto-leaves empty workspace) | `fn + m` |
| Grow | `fn + =` |
| Shrink | `fn + -` |

**Service Mode** (`fn + shift + ;` to enter)
| Key | Action |
|-----|--------|
| `r` | Reset/flatten layout |
| `f` | Toggle float/tile |
| `backspace` | Close all windows but current |
| `esc` | Exit service mode |

## JankyBorders (Active Window Highlight)

Tokyo Night colored border on the focused window.

### Install
```bash
brew tap FelixKratz/formulae
brew install borders
brew services start felixkratz/formulae/borders
```

### Config

Save to `~/.config/borders/bordersrc` and `chmod +x` it.

```bash
#!/bin/bash

options=(
	style=round
	width=7.0
	hidpi=on
	active_color=0xffc0caf5
	inactive_color=0x00000000
)

borders "${options[@]}"
```

### Notes
- Color `#c0caf5` is Tokyo Night's foreground (muted lavender-white) — visible against dark backgrounds.
- Inactive windows have no border (fully transparent).
- Changes can be applied live without restart: `borders width=6.0 active_color=0xffFF6600`
- Starts at login via `brew services`.

## SketchyBar (Status Bar)

Custom status bar that replaces the macOS menu bar. Shows AeroSpace workspaces, active app, power menu, clock, volume, battery, and F5 VPN status with toggle.

### Install
```bash
brew install sketchybar
brew services start sketchybar
```

### Required Permissions
Grant in **System Settings > Privacy & Security > Accessibility**:
- **SketchyBar** — for bar rendering
- `/usr/bin/osascript` — needed by the VPN toggle click script to interact with BIG-IP Edge Client's status bar menu

### Config
Save to `~/.config/sketchybar/sketchybarrc` and `chmod +x` it.

```bash
PLUGIN_DIR="$CONFIG_DIR/plugins"
FONT="JetBrainsMono Nerd Font Mono"
source "$CONFIG_DIR/colors.sh"

##### Bar Appearance #####
sketchybar --bar position=top \
                 height=32 \
                 color=$BAR_COLOR \
                 blur_radius=0 \
                 shadow=off \
                 sticky=on \
                 topmost=on

##### Changing Defaults #####
default=(
  padding_left=5
  padding_right=5
  icon.font="$FONT:Bold:20.0"
  label.font="$FONT:Regular:13.0"
  icon.color=$ICON_COLOR
  label.color=$LABEL_COLOR
  icon.padding_left=4
  icon.padding_right=4
  label.padding_left=4
  label.padding_right=4
)
sketchybar --default "${default[@]}"

##### AeroSpace Workspace Indicators #####
for sid in 1 2 3 4 5; do
  sketchybar --add item workspace."$sid" left \
             --set workspace."$sid" \
                   icon="$sid" \
                   icon.font="$FONT:Bold:14.0" \
                   icon.color=$DIM \
                   icon.highlight_color=$ICON_COLOR \
                   icon.padding_left=8 \
                   icon.padding_right=2 \
                   label.font="sketchybar-app-font:Regular:14.0" \
                   label.color=$HIGHLIGHT \
                   label.highlight_color=$ICON_COLOR \
                   label.y_offset=1 \
                   background.color=$HIGHLIGHT \
                   background.corner_radius=5 \
                   background.height=22 \
                   background.drawing=off \
                   script="$PLUGIN_DIR/aerospace.sh" \
                   click_script="aerospace workspace $sid"
done
sketchybar --subscribe workspace.1 front_app_switched

##### Front App #####
sketchybar --add item front_app left \
           --set front_app icon.drawing=off \
                           label.color=$ICON_COLOR \
                           script="$PLUGIN_DIR/front_app.sh" \
           --subscribe front_app front_app_switched

##### Right Items #####
sketchybar --add item power right \
           --set power icon="⏻" \
                       icon.color=$HIGHLIGHT \
                       label.drawing=off \
                       click_script="$PLUGIN_DIR/power.sh" \
           --add item clock right \
           --set clock update_freq=10 \
                       icon= \
                       icon.color=$HIGHLIGHT \
                       script="$PLUGIN_DIR/clock.sh" \
           --add item volume right \
           --set volume icon.color=$HIGHLIGHT \
                        script="$PLUGIN_DIR/volume.sh" \
           --subscribe volume volume_change \
           --add item battery right \
           --set battery update_freq=120 \
                         icon.color=$HIGHLIGHT \
                         script="$PLUGIN_DIR/battery.sh" \
           --subscribe battery system_woke power_source_change \
           --add item screenshot right \
           --set screenshot icon="󰄀" \
                            icon.color=$HIGHLIGHT \
                            label.drawing=off \
                            click_script="open -a Screenshot" \
           --add item vpn right \
           --set vpn update_freq=5 \
                     icon="󰌿" \
                     icon.color=$DIM \
                     label.drawing=on \
                     script="$PLUGIN_DIR/vpn.sh" \
                     click_script="$PLUGIN_DIR/vpn_click.sh"

##### Force all scripts to run the first time #####
sketchybar --update
```

### Colors

Save to `~/.config/sketchybar/colors.sh`. Sourced by `sketchybarrc` and plugin scripts.

```sh
#!/bin/sh
# Tokyo Night Storm palette for SketchyBar
BAR_COLOR=0xff24283b
ICON_COLOR=0xffc0caf5
LABEL_COLOR=0xffc0caf5
HIGHLIGHT=0xff7aa2f7
DIM=0xff565f89
```

### Plugin Scripts

Create `~/.config/sketchybar/plugins/` and save these scripts. `chmod +x` each one.

#### icon_map.sh
Download from [sketchybar-app-font releases](https://github.com/kvndrsslr/sketchybar-app-font/releases) — maps app names to ligature strings for the icon font.

#### aerospace_batch.sh
```bash
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
```

#### aerospace.sh
```bash
#!/bin/bash

source "$CONFIG_DIR/plugins/icon_map.sh"

# If triggered by front_app_switched, do a full batch update
if [ "$SENDER" = "front_app_switched" ]; then
  AEROSPACE_FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)" \
    "$CONFIG_DIR/plugins/aerospace_batch.sh"
  exit 0
fi

# Per-item update (initial load via sketchybar --update)
SID="${NAME##*.}"
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
NON_EMPTY="$(aerospace list-workspaces --monitor all --empty no)"

APPS=""
while IFS= read -r app; do
  [ -z "$app" ] && continue
  __icon_map "$app"
  APPS+="${icon_result} "
done < <(aerospace list-windows --workspace "$SID" --format '%{app-name}' 2>/dev/null | sort -u)

if echo "$NON_EMPTY" | grep -qx "$SID"; then
  if [ "$FOCUSED" = "$SID" ]; then
    sketchybar --set "$NAME" drawing=on icon.highlight=on label.highlight=on background.drawing=on label="$APPS"
  else
    sketchybar --set "$NAME" drawing=on icon.highlight=off label.highlight=off background.drawing=off label="$APPS"
  fi
else
  sketchybar --set "$NAME" drawing=off
fi
```

#### front_app.sh
```bash
#!/bin/sh

# Some events send additional information specific to the event in the $INFO
# variable. E.g. the front_app_switched event sends the name of the newly
# focused application in the $INFO variable:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

if [ "$SENDER" = "front_app_switched" ]; then
  sketchybar --set "$NAME" label="$INFO"
fi
```

#### clock.sh
```bash
#!/bin/sh

# The $NAME variable is passed from sketchybar and holds the name of
# the item invoking this script:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

sketchybar --set "$NAME" label="$(date '+%a %b %-d %-I:%M %p')"
```

#### volume.sh
```bash
#!/bin/sh

# The volume_change event supplies a $INFO variable in which the current volume
# percentage is passed to the script.

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"

  case "$VOLUME" in
    [6-9][0-9]|100) ICON="󰕾"
    ;;
    [3-5][0-9]) ICON="󰖀"
    ;;
    [1-9]|[1-2][0-9]) ICON="󰕿"
    ;;
    *) ICON="󰖁"
  esac

  sketchybar --set "$NAME" icon="$ICON" label="$VOLUME%"
fi
```

#### battery.sh
```bash
#!/bin/bash

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

case "${PERCENTAGE}" in
  9[0-9]|100) ICON=""
  ;;
  [6-8][0-9]) ICON=""
  ;;
  [3-5][0-9]) ICON=""
  ;;
  [1-2][0-9]) ICON=""
  ;;
  *) ICON=""
esac

if [[ "$CHARGING" != "" ]]; then
  ICON=""
fi

# The item invoking this script (name $NAME) will get its icon and label
# updated with the current battery status
sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%"
```

#### power.sh
```bash
#!/bin/bash
source "$CONFIG_DIR/colors.sh"

# Highlight the power icon while the menu is open
sketchybar --set power icon.color=$ICON_COLOR \
                       background.drawing=on \
                       background.color=$HIGHLIGHT \
                       background.corner_radius=5 \
                       background.height=22

# Launch native power menu window
rm -f /tmp/.sketchybar_power_choice
"$CONFIG_DIR/plugins/power-menu"
choice=$(cat /tmp/.sketchybar_power_choice 2>/dev/null)
rm -f /tmp/.sketchybar_power_choice

# Revert highlight
sketchybar --set power icon.color=$HIGHLIGHT \
                       background.drawing=off

case "$choice" in
  "Shut Down")   osascript -e 'tell application "System Events" to shut down' ;;
  "Restart")     osascript -e 'tell application "System Events" to restart' ;;
  "Sleep")       pmset sleepnow ;;
  "Lock Screen") osascript -e 'tell application "System Events" to key code 12 using {control down, command down}' ;;
  "Log Out")     osascript -e 'tell application "System Events" to log out' ;;
esac
```

#### power_menu.swift
The native Swift GUI for the power menu. Build with:
```bash
swiftc -o power-menu power_menu.swift
```

```swift
import AppKit

class PowerMenu: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    let actions = ["Lock Screen", "Sleep", "Restart", "Shut Down", "Log Out"]

    func applicationDidFinishLaunching(_ notification: Notification) {
        let width: CGFloat = 180
        let buttonHeight: CGFloat = 28
        let padding: CGFloat = 12
        let spacing: CGFloat = 6
        let height = padding * 2 + buttonHeight * CGFloat(actions.count) + spacing * CGFloat(actions.count - 1)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Power"
        window.center()
        window.delegate = self
        window.isReleasedWhenClosed = false

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        for (i, action) in actions.enumerated() {
            let y = height - padding - buttonHeight - CGFloat(i) * (buttonHeight + spacing)
            let button = NSButton(frame: NSRect(x: padding, y: y, width: width - padding * 2, height: buttonHeight))
            button.title = action
            button.bezelStyle = .rounded
            button.target = self
            button.action = #selector(buttonClicked(_:))
            contentView.addSubview(button)
        }

        window.contentView = contentView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func buttonClicked(_ sender: NSButton) {
        try? sender.title.write(toFile: "/tmp/.sketchybar_power_choice", atomically: true, encoding: .utf8)
        NSApp.terminate(nil)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = PowerMenu()
app.delegate = delegate
app.run()
```

#### vpn.sh
```bash
#!/bin/bash
source "$CONFIG_DIR/colors.sh"

# F5 BIG-IP Edge Client: svpn daemon runs when tunnel is active
if pgrep -x svpn > /dev/null 2>&1; then
  sketchybar --set "$NAME" icon="󰌾" icon.color=$HIGHLIGHT label="VPN" label.color=$HIGHLIGHT
else
  sketchybar --set "$NAME" icon="󰌿" icon.color=$DIM label="" label.color=$DIM
fi
```

#### vpn_click.sh
```bash
#!/bin/bash

# Toggle F5 BIG-IP Edge Client VPN via its status bar menu

APP="BIG-IP Edge Client"

# Ensure the app is running
if ! pgrep -f "$APP" > /dev/null 2>&1; then
  open -a "$APP"
  sleep 2
fi

if pgrep -x svpn > /dev/null 2>&1; then
  # VPN is connected — click Disconnect
  osascript -e "
    tell application \"System Events\"
      tell process \"$APP\"
        click menu bar item 1 of menu bar 2
        delay 0.3
        click menu item \"Disconnect\" of menu 1 of menu bar item 1 of menu bar 2
      end tell
    end tell"
else
  # VPN is disconnected — click Connect
  osascript -e "
    tell application \"System Events\"
      tell process \"$APP\"
        click menu bar item 1 of menu bar 2
        delay 0.3
        click menu item \"Connect\" of menu 1 of menu bar item 1 of menu bar 2
      end tell
    end tell"
fi
```

### Notes
- Tokyo Night Storm theme throughout — matches Ghostty, Starship, JankyBorders.
- `topmost=on` renders SketchyBar above the macOS menu bar (see macOS Settings section for auto-hide fallback).
- Power item (⏻) opens a picker dialog with Shut Down, Restart, Sleep, Lock Screen, and Log Out.
- Screenshot item opens the macOS Screenshot toolbar (`Cmd+Shift+5`) on click.
- VPN item polls every 5 seconds for the `svpn` process (F5 BIG-IP Edge Client). Clicking toggles connect/disconnect.
- Workspace indicators only show non-empty workspaces; the focused one gets a highlighted background.
- Starts at login via `brew services`.

## Terminal (Ghostty)

### Install
```bash
brew install --cask ghostty
```

### Config
Save to `~/.config/ghostty/config`:
```
theme = TokyoNight Storm
font-family = JetBrainsMono Nerd Font Mono
font-size = 14

window-padding-x = 10
window-padding-y = 10

background-opacity = 1

cursor-style = block
cursor-style-blink = false

copy-on-select = clipboard

minimum-contrast = 1

macos-titlebar-style = tabs
window-theme = auto

split-divider-color = #7aa2f7
unfocused-split-fill = #1a1b26
unfocused-split-opacity = 0.85

keybind = ctrl+q=close_surface
```

### Key Bindings

| Shortcut | Action |
|----------|--------|
| `ctrl + q` | Close surface (tab/split/window) |

## Shell (Zsh)

### Install
```bash
brew install starship
brew install eza
brew install fzf
brew install zsh-autosuggestions
brew install zsh-syntax-highlighting
brew install --cask font-jetbrains-mono-nerd-font
```

### Global setup

Everything is configured globally — no per-user `.zshrc` or `.zprofile` needed. Use those only for per-user overrides.

```bash
# Root's default shell is /bin/sh — change to zsh so /etc/zshrc is loaded
sudo chsh -s /bin/zsh root
```

Append to `/etc/zprofile`:
```bash
# Homebrew (global)
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Tokyo Night theme for eza:
```bash
sudo mkdir -p /etc/eza
sudo curl -sL https://raw.githubusercontent.com/eza-community/eza-themes/main/themes/tokyonight.yml -o /etc/eza/theme.yml
```

Append to `/etc/zshrc`:
```bash
# Disable Claude Code auto-update nag (managed via Homebrew)
export DISABLE_AUTOUPDATER=1
# eza config (global — theme at /etc/eza/theme.yml)
[[ ! -d ~/.config/eza ]] && export EZA_CONFIG_DIR=/etc/eza

# eza aliases
alias ls='eza --icons --group --links --blocksize'
alias ll='eza -la --icons --group --links'

# Yazi file manager
alias browse='yazi'

# Starship prompt (global — per-user ~/.config/starship.toml overrides)
[[ ! -f ~/.config/starship.toml ]] && export STARSHIP_CONFIG=/etc/starship.toml
eval "$(starship init zsh)"

# Plugins (guard autosuggestions — async PTY conflicts with sudo su)
if [[ -o login || -z "$SUDO_USER" ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# fzf
source <(fzf --zsh)
```

### /etc/starship.toml

Save with `sudo tee /etc/starship.toml`. Tokyo Night themed single-line prompt with OS icon, directory, git info, language versions, and command duration. Per-user override: `~/.config/starship.toml`.

```toml
"$schema" = 'https://starship.rs/config-schema.json'

format = """$os\
$directory\
$git_branch\
$git_status\
$character"""

palette = 'tokyo_night'

[os]
disabled = false
format = '[$symbol](fg:comment) '

[os.symbols]
Macos = ""

[directory]
style = "fg:foreground"
format = '[$path]($style) '
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = ""
style = "fg:comment"
format = '[$symbol $branch]($style) '

[git_status]
style = "fg:orange"
format = '[$all_status$ahead_behind]($style)'

[fill]
symbol = ' '

[nodejs]
symbol = ""
style = "fg:green"
format = 'via [$symbol $version]($style) '

[c]
symbol = ""
style = "fg:blue"
format = 'via [$symbol $version]($style) '

[rust]
symbol = ""
style = "fg:orange"
format = 'via [$symbol $version]($style) '

[golang]
symbol = ""
style = "fg:cyan"
format = 'via [$symbol $version]($style) '

[php]
symbol = ""
style = "fg:purple"
format = 'via [$symbol $version]($style) '

[java]
symbol = ""
style = "fg:red"
format = 'via [$symbol $version]($style) '

[kotlin]
symbol = ""
style = "fg:purple"
format = 'via [$symbol $version]($style) '

[haskell]
symbol = ""
style = "fg:purple"
format = 'via [$symbol $version]($style) '

[python]
symbol = ""
style = "fg:yellow"
format = 'via [$symbol $version(\($virtualenv\))]($style) '

[conda]
symbol = "󱔎"
style = "fg:green"
format = 'via [$symbol $environment]($style) '
ignore_base = false

[docker_context]
symbol = ""
style = "fg:cyan"
format = 'via [$symbol $context]($style) '

[cmd_duration]
show_milliseconds = false
format = '[took $duration](fg:comment) '
min_time = 2000

[character]
success_symbol = '[❯](fg:green)'
error_symbol = '[❯](fg:red)'
vimcmd_symbol = '[❮](bold fg:green)'
vimcmd_replace_one_symbol = '[❮](bold fg:purple)'
vimcmd_replace_symbol = '[❮](bold fg:purple)'
vimcmd_visual_symbol = '[❮](bold fg:yellow)'

[palettes.tokyo_night]
foreground = "#c0caf5"
comment = "#565f89"
red = "#f7768e"
orange = "#ff9e64"
yellow = "#e0af68"
green = "#9ece6a"
cyan = "#2ac3de"
blue = "#7aa2f7"
purple = "#bb9af7"
magenta = "#ff007c"
```

## Obsidian

### Install
```bash
brew install --cask obsidian
```

### Theme
Settings > Appearance > Themes > Manage > search **"Tokyo Night"** (by tcmmichaelb139) > install and activate.

## Yazi (Terminal File Manager)

### Install
```bash
brew install yazi
```

### Theme
```bash
git clone https://github.com/BennyOe/tokyo-night.yazi.git ~/.config/yazi/flavors/tokyo-night.yazi
```

Save to `~/.config/yazi/theme.toml`:
```toml
[flavor]
dark = "tokyo-night"
```

### Keymap
Save to `~/.config/yazi/keymap.toml`:
```toml
[[mgr.prepend_keymap]]
on = ["S"]
run = 'shell "$SHELL" --block'
desc = "Open shell here"
```

## Citrix Workspace

### Install
```bash
brew install --cask citrix-workspace
brew install duti
```

### Use Citrix Viewer for .ica files
By default, `.ica` files open the full Workspace app (self-service storefront UI). Point them at the embedded Viewer instead so only the session window launches:

```bash
duti -s com.citrix.receiver.icaviewer.mac .ica all
```

## Git

### Config
Save to `~/.gitconfig`:
```ini
[user]
	name = Nyber
	email = null@null.com
[init]
	defaultBranch = main
[pull]
	rebase = true
```

## GitHub CLI

### Install
```bash
brew install gh
gh auth login
```

### Config
Save to `~/.config/gh/config.yml`:
```yaml
version: 1
git_protocol: https
prompt: enabled
prefer_editor_prompt: disabled
aliases:
    co: pr checkout
color_labels: disabled
spinner: enabled
```

## Claude Code

### Install
```bash
brew install --cask claude-code
```

## macOS Settings

### Passwordless sudo
```bash
echo "wyoung5 ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/wyoung5
sudo chmod 0440 /etc/sudoers.d/wyoung5
```
Drop-in file at `/etc/sudoers.d/wyoung5` — survives macOS updates to the main sudoers file.

### Display sleep
```bash
sudo pmset -a displaysleep 15
```

### Finder
```bash
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
killall Finder
```
Shows hidden files, all extensions, path bar, status bar, list view by default, full POSIX path in title, folders sorted first, and searches the current folder instead of "This Mac".

### Dark mode
```bash
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
```

### Always show scrollbars
```bash
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
```

### Full keyboard access
Tab moves focus to all UI controls, not just text fields and lists.
```bash
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2
```

### Fast key repeat
Faster than System Preferences allows.
```bash
defaults write com.apple.Accessibility KeyRepeatInterval -float 0.083333333
defaults write com.apple.Accessibility KeyRepeatDelay -float 0.5
defaults write com.apple.Accessibility KeyRepeatEnabled -bool true
```

### Dock
Auto-hide, small icons, strip all persistent apps, hide recents, Quick Note hot corner (bottom-right).
```bash
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 43
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock persistent-others -array
defaults write com.apple.dock wvous-br-corner -int 14
defaults write com.apple.dock wvous-br-modifier -int 0
killall Dock
```

### Disable close/quit confirmations
```bash
defaults write NSGlobalDomain NSCloseAlwaysConfirmsChanges -bool false
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
```

### Login screen
Show name/password fields instead of user list (hides user accounts):
```bash
sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true
```

Profile picture (penguin for both accounts):
```bash
# Convert to JPEG (dsimport needs JPEG, not HEIC)
sips -s format jpeg "/Library/User Pictures/Animals/Penguin.heic" --out /tmp/penguin.jpg

# Embed image data via dsimport (dscl Picture path alone doesn't work on modern macOS)
printf '0x0A 0x5C 0x3A 0x2C dsRecTypeStandard:Users 2 dsAttrTypeStandard:RecordName externalbinary:dsAttrTypeStandard:JPEGPhoto\nwyoung5:/tmp/penguin.jpg\n' > /tmp/wyoung5_pic.dsimport
sudo dsimport /tmp/wyoung5_pic.dsimport /Local/Default M

printf '0x0A 0x5C 0x3A 0x2C dsRecTypeStandard:Users 2 dsAttrTypeStandard:RecordName externalbinary:dsAttrTypeStandard:JPEGPhoto\nwyoung:/tmp/penguin.jpg\n' > /tmp/wyoung_pic.dsimport
sudo dsimport /tmp/wyoung_pic.dsimport /Local/Default M
```

### macOS menu bar (hidden — replaced by SketchyBar)
SketchyBar replaces the macOS menu bar. Set `topmost=on` (not `topmost=window`) in `~/.config/sketchybar/sketchybarrc` so it renders above the system menu bar.

Auto-hide the macOS menu bar as a fallback:
```bash
defaults write com.apple.WindowManager AutoHideMenuBar -int 3
killall Dock
```
Note: `_HIHideMenuBar` no longer fully works on macOS 26. The `topmost=on` setting is what actually covers it.

