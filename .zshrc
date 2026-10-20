# Entrypoint for modular zsh config
for file in \
    "$HOME/.config/zsh/options.zsh" \
    "$HOME/.config/zsh/env.zsh" \
    "$HOME/.config/zsh/completion.zsh" \
    "$HOME/.config/zsh/aliases.zsh" \
    "$HOME/.config/zsh/functions.zsh" \
    "$HOME/.config/zsh/integrations.zsh" \
    "$HOME/.config/zsh/prompt.zsh"
do
    [[ -r "$file" ]] && source "$file"
done

[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Установщики любят дописывать сюда export PATH=... — переносите их
# в ~/.config/zsh/env.zsh (массив path), иначе они перекроют mise.
