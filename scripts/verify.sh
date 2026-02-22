#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
SKILLS_DIR="$CODEX_HOME_DIR/skills"
SKILLS_ROOT="$SKILLS_DIR"

REQUIRED_MCPS=(
  "context7"
  "github"
  "sequential-thinking"
  "shadcn"
  "serena"
  "playwright"
)

REQUIRED_CUSTOM_SKILLS=(
  "agent-development"
  "better-code-review"
  "better-debugger"
  "better-explorer"
  "better-plan"
  "better-think"
  "code-reviewer"
  "codex-md-improver"
  "command-development"
  "frontend-design"
  "github-server-sync"
  "hook-development"
  "init-project"
  "create-project"
  "manual-tester"
  "search-strategy"
  "serena-sync"
  "sql-queries"
  "status"
  "version-patrol"
  "webapp-testing"
  "writing-rules"
  "pptx"
)

say() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
err() { echo "[ERROR] $*"; }

if ! command -v codex >/dev/null 2>&1; then
  err "codex CLI not found"
  exit 1
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
  err "Skills directory not found: $SKILLS_DIR"
  exit 1
fi

if [[ -d "$SKILLS_DIR/custom" && ! -d "$SKILLS_DIR/agent-development" ]]; then
  warn "Detected nested custom directory; checking skills under $SKILLS_DIR/custom"
  SKILLS_ROOT="$SKILLS_DIR/custom"
fi

status="$(codex mcp list || true)"
if [[ -z "$status" ]]; then
  err "Failed to read MCP table"
  exit 1
fi

for mcp in "${REQUIRED_MCPS[@]}"; do
  if ! grep -Eq "^${mcp}[[:space:]]+" <<<"$status"; then
    err "Missing MCP: $mcp"
    exit 1
  fi
  if ! grep -E "^${mcp}[[:space:]].*[[:space:]]enabled([[:space:]]|$)" <<<"$status" >/dev/null; then
    err "MCP configured but not enabled: $mcp"
    exit 1
  fi
  say "MCP configured: $mcp"
done

for skill in "${REQUIRED_CUSTOM_SKILLS[@]}"; do
  if [[ ! -f "$SKILLS_ROOT/$skill/SKILL.md" ]]; then
    err "Missing custom skill: $skill"
    exit 1
  fi
  if ! grep -Eq '^name:' "$SKILLS_ROOT/$skill/SKILL.md"; then
    err "Skill missing frontmatter name: $skill"
    exit 1
  fi
  if ! grep -Eq '^description:' "$SKILLS_ROOT/$skill/SKILL.md"; then
    err "Skill missing frontmatter description: $skill"
    exit 1
  fi
  say "Custom skill OK: $skill"
done

say "Verification passed"
