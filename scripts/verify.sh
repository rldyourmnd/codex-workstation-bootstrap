#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/os/common/platform.sh"
source "$ROOT_DIR/scripts/os/common/layout.sh"

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
CONFIG_FILE="$CODEX_HOME_DIR/config.toml"
GLOBAL_AGENTS_FILE="$CODEX_HOME_DIR/AGENTS.md"
RULES_FILE="$CODEX_HOME_DIR/rules/default.rules"
RULES_MODE_FILE="$CODEX_HOME_DIR/.better-codex-rules-mode"
SKILLS_DIR="$CODEX_HOME_DIR/skills"
SKILLS_ROOT="$SKILLS_DIR"
TOOLCHAIN_CHECK="$ROOT_DIR/scripts/check-toolchain.sh"

REQUESTED_PROFILE="$(detect_profile_os)"
PROFILE_OS="$(resolve_profile_os "$REQUESTED_PROFILE")"
PROFILE_ROOT="$(resolve_runtime_root "$REQUESTED_PROFILE")"
CUSTOM_MANIFEST="$PROFILE_ROOT/skills/manifests/custom-skills.manifest.txt"
PROJECT_TRUST_SNAPSHOT="$PROFILE_ROOT/config/projects.trust.snapshot.toml"
AGENT_BASELINE_DIR="$(common_agent_skills_root)"

REQUIRED_MCPS=(
  "context7"
  "github"
  "sequential-thinking"
  "shadcn"
  "serena"
  "playwright"
)

say() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
err() { echo "[ERROR] $*"; }

if ! command -v codex >/dev/null 2>&1; then
  err "codex CLI not found"
  exit 1
fi

if [[ "$REQUESTED_PROFILE" != "$PROFILE_OS" ]]; then
  warn "Profile '$REQUESTED_PROFILE' has no payload, using '$PROFILE_OS'"
fi

if [[ ! -x "$TOOLCHAIN_CHECK" ]]; then
  err "Missing executable toolchain checker: $TOOLCHAIN_CHECK"
  exit 1
fi
if ! "$TOOLCHAIN_CHECK" --strict-codex-only; then
  err "Toolchain parity check failed"
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
if ! grep -q '[^[:space:]]' "$GLOBAL_AGENTS_FILE"; then
  err "Global AGENTS is empty: $GLOBAL_AGENTS_FILE"
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
  err "Global AGENTS does not include expected baseline phrase: 'think step by step'"
  exit 1
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

rules_mode="portable"
if [[ -f "$RULES_MODE_FILE" ]]; then
  rules_mode="$(head -n1 "$RULES_MODE_FILE" | tr -d '\r')"
fi
if [[ "$rules_mode" != "portable" && "$rules_mode" != "exact" ]]; then
  err "Invalid rules mode marker in $RULES_MODE_FILE: $rules_mode"
  exit 1
fi

if [[ -f "$PROJECT_TRUST_SNAPSHOT" ]] && grep -Eq '^\[projects\.' "$PROJECT_TRUST_SNAPSHOT"; then
  if grep -Eq '^\[projects\.' "$CONFIG_FILE"; then
    say "Project trust entries present in installed config"
  else
    warn "Project trust snapshot exists but installed config has no project trust entries"
  fi
fi

if [[ ! -f "$CUSTOM_MANIFEST" ]]; then
  err "Snapshot skills manifest missing: $CUSTOM_MANIFEST"
  exit 1
fi

REQUIRED_CUSTOM_SKILLS=()
while IFS= read -r line; do
  REQUIRED_CUSTOM_SKILLS+=("$line")
done < <(read_nonempty_lines "$CUSTOM_MANIFEST")
if [[ ${#REQUIRED_CUSTOM_SKILLS[@]} -eq 0 ]]; then
  err "Snapshot skills manifest is empty: $CUSTOM_MANIFEST"
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

if [[ -d "$AGENT_BASELINE_DIR" ]]; then
  REPO_AGENT_SKILLS=()
  while IFS= read -r line; do
    REPO_AGENT_SKILLS+=("$line")
  done < <(list_top_level_dirs "$AGENT_BASELINE_DIR")

  for skill in "${REPO_AGENT_SKILLS[@]}"; do
    if [[ ! -f "$SKILLS_ROOT/$skill/SKILL.md" ]]; then
      err "Missing repository agent baseline skill: $skill"
      exit 1
    fi
  done
  say "Verified repository agent baseline skills: ${#REPO_AGENT_SKILLS[@]}"
fi

say "Verified custom skills: ${#REQUIRED_CUSTOM_SKILLS[@]}"
say "Verification passed"
