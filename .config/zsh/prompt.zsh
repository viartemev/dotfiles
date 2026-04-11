# ============================================
# Prompt и подсветка
# ============================================
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Держим zsh-syntax-highlighting в самом конце
[[ -r ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
