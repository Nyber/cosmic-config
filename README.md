# Dotfiles

macOS setup — AeroSpace, Ghostty, SketchyBar, JankyBorders, zsh, Starship, eza.

## Install

```bash
git clone https://github.com/Nyber/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Clone anywhere you like — the install script detects its own location.

## What it does

1. Installs **Xcode Command Line Tools** (if missing) — needed by SbarLua and SketchyBar C helpers
2. Installs **Homebrew** (if missing)
3. Runs **`brew bundle`** — all packages, casks, and fonts from `Brewfile`
4. Builds **SbarLua** — Lua bindings required by SketchyBar's config
5. Starts **JankyBorders** and **SketchyBar** services
6. **Symlinks** everything under `home/` into `~/` (backs up existing files to `~/.dotfiles-backup/`)
7. Installs **system configs** (sudoers.d TERMINFO for Ghostty)
8. Sets **desktop wallpaper**
9. Applies **macOS settings** (dark mode, Dock, Finder, key repeat, passwordless sudo, display sleep, auto-hide menu bar, Citrix `.ica` association)

The script is idempotent — safe to re-run.

## Layout

```
dotfiles/
├── install.sh                          # Single install script
├── Brewfile                            # Homebrew manifest
├── home/                               # Mirrors ~/ (symlinked)
│   ├── .aerospace.toml                 # Tiling window manager config
│   ├── .gitconfig
│   ├── .zprofile                       # Homebrew shellenv
│   ├── .zshrc                          # Aliases, plugins, Starship prompt
│   ├── CLAUDE.md                       # Claude Code project instructions
│   ├── Library/LaunchAgents/
│   │   └── com.aerospace.minimize-daemon.plist  # Keeps minimize daemon alive
│   ├── Pictures/
│   │   └── tokyo-night-apple.png       # Desktop wallpaper
│   └── .config/
│       ├── aerospace/                  # Helper scripts
│       │   ├── close-window.sh         # Auto-switch on empty workspace
│       │   ├── launch-app.sh           # Generic app launcher (new window)
│       │   ├── minimize-daemon.sh      # Restore minimized windows to original workspace
│       │   ├── minimize-window.sh      # Minimize + empty workspace auto-switch
│       │   ├── move-window.sh          # Move window + follow if empty
│       │   ├── compact-workspaces.sh   # Fill gaps in workspace numbering
│       │   ├── snap-window.sh          # Snap/tile windows to screen halves
│       │   └── workspace-changed.sh    # SketchyBar update + hide Zoom overlay
│       ├── borders/bordersrc           # JankyBorders config
│       ├── eza/theme.yml               # eza color theme
│       ├── gh/config.yml               # GitHub CLI config
│       ├── ghostty/config              # Terminal config
│       ├── starship.toml               # Starship prompt config
│       ├── sketchybar/                 # Status bar (Lua config)
│       │   ├── sketchybarrc            # Entrypoint
│       │   ├── init.lua                # Loads bar, defaults, items
│       │   ├── bar.lua                 # Bar appearance
│       │   ├── colors.lua              # Tokyo Night palette
│       │   ├── default.lua             # Default item styling
│       │   ├── icons.lua               # NerdFont icons
│       │   ├── settings.lua            # Font, padding config
│       │   ├── items/                  # Bar items
│       │   │   ├── init.lua            # Loads all item modules
│       │   │   ├── apple.lua           # Apple menu popup (Apps, App Store, power)
│       │   │   ├── menus.lua           # App menu items
│       │   │   ├── spaces.lua          # AeroSpace workspace indicators + badge attention
│       │   │   ├── front_app.lua       # Active app name
│       │   │   ├── calendar.lua        # Date/time
│       │   │   ├── media.lua           # Now playing
│       │   │   └── widgets/            # Right-side widgets
│       │   │       ├── init.lua        # Loads all widget modules
│       │   │       ├── battery.lua
│       │   │       ├── volume.lua      # Volume + audio device picker
│       │   │       ├── notifications.lua # Bell icon + popup (macOS NC + custom push)
│       │   │       ├── screenshot.lua
│       │   │       ├── vpn.lua         # F5 BIG-IP toggle
│       │   │       └── wifi.lua        # WiFi status
│       │   └── helpers/                # C/ObjC/Swift helpers + SbarLua loader
│       │       ├── init.lua            # Loads SbarLua + builds C helpers
│       │       ├── makefile            # Builds all helper subdirectories
│       │       ├── app_icons.lua       # App → icon mapping
│       │       ├── badge_data.lua      # Badge attention data for workspaces
│       │       ├── json.lua            # JSON parser
│       │       ├── vpn_toggle.sh       # VPN connect/disconnect
│       │       ├── badges/             # Dock badge count reader (C)
│       │       │   ├── makefile
│       │       │   └── badges.c
│       │       ├── menus/              # Native menu bar access (ObjC)
│       │       │   ├── makefile
│       │       │   └── menus.m
│       │       ├── notifications/      # macOS Notification Center reader (Swift)
│       │       │   ├── makefile
│       │       │   └── notifications.swift
│       │       └── volume/             # Volume control helper (C)
│       │           ├── makefile
│       │           └── volume.c
```

## Key bindings

AeroSpace uses Option/Alt as the modifier key directly.

| Shortcut | Action |
|----------|--------|
| `opt + arrows` | Focus window |
| `opt + shift + arrows` | Move window |
| `opt + 1-9` | Switch workspace |
| `opt + shift + 1-9` | Move window to workspace |
| `opt + tab` | Toggle last workspace |
| `opt + shift + tab` | Move workspace to next monitor |
| `opt + f` | Fullscreen |
| `opt + m` | Minimize (restores to original workspace) |
| `opt + q` | Quit app |
| `opt + /` | Toggle tiles layout |
| `opt + ,` | Toggle accordion layout |
| `opt + =` / `opt + -` | Resize |
| `opt + b` | Launch Safari |
| `opt + o` | Launch Obsidian |
| `opt + s` | Launch Signal |
| `opt + t` | Launch Ghostty |
| `opt + z` | Launch Zoom |
| `opt + shift + ;` | Enter service mode |

**Service mode** (press key, then auto-returns to main):

| Key | Action |
|-----|--------|
| `esc` | Reload config & exit service mode |
| `r` | Flatten workspace tree |
| `f` | Toggle floating |
| `backspace` | Close all windows but current |
| `h/j/k/l` | Join with direction |

After editing `.aerospace.toml`, reload with `opt + shift + ;` then `esc`.

## Theme

Tokyo Night Storm across everything — Ghostty, SketchyBar, Starship, eza, JankyBorders.
