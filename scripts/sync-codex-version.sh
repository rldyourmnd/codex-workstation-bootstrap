#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_FILE="$ROOT_DIR/codex/meta/toolchain.lock"
APPLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY=true
      shift
      ;;
    *)
      echo "[ERROR] Unknown argument: $1"
      echo "Usage: scripts/sync-codex-version.sh [--apply]"
      exit 1
      ;;
  esac
done

say() { echo "[SYNC-CODEX] $*"; }
warn() { echo "[SYNC-CODEX][WARN] $*"; }
err() { echo "[SYNC-CODEX][ERROR] $*"; }

if [[ ! -f "$LOCK_FILE" ]]; then
  err "Missing lock file: $LOCK_FILE"
  exit 1
fi

expected="$(grep -E '^CODEX_VERSION=' "$LOCK_FILE" | head -n1 | cut -d'=' -f2- || true)"
if [[ -z "$expected" || "$expected" == "unknown" ]]; then
  err "No CODEX_VERSION found in $LOCK_FILE"
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  current="missing"
else
  current="$(codex --version 2>/dev/null | awk '{print $2}' || echo unknown)"
fi

if [[ "$current" == "$expected" ]]; then
  say "Codex already pinned to $expected"
  exit 0
fi

if ! $APPLY; then
  warn "Codex version mismatch: expected $expected, got $current"
  say "Run: npm i -g @openai/codex@$expected"
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  err "npm is required to install codex"
  exit 1
fi

say "Installing @openai/codex@$expected via npm -g"
npm i -g "@openai/codex@$expected"

installed="$(codex --version 2>/dev/null | awk '{print $2}' || echo unknown)"
if [[ "$installed" != "$expected" ]]; then
  err "Install completed but version mismatch remains: expected $expected, got $installed"
  exit 1
fi

say "Codex pinned successfully: $installed"

