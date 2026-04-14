#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0

ok() {
  printf '\033[32m[ok]\033[0m %s\n' "$*"
}

warn() {
  printf '\033[33m[warn]\033[0m %s\n' "$*"
}

fail() {
  printf '\033[31m[fail]\033[0m %s\n' "$*"
  FAILED=1
}

check_symlink() {
  local target="$1"
  local expected="$2"

  if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$expected" ]]; then
    ok "$target -> $expected"
  elif [[ -e "$target" || -L "$target" ]]; then
    fail "$target exists but is not linked to $expected"
  else
    fail "$target is missing"
  fi
}

formula_to_command() {
  case "$1" in
    git-delta) echo delta ;;
    ripgrep) echo rg ;;
    tlrc) echo tldr ;;
    *) echo "$1" ;;
  esac
}

check_command() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "command found: $cmd"
  else
    fail "command missing: $cmd"
  fi
}

check_git_config() {
  local key="$1"
  local expected="$2"
  local value
  value="$(git config --global --get "$key" || true)"

  if [[ "$value" == "$expected" ]]; then
    ok "git config $key = $expected"
  else
    fail "git config $key expected '$expected', got '${value:-<unset>}'"
  fi
}

printf '== symlinks ==\n'
check_symlink "$HOME/.zshrc" "$REPO_DIR/.zshrc"
check_symlink "$HOME/.config/zsh" "$REPO_DIR/.config/zsh"
check_symlink "$HOME/.config/starship.toml" "$REPO_DIR/.config/starship.toml"
check_symlink "$HOME/.tmux.conf" "$REPO_DIR/.tmux.conf"

printf '\n== syntax ==\n'
if zsh -n "$REPO_DIR/.zshrc"; then
  ok ".zshrc syntax"
else
  fail ".zshrc syntax"
fi

while IFS= read -r -d '' file; do
  if zsh -n "$file"; then
    ok "$(basename "$file") syntax"
  else
    fail "$(basename "$file") syntax"
  fi
done < <(find "$REPO_DIR/.config/zsh" -type f -name '*.zsh' -print0 | sort -z)

printf '\n== commands ==\n'
while IFS= read -r formula; do
  [[ -n "$formula" ]] || continue
  check_command "$(formula_to_command "$formula")"
done < <(awk -F'"' '/^brew / {print $2}' "$REPO_DIR/Brewfile")

printf '\n== git config ==\n'
check_git_config core.pager delta
check_git_config pager.diff delta
check_git_config delta.navigate true
check_git_config delta.side-by-side true
check_git_config alias.st 'status -sb'
check_git_config alias.lg 'log --graph --decorate --oneline --all'

printf '\n== tmux ==\n'
if command -v tmux >/dev/null 2>&1; then
  ok "command found: tmux"
else
  warn "command missing: tmux"
fi

printf '\n== summary ==\n'
if [[ $FAILED -eq 0 ]]; then
  ok 'doctor passed'
else
  fail 'doctor found issues'
fi

exit $FAILED
