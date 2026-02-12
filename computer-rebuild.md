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

exec-on-workspace-change = ['/bin/bash', '-c', '$HOME/.config/aerospace/workspace-changed.sh']

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
    alt-cmd-m     = 'exec-and-forget $HOME/.config/aerospace/minimize-window.sh'
    alt-cmd-q     = ['close --quit-if-last-window', 'exec-and-forget $HOME/.config/aerospace/close-window.sh']

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
    alt-cmd-shift-1 = ['move-node-to-workspace 1', 'exec-and-forget $HOME/.config/aerospace/move-window.sh 1']
    alt-cmd-shift-2 = ['move-node-to-workspace 2', 'exec-and-forget $HOME/.config/aerospace/move-window.sh 2']
    alt-cmd-shift-3 = ['move-node-to-workspace 3', 'exec-and-forget $HOME/.config/aerospace/move-window.sh 3']
    alt-cmd-shift-4 = ['move-node-to-workspace 4', 'exec-and-forget $HOME/.config/aerospace/move-window.sh 4']
    alt-cmd-shift-5 = ['move-node-to-workspace 5', 'exec-and-forget $HOME/.config/aerospace/move-window.sh 5']
    alt-cmd-shift-6 = ['move-node-to-workspace 6', 'exec-and-forget $HOME/.config/aerospace/move-window.sh 6']
    alt-cmd-shift-7 = ['move-node-to-workspace 7', 'exec-and-forget $HOME/.config/aerospace/move-window.sh 7']
    alt-cmd-shift-8 = ['move-node-to-workspace 8', 'exec-and-forget $HOME/.config/aerospace/move-window.sh 8']
    alt-cmd-shift-9 = ['move-node-to-workspace 9', 'exec-and-forget $HOME/.config/aerospace/move-window.sh 9']

    # --- Quick switch ---
    alt-cmd-tab = 'workspace-back-and-forth'
    alt-cmd-shift-tab = 'move-workspace-to-monitor --wrap-around next'

    # --- Launch apps: fn + key ---
    alt-cmd-b = 'exec-and-forget $HOME/.config/aerospace/launch-app.sh Safari'
    alt-cmd-o = 'exec-and-forget $HOME/.config/aerospace/launch-app.sh Obsidian'
    alt-cmd-s = 'exec-and-forget $HOME/.config/aerospace/launch-app.sh Signal'
    alt-cmd-t = 'exec-and-forget $HOME/.config/aerospace/launch-app.sh Ghostty'
    alt-cmd-z = 'exec-and-forget $HOME/.config/aerospace/launch-app.sh zoom.us'

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
#!/bin/sh
# Generic launcher: open a new window if the app is running, otherwise launch it.
# Usage: launch-app.sh <AppName>  (e.g., Safari, Obsidian, Ghostty)
app="$1"
[ -z "$app" ] && exit 1
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
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)"
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
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)"
```

#### minimize-window.sh
Minimizes the focused window via `fn+m`. Writes the `.minimized` tracking file directly (guaranteed workspace capture) and wakes the daemon from slow sleep. Handles the empty-workspace auto-switch.

```bash
#!/bin/sh
# Minimize the focused window via fn+m. Writes the .minimized tracking file
# directly (guaranteed workspace capture) and wakes the daemon from slow sleep.

MDIR="$HOME/.config/aerospace"
WINDOW_ID=$(aerospace list-windows --focused --format '%{window-id}')

if [ -z "$WINDOW_ID" ]; then
  exit 0
fi

WORKSPACE=$(aerospace list-workspaces --focused)

aerospace macos-native-minimize --window-id "$WINDOW_ID"

# Write tracking file AFTER minimize to avoid false-restore race condition
echo "$WORKSPACE" > "$MDIR/.minimized-$WINDOW_ID"

# Wake daemon from slow sleep
PIDFILE="$MDIR/.minimize-daemon.pid"
if [ -f "$PIDFILE" ]; then
  kill -USR1 "$(cat "$PIDFILE")" 2>/dev/null
fi

# If workspace is now empty, switch away
sleep 0.1
if [ -z "$(aerospace list-windows --workspace focused)" ]; then
  aerospace workspace-back-and-forth
fi

sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)"
```

#### minimize-daemon.sh
Persistent background daemon managed by a LaunchAgent (`KeepAlive` ensures auto-restart). Adaptive polling: 2s when tracking minimized windows, 15s when idle. `minimize-window.sh` sends USR1 to wake from slow sleep immediately. Uses a single `awk` pass for efficient window-diff detection instead of per-line grep. Triggers a lightweight `badge_check` event only when the window list changes (badge colors only, no full icon rebuild).

```bash
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
trap 'rm -f "$PREV_FILE" "$PREV_FILE.new" "$CURR_FILE" "$PIDFILE"' EXIT
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

  # Save curr as prev, triggering badge check only if window list changed
  grep -v NULL "$CURR_FILE" > "$PREV_FILE.new"
  if ! cmp -s "$PREV_FILE" "$PREV_FILE.new"; then
    sketchybar --trigger badge_check
  fi
  mv "$PREV_FILE.new" "$PREV_FILE"

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
```

#### workspace-changed.sh
Called by `exec-on-workspace-change`. Updates SketchyBar and hides the Zoom app when switching away from its workspace. Zoom creates a persistent floating video overlay (CGWindow layer 3) that's visible on all workspaces — hiding the app suppresses it. Zoom stays running and still receives calls/messages via macOS notifications.

```bash
#!/bin/sh
# Called by AeroSpace on workspace change.
# 1. Updates SketchyBar
# 2. Hides Zoom when leaving its workspace, unhides when arriving

sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$AEROSPACE_FOCUSED_WORKSPACE"

# Hide/unhide Zoom based on whether it's on the focused workspace
if pgrep -xq "zoom.us"; then
    case "$(aerospace list-windows --workspace "$AEROSPACE_FOCUSED_WORKSPACE" --format '%{app-name}' 2>/dev/null)" in
        *zoom.us*) vis=true ;; *) vis=false ;;
    esac
    osascript -e "tell application \"System Events\" to set visible of process \"zoom.us\" to $vis" 2>/dev/null
fi
```

### LaunchAgent

The minimize daemon runs as a LaunchAgent so it starts at login and auto-restarts if it dies. The plist is symlinked from dotfiles to `~/Library/LaunchAgents/`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.aerospace.minimize-daemon</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>exec $HOME/.config/aerospace/minimize-daemon.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/dev/null</string>
    <key>StandardErrorPath</key>
    <string>/dev/null</string>
</dict>
</plist>
```

To load manually (install.sh handles this via symlink):
```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.aerospace.minimize-daemon.plist
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
| Signal | `fn + s` |
| Ghostty (new window) | `fn + t` |
| Zoom | `fn + z` |

**Layout & Resize**
| Action | Shortcut |
|--------|----------|
| Toggle tiles direction | `fn + /` |
| Toggle accordion | `fn + ,` |
| Quit app | `fn + q` |
| Fullscreen | `fn + f` |
| Minimize (restores to original workspace) | `fn + m` |
| Grow | `fn + =` |
| Shrink | `fn + -` |

**Service Mode** (`fn + shift + ;` to enter)
| Key | Action |
|-----|--------|
| `r` | Reset/flatten layout |
| `f` | Toggle float/tile |
| `backspace` | Close all windows but current |
| `fn + shift + h` | Join with left |
| `fn + shift + j` | Join with down |
| `fn + shift + k` | Join with up |
| `fn + shift + l` | Join with right |
| `esc` | Reload config & exit service mode |

## Karabiner-Elements (Key Remapping)

Maps `fn+key` to `cmd+option+key` so AeroSpace can use the `fn` key as its modifier while `ctrl` stays free for apps.

### Install
```bash
brew install --cask karabiner-elements
```

### Required Permissions
Grant in **System Settings > Privacy & Security**:
- **Input Monitoring** — toggle on Karabiner-Elements and karabiner_grabber
- **Accessibility** — toggle on karabiner_grabber

### Config
Config lives at `~/.config/karabiner/karabiner.json` (symlinked from dotfiles). It contains one rule: every key in the AeroSpace binding set gets `fn+key → cmd+option+key`.

The config is generated by `~/.config/karabiner/generate-config.sh`. If you add new AeroSpace bindings, edit the `KEYS` array in that script and re-run it:
```bash
bash ~/.config/karabiner/generate-config.sh
```

### Notes
- Karabiner only intercepts `fn+key` combos — tapping fn alone still reaches macOS, so the emoji picker works.
- The fn emoji picker is explicitly enabled: `defaults write com.apple.HIToolbox AppleFnUsageType -int 2`
- The `"optional": ["any"]` modifier allows `fn+shift+key` combos to pass through as `cmd+option+shift+key` (used for AeroSpace move bindings).
- Menu bar icon is hidden via `"show_in_menu_bar": false` in the config.

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

Custom status bar that replaces the macOS menu bar. Uses **SbarLua** for Lua-based configuration. Shows AeroSpace workspaces with app icons, menus toggle, front app, media controls, calendar, volume (with audio device switching), battery, screenshot, and VPN toggle.

### Install
```bash
brew install sketchybar lua
brew services start sketchybar
```

### SbarLua (Lua bindings for SketchyBar)
SketchyBar's Lua API requires the SbarLua shared library. Install it:
```bash
(git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua && make install && rm -rf /tmp/SbarLua)
```
This installs `sketchybar.so` to `~/.local/share/sketchybar_lua/`.

### Required Permissions
Grant in **System Settings > Privacy & Security > Accessibility**:
- **SketchyBar** — for bar rendering
- `/usr/bin/osascript` — needed by the VPN toggle click script to interact with BIG-IP Edge Client's status bar menu

### Config

The entire config lives in `~/.config/sketchybar/` (symlinked from dotfiles). The entrypoint is `sketchybarrc` which loads the Lua modules.

```
~/.config/sketchybar/
sketchybarrc          # Entrypoint (loads helpers + init.lua)
init.lua              # Loads bar, defaults, items; starts event loop
bar.lua               # Bar appearance (height, color, topmost)
colors.lua            # Tokyo Night Storm palette
default.lua           # Default item styling
icons.lua             # SF Symbols + NerdFont icon maps
settings.lua          # Font, padding, icon set selection
items/
  init.lua            # Loads all items
  apple.lua           # Apple menu popup (About, Applications, App Store, power controls)
  menus.lua           # App menu items (swap with spaces on click)
  spaces.lua          # AeroSpace workspace indicators with app icons + badge attention
  front_app.lua       # Active app name
  calendar.lua        # Date/time
  media.lua           # Now playing (Spotify/Music)
  widgets/
    init.lua          # Loads all widget modules
    battery.lua       # Battery % with remaining time popup
    volume.lua        # Volume with slider popup + audio device picker
    screenshot.lua    # Screenshot toolbar launcher
    vpn.lua           # F5 BIG-IP Edge Client toggle
