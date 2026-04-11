#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX="backup-$(date +%Y%m%d-%H%M%S)"
INSTALL_BREW=0
SKIP_GIT_CONFIG=0

log() {
  printf '\033[1;34m==>\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33mwarning:\033[0m %s\n' "$*"
}

backup_path() {
  local target="$1"

  if [[ -e "$target" || -L "$target" ]]; then
    mv "$target" "${target}.${BACKUP_SUFFIX}"
    log "backup: $target -> ${target}.${BACKUP_SUFFIX}"
  fi
}

symlink_path() {
  local source_path="$1"
  local target_path="$2"

  mkdir -p "$(dirname "$target_path")"

  if [[ -L "$target_path" ]] && [[ "$(readlink "$target_path")" == "$source_path" ]]; then
    log "already linked: $target_path"
    return 0
  fi

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    backup_path "$target_path"
  fi

  ln -snf "$source_path" "$target_path"
  log "linked: $target_path -> $source_path"
}

configure_git_delta() {
  if ! command -v git >/dev/null 2>&1; then
    warn "git not found, skipping global git config"
    return 0
  fi

  if ! command -v delta >/dev/null 2>&1; then
    warn "delta not found, skipping delta git config"
    return 0
  fi

  git config --global core.pager delta
  git config --global interactive.diffFilter 'delta --color-only'
  git config --global delta.navigate true
  git config --global delta.side-by-side true
  git config --global delta.line-numbers true
  git config --global delta.hyperlinks true
  git config --global diff.colorMoved default
  git config --global merge.conflictstyle zdiff3
  git config --global pager.diff delta
  git config --global pager.log delta
  git config --global pager.reflog delta
  git config --global pager.show delta

  log 'configured global git + delta'
}

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --brew              install/update tools from Brewfile
  --skip-git-config   do not configure global git + delta
  -h, --help          show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brew)
      INSTALL_BREW=1
      ;;
    --skip-git-config)
      SKIP_GIT_CONFIG=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      warn "unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

log "repo: $REPO_DIR"

if [[ $INSTALL_BREW -eq 1 ]]; then
  if command -v brew >/dev/null 2>&1; then
    log 'installing brew dependencies from Brewfile'
    brew bundle --file "$REPO_DIR/Brewfile"
  else
    warn 'Homebrew not found, skipping Brewfile install'
  fi
fi

symlink_path "$REPO_DIR/.zshrc" "$HOME/.zshrc"
symlink_path "$REPO_DIR/.config/zsh" "$HOME/.config/zsh"
symlink_path "$REPO_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

if [[ ! -f "$HOME/.zshrc.local" ]]; then
  cp "$REPO_DIR/.zshrc.local.example" "$HOME/.zshrc.local"
  log 'created ~/.zshrc.local from example'
fi

if [[ $SKIP_GIT_CONFIG -eq 0 ]]; then
  configure_git_delta
fi

log 'done'
printf '\nNext steps:\n'
printf '  1) source ~/.zshrc\n'
printf '  2) atuin import auto\n'
printf '  3) for project envs: direnv allow\n'
