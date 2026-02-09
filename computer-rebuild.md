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

exec-on-workspace-change = ['/bin/bash', '-c', 'sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE']

[key-mapping]
    preset = 'qwerty'

# 5px gaps between windows only, no edge padding
[gaps]
    inner.horizontal = 5
    inner.vertical =   5
    outer.left =       0
    outer.bottom =     0
    outer.top =        0
    outer.right =      0

[mode.main.binding]

    # --- Move windows: ctrl + shift + arrows ---
    ctrl-shift-left  = 'move left'
    ctrl-shift-down  = 'move down'
    ctrl-shift-up    = 'move up'
    ctrl-shift-right = 'move right'

    # --- Focus (navigate): ctrl + arrows ---
    ctrl-left  = 'focus left'
    ctrl-down  = 'focus down'
    ctrl-up    = 'focus up'
    ctrl-right = 'focus right'

    # --- Layout ---
    ctrl-slash = 'layout tiles horizontal vertical'
    ctrl-comma = 'layout accordion horizontal vertical'
    ctrl-f     = 'fullscreen'
    ctrl-m     = 'macos-native-minimize'
    ctrl-q     = 'close'

    # --- Resize ---
    ctrl-equal = 'resize smart +50'
    ctrl-minus = 'resize smart -50'

    # --- Workspaces: ctrl + number (like macOS ctrl+1/2/3 for Spaces) ---
    ctrl-1 = 'workspace 1'
    ctrl-2 = 'workspace 2'
    ctrl-3 = 'workspace 3'
    ctrl-4 = 'workspace 4'
    ctrl-5 = 'workspace 5'
    ctrl-6 = 'workspace 6'
    ctrl-7 = 'workspace 7'
    ctrl-8 = 'workspace 8'
    ctrl-9 = 'workspace 9'

    # --- Move window to workspace: ctrl + shift + number ---
    ctrl-shift-1 = ['move-node-to-workspace 1', 'exec-and-forget ~/.config/aerospace/move-window.sh 1']
    ctrl-shift-2 = ['move-node-to-workspace 2', 'exec-and-forget ~/.config/aerospace/move-window.sh 2']
    ctrl-shift-3 = ['move-node-to-workspace 3', 'exec-and-forget ~/.config/aerospace/move-window.sh 3']
    ctrl-shift-4 = ['move-node-to-workspace 4', 'exec-and-forget ~/.config/aerospace/move-window.sh 4']
    ctrl-shift-5 = ['move-node-to-workspace 5', 'exec-and-forget ~/.config/aerospace/move-window.sh 5']
    ctrl-shift-6 = ['move-node-to-workspace 6', 'exec-and-forget ~/.config/aerospace/move-window.sh 6']
    ctrl-shift-7 = ['move-node-to-workspace 7', 'exec-and-forget ~/.config/aerospace/move-window.sh 7']
    ctrl-shift-8 = ['move-node-to-workspace 8', 'exec-and-forget ~/.config/aerospace/move-window.sh 8']
    ctrl-shift-9 = ['move-node-to-workspace 9', 'exec-and-forget ~/.config/aerospace/move-window.sh 9']

    # --- Quick switch ---
    ctrl-tab = 'workspace-back-and-forth'
    ctrl-shift-tab = 'move-workspace-to-monitor --wrap-around next'

    # --- Launch apps: ctrl + key ---
    ctrl-b = 'exec-and-forget /Users/wyoung5/.config/aerospace/launch-safari.sh'
    ctrl-o = 'exec-and-forget /Users/wyoung5/.config/aerospace/launch-obsidian.sh'
    ctrl-t = 'exec-and-forget /Users/wyoung5/.config/aerospace/launch-terminal.sh'

    # --- Service mode (ctrl+shift+;) ---
    ctrl-shift-semicolon = 'mode service'

[mode.service.binding]
    esc = ['reload-config', 'mode main']
    r = ['flatten-workspace-tree', 'mode main']
    f = ['layout floating tiling', 'mode main']
    backspace = ['close-all-windows-but-current', 'mode main']
    ctrl-shift-h = ['join-with left', 'mode main']
    ctrl-shift-j = ['join-with down', 'mode main']
    ctrl-shift-k = ['join-with up', 'mode main']
    ctrl-shift-l = ['join-with right', 'mode main']
