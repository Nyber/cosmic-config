# Homebrew (global)
eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_NO_ENV_HINTS=1

# OrbStack CLI integration
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
