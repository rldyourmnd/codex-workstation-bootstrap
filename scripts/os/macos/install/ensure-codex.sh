#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
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
      echo "Usage: scripts/os/macos/install/ensure-codex.sh [--expected-version <version>]"
      exit 1
      ;;
  esac
done

say() { echo "[OS:macOS] $*"; }
warn() { echo "[OS:macOS][WARN] $*"; }
err() { echo "[OS:macOS][ERROR] $*"; }

if [[ "$(platform_id)" != "macos" ]]; then
  err "This script supports only macOS"
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  err "Homebrew is required on macOS. Install first: https://brew.sh/"
  exit 1
fi

if ! brew list --cask codex >/dev/null 2>&1; then
  say "Installing codex via Homebrew cask"
  brew install --cask codex
fi

if ! command -v codex >/dev/null 2>&1; then
  err "codex binary not found after brew install"
  exit 1
fi

current="$(codex --version 2>/dev/null | awk '{print $2}' || true)"
say "codex version detected: ${current:-unknown}"

if [[ -n "$EXPECTED_VERSION" && "$EXPECTED_VERSION" != "unknown" && "$current" != "$EXPECTED_VERSION" ]]; then
  warn "Expected codex $EXPECTED_VERSION, got $current"
fi