helpers/
  init.lua            # Loads SbarLua module + builds C helpers
  makefile            # Builds C helpers
  .gitignore          # Ignores compiled binaries
  app_icons.lua       # App name to sketchybar-app-font icon map
  vpn_toggle.sh       # VPN connect/disconnect via osascript
  menus/              # Native menu bar access (C)
    makefile
    menus.c
```

### Building C helpers
On first run, `helpers/init.lua` runs `make` in the `helpers/` directory to compile the `menus` C helper. This requires Xcode Command Line Tools.

### Notes
- Tokyo Night Storm theme throughout — matches Ghostty, Starship, JankyBorders.
- `topmost=on` renders SketchyBar above the macOS menu bar (see macOS Settings section for auto-hide fallback).
- AeroSpace integration uses `sketchybar --trigger aerospace_workspace_change` events (not shell plugin scripts).
- Workspace indicators show app icons via `sketchybar-app-font`; only non-empty or focused workspaces are visible. Apps with dock badges (non-empty `StatusLabel` via `lsappinfo`) turn their workspace icons red — checked inline in Lua, no shell script.
- The minimize-daemon triggers a lightweight `badge_check` custom event (badge colors only) instead of `space_windows_change` (full icon rebuild).
- Apple icon opens a custom popup menu replacing the native Apple menu — includes About This Mac, Applications (Spotlight Apps view), App Store, Force Quit, Sleep, Restart, Shut Down, Lock Screen, and Log Out.
- Clicking the front app toggles between showing workspace indicators and native app menus.
- Media widget shows now playing info for Spotify/Music with playback controls popup.
- Volume widget includes a slider popup and audio device picker (via `switchaudio-osx`).
- VPN item is event-driven (`network_change`, `vpn_change`, `system_woke`), checking for the `svpn` process (F5 BIG-IP Edge Client). Clicking toggles connect/disconnect.
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
export HOMEBREW_NO_ENV_HINTS=1
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

# Explicit key bindings (fallback if terminfo is missing)
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char
bindkey '^[[3~' delete-char

# Starship prompt (global — per-user ~/.config/starship.toml overrides)
[[ ! -f ~/.config/starship.toml ]] && export STARSHIP_CONFIG=/etc/starship.toml
eval "$(starship init zsh)"

# Plugins (guard — async PTY conflicts with sudo su)
if [[ -o login || -z "$SUDO_USER" ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# fzf
source <(fzf --zsh)
```

### /etc/starship.toml

Save with `sudo tee /etc/starship.toml`. Tokyo Night themed single-line prompt with OS icon, username, directory, git info, and command duration. Per-user override: `~/.config/starship.toml`.

