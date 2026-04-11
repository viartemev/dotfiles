# ============================================
# Автодополнение
# ============================================
fpath=(~/.zsh/zsh-completions/src $fpath)
autoload -Uz compinit

local_zsh_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$local_zsh_cache_dir" ]] || mkdir -p "$local_zsh_cache_dir"
_zcompdump="$local_zsh_cache_dir/zcompdump-${ZSH_VERSION}"

if [[ -s "$_zcompdump" ]]; then
    compinit -C -d "$_zcompdump"
else
    compinit -d "$_zcompdump"
fi

unset _zcompdump local_zsh_cache_dir

zstyle ':completion:*' menu select                           # Меню выбора
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # Case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # Цвета в списке
zstyle ':completion:*' rehash true                          # Автоматически находить новые команды
zstyle ':completion:*' use-cache on                         # Кэш автодополнений
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