```

### Launch Scripts

Create `~/.config/aerospace/` and save these scripts. `chmod +x` each one.

#### launch-safari.sh
```bash
#!/bin/bash
# Always open a new Safari window on the current workspace
if pgrep -x Safari > /dev/null; then
    osascript -e 'tell application "Safari" to make new document'
fi
osascript -e 'tell application "Safari" to activate'
```

#### launch-terminal.sh
```bash
#!/bin/bash
# Always open a new Ghostty window on the current workspace
if pgrep -x ghostty > /dev/null; then
    osascript -e 'tell application "Ghostty" to activate'
    osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "New Window" of menu "File" of menu bar 1'
else
    open -a Ghostty
fi
```

#### launch-obsidian.sh
```bash
#!/bin/bash
# Always open a new Obsidian window on the current workspace
if pgrep -x Obsidian > /dev/null; then
    osascript -e 'tell application "Obsidian" to activate'
    osascript -e 'tell application "System Events" to tell process "Obsidian" to click menu item "New window" of menu "File" of menu bar 1'
else
    open -a Obsidian
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
sketchybar --trigger aerospace_workspace_change
```

### Key Shortcuts

All shortcuts use `ctrl` as the base modifier. Add `shift` to move instead of focus.

**Navigate**
| Action | Shortcut |
|--------|----------|
| Focus left | `ctrl + left` |
| Focus down | `ctrl + down` |
| Focus up | `ctrl + up` |
| Focus right | `ctrl + right` |

**Move Windows**
| Action | Shortcut |
|--------|----------|
| Move left | `ctrl + shift + left` |
| Move down | `ctrl + shift + down` |
| Move up | `ctrl + shift + up` |
| Move right | `ctrl + shift + right` |
| Move to workspace N | `ctrl + shift + 1-9` |

**Workspaces**
| Action | Shortcut |
|--------|----------|
| Switch to workspace N | `ctrl + 1-9` |
| Toggle last workspace | `ctrl + tab` |
| Move workspace to monitor | `ctrl + shift + tab` |

**Launch Apps**
| Action | Shortcut |
|--------|----------|
| Safari (current workspace) | `ctrl + b` |
| Obsidian (current workspace) | `ctrl + o` |
| Terminal (current workspace) | `ctrl + t` |

**Layout & Resize**
| Action | Shortcut |
|--------|----------|
| Toggle tiles direction | `ctrl + /` |
| Toggle accordion | `ctrl + ,` |
| Close window | `ctrl + q` |
| Fullscreen | `ctrl + f` |
| Minimize | `ctrl + m` |
| Grow | `ctrl + =` |
| Shrink | `ctrl + -` |

**Service Mode** (`ctrl + shift + ;` to enter)
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
	active_color=0xff7aa2f7
	inactive_color=0x00000000
)

borders "${options[@]}"
```

### Notes
- Color `#7aa2f7` is Tokyo Night's blue accent.
- Inactive windows have no border (fully transparent).
- Changes can be applied live without restart: `borders width=6.0 active_color=0xffFF6600`
- Starts at login via `brew services`.

## SketchyBar (Status Bar)

Custom status bar that replaces the macOS menu bar. Shows AeroSpace workspaces, active app, clock, volume, battery, and F5 VPN status with toggle.

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

##### Tokyo Night Storm Theme #####
BAR_COLOR=0xff24283b
ICON_COLOR=0xffc0caf5
LABEL_COLOR=0xffc0caf5
HIGHLIGHT=0xff7aa2f7
DIM=0xff565f89

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
  icon.font="JetBrainsMono Nerd Font Mono:Bold:14.0"
  label.font="JetBrainsMono Nerd Font Mono:Regular:13.0"
  icon.color=$ICON_COLOR
  label.color=$LABEL_COLOR
  icon.padding_left=4
  icon.padding_right=4
  label.padding_left=4
  label.padding_right=4
)
sketchybar --default "${default[@]}"

##### AeroSpace Workspace Indicators #####
sketchybar --add event aerospace_workspace_change

