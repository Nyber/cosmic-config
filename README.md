# Dotfiles

macOS setup — AeroSpace, Ghostty, SketchyBar, JankyBorders, Yazi, zsh, Starship, eza.

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
7. Copies **wallpaper** to `~/Pictures/`
8. Applies **macOS settings** (passwordless sudo, display sleep, auto-hide menu bar, wallpaper, Citrix `.ica` association)

The script is idempotent — safe to re-run.

## Layout

```
dotfiles/
├── install.sh              # Single install script
├── Brewfile                # Homebrew manifest
├── home/                   # Mirrors ~/ (symlinked)
│   ├── .aerospace.toml
│   └── .config/
│       ├── aerospace/      # App launch + move-window scripts
│       ├── borders/        # JankyBorders config
│       ├── ghostty/        # Terminal config
│       ├── sketchybar/     # Status bar config + plugins
│       └── yazi/           # File manager config
├── etc/                    # System configs (copied to /etc/)
│   ├── zshrc.append        # Appended to /etc/zshrc
│   ├── zprofile.append     # Appended to /etc/zprofile
│   ├── starship.toml       # Prompt theme
│   └── eza/theme.yml       # ls theme
└── wallpaper/
    └── windows-xp-bliss.jpg
```

## Key bindings

| Shortcut | Action |
|----------|--------|
| `ctrl + m` | Minimize window (AeroSpace) |
| `ctrl + q` | Close Ghostty surface (tab/split/window) |

See `.aerospace.toml` for the full AeroSpace shortcut map (`ctrl` as base modifier).

After editing `.aerospace.toml`, reload with `ctrl + shift + ;` then `esc`, or run `aerospace reload-config`.

## Theme

Tokyo Night across everything — Ghostty, SketchyBar, Starship, eza, JankyBorders, Yazi.
