#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKIP_CURATED=false
FORCE=true
CLEAN_SKILLS=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-curated)
      SKIP_CURATED=true
      shift
      ;;
    --no-force)
      FORCE=false
      shift
      ;;
    --no-clean-skills)
      CLEAN_SKILLS=false
      shift
      ;;
    *)
      echo "[ERROR] Unknown argument: $1"
      echo "Usage: scripts/bootstrap.sh [--skip-curated] [--no-force] [--no-clean-skills]"
      exit 1
      ;;
  esac
done

say() { echo "[BOOTSTRAP] $*"; }
warn() { echo "[BOOTSTRAP][WARN] $*"; }

if ! command -v codex >/dev/null 2>&1; then
  warn "codex CLI not found in PATH. Install first: npm i -g @openai/codex"
fi

if [[ -z "${CONTEXT7_API_KEY:-}" ]]; then
  warn "CONTEXT7_API_KEY is empty"
fi
if [[ -z "${GITHUB_MCP_TOKEN:-}" ]]; then
  warn "GITHUB_MCP_TOKEN is empty"
fi

install_args=()
if $FORCE; then
  install_args+=(--force)
fi
if $SKIP_CURATED; then
  install_args+=(--skip-curated)
fi
if $CLEAN_SKILLS; then
  install_args+=(--clean-skills)
fi

say "Running install.sh ${install_args[*]}"
"$ROOT_DIR/scripts/install.sh" "${install_args[@]}"

say "Running verify.sh"
"$ROOT_DIR/scripts/verify.sh"

say "Running codex-activate.sh --check-only"
"$ROOT_DIR/scripts/codex-activate.sh" --check-only

say "Bootstrap complete"