for sid in 1 2 3 4 5; do
  sketchybar --add item workspace."$sid" left \
             --set workspace."$sid" \
                   icon="$sid" \
                   icon.color=$DIM \
                   icon.highlight_color=$ICON_COLOR \
                   icon.padding_left=8 \
                   icon.padding_right=8 \
                   background.color=$HIGHLIGHT \
                   background.corner_radius=5 \
                   background.height=22 \
                   background.drawing=off \
                   label.drawing=off \
                   script="$PLUGIN_DIR/aerospace.sh" \
                   click_script="aerospace workspace $sid" \
             --subscribe workspace."$sid" aerospace_workspace_change
done

##### Front App #####
sketchybar --add item front_app left \
           --set front_app icon.drawing=off \
                           label.color=$ICON_COLOR \
                           script="$PLUGIN_DIR/front_app.sh" \
           --subscribe front_app front_app_switched

##### Right Items #####
sketchybar --add item clock right \
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

### Plugin Scripts

Create `~/.config/sketchybar/plugins/` and save these scripts. `chmod +x` each one.

#### aerospace.sh
```bash
#!/bin/sh

# Show only in-use workspaces, highlight the focused one.
# Each workspace item runs this script independently via the event subscription.

SID="${NAME##*.}"
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
NON_EMPTY="$(aerospace list-workspaces --monitor all --empty no)"

if echo "$NON_EMPTY" | grep -qx "$SID"; then
  if [ "$FOCUSED" = "$SID" ]; then
    sketchybar --set "$NAME" drawing=on icon.highlight=on background.drawing=on
  else
    sketchybar --set "$NAME" drawing=on icon.highlight=off background.drawing=off
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
#!/bin/sh

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

#### vpn.sh
```bash
#!/bin/bash

HIGHLIGHT=0xff7aa2f7
DIM=0xff565f89

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
  osascript -e '
    tell application "System Events"
      tell process "BIG-IP Edge Client"
        click menu bar item 1 of menu bar 2
        delay 0.3
        click menu item "Disconnect" of menu 1 of menu bar item 1 of menu bar 2
      end tell
    end tell'
else
  # VPN is disconnected — click Connect
  osascript -e '
    tell application "System Events"
      tell process "BIG-IP Edge Client"
        click menu bar item 1 of menu bar 2
        delay 0.3
        click menu item "Connect" of menu 1 of menu bar item 1 of menu bar 2
      end tell
    end tell'
fi
```

### Notes
- Tokyo Night Storm theme throughout — matches Ghostty, Starship, JankyBorders.
- `topmost=on` renders SketchyBar above the macOS menu bar (see macOS Settings section for auto-hide fallback).
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

### Disable close/quit confirmations
```bash
defaults write NSGlobalDomain NSCloseAlwaysConfirmsChanges -bool false
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
```

### macOS menu bar (hidden — replaced by SketchyBar)
SketchyBar replaces the macOS menu bar. Set `topmost=on` (not `topmost=window`) in `~/.config/sketchybar/sketchybarrc` so it renders above the system menu bar.

Auto-hide the macOS menu bar as a fallback:
```bash
defaults write com.apple.WindowManager AutoHideMenuBar -int 3
killall Dock
```
Note: `_HIHideMenuBar` no longer fully works on macOS 26. The `topmost=on` setting is what actually covers it.

### Wallpaper (Windows XP "Bliss")

Desktop and lock screen both use the classic Windows XP "Bliss" wallpaper.

1. Place the image at `~/Pictures/windows-xp-bliss.jpg`.

2. Set the desktop wallpaper:
```bash
osascript -e 'tell application "System Events" to tell every desktop to set picture to "/Users/wyoung5/Pictures/windows-xp-bliss.jpg"'
```

3. Set the lock screen wallpaper (macOS 26+):

   macOS 26 uses `~/Library/Application Support/com.apple.wallpaper/Store/Index.plist`. The lock screen corresponds to "Idle" entries with provider `com.apple.wallpaper.choice.image`. Edit the plist to point the idle image path to `~/Pictures/windows-xp-bliss.jpg`.

   **Note:** The old method (`sudo cp` to `/Library/Caches/Desktop Pictures/`) no longer works on macOS 26+. macOS updates may also reset the lock screen image.