```toml
"$schema" = 'https://starship.rs/config-schema.json'

format = """$os\
$username\
$directory\
$git_branch\
$git_status\
$character"""

palette = 'tokyo_night'
command_timeout = 200

[os]
disabled = false
format = '[$symbol](fg:foreground) '

[os.symbols]
Macos = ""

[username]
show_always = true
format = "[$user]($style) "
style_root = "fg:red bold"
style_user = "fg:foreground"

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

## Wallpaper

Tokyo Night Storm "Apple Retro" — Apple logo with retro color stripes on dark navy background.

- **File**: `~/Pictures/tokyo-night-apple.png` (2560x1440, symlinked from dotfiles)
- **Source**: [tokyo-night/wallpapers](https://github.com/tokyo-night/wallpapers) `storm/os/apple_00_2560x1440.png`

Set automatically by `install.sh`. To set manually:
```bash
osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "'"$HOME/Pictures/tokyo-night-apple.png"'"'
```

Lock screen wallpaper is set separately from the desktop — macOS caches it per-user and updates may reset it. `install.sh` handles this automatically. To fix manually:
```bash
USER_UUID="$(dscl . -read /Users/"$(whoami)" GeneratedUID | awk '{print $2}')"
sudo cp ~/Pictures/tokyo-night-apple.png "/Library/Caches/Desktop Pictures/$USER_UUID/lockscreen.png"
sudo chown "$(whoami):_securityagent" "/Library/Caches/Desktop Pictures/$USER_UUID/lockscreen.png"
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
	email = 4050537+Nyber@users.noreply.github.com
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
editor:
prompt: enabled
prefer_editor_prompt: disabled
pager:
aliases:
    co: pr checkout
http_unix_socket:
browser:
color_labels: disabled
accessible_colors: disabled
accessible_prompter: disabled
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

### Power management (AC power)
```bash
sudo pmset -c sleep 0 displaysleep 0 disksleep 0 standby 0 powernap 0
```
Prevents sleep, display off, disk sleep, standby, and Power Nap when plugged in. Battery defaults are unchanged.

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

### Do Not Disturb (24/7 schedule)
SketchyBar's bell widget reads notifications from the usernoted SQLite DB. Native notification banners are redundant. A 24/7 DND schedule suppresses banners/sounds while keeping the notification storage pipeline intact — `usernoted` still writes to its DB, and the bell widget reads from it normally.

`install.sh` writes the schedule to `~/Library/DoNotDisturb/DB/ModeConfigurations.json` and signals `donotdisturbd` via `SIGHUP`. The schedule persists across reboots with no LaunchAgent needed.

**What's suppressed:** banner popups, notification sounds, lock screen previews.
**What still works:** usernoted DB storage, SketchyBar bell widget, app badge counts, all other system functionality.

**Failed approaches:**
- `launchctl disable com.apple.notificationcenterui.agent` — kills banners but breaks the notification delivery pipeline (notifications stop being stored)
- `shortcuts run` via LaunchAgent — requires a manually-created Shortcut in Shortcuts.app (no programmatic creation: XPC service ignores SQLite inserts, `shortcuts sign` requires iCloud, unsigned `.shortcut` files aren't importable)

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

Profile picture (Apple logo on Tokyo Night background — `~/Pictures/profile.jpg`, symlinked from dotfiles):
```bash
# Embed image data via dsimport (dscl Picture path alone doesn't work on modern macOS)
# install.sh sets this for $(whoami) automatically
CURRENT_USER="$(whoami)"
printf '0x0A 0x5C 0x3A 0x2C dsRecTypeStandard:Users 2 dsAttrTypeStandard:RecordName externalbinary:dsAttrTypeStandard:JPEGPhoto\n%s:%s\n' "$CURRENT_USER" "$HOME/Pictures/profile.jpg" > /tmp/user_pic.dsimport
sudo dsimport /tmp/user_pic.dsimport /Local/Default M
```

### macOS menu bar (hidden — replaced by SketchyBar)
SketchyBar replaces the macOS menu bar. Set `topmost=on` (not `topmost=window`) in `~/.config/sketchybar/sketchybarrc` so it renders above the system menu bar.

Auto-hide the macOS menu bar as a fallback:
```bash
defaults write com.apple.WindowManager AutoHideMenuBar -int 3
killall Dock
```
Note: `_HIHideMenuBar` no longer fully works on macOS 26. The `topmost=on` setting is what actually covers it.

## Manual Steps

Things that require manual intervention after running `install.sh`:

- [ ] Grant **Accessibility** permissions (System Settings > Privacy & Security):
  - AeroSpace
  - SketchyBar
  - `/usr/bin/osascript`
  - karabiner_grabber
- [ ] Grant **Input Monitoring** permission:
  - Karabiner-Elements
  - karabiner_grabber
- [ ] `gh auth login` — authenticate GitHub CLI
- [ ] Install Obsidian Tokyo Night theme: Settings > Appearance > Themes > Manage > search "Tokyo Night" > install and activate
- [ ] Log out/restart for macOS settings to take effect (login screen, Dock, Finder)
