#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="/tmp/better-codex-selftest-home"
MANIFEST_FILE="$ROOT_DIR/codex/skills/custom-skills.manifest.txt"

say() { echo "[SELF-TEST] $*"; }
err() { echo "[SELF-TEST][ERROR] $*"; }

cd "$ROOT_DIR"

for f in scripts/install.sh scripts/verify.sh scripts/codex-activate.sh scripts/export-from-local.sh scripts/bootstrap.sh scripts/audit-codex-agents.sh; do
  bash -n "$f"
done
say "Shell syntax: OK"

scripts/audit-codex-agents.sh
say "Agent profile audit: OK"

rm -rf "$TEST_HOME"
mkdir -p "$TEST_HOME"

CONTEXT7_API_KEY='ctx7sk-selftest' GITHUB_MCP_TOKEN='gho_selftest' CODEX_HOME="$TEST_HOME" scripts/install.sh --force --skip-curated --clean-skills

if [[ ! -f "$TEST_HOME/config.toml" ]]; then
  err "Missing generated config.toml"
  exit 1
fi
if [[ ! -f "$TEST_HOME/AGENTS.md" ]]; then
  err "Missing global AGENTS.md"
  exit 1
fi
if [[ ! -f "$TEST_HOME/rules/default.rules" ]]; then
  err "Missing installed rules file"
  exit 1
fi

if [[ ! -f "$MANIFEST_FILE" ]]; then
  err "Missing skills manifest: $MANIFEST_FILE"
  exit 1
fi

mapfile -t required_skills < <(grep -Ev '^\s*#|^\s*$' "$MANIFEST_FILE")
if [[ ${#required_skills[@]} -eq 0 ]]; then
  err "Skills manifest is empty"
  exit 1
fi

for skill in "${required_skills[@]}"; do
  if [[ ! -f "$TEST_HOME/skills/$skill/SKILL.md" ]]; then
    err "Missing installed skill: $skill"
    exit 1
  fi
done

if ! grep -q 'CONTEXT7_API_KEY = "ctx7sk-selftest"' "$TEST_HOME/config.toml"; then
  err "Context7 token substitution failed"
  exit 1
fi
if ! grep -q 'Authorization = "Bearer gho_selftest"' "$TEST_HOME/config.toml"; then
  err "GitHub MCP token substitution failed"
  exit 1
fi
if grep -q '__HOME__' "$TEST_HOME/rules/default.rules"; then
  err "Rules home placeholder replacement failed"
  exit 1
fi

say "Clean-room install assertions: OK"
say "Self-test passed"
