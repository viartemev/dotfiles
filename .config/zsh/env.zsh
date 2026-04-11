# ============================================
# Переменные окружения и PATH
# ============================================
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
export LANG="${LANG:-en_US.UTF-8}"
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
export GOPATH="${GOPATH:-$HOME/go}"
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"

typeset -U path PATH fpath

# Homebrew (для M1/M2/M3 Mac)
if [[ -x /opt/homebrew/bin/brew ]] && [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

path=(
    "$HOME/.local/bin"
    "$GOPATH/bin"
    "$PYENV_ROOT/bin"
    "$HOME/.opencode/bin"
    "$BUN_INSTALL/bin"
    $path
)

# ============================================
# Цвета и форматирование
# ============================================
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
export LS_COLORS='di=1;36:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=34;43'
