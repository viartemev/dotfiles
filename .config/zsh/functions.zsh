# ============================================
# Функции
# ============================================

# Создать директорию и перейти в нее
mkcd() {
    emulate -L zsh

    [[ $# -eq 1 ]] || {
        echo 'usage: mkcd <directory>'
        return 1
    }

    mkdir -p "$1" && builtin cd -- "$1"
}

# Извлечь любой архив
extract() {
    emulate -L zsh

    [[ $# -eq 1 ]] || {
        echo 'usage: extract <archive>'
        return 1
    }

    [[ -f "$1" ]] || {
        echo "'$1' is not a valid file"
        return 1
    }

    case "$1" in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz)  tar xzf "$1" ;;
        *.bz2)     bunzip2 "$1" ;;
        *.rar)     unrar e "$1" ;;
        *.gz)      gunzip "$1" ;;
        *.tar)     tar xf "$1" ;;
        *.tbz2)    tar xjf "$1" ;;
        *.tgz)     tar xzf "$1" ;;
        *.zip)     unzip "$1" ;;
        *.Z)       uncompress "$1" ;;
        *.7z)      7z x "$1" ;;
        *)
            echo "'$1' cannot be extracted via extract()"
            return 1
            ;;
    esac
}

# Создать backup файла или директории
backup() {
    emulate -L zsh

    [[ $# -eq 1 ]] || {
        echo 'usage: backup <path>'
        return 1
    }

    [[ -e "$1" ]] || {
        echo "'$1' does not exist"
        return 1
    }

    command cp -R "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"
}

# Профилирование старта zsh
profile_zsh_startup() {
    emulate -L zsh

    local tmpdir
    tmpdir=$(mktemp -d) || return 1

    cat > "$tmpdir/.zshrc" <<'EOF'
zmodload zsh/zprof
source "$HOME/.zshrc"
zprof
EOF

    ZDOTDIR="$tmpdir" zsh -i -c exit
    command rm -rf -- "$tmpdir"
}

# Выбрать файл через fd + fzf и открыть в editor
vf() {
    emulate -L zsh

    command -v fzf >/dev/null 2>&1 || { echo 'fzf is required'; return 1; }

    local file_cmd preview_cmd file
    if command -v fd >/dev/null 2>&1; then
        file_cmd=(fd --type f --hidden --follow --exclude .git)
    else
        file_cmd=(find . -type f -not -path '*/.git/*')
    fi

    if command -v bat >/dev/null 2>&1; then
        preview_cmd='bat --style=plain --color=always --line-range=:200 {}'
    else
        preview_cmd='sed -n "1,200p" {}'
    fi

    file=$("${file_cmd[@]}" | fzf --preview "$preview_cmd") || return
    "$EDITOR" "$file"
}

# Выбрать директорию через fd + fzf и перейти в нее.
# По умолчанию поиск быстрый и неглубокий, чтобы не сканировать весь диск.
cdf() {
    emulate -L zsh

    command -v fzf >/dev/null 2>&1 || { echo 'fzf is required'; return 1; }

    local dir_cmd dir
    if command -v fd >/dev/null 2>&1; then
        dir_cmd=(fd --type d --hidden --follow --max-depth 3 \
            --exclude .git \
            --exclude node_modules \
            --exclude dist \
            --exclude build \
            --exclude target \
            --exclude .next \
            --exclude vendor \
            --exclude .venv)
    else
        dir_cmd=(find . -maxdepth 3 -type d \
            -not -path '*/.git/*' \
            -not -path '*/node_modules/*' \
            -not -path '*/dist/*' \
            -not -path '*/build/*' \
            -not -path '*/target/*' \
            -not -path '*/.next/*' \
            -not -path '*/vendor/*' \
            -not -path '*/.venv/*')
    fi

    dir=$("${dir_cmd[@]}" | fzf) || return
    builtin cd -- "$dir"
}

# Полный глубокий поиск директорий, если реально нужно пройти всё дерево.
cdfa() {
    emulate -L zsh

    command -v fzf >/dev/null 2>&1 || { echo 'fzf is required'; return 1; }

    local dir_cmd dir
    if command -v fd >/dev/null 2>&1; then
        dir_cmd=(fd --type d --hidden --follow \
            --exclude .git \
            --exclude node_modules \
            --exclude dist \
            --exclude build \
            --exclude target \
            --exclude .next \
            --exclude vendor \
            --exclude .venv)
    else
        dir_cmd=(find . -type d \
            -not -path '*/.git/*' \
            -not -path '*/node_modules/*' \
            -not -path '*/dist/*' \
            -not -path '*/build/*' \
            -not -path '*/target/*' \
            -not -path '*/.next/*' \
            -not -path '*/vendor/*' \
            -not -path '*/.venv/*')
    fi

    dir=$("${dir_cmd[@]}" | fzf) || return
    builtin cd -- "$dir"
}

# Поиск по проекту через rg + fzf и открытие результата в editor
rgv() {
    emulate -L zsh

    command -v rg >/dev/null 2>&1 || { echo 'ripgrep (rg) is required'; return 1; }
    command -v fzf >/dev/null 2>&1 || { echo 'fzf is required'; return 1; }

    [[ $# -gt 0 ]] || {
        echo 'usage: rgv <query>'
        return 1
    }

    local preview_cmd selection file line
    if command -v bat >/dev/null 2>&1; then
        preview_cmd='bat --style=plain --color=always --highlight-line {2} {1}'
    else
        preview_cmd='sed -n "1,200p" {1}'
    fi

    selection=$(rg --line-number --no-heading --hidden --glob '!.git' "$*" | \
        fzf --delimiter ':' --preview "$preview_cmd") || return

    file=${selection%%:*}
    line=${selection#*:}
    line=${line%%:*}

    "$EDITOR" "+${line}" "$file"
}

# Выбрать git branch через fzf и переключиться
gbr() {
    emulate -L zsh

    command -v git >/dev/null 2>&1 || return 1
    command -v fzf >/dev/null 2>&1 || { echo 'fzf is required'; return 1; }
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo 'not a git repository'; return 1; }

    local branch
    branch=$(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads refs/remotes | awk '!seen[$0]++' | fzf) || return
    branch=${branch#origin/}
    git switch "$branch" 2>/dev/null || git checkout "$branch"
}

# Выбрать commit через fzf и показать его
# Полезно для быстрого просмотра истории с preview.
glogf() {
    emulate -L zsh

    command -v git >/dev/null 2>&1 || return 1
    command -v fzf >/dev/null 2>&1 || { echo 'fzf is required'; return 1; }
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo 'not a git repository'; return 1; }

    local selection commit
    selection=$(git log --graph --color=always --date=short \
        --pretty=format:'%C(auto)%h %C(blue)%ad%C(reset) %C(yellow)%d%C(reset) %s %C(black)%C(bold)- %an' | \
        fzf --ansi --no-sort --reverse --preview 'commit=$(echo {} | grep -o "[a-f0-9]\{7,\}" | head -1); [ -n "$commit" ] && git show --color=always --stat "$commit"') || return

    commit=$(echo "$selection" | grep -o '[a-f0-9]\{7,\}' | head -1) || return
    [[ -n "$commit" ]] && git show --stat "$commit"
}

# Выбрать commit и создать fixup commit для autosquash workflow
gfixup() {
    emulate -L zsh

    command -v git >/dev/null 2>&1 || return 1
    command -v fzf >/dev/null 2>&1 || { echo 'fzf is required'; return 1; }
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo 'not a git repository'; return 1; }

    local selection commit
    selection=$(git log --color=always --pretty=format:'%C(auto)%h %s %C(black)%C(bold)- %an, %ar' | \
        fzf --ansi --reverse --preview 'commit=$(echo {} | awk "{print \$1}"); [ -n "$commit" ] && git show --color=always --stat "$commit"') || return

    commit=$(echo "$selection" | awk '{print $1}') || return
    [[ -n "$commit" ]] && git commit --fixup "$commit"
}

# Выбрать измененный файл через fzf и открыть его в editor
gcf() {
    emulate -L zsh

    command -v git >/dev/null 2>&1 || return 1
    command -v fzf >/dev/null 2>&1 || { echo 'fzf is required'; return 1; }
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo 'not a git repository'; return 1; }

    local selection file preview_cmd

    if command -v bat >/dev/null 2>&1; then
        preview_cmd='file=$(echo {} | cut -c4- | awk -F" -> " "{print \$NF}"); if git diff --quiet -- "$file" 2>/dev/null && git diff --cached --quiet -- "$file" 2>/dev/null; then bat --style=plain --color=always --line-range=:200 "$file"; else git diff --color=always -- "$file"; git diff --cached --color=always -- "$file"; fi'
    else
        preview_cmd='file=$(echo {} | cut -c4- | awk -F" -> " "{print \$NF}"); git diff --color=always -- "$file"; git diff --cached --color=always -- "$file"; [ -f "$file" ] && sed -n "1,200p" "$file"'
    fi

    selection=$(git status --short | fzf --reverse --preview "$preview_cmd") || return
    file=$(echo "$selection" | cut -c4- | awk -F' -> ' '{print $NF}')

    [[ -n "$file" ]] && "$EDITOR" "$file"
}
