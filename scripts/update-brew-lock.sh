#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_FILE="$REPO_DIR/Brewfile.lock.json"

if ! command -v brew >/dev/null 2>&1; then
  echo 'brew not found' >&2
  exit 1
fi

mapfile -t formulas < <(awk -F'"' '/^brew / {print $2}' "$REPO_DIR/Brewfile")

if [[ ${#formulas[@]} -eq 0 ]]; then
  echo 'no formulas found in Brewfile' >&2
  exit 1
fi

brew info --json=v2 "${formulas[@]}" > "$LOCK_FILE"
printf 'Wrote %s\n' "$LOCK_FILE"
