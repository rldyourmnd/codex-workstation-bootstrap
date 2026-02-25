#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/os/common/platform.sh"
source "$ROOT_DIR/scripts/os/common/layout.sh"

PROFILE_ROOT="$(resolve_runtime_root "$(detect_profile_os)")"
LOCK_FILE="$PROFILE_ROOT/meta/toolchain.lock"

STRICT=false
STRICT_CODEX_ONLY=true
REQUIRE_SECRETS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      STRICT=true
      STRICT_CODEX_ONLY=false
      shift
      ;;
    --strict-codex-only)
      STRICT_CODEX_ONLY=true
      STRICT=false
      shift
      ;;
    --require-secrets)
      REQUIRE_SECRETS=true
      shift
      ;;
    *)
      echo "[ERROR] Unknown argument: $1"
      echo "Usage: scripts/check-toolchain.sh [--strict] [--strict-codex-only] [--require-secrets]"
      exit 1
      ;;
  esac
done

say() { echo "[TOOLCHAIN] $*"; }
warn() { echo "[TOOLCHAIN][WARN] $*"; }
err() { echo "[TOOLCHAIN][ERROR] $*"; }

if [[ ! -f "$LOCK_FILE" ]]; then
  err "Missing lock file: $LOCK_FILE"
  exit 1
fi

required_bins=(codex python3 rsync sed awk)
for bin in "${required_bins[@]}"; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    err "Missing required binary: $bin"
    exit 1
  fi
done

if $REQUIRE_SECRETS; then
  if [[ -z "${CONTEXT7_API_KEY:-}" ]]; then
    err "Missing CONTEXT7_API_KEY"
    exit 1
  fi
  if [[ -z "${GITHUB_MCP_TOKEN:-}" ]]; then
    err "Missing GITHUB_MCP_TOKEN"
    exit 1
  fi
fi

get_lock_val() {
  local key="$1"
  grep -E "^${key}=" "$LOCK_FILE" | head -n1 | cut -d'=' -f2- || true
}

expected_codex="$(get_lock_val CODEX_VERSION)"
expected_node="$(get_lock_val NODE_VERSION)"
expected_npm="$(get_lock_val NPM_VERSION)"
expected_python="$(get_lock_val PYTHON_VERSION)"
expected_uv="$(get_lock_val UV_VERSION)"
expected_uvx="$(get_lock_val UVX_VERSION)"
expected_gh="$(get_lock_val GH_VERSION)"

current_codex="$(codex --version 2>/dev/null | awk '{print $2}' || true)"
current_node="$(node --version 2>/dev/null | sed 's/^v//' || true)"
current_npm="$(npm --version 2>/dev/null || true)"
current_python="$(python3 --version 2>/dev/null | awk '{print $2}' || true)"
current_uv="$(uv --version 2>/dev/null | awk '{print $2}' || true)"
current_uvx="$(uvx --version 2>/dev/null | awk '{print $2}' || true)"
current_gh="$(gh --version 2>/dev/null | head -n1 | awk '{print $3}' || true)"

mismatches=0
hard_fail=0

check_one() {
  local name="$1"
  local expected="$2"
  local current="$3"
  if [[ -z "$expected" || "$expected" == "unknown" ]]; then
    warn "No expected value in lock for $name (skipping)"
    return
  fi
  if [[ "$expected" == "$current" ]]; then
    say "$name OK ($current)"
    return
  fi
  mismatches=$((mismatches + 1))
  if $STRICT; then
    err "$name mismatch: expected $expected, got $current"
    hard_fail=1
    return
  fi
  if $STRICT_CODEX_ONLY && [[ "$name" == "CODEX_VERSION" ]]; then
    err "$name mismatch: expected $expected, got $current"
    hard_fail=1
    return
  fi
  warn "$name mismatch: expected $expected, got $current"
}

check_one CODEX_VERSION "$expected_codex" "$current_codex"
check_one NODE_VERSION "$expected_node" "$current_node"
check_one NPM_VERSION "$expected_npm" "$current_npm"
check_one PYTHON_VERSION "$expected_python" "$current_python"
check_one UV_VERSION "$expected_uv" "$current_uv"
check_one UVX_VERSION "$expected_uvx" "$current_uvx"
check_one GH_VERSION "$expected_gh" "$current_gh"

if [[ $hard_fail -gt 0 ]]; then
  err "Toolchain check failed"
  exit 1
fi

if [[ $mismatches -gt 0 ]]; then
  warn "Toolchain check completed with $mismatches mismatch(es)"
else
  say "Toolchain check passed with exact match"
fi
