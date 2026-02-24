#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
source "$ROOT_DIR/scripts/os/common/platform.sh"

say() { echo "[OS:macOS][Claude] $*"; }
warn() { echo "[OS:macOS][Claude][WARN] $*"; }
err() { echo "[OS:macOS][Claude][ERROR] $*"; }

if [[ "$(platform_id)" != "macos" ]]; then
  err "This script supports only macOS"
  exit 1
fi

if command -v claude >/dev/null 2>&1; then
  say "claude already available in PATH"
  claude --version || true
  exit 0
fi

if ! command -v brew >/dev/null 2>&1; then
  err "Homebrew is required on macOS. Install first: https://brew.sh/"
  exit 1
fi

if ! brew list --cask claude-code >/dev/null 2>&1; then
  say "Installing Claude Code via Homebrew cask"
  brew install --cask claude-code
fi

if ! command -v claude >/dev/null 2>&1; then
  warn "claude binary not found after brew install."
  warn "Fallback option: curl -fsSL https://claude.ai/install.sh | bash"
  exit 1
fi

say "Claude Code installed"
claude --version || true
