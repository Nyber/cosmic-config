# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a macOS dotfiles repo at `~/.dotfiles/`. It manages the complete desktop environment: AeroSpace tiling WM, SketchyBar status bar, Karabiner keyboard remapping, Ghostty terminal, and shell config — all themed Tokyo Night Storm.

## Key Commands

```bash
# Full install (idempotent, safe to re-run)
~/.dotfiles/install.sh

# Reload AeroSpace config after editing .aerospace.toml
# (or press fn+shift+; then esc)
aerospace reload-config

# Reload SketchyBar after config changes (also auto-rebuilds C helpers)
sketchybar --reload

# Rebuild SketchyBar C helpers only (after editing C source)
cd ~/.config/sketchybar/helpers && make

# Regenerate Karabiner config after editing KEYS array
~/.config/karabiner/generate-config.sh

# Restart services
brew services restart sketchybar
brew services restart felixkratz/formulae/borders

# Reload minimize-daemon LaunchAgent
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.aerospace.minimize-daemon.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.aerospace.minimize-daemon.plist
```

## Architecture

### install.sh

Idempotent 10-step installer: Xcode CLI tools → Homebrew → brew bundle → SbarLua → services → symlinks → system configs → Yazi flavor → wallpaper → macOS settings.

- `home/` tree is symlinked into `~/` (with backup to `~/.dotfiles-backup/`)
- `etc/` files are injected into `/etc/` using marker blocks (`# BEGIN/END dotfiles`) for safe re-runs
- `link_file()` detects when a parent dir is already symlinked to prevent self-referencing corruption

### SketchyBar (Lua)

Entry: `sketchybarrc` → `helpers/init.lua` (sets up SbarLua, runs `make` to auto-build C helpers) → `init.lua` → loads `bar`, `default`, `items`. C helpers are rebuilt on every `sketchybar --reload`.

**Items** (`items/init.lua` loads all):
- `apple.lua` — Custom Apple menu popup (replaces native). Opens Apps via Spotlight, App Store, power controls.
- `spaces.lua` — **Most complex item.** Workspace indicators with badge attention (red icons for apps with notifications). Uses C helper `badges/badges` to read dock badge counts. Real-time detection via `lsappinfo listen` pipe that triggers `badge_check` events on dock badge changes, with 60s routine fallback. Debounces updates with `update_pending` flag to avoid redundant subprocess calls.
- `menus.lua` — Native app menu items via C helper. Supports `swap_menus_and_spaces` toggle.
- `front_app.lua` — Current app name. Click triggers `swap_menus_and_spaces` to toggle between menus and workspace indicators.
- `calendar.lua` — Date/time display, click opens Calendar.app.
- `media.lua` — Album art + scrolling artist/title for Spotify/Music via `nowplaying-cli`. Animated expand/collapse on hover.
- `widgets/` — battery, volume (with audio device picker via `SwitchAudioSource`), screenshot, VPN toggle, wifi, OrbStack status

**Cross-cutting event:** `swap_menus_and_spaces` — toggled by clicking front_app, swaps visibility of menus vs. workspace indicators. Handled in `front_app.lua`, `menus.lua`, and `spaces.lua`.

**Helpers** (`helpers/`):
- C helpers compiled via makefiles: `badges/`, `menus/`, `volume/` — each in its own subdir with a makefile, binaries output to `<subdir>/bin/`
- `menus/` uses private `SkyLight` framework + Carbon for Accessibility API — temporarily shows native menu bar via `SLSSetMenuBarInsetAndAlpha` when selecting extra menu bar items
- `app_icons.lua` — 340+ app-to-icon mappings (sketchybar-app-font glyphs)
- `badge_data.lua` — Shared mutable state between `spaces.lua` and the minimize daemon
- `json.lua` — Pure-Lua JSON decoder, fallback for when `sbar.exec` doesn't auto-parse
- Top-level `helpers/makefile` orchestrates subdirectory builds

**SbarLua caveat:** `sbar.exec` auto-parses JSON stdout into a Lua table. Always check `type(result)` before calling `json.decode` — it may already be a table.

### AeroSpace Helper Scripts

All in `home/.config/aerospace/`. Consistent pattern: scripts auto-switch workspaces when the current one becomes empty, and refresh SketchyBar.

- `workspace-changed.sh` — Triggered by `exec-on-workspace-change`. Updates SketchyBar + hides Zoom overlay on non-Zoom workspaces.
- `minimize-daemon.sh` — Background daemon (LaunchAgent, `KeepAlive=true`). Tracks minimized windows via `.minimized-<id>` files, restores them to original workspace on unminimize. Adaptive polling (2-15s). Woken by USR1 signal from `minimize-window.sh`.
- `launch-app.sh` — Opens new window if app running, else `open -a`. Moves window to current workspace.
- `close-window.sh`, `move-window.sh`, `minimize-window.sh` — Each handles empty-workspace auto-switch.

### Karabiner-Elements

`generate-config.sh` is the single source of truth. Edit the `KEYS` array, run the script — it generates `karabiner.json`. Maps `fn+key` → `cmd+option+key` so AeroSpace uses fn as modifier while ctrl stays free for apps.

### Shell Config

All global (no per-user `.zshrc`/`.zprofile`):
- `etc/zprofile.append` → `/etc/zprofile` — Homebrew shellenv
- `etc/zshrc.append` → `/etc/zshrc` — eza alias, plugins (zsh-autosuggestions, zsh-syntax-highlighting, fzf), Starship prompt

## Important Patterns

- **LaunchAgent scripts must use full paths** (`/opt/homebrew/bin/sketchybar`, `/opt/homebrew/bin/aerospace`) — launchd PATH is minimal
- **Marker-based system config injection** — `install_block()` uses `# BEGIN/END dotfiles` for idempotent `/etc/` updates
- **Event-driven SketchyBar updates** — AeroSpace scripts trigger custom events rather than polling
- **Signal-based daemon wakeup** — USR1 signal wakes minimize-daemon from slow sleep immediately
- **Tokyo Night colors** are centralized in `sketchybar/colors.lua` — use those constants, don't hardcode hex values in items
- **NerdFont glyphs are invisible to text tools** — files like `icons.lua` contain 3-byte UTF-8 NerdFont glyphs (U+F000–U+FFFF) that display identically to empty strings in Read/Edit. After editing these files, always verify with `xxd` that glyphs survived (look for `22 ef xx xx 22` not `2222`). Use binary-safe methods (python `open('f','rb')`) to insert glyphs, not the Edit tool.
