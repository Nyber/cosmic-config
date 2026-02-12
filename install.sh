#!/bin/bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup"

info()  { printf '\033[1;34m==> %s\033[0m\n' "$1"; }
ok()    { printf '\033[1;32m    ✓ %s\033[0m\n' "$1"; }
skip()  { printf '\033[1;33m    ⊘ %s (skipped)\033[0m\n' "$1"; }

# ---------------------------------------------------------------------------
# 1. Homebrew
# ---------------------------------------------------------------------------
info "Checking Homebrew"
if command -v brew &>/dev/null; then
    ok "Homebrew already installed"
else
    info "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    ok "Homebrew installed"
fi

# ---------------------------------------------------------------------------
# 1.5. Xcode Command Line Tools
# ---------------------------------------------------------------------------
info "Checking Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
    ok "Xcode CLI tools already installed"
else
    info "Installing Xcode CLI tools"
    xcode-select --install
    info "Waiting for Xcode CLI tools installation (press Enter when done)..."
    read -r
fi

# ---------------------------------------------------------------------------
# 2. brew bundle
# ---------------------------------------------------------------------------
info "Running brew bundle"
brew bundle --file="$DOTFILES/Brewfile"
ok "Packages installed"

# ---------------------------------------------------------------------------
# 2.5. SbarLua (Lua bindings for SketchyBar)
# ---------------------------------------------------------------------------
info "Installing SbarLua"
SBARLUA_DIR="$HOME/.local/share/sketchybar_lua"
if [[ -f "$SBARLUA_DIR/sketchybar.so" ]]; then
    ok "SbarLua already installed"
else
    (git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua \
      && cd /tmp/SbarLua && make install && rm -rf /tmp/SbarLua)
    ok "SbarLua installed"
fi

# ---------------------------------------------------------------------------
# 3. Start services
# ---------------------------------------------------------------------------
BREW_SERVICES="$(brew services list)"

info "Starting JankyBorders service"
if echo "$BREW_SERVICES" | grep -q 'borders.*started'; then
    ok "JankyBorders already running"
else
    brew services start felixkratz/formulae/borders
    ok "JankyBorders started"
fi

info "Starting SketchyBar service"
if echo "$BREW_SERVICES" | grep -q 'sketchybar.*started'; then
    ok "SketchyBar already running"
else
    brew services start sketchybar
    ok "SketchyBar started"
fi

# ---------------------------------------------------------------------------
# 4. Symlinks (home/ → ~/)
# ---------------------------------------------------------------------------
info "Creating symlinks"

