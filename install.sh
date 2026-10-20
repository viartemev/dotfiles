#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX="backup-$(date +%Y%m%d-%H%M%S)"
INSTALL_BREW=0
APPLY_MACOS_DEFAULTS=0

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

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --brew       install/update tools from Brewfile
  --macos      apply macOS defaults from scripts/macos-defaults.sh
  -h, --help   show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brew)
      INSTALL_BREW=1
      ;;
    --macos)
      APPLY_MACOS_DEFAULTS=1
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
    if [[ -f "$REPO_DIR/Brewfile.work" ]]; then
      log 'installing machine-specific deps from Brewfile.work'
      brew bundle --file "$REPO_DIR/Brewfile.work"
    fi
  else
    warn 'Homebrew not found, skipping Brewfile install'
  fi
fi

symlink_path "$REPO_DIR/.zshrc" "$HOME/.zshrc"
symlink_path "$REPO_DIR/.config/zsh" "$HOME/.config/zsh"
symlink_path "$REPO_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
symlink_path "$REPO_DIR/.tmux.conf" "$HOME/.tmux.conf"
symlink_path "$REPO_DIR/.gitconfig" "$HOME/.gitconfig"
symlink_path "$REPO_DIR/.config/git/ignore" "$HOME/.config/git/ignore"
symlink_path "$REPO_DIR/.config/mise/config.toml" "$HOME/.config/mise/config.toml"

if [[ ! -f "$HOME/.zshrc.local" ]]; then
  cp "$REPO_DIR/.zshrc.local.example" "$HOME/.zshrc.local"
  log 'created ~/.zshrc.local from example'
fi

if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  cp "$REPO_DIR/.gitconfig.local.example" "$HOME/.gitconfig.local"
  log 'created ~/.gitconfig.local from example'
fi

if [[ $APPLY_MACOS_DEFAULTS -eq 1 ]]; then
  "$REPO_DIR/scripts/macos-defaults.sh"
fi

log 'done'
printf '\nNext steps:\n'
printf '  1) source ~/.zshrc\n'
printf '  2) review ~/.gitconfig.local and fill in user.name / user.email\n'
printf '  3) atuin import auto\n'
printf '  4) in tmux: press prefix + I to install TPM plugins\n'
printf '  5) for project envs: direnv allow\n'
printf '  6) optional: make macos\n'
printf '  7) run ./scripts/doctor.sh to verify setup\n'
