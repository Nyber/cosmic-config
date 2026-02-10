# Dotfiles

macOS setup — AeroSpace, Karabiner-Elements, Ghostty, SketchyBar, JankyBorders, Yazi, zsh, Starship, eza.

## Install

```bash
git clone https://github.com/Nyber/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Clone anywhere you like — the install script detects its own location.

## What it does

1. Installs **Homebrew** (if missing)
2. Runs **`brew bundle`** — all packages, casks, and fonts from `Brewfile`
3. Starts **JankyBorders** and **SketchyBar** services
4. **Symlinks** everything under `home/` into `~/` (backs up existing files to `~/.dotfiles-backup/`)
5. Installs **system configs** into `/etc/` with marker-managed blocks (`# BEGIN/END dotfiles`)
6. Clones **Yazi Tokyo Night** flavor
7. Applies **macOS settings** (dark mode, Dock, Finder, key repeat, passwordless sudo, display sleep, auto-hide menu bar, Citrix `.ica` association)

The script is idempotent — safe to re-run.

## Layout

```
dotfiles/
├── install.sh                          # Single install script
├── Brewfile                            # Homebrew manifest
├── computer-rebuild.md                 # Full setup reference
├── home/                               # Mirrors ~/ (symlinked)
│   ├── .aerospace.toml                 # Tiling window manager config
│   ├── .gitconfig
│   └── .config/
│       ├── aerospace/                  # Helper scripts
│       │   ├── close-window.sh         # Auto-switch on empty workspace
│       │   ├── move-window.sh          # Move window + switch workspace
│       │   ├── launch-safari.sh
│       │   ├── launch-obsidian.sh
│       │   └── launch-terminal.sh
│       ├── borders/bordersrc           # JankyBorders config
│       ├── gh/config.yml               # GitHub CLI config
│       ├── ghostty/config              # Terminal config
│       ├── karabiner/                  # Keyboard remapping
│       │   ├── generate-config.sh      # Generates karabiner.json from key list
│       │   └── karabiner.json          # Generated — do not edit directly
│       ├── sketchybar/                 # Status bar
│       │   ├── sketchybarrc            # Main config
│       │   └── plugins/
│       │       ├── aerospace.sh        # Workspace indicator
│       │       ├── aerospace_batch.sh  # Batch workspace updates
│       │       ├── battery.sh
│       │       ├── clock.sh
│       │       ├── front_app.sh
│       │       ├── volume.sh
│       │       ├── vpn.sh
│       │       ├── vpn_click.sh        # F5 VPN toggle (AppleScript)
│       │       ├── power.sh            # Power menu trigger
│       │       └── power_menu.swift    # Power menu UI
│       └── yazi/                       # File manager
│           ├── keymap.toml
│           └── theme.toml
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
| `fn + m` | Minimize |
| `fn + q` | Close window |
| `fn + /` | Toggle tiles layout |
| `fn + ,` | Toggle accordion layout |
| `fn + =` / `fn + -` | Resize |
| `fn + b` | Launch Safari |
| `fn + o` | Launch Obsidian |
| `fn + t` | Launch Ghostty |
| `fn + shift + ;` | Enter service mode |

**Service mode** (press key, then auto-returns to main):

| Key | Action |
|-----|--------|
| `esc` | Reload config |
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

Tokyo Night Storm across everything — Ghostty, SketchyBar, Starship, eza, JankyBorders, Yazi.
