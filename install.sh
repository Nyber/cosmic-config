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
info "Starting JankyBorders service"
if brew services list | grep -q 'borders.*started'; then
    ok "JankyBorders already running"
else
    brew services start felixkratz/formulae/borders
    ok "JankyBorders started"
fi

info "Starting SketchyBar service"
if brew services list | grep -q 'sketchybar.*started'; then
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
if [[ -f "$HOME/Pictures/tokyo-night-apple.png" ]]; then
    osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "'"$HOME/Pictures/tokyo-night-apple.png"'"' 2>/dev/null || true
    ok "Desktop wallpaper set"
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

# Power management
sudo pmset -a displaysleep 15
ok "Display sleep set to 15 min"

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
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
killall Finder 2>/dev/null || true
ok "Finder: hidden files, extensions, path/status bar, list view, folders first"

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
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 43
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock persistent-others -array
defaults write com.apple.dock wvous-br-corner -int 14
defaults write com.apple.dock wvous-br-modifier -int 0
killall Dock 2>/dev/null || true
ok "Dock: autohide, small icons, stripped apps, Quick Note hot corner"

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

# Login screen profile picture (penguin)
if [[ -f "/Library/User Pictures/Animals/Penguin.heic" ]]; then
    sips -s format jpeg "/Library/User Pictures/Animals/Penguin.heic" --out /tmp/penguin.jpg >/dev/null 2>&1
    CURRENT_USER="$(whoami)"
    printf '0x0A 0x5C 0x3A 0x2C dsRecTypeStandard:Users 2 dsAttrTypeStandard:RecordName externalbinary:dsAttrTypeStandard:JPEGPhoto\n%s:/tmp/penguin.jpg\n' "$CURRENT_USER" > /tmp/user_pic.dsimport
    sudo dsimport /tmp/user_pic.dsimport /Local/Default M 2>/dev/null
    rm -f /tmp/penguin.jpg /tmp/user_pic.dsimport
    ok "Login screen profile picture (penguin)"
else
    skip "Penguin image not found"
fi

# ---------------------------------------------------------------------------
info "Done! You may need to log out/restart for some changes to take effect."
