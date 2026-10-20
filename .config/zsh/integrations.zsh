# ============================================
# Интеграции и плагины
# ============================================

# zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
    alias cd='z'
fi

# zsh-autosuggestions
if [[ -r ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# fzf
if command -v fzf >/dev/null 2>&1 && [[ -t 0 ]] && [[ -t 1 ]]; then
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
    fi

    if command -v bat >/dev/null 2>&1; then
        export FZF_CTRL_T_OPTS='--preview "bat --style=plain --color=always --line-range=:200 {}"'
    fi

    if command -v eza >/dev/null 2>&1; then
        export FZF_ALT_C_OPTS='--preview "eza --tree --level=2 --color=always {} | head -200"'
    fi

    eval "$(fzf --zsh)"
fi

# atuin
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh --disable-up-arrow)"
fi

# direnv
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# mise — единый version manager для всего
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi

# bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
