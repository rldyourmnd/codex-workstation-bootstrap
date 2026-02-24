#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/os/common/platform.sh"

SKIP_CURATED=false
FORCE=true
CLEAN_SKILLS=true
RULES_MODE="exact"
APPLY_PROJECT_TRUST=true
SYNC_CODEX_VERSION=true
STRICT_TOOLCHAIN=true
RESTORE_FULL_HOME=false
INSTALL_CLAUDE_CODE=false

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
    --full-home)
      RESTORE_FULL_HOME=true
      shift
      ;;
    --with-claude-code)
      INSTALL_CLAUDE_CODE=true
      shift
      ;;
    *)
      echo "[ERROR] Unknown argument: $1"
      echo "Usage: scripts/bootstrap.sh [--skip-curated] [--no-force] [--no-clean-skills] [--portable-rules] [--skip-project-trust] [--no-sync-codex-version] [--no-strict-toolchain] [--full-home] [--with-claude-code]"
      exit 1
      ;;
  esac
done

say() { echo "[BOOTSTRAP] $*"; }
warn() { echo "[BOOTSTRAP][WARN] $*"; }

expected_codex="$(
  grep -E '^CODEX_VERSION=' "$ROOT_DIR/codex/meta/toolchain.lock" | head -n1 | cut -d'=' -f2- || true
)"
platform="$(platform_id)"
os_setup_script="$ROOT_DIR/scripts/os/$platform/install/ensure-codex.sh"
os_setup_script_ps1="$ROOT_DIR/scripts/os/$platform/install/ensure-codex.ps1"
claude_setup_script="$ROOT_DIR/scripts/os/$platform/install/ensure-claude-code.sh"
claude_setup_script_ps1="$ROOT_DIR/scripts/os/$platform/install/ensure-claude-code.ps1"

run_powershell_script() {
  local script="$1"
  shift || true
  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$script" "$@"
    return $?
  fi
  if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -ExecutionPolicy Bypass -File "$script" "$@"
    return $?
  fi
  return 127
}

if [[ -x "$os_setup_script" ]]; then
  say "Running OS bootstrap: scripts/os/$platform/install/ensure-codex.sh"
  "$os_setup_script" --expected-version "${expected_codex:-unknown}"
elif [[ -f "$os_setup_script_ps1" ]]; then
  say "Running OS bootstrap: scripts/os/$platform/install/ensure-codex.ps1"
  if ! run_powershell_script "$os_setup_script_ps1" -ExpectedVersion "${expected_codex:-unknown}"; then
    warn "PowerShell bootstrap failed or PowerShell unavailable on this shell"
  fi
else
  warn "No OS bootstrap script found for platform '$platform'"
fi

if $INSTALL_CLAUDE_CODE; then
  if [[ -x "$claude_setup_script" ]]; then
    say "Running Claude Code bootstrap: scripts/os/$platform/install/ensure-claude-code.sh"
    "$claude_setup_script"
  elif [[ -f "$claude_setup_script_ps1" ]]; then
    say "Running Claude Code bootstrap: scripts/os/$platform/install/ensure-claude-code.ps1"
    if ! run_powershell_script "$claude_setup_script_ps1"; then
      warn "Claude Code PowerShell bootstrap failed or PowerShell unavailable"
    fi
  else
    warn "No Claude Code bootstrap script for platform '$platform'"
  fi
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
if $RESTORE_FULL_HOME; then
  install_args+=(--restore-full-home)
fi

say "Running install.sh ${install_args[*]}"
"$ROOT_DIR/scripts/install.sh" "${install_args[@]}"

if $RESTORE_FULL_HOME; then
  say "Running verify.sh --full-home"
  "$ROOT_DIR/scripts/verify.sh" --full-home
  say "Skipping audit-codex-agents.sh and codex-activate.sh in full-home mode"
  say "Bootstrap complete"
  exit 0
fi

say "Running verify.sh"
"$ROOT_DIR/scripts/verify.sh"

say "Running audit-codex-agents.sh"
"$ROOT_DIR/scripts/audit-codex-agents.sh"

say "Running codex-activate.sh --check-only"
"$ROOT_DIR/scripts/codex-activate.sh" --check-only

say "Bootstrap complete"
