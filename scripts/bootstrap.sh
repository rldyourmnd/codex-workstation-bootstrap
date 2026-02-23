#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKIP_CURATED=false
FORCE=true
CLEAN_SKILLS=true
RULES_MODE="exact"
APPLY_PROJECT_TRUST=true
SYNC_CODEX_VERSION=true
STRICT_TOOLCHAIN=true

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
    --portable-rules)
      RULES_MODE="portable"
      shift
      ;;
    --skip-project-trust)
      APPLY_PROJECT_TRUST=false
      shift
      ;;
    --no-sync-codex-version)
      SYNC_CODEX_VERSION=false
      shift
      ;;
    --sync-codex-version)
      SYNC_CODEX_VERSION=true
      shift
      ;;
    --no-strict-toolchain)
      STRICT_TOOLCHAIN=false
      shift
      ;;
    *)
      echo "[ERROR] Unknown argument: $1"
      echo "Usage: scripts/bootstrap.sh [--skip-curated] [--no-force] [--no-clean-skills] [--portable-rules] [--skip-project-trust] [--no-sync-codex-version] [--no-strict-toolchain]"
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

if $SYNC_CODEX_VERSION; then
  say "Running sync-codex-version.sh --apply"
  "$ROOT_DIR/scripts/sync-codex-version.sh" --apply
fi

if $STRICT_TOOLCHAIN; then
  say "Running check-toolchain.sh --strict-codex-only --require-secrets"
  "$ROOT_DIR/scripts/check-toolchain.sh" --strict-codex-only --require-secrets
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
install_args+=(--rules-mode "$RULES_MODE")
if ! $APPLY_PROJECT_TRUST; then
  install_args+=(--skip-project-trust)
fi

say "Running install.sh ${install_args[*]}"
"$ROOT_DIR/scripts/install.sh" "${install_args[@]}"

say "Running verify.sh"
"$ROOT_DIR/scripts/verify.sh"

say "Running audit-codex-agents.sh"
"$ROOT_DIR/scripts/audit-codex-agents.sh"

say "Running codex-activate.sh --check-only"
"$ROOT_DIR/scripts/codex-activate.sh" --check-only

say "Bootstrap complete"
