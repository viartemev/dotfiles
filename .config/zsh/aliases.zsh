# ============================================
# Алиасы - Навигация
# ============================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# ============================================
# Алиасы - ls (или eza если установлен)
# ============================================
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons'
    alias ll='eza -lah --icons --git'
    alias la='eza -a --icons'
    alias lt='eza --tree --level=2 --icons'
else
    alias ls='ls -G'
    alias ll='ls -lAhG'
    alias la='ls -AG'
fi

# ============================================
# Алиасы - Git
# ============================================
alias gst='git status -sb'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit -m'
alias gci='git commit'
alias gca='git commit --amend'
alias gp='git push'
alias gpu='git push -u origin'
alias gl='git pull'
alias glog='git log --oneline --graph --decorate --all'
alias gco='git checkout'
alias gsw='git switch'
alias gswc='git switch -c'
alias grs='git restore'
alias grss='git restore --staged'
alias gb='git branch'
alias gba='git branch -a'

if command -v delta >/dev/null 2>&1; then
    alias gd='git -c core.pager=delta diff'
    alias gds='git -c core.pager=delta diff --staged'
    alias gsh='git -c core.pager=delta show'
else
    alias gd='git diff'
    alias gds='git diff --staged'
    alias gsh='git show'
fi

# ============================================
# Алиасы - Поиск и утилиты
# ============================================
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias cls='clear'
alias path='print -l $path'

if command -v bat >/dev/null 2>&1; then
    alias cat='bat --style=plain --paging=never'
fi

if command -v rg >/dev/null 2>&1; then
    alias rgi='rg -i'
fi

if command -v lazygit >/dev/null 2>&1; then
    alias lg='lazygit'
fi

if command -v dust >/dev/null 2>&1; then
    alias space='dust'
fi

if command -v duf >/dev/null 2>&1; then
    alias disk='duf'
fi

if command -v btop >/dev/null 2>&1; then
    alias top='btop'
fi

if command -v tldr >/dev/null 2>&1; then
    alias tl='tldr'
elif command -v tlrc >/dev/null 2>&1; then
    alias tl='tlrc'
fi

# ============================================
# Алиасы - Быстрое редактирование
# ============================================
alias zshconfig="$EDITOR ~/.zshrc"
alias zshdir="$EDITOR ~/.config/zsh"
alias zshreload="source ~/.zshrc && echo 'zsh config reloaded!'"
alias starconfig="$EDITOR ~/.config/starship.toml"
