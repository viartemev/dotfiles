#!/usr/bin/env bash
# Share agent configuration between machines through this repository.
#
#   ./scripts/agent-sync.sh status    show what is linked, drifted or uncommitted
#   ./scripts/agent-sync.sh capture   copy live config into the repo (secrets stay out)
#   ./scripts/agent-sync.sh sync      capture, commit, rebase-pull, push
#   ./scripts/agent-sync.sh check     scan config files for credentials
#   ./scripts/agent-sync.sh add <tool>/<path>   start sharing a new path
#
# Shared paths are listed in agents/links.txt. install.sh creates the symlinks,
# so files edited in place are versioned immediately; capture is only needed for
# paths that are not linked yet or were changed while the link was missing.
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LINKS_FILE="$REPO_DIR/agents/links.txt"
COMMIT_MESSAGE="${AGENT_SYNC_COMMIT_MESSAGE:-}"

# Never share or scan these; they hold credentials or per-machine state.
SECRET_NAMES='auth\.json|\.credentials[^/]*|credentials\.json|mcp\.json|auth-secret|bb\.db.*|history\.jsonl|models_cache\.json|settings\.local\.json|installation_id|host-id|machine-environment-key|\.env[^/]*|secrets/'
JUNK_NAMES='\.DS_Store|node_modules|\.git$|\.backup-[0-9]|\.bak[.-]'
MAX_BYTES=$((512 * 1024))

CREDENTIAL_PATTERNS='xpl_[A-Za-z0-9]{16,}|sk-[A-Za-z0-9]{20,}|sk-ant-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|xox[abprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{20,}\.eyJ[A-Za-z0-9_-]{10,}\.'

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*"; }
err() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; }
ok() { printf '\033[32m[ok]\033[0m %s\n' "$*"; }

agent_dir_for() {
  case "$1" in
    pi) printf '%s' "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}" ;;
    claude) printf '%s' "$HOME/.claude" ;;
    codex) printf '%s' "$HOME/.codex" ;;
    bb) printf '%s' "$HOME/.bb" ;;
    *) return 1 ;;
  esac
}

# Print "<tool> <relative-path>" for every manifest entry, comments stripped.
manifest_entries() {
  [[ -f "$LINKS_FILE" ]] || return 0
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | tr -d '[:space:]')"
    [[ -n "$line" ]] || continue
    printf '%s\n' "$line"
  done <"$LINKS_FILE"
}

cmd_status() {
  local entry tool rel src dst state=0
  while IFS= read -r entry; do
    tool="${entry%%/*}"
    rel="${entry#*/}"
    src="$REPO_DIR/agents/$entry"
    dst="$(agent_dir_for "$tool")/$rel" || { warn "unknown tool in manifest: $tool"; continue; }

    if [[ ! -e "$src" ]]; then
      printf '  %-34s not in repo yet (optional)\n' "$entry"
      continue
    fi
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
      printf '  %-34s ' "$entry"
      ok "linked"
    elif [[ -e "$dst" ]]; then
      printf '  %-34s ' "$entry"
      printf '\033[33m[not linked]\033[0m %s exists\n' "$dst"
      state=1
    else
      printf '  %-34s ' "$entry"
      printf '\033[33m[not linked]\033[0m %s missing\n' "$dst"
      state=1
    fi
  done < <(manifest_entries)

  printf '\n'
  if ! git -C "$REPO_DIR" diff --quiet -- agents 2>/dev/null ||
    [[ -n "$(git -C "$REPO_DIR" status --porcelain -- agents 2>/dev/null)" ]]; then
    warn 'repo has uncommitted changes under agents/'
    git -C "$REPO_DIR" --no-pager diff --stat -- agents | sed 's/^/    /'
    warn 'run: ./scripts/agent-sync.sh sync'
    state=1
  else
    ok 'repo changes under agents/ are committed'
  fi
  return $state
}

# Replace literal API keys in a captured models.json with a reference to
# <agent-dir>/secrets/<provider>-api.key so the repo never holds the secret.
redact_model_keys() {
  local models="$1" agent_dir="$2"
  AGENT_DIR="$agent_dir" MODELS="$models" python3 - <<'PY'
import json
import os
import pathlib

models = pathlib.Path(os.environ["MODELS"])
agent_dir = pathlib.Path(os.environ["AGENT_DIR"])
secrets = agent_dir / "secrets"

try:
    data = json.loads(models.read_text())
except (OSError, ValueError):
    raise SystemExit(0)

changed = False
for name, provider in (data.get("providers") or {}).items():
    if not isinstance(provider, dict):
        continue
    key = provider.get("apiKey")
    if isinstance(key, str) and key and not key.startswith(("!", "$")):
        secrets.mkdir(parents=True, exist_ok=True)
        os.chmod(secrets, 0o700)
        target = secrets / f"{name}-api.key"
        target.write_text(key + "\n")
        os.chmod(target, 0o600)
        provider["apiKey"] = f"!cat ~/.pi/agent/secrets/{name}-api.key"
        changed = True
        print(f"    moved {name} apiKey into {target}")

if changed:
    models.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
PY
}

capture_one() {
  local tool="$1" rel="$2" src="$3" dst="$4"

  # Already the linked repo path: live edits are versioned, nothing to copy.
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    return 0
  fi

  if [[ -d "$dst" ]]; then
    mkdir -p "$src"
    rsync -aL \
      --exclude '.DS_Store' --exclude 'node_modules' --exclude '.git' \
      --exclude '*.backup-*' --exclude '*.bak*' --exclude '.trash' \
      "$dst/" "$src/"
    return 0
  fi

  [[ -e "$dst" ]] || return 0
  local size
  size="$(wc -c <"$dst" | tr -d ' ')"
  if ((size > MAX_BYTES)); then
    warn "$rel: $((size / 1024))K is larger than the limit, skipping"
    return 0
  fi
  mkdir -p "$(dirname "$src")"
  cp -L "$dst" "$src"
}

