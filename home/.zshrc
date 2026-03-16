# Disable Claude Code auto-update nag (managed via Homebrew)
export DISABLE_AUTOUPDATER=1

# eza aliases
alias ls='eza --icons --group --links --blocksize'
alias ll='eza -la --icons --group --links'

# Obsidian terminal lacks Nerd Font — fall back to plain ls
if [[ "$__CFBundleIdentifier" == "md.obsidian" ]]; then
  alias ls='command ls'
  alias ll='command ls -al'
fi

# Explicit key bindings (fallback if terminfo is missing)
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char
bindkey '^[[3~' delete-char

# Starship prompt
eval "$(starship init zsh)"

# Plugins (guard — async PTY conflicts with sudo su)
if [[ -o login || -z "$SUDO_USER" ]]; then
  [[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# fzf
command -v fzf &>/dev/null && source <(fzf --zsh)
