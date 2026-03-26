# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a macOS dotfiles repo at `~/.dotfiles/`. It manages the complete desktop environment: AeroSpace tiling WM, SketchyBar status bar, Ghostty terminal, and shell config — all themed Tokyo Night Storm.

## Key Commands

```bash
# Full install (idempotent, safe to re-run)
~/.dotfiles/install.sh

# Reload AeroSpace config after editing .aerospace.toml
# (or press opt+shift+; then esc)
aerospace reload-config

# Reload SketchyBar after config changes (also auto-rebuilds C helpers)
sketchybar --reload

# Rebuild SketchyBar C helpers only (after editing C source)
cd ~/.config/sketchybar/helpers && make

# Restart services
brew services restart sketchybar
brew services restart felixkratz/formulae/borders

# Reload minimize-daemon LaunchAgent
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.aerospace.minimize-daemon.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.aerospace.minimize-daemon.plist
```

## Architecture

### install.sh

Idempotent 9-step installer: Xcode CLI tools → Homebrew → brew bundle → SbarLua → services → symlinks → system configs → wallpaper → macOS settings.

- `home/` tree is symlinked into `~/` (with backup to `~/.dotfiles-backup/`)
- System configs (step 7) only handles sudoers.d TERMINFO — shell config lives entirely in `home/`
- `link_file()` detects when a parent dir is already symlinked to prevent self-referencing corruption

### SketchyBar (Lua)

Entry: `sketchybarrc` → `helpers/init.lua` (sets up SbarLua, runs `make` to auto-build C helpers) → `init.lua` → loads `bar`, `default`, `items`. C helpers are rebuilt on every `sketchybar --reload`.

**Items** (`items/init.lua` loads all):
- `apple.lua` — Custom Apple menu popup (replaces native). About This Mac, Applications (Spotlight), App Store, Force Quit, Sleep, Restart, Shut Down, Lock Screen, Log Out.
- `menus.lua` — Native app menu items via C helper. Defines and handles `swap_menus_and_spaces` event.
- `spaces.lua` — **Most complex item.** Workspace indicators with badge attention (red icons for apps with notifications). Uses C helper `badges/badges` to read dock badge counts. Real-time detection via `lsappinfo listen` pipe that triggers `badge_check` events on dock badge changes, with 60s routine fallback. Debounces updates with `update_pending`/`recheck_needed` flags — coalesces rapid events while guaranteeing the final state is always queried. Subscribes to `aerospace_workspace_change`, `front_app_switched`, `space_windows_change`, `display_change`, `space_change`, and `system_woke`. Includes `spaces_indicator` toggle icon.
- `front_app.lua` — Current app name (active display only). Click triggers `swap_menus_and_spaces` to toggle between menus and workspace indicators.
- `calendar.lua` — Date/time display, click opens Calendar.app.
- `media.lua` — Album art + truncated artist/title for Spotify/Music. Animated expand/collapse on hover. `nowplaying-cli` used for popup playback controls.
- `widgets/` — battery, volume (with audio device picker via `SwitchAudioSource`), screenshot, VPN toggle, wifi

**Cross-cutting event:** `swap_menus_and_spaces` — toggled by clicking front_app, swaps visibility of menus vs. workspace indicators. Handled in `front_app.lua`, `menus.lua`, and `spaces.lua`.

**Helpers** (`helpers/`):
- C helpers compiled via makefiles: `badges/`, `menus/`, `volume/` — each in its own subdir with a makefile, binaries output to `<subdir>/bin/`
- `menus/` uses private `SkyLight` framework + Carbon for Accessibility API — temporarily shows native menu bar via `SLSSetMenuBarInsetAndAlpha` when selecting extra menu bar items
- `app_icons.lua` — 340+ app-to-icon mappings (sketchybar-app-font glyphs)
- `badge_data.lua` — Shared badge state for `spaces.lua` (minimize daemon triggers rechecks via `sketchybar --trigger badge_check`)
- `json.lua` — Pure-Lua JSON decoder, fallback for when `sbar.exec` doesn't auto-parse
- Top-level `helpers/makefile` orchestrates subdirectory builds

**SbarLua caveat:** `sbar.exec` auto-parses JSON stdout into a Lua table. Always check `type(result)` before calling `json.decode` — it may already be a table.

### AeroSpace Helper Scripts

All in `home/.config/aerospace/`. Scripts auto-compact workspaces (fill gaps) and refresh SketchyBar.

- `compact-workspaces.sh` — Core compaction logic. Detects gaps in workspace numbering (e.g., 1,2,4,5 → 1,2,3,4), moves windows down to fill gaps, updates `.minimized-*` tracking files for renumbered occupied workspaces, focuses the correct workspace, and triggers SketchyBar. Uses `mkdir`-based non-blocking lock to prevent concurrent runs.
- `workspace-changed.sh` — Triggered by `exec-on-workspace-change`. Updates SketchyBar + hides Zoom overlay on non-Zoom workspaces.
- `close-window.sh`, `move-window.sh`, `minimize-window.sh` — Each calls `compact-workspaces.sh` after its action.

**AeroSpace callbacks** (in `.aerospace.toml`):
- `exec-on-workspace-change` → runs `workspace-changed.sh`
- `on-focused-monitor-changed` → moves mouse + triggers SketchyBar refresh
- `[[on-window-detected]]` → triggers `aerospace_workspace_change` for any new window (Login Items, `open` commands, background windows)
- `minimize-daemon.sh` — Background daemon (LaunchAgent, `KeepAlive=true`). Tracks minimized windows via `.minimized-<id>` files in `~/.config/aerospace/`, restores them to original workspace on unminimize (or to end if workspace was compacted with different content), then compacts. Also triggers compact on any window list change (catches non-keybinding closes, app quits). Uses file birth time (`stat -f %B`) to avoid false restores from async minimize delay. Adaptive polling (2-15s). Temp files stored in `~/.config/aerospace/` (not `/tmp`) to survive macOS cleanup.
- `launch-app.sh` — Opens new window if app running (Cmd+N), else `open -a`. Moves new window to current workspace only when app already has windows.

### Shell Config

Per-user dotfiles (symlinked from `home/` into `~/`):
- `home/.zprofile` → `~/.zprofile` — Homebrew shellenv
- `home/.zshrc` → `~/.zshrc` — eza aliases, plugins (zsh-autosuggestions, zsh-syntax-highlighting, fzf), Starship prompt
- `home/.config/starship.toml` → `~/.config/starship.toml` — Starship config (Tokyo Night palette)
- `home/.config/eza/theme.yml` → `~/.config/eza/theme.yml` — eza color theme

## Important Patterns

- **LaunchAgent scripts must use full paths** (`/opt/homebrew/bin/sketchybar`, `/opt/homebrew/bin/aerospace`) — launchd PATH is minimal
- **Event-driven SketchyBar updates** — AeroSpace scripts trigger custom events rather than polling
- **File birth time for restore detection** — minimize-daemon uses `stat -f %B` (macOS APFS birth time) to distinguish "just minimized" (< 3s) from "restored from Dock" (>= 3s), avoiding false restores from async minimize delay
- **Tokyo Night colors** are centralized in `sketchybar/colors.lua` — use those constants, don't hardcode hex values in items
- **NerdFont glyphs are invisible to text tools** — files like `icons.lua` contain 3-byte UTF-8 NerdFont glyphs (U+F000–U+FFFF) that display identically to empty strings in Read/Edit. After editing these files, always verify with `xxd` that glyphs survived (look for `22 ef xx xx 22` not `2222`). Use binary-safe methods (python `open('f','rb')`) to insert glyphs, not the Edit tool.