cmd_capture() {
  local entry tool rel src dst
  while IFS= read -r entry; do
    tool="${entry%%/*}"
    rel="${entry#*/}"
    src="$REPO_DIR/agents/$entry"
    dst="$(agent_dir_for "$tool")/$rel" || continue
    capture_one "$tool" "$rel" "$src" "$dst"
  done < <(manifest_entries)

  if [[ -f "$REPO_DIR/agents/pi/models.json" && -d "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}" ]]; then
    redact_model_keys \
      "$REPO_DIR/agents/pi/models.json" \
      "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
  fi

  prune_excluded
  cmd_check
}

# Drop anything that slipped in from a live directory but must never be shared.
prune_excluded() {
  local found
  found="$(find "$REPO_DIR/agents" -type f \
    \( -name 'auth.json' -o -name '.credentials*' -o -name 'mcp.json' \
    -o -name 'auth-secret' -o -name 'history.jsonl' -o -name '*.sqlite*' \
    -o -name '*.db' -o -name '.env' \) -print 2>/dev/null || true)"
  if [[ -n "$found" ]]; then
    warn 'removing machine-local files that must not be committed:'
    while IFS= read -r file; do
      printf '    %s\n' "${file#"$REPO_DIR/"}"
      rm -f "$file"
    done <<<"$found"
  fi
}

cmd_check() {
  local staged=0
  case "${1:-}" in
    --staged) staged=1 ;;
  esac

  local hits="" file content
  if ((staged)); then
    content="$(git -C "$REPO_DIR" diff --cached -U0 -- agents 2>/dev/null || true)"
    if [[ -n "$content" ]]; then
      hits="$(printf '%s\n' "$content" | grep -E '^\+' |
        grep -nIE "$CREDENTIAL_PATTERNS" || true)"
    fi
  else
    while IFS= read -r file; do
      hits="$hits$(grep -nIE "$CREDENTIAL_PATTERNS" "$file" 2>/dev/null |
        sed "s|^|${file#"$REPO_DIR/"}:|" || true)"$'\n'
    done < <(find "$REPO_DIR/agents" -type f -size -"${MAX_BYTES}"c \
      \( -name '*.json' -o -name '*.jsonl' -o -name '*.toml' -o -name '*.md' \
      -o -name '*.yaml' -o -name '*.yml' -o -name '*.txt' -o -name '*.sh' \
      -o -name '*.env' \) -print 2>/dev/null)
    hits="$(printf '%s' "$hits" | sed '/^$/d')"
  fi

  if [[ -n "$hits" ]]; then
    err 'possible credentials in shared agent config:'
    printf '%s\n' "$hits" | sed 's/^/    /' | cut -c1-160
    err 'move the value out of the repo before committing'
    return 1
  fi
  ok 'no credentials found in agents/'
}

cmd_sync() {
  cmd_capture || return 1

  if git -C "$REPO_DIR" diff --quiet -- agents && [[ -z "$(git -C "$REPO_DIR" status --porcelain -- agents)" ]]; then
    log 'nothing to commit'
  else
    local message="${COMMIT_MESSAGE:-agents: sync config from $(hostname -s)}"
    git -C "$REPO_DIR" add -A -- agents
    git -C "$REPO_DIR" commit -q -m "$message"
    log "committed: $message"
  fi

  log 'pulling remote changes'
  git -C "$REPO_DIR" pull --rebase --autostash --quiet origin HEAD

  if git -C "$REPO_DIR" rev-parse '@{u}' >/dev/null 2>&1; then
    if [[ -n "$(git -C "$REPO_DIR" log --oneline '@{u}..HEAD')" ]]; then
      log 'pushing'
      git -C "$REPO_DIR" push --quiet
      ok 'pushed'
    else
      log 'remote already up to date'
    fi
  fi
}

cmd_add() {
  local entry="${1:-}"
  [[ -n "$entry" ]] || { err 'usage: agent-sync.sh add <tool>/<path>'; return 1; }
  local tool="${entry%%/*}"
  local dst
  dst="$(agent_dir_for "$tool")/${entry#*/}" || { err "unknown tool: $tool"; return 1; }
  if [[ -e "$dst" ]]; then
    ok "source exists: $dst"
  else
    warn "source does not exist yet: $dst"
  fi
  case "$entry" in
    *[!/]) ;;
    *)
      entry="${entry%/}"
      if [[ -d "$dst" ]]; then
        entry="$entry/"
        mkdir -p "$REPO_DIR/agents/$entry"
      elif [[ -e "$dst" ]]; then
        mkdir -p "$(dirname "$REPO_DIR/agents/$entry")"
        cp -L "$dst" "$REPO_DIR/agents/$entry"
      fi
      ;;
  esac
  if grep -qxF "$entry" "$LINKS_FILE" 2>/dev/null; then
    ok "already listed: $entry"
  else
    printf '%s\n' "$entry" >>"$LINKS_FILE"
    log "added to agents/links.txt: $entry"
    log 'run ./install.sh to create the symlink'
  fi
}

case "${1:-status}" in
  status) cmd_status ;;
  capture) cmd_capture ;;
  sync) cmd_sync ;;
  check) shift; cmd_check "$@" ;;
  add) shift; cmd_add "$@" ;;
  -h | --help | help)
    sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    ;;
  *)
    err "unknown command: $1"
    sed -n '3,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
