#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
CONFIG_FILE="$CODEX_HOME_DIR/config.toml"
GLOBAL_AGENTS_FILE="$CODEX_HOME_DIR/AGENTS.md"
RULES_FILE="$CODEX_HOME_DIR/rules/default.rules"
SKILLS_DIR="$CODEX_HOME_DIR/skills"
SKILLS_ROOT="$SKILLS_DIR"
CUSTOM_MANIFEST="$ROOT_DIR/codex/skills/custom-skills.manifest.txt"

REQUIRED_MCPS=(
  "context7"
  "github"
  "sequential-thinking"
  "shadcn"
  "serena"
  "playwright"
)

DEFAULT_REQUIRED_CUSTOM_SKILLS=(
  "agent-development"
  "better-code-review"
  "better-debugger"
  "better-explorer"
  "better-plan"
  "better-think"
  "cloudflare-deploy"
  "code-reviewer"
  "codex-md-improver"
  "command-development"
  "create-project"
  "figma-implement-design"
  "frontend-design"
  "gh-address-comments"
  "github-server-sync"
  "hook-development"
  "init-project"
  "manual-tester"
  "pdf"
  "playwright"
  "pptx"
  "search-strategy"
  "security-best-practices"
  "security-ownership-map"
  "security-threat-model"
  "serena-sync"
  "spreadsheet"
  "sql-queries"
  "status"
  "version-patrol"
  "webapp-testing"
  "writing-rules"
  "yeet"
)

say() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
err() { echo "[ERROR] $*"; }

if ! command -v codex >/dev/null 2>&1; then
  err "codex CLI not found"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  err "Config not found: $CONFIG_FILE"
  exit 1
fi
if [[ ! -f "$GLOBAL_AGENTS_FILE" ]]; then
  err "Global AGENTS not found: $GLOBAL_AGENTS_FILE"
  exit 1
fi
if [[ ! -f "$RULES_FILE" ]]; then
  err "Rules file not found: $RULES_FILE"
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

if ! grep -q '__CONTEXT7_API_KEY__' "$CONFIG_FILE"; then
  say "Config appears tokenized for Context7"
else
  warn "Config still contains Context7 placeholder"
fi
if ! grep -q '__GITHUB_MCP_TOKEN__' "$CONFIG_FILE"; then
  say "Config appears tokenized for GitHub MCP"
else
  warn "Config still contains GitHub MCP placeholder"
fi

if ! grep -Eiq 'think step by step' "$GLOBAL_AGENTS_FILE"; then
  warn "Global AGENTS does not include expected baseline phrase: 'think step by step'"
else
  say "Global AGENTS baseline phrase found"
fi

if grep -q '__HOME__' "$RULES_FILE"; then
  warn "Rules still contain __HOME__ placeholder"
else
  say "Rules home placeholders resolved"
fi

if grep -Eq '^prefix_rule\(pattern=\["gh"\]' "$RULES_FILE"; then
  say "Rules include gh prefix rule"
else
  warn "Rules do not include explicit gh prefix rule"
fi

if [[ -f "$CUSTOM_MANIFEST" ]]; then
  mapfile -t REQUIRED_CUSTOM_SKILLS < <(grep -Ev '^\s*#|^\s*$' "$CUSTOM_MANIFEST" || true)
else
  REQUIRED_CUSTOM_SKILLS=("${DEFAULT_REQUIRED_CUSTOM_SKILLS[@]}")
fi

if [[ ${#REQUIRED_CUSTOM_SKILLS[@]} -eq 0 ]]; then
  err "No expected skills listed for verification"
  exit 1
fi

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

say "Verified custom skills: ${#REQUIRED_CUSTOM_SKILLS[@]}"
say "Verification passed"
