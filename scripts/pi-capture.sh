#!/usr/bin/env bash
# Copy the current machine's pi configuration into this repository.
#
# Shared files (settings.json, models.json, AGENTS.md) are safe to commit:
# literal API keys in models.json are moved into <agent-dir>/secrets and
# replaced with "!cat ~/.pi/agent/secrets/<provider>-api.key".
# mcp.json is written as pi/mcp.json.example because server URLs are usually
# per-machine/internal.
#
# Typical use on a machine that already has a pi config but no repo checkout:
#   cd ~/dotfiles && ./scripts/pi-capture.sh
#   git checkout -b pi-config-$(hostname -s) && git add pi && git diff --cached
#   git commit -m 'pi: config from <host>' && git push -u origin HEAD
# Then run ./install.sh on that machine to replace the files with symlinks.
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"

log() {
  printf '\033[1;34m==>\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33mwarning:\033[0m %s\n' "$*"
}

if [[ ! -d "$AGENT_DIR" ]]; then
  warn "agent directory not found: $AGENT_DIR"
  exit 1
fi

mkdir -p "$REPO_DIR/pi" "$AGENT_DIR/secrets"
chmod 700 "$AGENT_DIR/secrets"

for file in settings.json AGENTS.md; do
  if [[ -f "$AGENT_DIR/$file" ]]; then
    cp "$AGENT_DIR/$file" "$REPO_DIR/pi/$file"
    log "captured $file"
  else
    warn "$file not found in $AGENT_DIR"
  fi
done

if [[ -f "$AGENT_DIR/models.json" ]]; then
  AGENT_DIR="$AGENT_DIR" REPO_DIR="$REPO_DIR" python3 - <<'PY'
import json
import os
import pathlib

agent_dir = pathlib.Path(os.environ["AGENT_DIR"])
repo_dir = pathlib.Path(os.environ["REPO_DIR"])
secrets = agent_dir / "secrets"

data = json.loads((agent_dir / "models.json").read_text())
for name, provider in (data.get("providers") or {}).items():
    key = provider.get("apiKey")
    if isinstance(key, str) and key and not key.startswith(("!", "$")):
        target = secrets / f"{name}-api.key"
        target.write_text(key + "\n")
        os.chmod(target, 0o600)
        provider["apiKey"] = f"!cat ~/.pi/agent/secrets/{name}-api.key"
        print(f"moved {name} apiKey into {target}")

(repo_dir / "pi" / "models.json").write_text(
    json.dumps(data, indent=2, ensure_ascii=False) + "\n"
)
PY
  log 'captured models.json (API keys are referenced from secrets/)'
else
  warn "models.json not found in $AGENT_DIR"
fi

if [[ -f "$AGENT_DIR/mcp.json" ]]; then
  cp "$AGENT_DIR/mcp.json" "$REPO_DIR/pi/mcp.json.example"
  log 'captured mcp.json as pi/mcp.json.example'
  warn 'review pi/mcp.json.example: internal or private server URLs should not be committed'
fi

printf '\n'
log "diff in $REPO_DIR/pi"
git -C "$REPO_DIR" --no-pager diff --stat -- pi || true
