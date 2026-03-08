# Dotfiles

macOS setup — AeroSpace, Karabiner-Elements, Ghostty, SketchyBar, JankyBorders, zsh, Starship, eza.

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
6. **Symlinks** everything under `home/` into `~/` (backs up existing files to `~/.dotfiles-backup/`), plus `computer-rebuild.md` → `~/`
7. Installs **system configs** into `/etc/` with marker-managed blocks (`# BEGIN/END dotfiles`)
8. Sets **desktop wallpaper**
9. Applies **macOS settings** (dark mode, Dock, Finder, key repeat, passwordless sudo, display sleep, auto-hide menu bar, login screen, Citrix `.ica` association)

The script is idempotent — safe to re-run.

## Layout

```
dotfiles/
├── install.sh                          # Single install script
├── Brewfile                            # Homebrew manifest
├── computer-rebuild.md                 # Full setup reference (symlinked to ~/)
├── home/                               # Mirrors ~/ (symlinked)
│   ├── .aerospace.toml                 # Tiling window manager config
│   ├── .gitconfig
│   ├── Library/LaunchAgents/
│   │   └── com.aerospace.minimize-daemon.plist  # Keeps minimize daemon alive
│   ├── Pictures/
│   │   ├── profile.jpg                 # Login screen profile picture
│   │   └── tokyo-night-apple.png       # Desktop wallpaper
│   └── .config/
│       ├── aerospace/                  # Helper scripts
│       │   ├── close-window.sh         # Auto-switch on empty workspace
│       │   ├── launch-app.sh           # Generic app launcher (new window)
│       │   ├── minimize-daemon.sh       # Restore minimized windows to original workspace
│       │   ├── minimize-window.sh      # Minimize + empty workspace auto-switch
│       │   ├── move-window.sh          # Move window + follow if empty
│       │   └── workspace-changed.sh    # SketchyBar update + hide Zoom overlay
│       ├── borders/bordersrc           # JankyBorders config
│       ├── gh/config.yml               # GitHub CLI config
│       ├── ghostty/config              # Terminal config
│       ├── karabiner/                  # Keyboard remapping
│       │   ├── generate-config.sh      # Generates karabiner.json from key list
│       │   └── karabiner.json          # Generated — do not edit directly
│       ├── sketchybar/                 # Status bar (Lua config)
│       │   ├── sketchybarrc            # Entrypoint
│       │   ├── init.lua                # Loads bar, defaults, items
│       │   ├── bar.lua                 # Bar appearance
│       │   ├── colors.lua              # Tokyo Night palette
│       │   ├── default.lua             # Default item styling
│       │   ├── icons.lua               # SF Symbols + NerdFont icons
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
│       │   │       ├── screenshot.lua
│       │   │       └── vpn.lua         # F5 BIG-IP toggle
│       │   └── helpers/                # C helpers + SbarLua loader
│       │       ├── init.lua            # Loads SbarLua + builds C helpers
│       │       ├── makefile            # Builds C helpers
│       │       ├── .gitignore          # Ignores compiled binaries
│       │       ├── app_icons.lua       # App → icon mapping
│       │       ├── badge_data.lua      # Badge attention data for workspaces
│       │       ├── json.lua            # JSON parser
│       │       ├── vpn_toggle.sh       # VPN connect/disconnect
│       │       └── menus/              # Native menu bar access (C)
│       │           ├── makefile
│       │           └── menus.c
├── etc/                                # System configs (copied to /etc/)
│   ├── zshrc.append                    # Appended to /etc/zshrc
│   ├── zprofile.append                 # Appended to /etc/zprofile
│   ├── starship.toml                   # Prompt theme
│   └── eza/theme.yml                   # ls theme
```

## Key bindings

Karabiner-Elements maps `fn` to `cmd+option`, so AeroSpace binds `alt-cmd-*` but you press `fn+*`.

| Shortcut | Action |
|----------|--------|
| `fn + arrows` | Focus window |
| `fn + shift + arrows` | Move window |
| `fn + 1-9` | Switch workspace |
| `fn + shift + 1-9` | Move window to workspace |
| `fn + tab` | Toggle last workspace |
| `fn + shift + tab` | Move workspace to next monitor |
| `fn + f` | Fullscreen |
| `fn + m` | Minimize (restores to original workspace) |
| `fn + q` | Quit app |
| `fn + /` | Toggle tiles layout |
| `fn + ,` | Toggle accordion layout |
| `fn + =` / `fn + -` | Resize |
| `fn + b` | Launch Safari |
| `fn + o` | Launch Obsidian |
| `fn + s` | Launch Signal |
| `fn + t` | Launch Ghostty |
| `fn + z` | Launch Zoom |
| `fn + shift + ;` | Enter service mode |

**Service mode** (press key, then auto-returns to main):

| Key | Action |
|-----|--------|
| `esc` | Reload config & exit service mode |
| `r` | Flatten workspace tree |
| `f` | Toggle floating |
| `backspace` | Close all windows but current |
| `fn + shift + h/j/k/l` | Join with direction |

After editing `.aerospace.toml`, reload with `fn + shift + ;` then `esc`.

## Karabiner config

`karabiner.json` is generated — don't edit it by hand. To add or remove key mappings:

1. Edit the `KEYS` array in `generate-config.sh`
2. Run `~/.config/karabiner/generate-config.sh`

Karabiner auto-reloads on file change.

## Theme

Tokyo Night Storm across everything — Ghostty, SketchyBar, Starship, eza, JankyBorders.
