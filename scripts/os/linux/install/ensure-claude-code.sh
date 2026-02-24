#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
source "$ROOT_DIR/scripts/os/common/platform.sh"

say() { echo "[OS:linux][Claude] $*"; }
warn() { echo "[OS:linux][Claude][WARN] $*"; }
err() { echo "[OS:linux][Claude][ERROR] $*"; }

if [[ "$(platform_id)" != "linux" ]]; then
  err "This script supports only Linux"
  exit 1
fi

if command -v claude >/dev/null 2>&1; then
  say "claude already available in PATH"
  claude --version || true
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  err "curl is required to install Claude Code on Linux"
  exit 1
fi

say "Installing Claude Code via official installer"
curl -fsSL https://claude.ai/install.sh | bash

if ! command -v claude >/dev/null 2>&1; then
  warn "claude binary not found in current shell after install."
  warn "Open a new shell and run: claude --version"
  exit 1
fi

say "Claude Code installed"
claude --version || true
