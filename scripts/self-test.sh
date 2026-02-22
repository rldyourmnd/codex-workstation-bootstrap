#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="/tmp/better-codex-selftest-home"

say() { echo "[SELF-TEST] $*"; }
err() { echo "[SELF-TEST][ERROR] $*"; }

cd "$ROOT_DIR"

for f in scripts/install.sh scripts/verify.sh scripts/codex-activate.sh scripts/export-from-local.sh; do
  bash -n "$f"
done
say "Shell syntax: OK"

rm -rf "$TEST_HOME"
mkdir -p "$TEST_HOME"

CONTEXT7_API_KEY='ctx7sk-selftest' GITHUB_MCP_TOKEN='gho_selftest' CODEX_HOME="$TEST_HOME" scripts/install.sh --force --skip-curated

if [[ ! -f "$TEST_HOME/config.toml" ]]; then
  err "Missing generated config.toml"
  exit 1
fi

required_skills=(
  agent-development
  code-reviewer
  codex-md-improver
  command-development
  frontend-design
  hook-development
  pptx
  search-strategy
  sql-queries
  webapp-testing
  writing-rules
)

for skill in "${required_skills[@]}"; do
  if [[ ! -f "$TEST_HOME/skills/$skill/SKILL.md" ]]; then
    err "Missing installed skill: $skill"
    exit 1
  fi
done

if [[ ! -f "$TEST_HOME/rules/default.rules" ]]; then
  err "Missing installed rules template"
  exit 1
fi

if ! grep -q 'CONTEXT7_API_KEY = "ctx7sk-selftest"' "$TEST_HOME/config.toml"; then
  err "Context7 token substitution failed"
  exit 1
fi
if ! grep -q 'Authorization = "Bearer gho_selftest"' "$TEST_HOME/config.toml"; then
  err "GitHub MCP token substitution failed"
  exit 1
fi

say "Clean-room install assertions: OK"
say "Self-test passed"
