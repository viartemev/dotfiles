# ============================================
# Переменные окружения и PATH
# ============================================
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
export LANG="${LANG:-en_US.UTF-8}"
export GOPATH="${GOPATH:-$HOME/go}"
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"

typeset -U path PATH fpath

# Homebrew (ставим РАНЬШЕ системных путей, а не через brew shellenv)
if [[ -x /opt/homebrew/bin/brew ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
    export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
    export HOMEBREW_REPOSITORY="/opt/homebrew"
    [ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"
    export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
fi

path=(
    /opt/homebrew/bin
    /opt/homebrew/sbin
    "$HOME/.local/bin"
    "$GOPATH/bin"
    "$HOME/.opencode/bin"
    "$BUN_INSTALL/bin"
    "$HOME/.strix/bin"
    $path
)

# ============================================
# Цвета и форматирование
# ============================================
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
export LS_COLORS='di=1;36:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=34;43'
