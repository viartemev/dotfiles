#!/usr/bin/env bash
# Deprecated alias kept for older instructions: use scripts/agent-sync.sh.
# `pi-capture` now captures every shared agent config, not only pi.
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$REPO_DIR/scripts/agent-sync.sh" capture