link_file() {
    local src="$1"   # absolute path in dotfiles
    local dest="$2"  # absolute path in ~/

    # If a parent directory is a symlink into the dotfiles repo, the file is
    # already effectively linked — skip to avoid creating self-referencing symlinks.
    local dest_real
    dest_real="$(cd "$(dirname "$dest")" 2>/dev/null && pwd -P)"
    if [[ "$dest_real" == "$(dirname "$src")" ]]; then
        skip "$dest"
        return
    fi

    if [[ -L "$dest" ]]; then
        local current
        current="$(readlink "$dest")"
        if [[ "$current" == "$src" ]]; then
            skip "$dest"
            return
        fi
    fi

    # Back up existing regular file
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        mkdir -p "$BACKUP_DIR/$(dirname "${dest#$HOME/}")"
        mv "$dest" "$BACKUP_DIR/${dest#$HOME/}"
        info "Backed up $dest → $BACKUP_DIR/${dest#$HOME/}"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
    ok "$dest → $src"
}

# Walk home/ and symlink each file
while IFS= read -r -d '' file; do
    rel="${file#$DOTFILES/home/}"
    link_file "$file" "$HOME/$rel"
done < <(find "$DOTFILES/home" -type f -print0)

# computer-rebuild.md → ~/
link_file "$DOTFILES/computer-rebuild.md" "$HOME/computer-rebuild.md"

# Load LaunchAgents (idempotent — bootout first to handle re-runs)
for plist in "$HOME"/Library/LaunchAgents/com.aerospace.minimize-daemon.plist \
             "$HOME"/Library/LaunchAgents/com.user.notif-watcher.plist; do
    label="$(defaults read "$plist" Label 2>/dev/null)" || continue
    launchctl bootout "gui/$(id -u)/$label" 2>/dev/null
    launchctl bootstrap "gui/$(id -u)" "$plist" 2>/dev/null && ok "Loaded $label" || skip "Could not load $label"
done

# ---------------------------------------------------------------------------
# 5. System configs (sudo)
# ---------------------------------------------------------------------------
info "Installing system configs (sudo required)"

# Helper: install a block between markers into a system file
install_block() {
    local src="$1"    # source append file
    local dest="$2"   # target system file
    local marker_begin="# BEGIN dotfiles"
    local marker_end="# END dotfiles"

    local block
    block="$marker_begin
$(cat "$src")
$marker_end"

    if grep -q "$marker_begin" "$dest" 2>/dev/null; then
        # Replace existing block — write new content to temp, then swap
        local tmp block_file
        tmp="$(mktemp)"
        block_file="$(mktemp)"
        printf '%s\n' "$block" > "$block_file"
        awk -v begin="$marker_begin" -v end="$marker_end" -v bfile="$block_file" '
            $0 == begin { skip=1; while ((getline line < bfile) > 0) print line; close(bfile); next }
            $0 == end   { skip=0; next }
            !skip       { print }
        ' "$dest" > "$tmp"
        sudo cp "$tmp" "$dest"
        rm "$tmp" "$block_file"
        ok "$dest (block replaced)"
    else
        # Append block
        printf '\n%s\n' "$block" | sudo tee -a "$dest" >/dev/null
        ok "$dest (block appended)"
    fi
}

# /etc/starship.toml — full file copy
sudo cp "$DOTFILES/etc/starship.toml" /etc/starship.toml
ok "/etc/starship.toml"

# /etc/eza/theme.yml — full file copy
sudo mkdir -p /etc/eza
sudo cp "$DOTFILES/etc/eza/theme.yml" /etc/eza/theme.yml
ok "/etc/eza/theme.yml"

# Preserve Ghostty TERMINFO through sudo su (SIP blocks /usr/share/terminfo)
echo 'Defaults env_keep += "TERMINFO"' | sudo tee /etc/sudoers.d/terminfo > /dev/null
sudo chmod 440 /etc/sudoers.d/terminfo
ok "/etc/sudoers.d/terminfo (env_keep TERMINFO)"

# /etc/zshrc — append block
install_block "$DOTFILES/etc/zshrc.append" /etc/zshrc

# /etc/zprofile — append block
install_block "$DOTFILES/etc/zprofile.append" /etc/zprofile

# ---------------------------------------------------------------------------
# 6. Yazi Tokyo Night flavor
# ---------------------------------------------------------------------------
info "Yazi Tokyo Night flavor"
YAZI_FLAVOR_DIR="$HOME/.config/yazi/flavors/tokyo-night.yazi"
if [[ -d "$YAZI_FLAVOR_DIR" ]]; then
    ok "Already cloned"
else
    git clone https://github.com/BennyOe/tokyo-night.yazi.git "$YAZI_FLAVOR_DIR"
    ok "Cloned tokyo-night.yazi"
fi

# ---------------------------------------------------------------------------
# 6.5. Wallpaper
# ---------------------------------------------------------------------------
info "Setting wallpaper"
WALLPAPER="$HOME/Pictures/tokyo-night-apple.png"
if [[ -f "$WALLPAPER" ]]; then
    WALLPAPER_REAL="$(readlink -f "$WALLPAPER" 2>/dev/null || echo "$WALLPAPER")"
    CURRENT_WALLPAPER="$(osascript -e 'tell application "System Events" to get picture of desktop 1' 2>/dev/null || true)"
    if [[ "$CURRENT_WALLPAPER" == "$WALLPAPER" || "$CURRENT_WALLPAPER" == "$WALLPAPER_REAL" ]]; then
        ok "Desktop wallpaper already set"
    else
        osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "'"$WALLPAPER"'"' 2>/dev/null || true
        ok "Desktop wallpaper set"
    fi
else
    skip "Wallpaper image not found"
fi

# ---------------------------------------------------------------------------
# 7. macOS settings
# ---------------------------------------------------------------------------
info "macOS settings"

# Root shell → zsh
if [[ "$(dscl . -read /Users/root UserShell 2>/dev/null | awk '{print $2}')" == "/bin/zsh" ]]; then
    ok "Root shell already zsh"
else
    sudo chsh -s /bin/zsh root
    ok "Root shell set to zsh"
fi

# Passwordless sudo
SUDOERS_FILE="/etc/sudoers.d/$(whoami)"
if [[ -f "$SUDOERS_FILE" ]]; then
    ok "Passwordless sudo already configured"
else
    echo "$(whoami) ALL=(ALL) NOPASSWD: ALL" | sudo tee "$SUDOERS_FILE" >/dev/null
    sudo chmod 0440 "$SUDOERS_FILE"
    ok "Passwordless sudo configured"
fi

# Power management (AC: never sleep; battery: unchanged defaults)
sudo pmset -c sleep 0 displaysleep 0 disksleep 0 standby 0 powernap 0
ok "AC power: sleep, display sleep, disk sleep, standby, powernap disabled"

# fn key: show Emoji picker (Karabiner only intercepts fn+key, not fn alone)
defaults write com.apple.HIToolbox AppleFnUsageType -int 2
ok "fn key emoji picker enabled"

# Auto-hide macOS menu bar (SketchyBar replaces it with topmost=on)
defaults write com.apple.WindowManager AutoHideMenuBar -int 3
ok "macOS menu bar auto-hidden (SketchyBar replaces it)"

# Don't confirm unsaved changes on close
defaults write NSGlobalDomain NSCloseAlwaysConfirmsChanges -bool false
ok "Close without confirming changes"

# Don't restore windows on relaunch
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
ok "Don't restore windows on relaunch"

# Finder
FINDER_CHANGED=false
[[ "$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null)" != "1" ]] && FINDER_CHANGED=true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
if $FINDER_CHANGED; then
    killall Finder 2>/dev/null || true
    ok "Finder: hidden files, extensions, path/status bar, list view, folders first"
else
    ok "Finder: already configured"
fi

# Dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
ok "Dark mode"

# Always show scrollbars
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
ok "Always show scrollbars"

# Full keyboard access (Tab through all UI controls)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2
ok "Full keyboard access"

# Fast key repeat (faster than System Preferences allows)
defaults write com.apple.Accessibility KeyRepeatInterval -float 0.083333333
defaults write com.apple.Accessibility KeyRepeatDelay -float 0.5
defaults write com.apple.Accessibility KeyRepeatEnabled -bool true
ok "Fast key repeat"

# Dock
DOCK_CHANGED=false
[[ "$(defaults read com.apple.dock autohide 2>/dev/null)" != "1" ]] && DOCK_CHANGED=true
[[ "$(defaults read com.apple.dock tilesize 2>/dev/null)" != "43" ]] && DOCK_CHANGED=true
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 43
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock persistent-others -array
defaults write com.apple.dock wvous-br-corner -int 14
defaults write com.apple.dock wvous-br-modifier -int 0
if $DOCK_CHANGED; then
    killall Dock 2>/dev/null || true
    ok "Dock: autohide, small icons, stripped apps, Quick Note hot corner"
else
    ok "Dock: already configured"
fi


# Do Not Disturb — 24/7 schedule (SketchyBar bell widget handles notifications)
DND_CONFIG="$HOME/Library/DoNotDisturb/DB/ModeConfigurations.json"
if [[ -f "$DND_CONFIG" ]]; then
    DND_RESULT="$(python3 -c "
import json, time, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
mode = data['data'][0]['modeConfigurations']['com.apple.donotdisturb.mode.default']
triggers = mode['triggers']['triggers']
sched = None
for t in triggers:
    if t.get('class') == 'DNDModeConfigurationScheduleTrigger':
        sched = t
        break
if (sched and sched.get('enabledSetting') == 2
    and sched.get('timePeriodStartTimeHour') == 0
    and sched.get('timePeriodEndTimeHour') == 23
    and sched.get('timePeriodEndTimeMinute') == 59
    and sched.get('timePeriodWeekdays') == 127):
    print('ok')
    sys.exit(0)
if sched is None:
    sched = {'class': 'DNDModeConfigurationScheduleTrigger', 'creationDate': time.time() - 978307200, 'timePeriodWeekdays': 127}
    triggers.append(sched)
sched['enabledSetting'] = 2
sched['timePeriodStartTimeHour'] = 0
sched['timePeriodStartTimeMinute'] = 0
sched['timePeriodEndTimeHour'] = 23
sched['timePeriodEndTimeMinute'] = 59
sched['timePeriodWeekdays'] = 127
now = time.time() - 978307200
mode['lastModified'] = now
data['header']['timestamp'] = now
with open(sys.argv[1], 'w') as f:
    json.dump(data, f)
print('changed')
" "$DND_CONFIG")"
    if [[ "$DND_RESULT" == "changed" ]]; then
        killall -HUP donotdisturbd 2>/dev/null || true
        ok "Do Not Disturb 24/7 schedule (bell widget handles notifications)"
    else
        ok "Do Not Disturb already configured"
    fi
else
    skip "DND config not found (enable manually: System Settings → Focus → DND → Schedule 24/7)"
fi

# Citrix .ica file association
if command -v duti &>/dev/null; then
    duti -s com.citrix.receiver.icaviewer.mac .ica all
    ok ".ica files → Citrix Workspace"
else
    skip "duti not found, skipping .ica association"
fi

# Login screen: show name/password fields instead of user list
sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true
ok "Login screen: name/password fields"

# Login screen profile picture (Apple logo, Tokyo Night background)
PROFILE_PIC="$HOME/Pictures/profile.jpg"
if [[ -f "$PROFILE_PIC" ]]; then
    CURRENT_USER="$(whoami)"
    PROFILE_PIC_REAL="$(readlink -f "$PROFILE_PIC" 2>/dev/null || echo "$PROFILE_PIC")"
    printf '0x0A 0x5C 0x3A 0x2C dsRecTypeStandard:Users 2 dsAttrTypeStandard:RecordName externalbinary:dsAttrTypeStandard:JPEGPhoto\n%s:%s\n' "$CURRENT_USER" "$PROFILE_PIC_REAL" > /tmp/user_pic.dsimport
    sudo dsimport /tmp/user_pic.dsimport /Local/Default M 2>/dev/null
    rm -f /tmp/user_pic.dsimport
    sudo dscl . -delete /Users/"$CURRENT_USER" Picture 2>/dev/null
    sudo dscl . -create /Users/"$CURRENT_USER" Picture "$PROFILE_PIC"
    ok "Login screen profile picture (Apple logo, Tokyo Night background)"
else
    skip "Profile picture not found"
fi

# Lock screen wallpaper (macOS can reset this on updates)
WALLPAPER="$HOME/Pictures/tokyo-night-apple.png"
if [[ -f "$WALLPAPER" ]]; then
    USER_UUID="$(dscl . -read /Users/"$(whoami)" GeneratedUID 2>/dev/null | awk '{print $2}')"
    LOCKSCREEN_DIR="/Library/Caches/Desktop Pictures/$USER_UUID"
    if [[ -n "$USER_UUID" && -d "$LOCKSCREEN_DIR" ]]; then
        sudo cp "$WALLPAPER" "$LOCKSCREEN_DIR/lockscreen.png"
        sudo chown "$(whoami):_securityagent" "$LOCKSCREEN_DIR/lockscreen.png"
        sudo chmod 644 "$LOCKSCREEN_DIR/lockscreen.png"
        ok "Lock screen wallpaper"
    else
        skip "Lock screen cache directory not found"
    fi
else
    skip "Wallpaper image not found"
fi

# ---------------------------------------------------------------------------
info "Done! You may need to log out/restart for some changes to take effect."
