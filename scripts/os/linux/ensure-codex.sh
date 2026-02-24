#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT_DIR/scripts/os/common/platform.sh"

EXPECTED_VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --expected-version)
      if [[ $# -lt 2 ]]; then
        echo "[ERROR] --expected-version requires a value"
        exit 1
      fi
      EXPECTED_VERSION="$2"
      shift 2
      ;;
    *)
      echo "[ERROR] Unknown argument: $1"
      echo "Usage: scripts/os/linux/ensure-codex.sh [--expected-version <version>]"
      exit 1
      ;;
  esac
done

say() { echo "[OS:linux] $*"; }
warn() { echo "[OS:linux][WARN] $*"; }
err() { echo "[OS:linux][ERROR] $*"; }

if [[ "$(platform_id)" != "linux" ]]; then
  err "This script supports only Linux"
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  if ! command -v npm >/dev/null 2>&1; then
    err "codex is missing and npm is unavailable. Install node/npm first."
    exit 1
  fi

  if [[ -n "$EXPECTED_VERSION" && "$EXPECTED_VERSION" != "unknown" ]]; then
    say "Installing codex via npm (@openai/codex@$EXPECTED_VERSION)"
    npm i -g "@openai/codex@$EXPECTED_VERSION"
  else
    say "Installing codex via npm (@openai/codex)"
    npm i -g @openai/codex
  fi
fi

if ! command -v codex >/dev/null 2>&1; then
  err "codex binary not found after install"
  exit 1
fi

current="$(codex --version 2>/dev/null | awk '{print $2}' || true)"
say "codex version detected: ${current:-unknown}"

if [[ -n "$EXPECTED_VERSION" && "$EXPECTED_VERSION" != "unknown" && "$current" != "$EXPECTED_VERSION" ]]; then
  warn "Expected codex $EXPECTED_VERSION, got $current"
fi
