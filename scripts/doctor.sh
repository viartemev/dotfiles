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
check_symlink "$HOME/.gitconfig" "$REPO_DIR/.gitconfig"
check_symlink "$HOME/.config/git/ignore" "$REPO_DIR/.config/git/ignore"
check_symlink "$HOME/.config/zed" "$REPO_DIR/.config/zed"
for file in settings.json keymap.json; do
  if [[ -f "$REPO_DIR/.config/zed/$file" ]]; then
    ok "~/.config/zed/$file present"
  else
    fail "~/.config/zed/$file missing"
  fi
done

printf '\n== agents ==\n'
PI_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
if [[ -f "$REPO_DIR/agents/links.txt" ]]; then
  while IFS= read -r entry; do
    entry="${entry%%#*}"
    entry="$(printf '%s' "$entry" | tr -d '[:space:]')"
    [[ -n "$entry" ]] || continue
    tool="${entry%%/*}"
    rel="${entry#*/}"
    case "$tool" in
      pi) agent_dir="$PI_AGENT_DIR" ;;
      claude) agent_dir="$HOME/.claude" ;;
      codex) agent_dir="$HOME/.codex" ;;
      bb) agent_dir="$HOME/.bb" ;;
      *) warn "unknown agent tool in links.txt: $tool"; continue ;;
    esac
    if [[ ! -e "$REPO_DIR/agents/$entry" ]]; then
      warn "agents/$entry is listed but not in the repo"
      continue
    fi
    check_symlink "$agent_dir/$rel" "$REPO_DIR/agents/$entry"
  done < "$REPO_DIR/agents/links.txt"
fi

if [[ -f "$PI_AGENT_DIR/mcp.json" ]]; then
  ok "$PI_AGENT_DIR/mcp.json exists (local)"
else
  warn "$PI_AGENT_DIR/mcp.json missing"
fi
if [[ -s "$PI_AGENT_DIR/secrets/explabs-api.key" ]]; then
  ok "$PI_AGENT_DIR/secrets/explabs-api.key has content"
else
  warn "$PI_AGENT_DIR/secrets/explabs-api.key missing or empty"
fi
if [[ -f "$PI_AGENT_DIR/auth.json" ]]; then
  ok "$PI_AGENT_DIR/auth.json exists (local)"
else
  warn "$PI_AGENT_DIR/auth.json missing: run pi and log in to the OAuth providers"
fi
if [[ -x "$REPO_DIR/scripts/agent-sync.sh" ]]; then
  "$REPO_DIR/scripts/agent-sync.sh" check >/dev/null 2>&1 && \
    ok 'agent config free of credentials' || \
    fail 'possible credentials in agents/'
fi
if [[ -L "$REPO_DIR/.git/hooks/pre-commit" ]]; then
  ok 'pre-commit credential guard installed'
else
  warn 'pre-commit credential guard not installed (run ./install.sh)'
fi

printf '\n== local files ==\n'
if [[ -f "$HOME/.zshrc.local" ]]; then
  ok '~/.zshrc.local exists'
else
  warn '~/.zshrc.local missing'
fi

if [[ -f "$HOME/.gitconfig.local" ]]; then
  ok '~/.gitconfig.local exists'
else
  warn '~/.gitconfig.local missing'
fi

printf '\n== syntax ==\n'
if zsh -n "$REPO_DIR/.zshrc"; then
  ok '.zshrc syntax'
else
  fail '.zshrc syntax'
fi

while IFS= read -r -d '' file; do
  if zsh -n "$file"; then
    ok "$(basename "$file") syntax"
  else
    fail "$(basename "$file") syntax"
  fi
done < <(find "$REPO_DIR/.config/zsh" -type f -name '*.zsh' -print0 | sort -z)

if bash -n "$REPO_DIR/install.sh"; then
  ok 'install.sh syntax'
else
  fail 'install.sh syntax'
fi

while IFS= read -r -d '' file; do
  if bash -n "$file"; then
    ok "$(basename "$file") syntax"
  else
    fail "$(basename "$file") syntax"
  fi
done < <(find "$REPO_DIR/scripts" -type f -name '*.sh' -print0 | sort -z)

printf '\n== commands ==\n'
while IFS= read -r formula; do
  [[ -n "$formula" ]] || continue
  check_command "$(formula_to_command "$formula")"
done < <(awk -F'"' '/^brew / {print $2}' "$REPO_DIR/Brewfile")

printf '\n== git config ==\n'
check_git_config core.pager delta
check_git_config core.excludesfile '~/.config/git/ignore'
check_git_config pager.diff delta
check_git_config delta.navigate true
check_git_config delta.side-by-side true
check_git_config fetch.prune true
check_git_config alias.st 'status -sb'
check_git_config alias.lg 'log --graph --decorate --oneline --all'

printf '\n== node ==\n'
if zsh -ic 'command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1'; then
  ok "node $(zsh -ic 'node -v')"
  ok "npm $(zsh -ic 'npm -v')"
else
  warn 'node/npm not found in interactive zsh'
fi

printf '\n== go tooling ==\n'
for cmd in gopls dlv; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "command found: $cmd"
  else
    warn "command missing: $cmd (go install golang.org/x/tools/gopls@latest / github.com/go-delve/delve/cmd/dlv@latest)"
  fi
done

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
