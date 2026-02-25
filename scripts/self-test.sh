#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/os/common/platform.sh"
source "$ROOT_DIR/scripts/os/common/layout.sh"

TEST_HOME="/tmp/better-codex-selftest-home"
PROFILE_ROOT="$(profile_runtime_root "macos")"
MANIFEST_FILE="$PROFILE_ROOT/skills/manifests/custom-skills.manifest.txt"

say() { echo "[SELF-TEST] $*"; }
warn() { echo "[SELF-TEST][WARN] $*"; }
err() { echo "[SELF-TEST][ERROR] $*"; }

cd "$ROOT_DIR"

for f in \
  scripts/install.sh \
  scripts/verify.sh \
  scripts/codex-activate.sh \
  scripts/export-from-local.sh \
  scripts/bootstrap.sh \
  scripts/audit-codex-agents.sh \
  scripts/check-toolchain.sh \
  scripts/sync-codex-version.sh \
  scripts/render-portable-rules.sh \
  scripts/os/common/platform.sh \
  scripts/os/common/layout.sh \
  scripts/os/macos/install/ensure-codex.sh \
  scripts/os/linux/install/ensure-codex.sh \
  scripts/os/macos/install/ensure-claude-code.sh \
  scripts/os/linux/install/ensure-claude-code.sh; do
  bash -n "$f"
done
say "Shell syntax: OK"

scripts/check-toolchain.sh --strict-codex-only
say "Toolchain parity check: OK"

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
if ! grep -q '[^[:space:]]' "$TEST_HOME/AGENTS.md"; then
  err "Installed AGENTS.md is empty"
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

required_skills=()
while IFS= read -r line; do
  required_skills+=("$line")
done < <(read_nonempty_lines "$MANIFEST_FILE")

if [[ ${#required_skills[@]} -eq 0 ]]; then
  err "Skills manifest is empty: $MANIFEST_FILE"
  exit 1
fi
for skill in "${required_skills[@]}"; do
  if [[ ! -f "$TEST_HOME/skills/$skill/SKILL.md" ]]; then
    err "Missing installed skill: $skill"
    exit 1
  fi
done

repo_agent_skills=()
while IFS= read -r line; do
  repo_agent_skills+=("$line")
done < <(list_top_level_dirs "$(common_agent_skills_root)")

for skill in "${repo_agent_skills[@]}"; do
  if [[ ! -f "$TEST_HOME/skills/$skill/SKILL.md" ]]; then
    err "Missing installed repository agent skill: $skill"
    exit 1
  fi
done

if grep -q '__CONTEXT7_API_KEY__' "$PROFILE_ROOT/config/config.template.toml"; then
  if ! grep -Eq 'ctx7sk-selftest' "$TEST_HOME/config.toml"; then
    err "Context7 token substitution failed"
    exit 1
  fi
else
  warn "Config template has no Context7 placeholder; skipping substitution assertion"
fi

if grep -q '__GITHUB_MCP_TOKEN__' "$PROFILE_ROOT/config/config.template.toml"; then
  if ! grep -Eq 'gho_selftest' "$TEST_HOME/config.toml"; then
    err "GitHub MCP token substitution failed"
    exit 1
  fi
else
  warn "Config template has no GitHub placeholder; skipping substitution assertion"
fi
if grep -q '__HOME__' "$TEST_HOME/rules/default.rules"; then
  err "Rules home placeholder replacement failed"
  exit 1
fi

if [[ ! -f "$TEST_HOME/.better-codex-rules-mode" ]]; then
  err "Missing installed rules mode marker"
  exit 1
fi
rules_mode="$(cat "$TEST_HOME/.better-codex-rules-mode")"
if [[ "$rules_mode" != "portable" && "$rules_mode" != "exact" ]]; then
  err "Invalid installed rules mode marker: $rules_mode"
  exit 1
fi

say "Clean-room install assertions: OK"
say "Self-test passed"
