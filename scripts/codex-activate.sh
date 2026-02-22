#!/usr/bin/env bash
set -euo pipefail

# Codex MCP/Skills bootstrap and health check for this repo.
# Usage:
#   scripts/codex-activate.sh            # enable required MCP, then validate
#   scripts/codex-activate.sh --check-only

CHECK_ONLY=false
if [[ "${1:-}" == "--check-only" ]]; then
  CHECK_ONLY=true
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "[ERROR] codex CLI is not installed or not in PATH"
  exit 1
fi

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
SKILLS_DIR="$CODEX_HOME_DIR/skills"

REQUIRED_MCPS=(
  "context7"
  "github"
  "sequential-thinking"
  "shadcn"
  "serena"
  "playwright"
)

REQUIRED_SKILLS=(
  "frontend-design"
  "code-reviewer"
  "webapp-testing"
  "pptx"
  "hook-development"
  "command-development"
  "agent-development"
  "writing-rules"
  "codex-md-improver"
  "sql-queries"
  "search-strategy"
  "cloudflare-deploy"
  "gh-address-comments"
  "pdf"
  "security-best-practices"
  "security-ownership-map"
  "security-threat-model"
  "spreadsheet"
  "yeet"
  "playwright"
  "better-explorer"
  "serena-sync"
  "version-patrol"
  "better-think"
  "better-plan"
  "better-code-review"
  "manual-tester"
  "better-debugger"
  "github-server-sync"
  "init-project"
  "create-project"
  "status"
)

warn_count=0
err_count=0

say() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; warn_count=$((warn_count + 1)); }
err() { echo "[ERROR] $*"; err_count=$((err_count + 1)); }

say "Collecting MCP status..."
MCP_LIST="$(codex mcp list || true)"
if [[ -z "$MCP_LIST" ]]; then
  err "Unable to read MCP status via 'codex mcp list'"
fi

enable_mcp() {
  local name="$1"
  if $CHECK_ONLY; then
    return
  fi
  if codex mcp enable "$name" >/dev/null 2>&1; then
    say "MCP enabled: $name"
  else
    warn "Failed to enable MCP '$name' automatically (may require manual setup)"
  fi
}

for mcp in "${REQUIRED_MCPS[@]}"; do
  if ! grep -Eq "^${mcp}[[:space:]]+" <<<"$MCP_LIST"; then
    err "Missing MCP config: $mcp"
    continue
  fi
  if grep -Eq "^${mcp}[[:space:]]+.*[[:space:]]enabled[[:space:]]" <<<"$MCP_LIST"; then
    say "MCP present/enabled: $mcp"
  else
    warn "MCP configured but disabled: $mcp"
    enable_mcp "$mcp"
  fi

done

MCP_LIST_AFTER="$(codex mcp list || true)"
MCP_LIST_AFTER_CLEAN="$(printf '%s\n' "$MCP_LIST_AFTER" | tr -d '\r' | sed -E 's/\x1B\\[[0-9;]*[[:alpha:]]//g')"
if grep -Eiq "context7.*not logged in" <<<"$MCP_LIST_AFTER_CLEAN"; then
  warn "context7 MCP is enabled but not logged in (check CONTEXT7_API_KEY)"
fi
if grep -Eiq "github.*not logged in" <<<"$MCP_LIST_AFTER_CLEAN"; then
  warn "github MCP is enabled but not logged in (check token/header in Codex config)"
fi

say "Validating required skills in $SKILLS_DIR"
if [[ ! -d "$SKILLS_DIR" ]]; then
  err "Skills directory not found: $SKILLS_DIR"
else
  for skill in "${REQUIRED_SKILLS[@]}"; do
    if [[ ! -d "$SKILLS_DIR/$skill" ]]; then
      err "Missing skill directory: $skill"
      continue
    fi
    if [[ ! -f "$SKILLS_DIR/$skill/SKILL.md" ]]; then
      err "Missing SKILL.md: $skill"
      continue
    fi
    if ! grep -Eq '^name:' "$SKILLS_DIR/$skill/SKILL.md"; then
      warn "SKILL.md has no 'name:' field: $skill"
    fi
    if ! grep -Eq '^description:' "$SKILLS_DIR/$skill/SKILL.md"; then
      warn "SKILL.md has no 'description:' field: $skill"
    fi
    say "Skill OK: $skill"
  done

  say "Auditing all installed skills for SKILL.md/frontmatter"
  mapfile -t installed_skill_dirs < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
  for installed in "${installed_skill_dirs[@]}"; do
    if [[ "$installed" == ".system" ]]; then
      continue
    fi
    if [[ ! -f "$SKILLS_DIR/$installed/SKILL.md" ]]; then
      err "Installed skill has no SKILL.md: $installed"
      continue
    fi
    if ! grep -Eq '^name:' "$SKILLS_DIR/$installed/SKILL.md"; then
      warn "Installed SKILL.md has no 'name:' field: $installed"
    fi
    if ! grep -Eq '^description:' "$SKILLS_DIR/$installed/SKILL.md"; then
      warn "Installed SKILL.md has no 'description:' field: $installed"
    fi
  done

  # Duplicate skill name detection from frontmatter.
  mapfile -t skill_files < <(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -type f -name 'SKILL.md' | sort)
  if [[ ${#skill_files[@]} -gt 0 ]]; then
    dupes="$(awk '/^name:/ {print $2}' "${skill_files[@]}" | sort | uniq -d || true)"
    if [[ -n "$dupes" ]]; then
      warn "Duplicate skill name(s) detected in frontmatter: $dupes"
    else
      say "No duplicate frontmatter names detected across installed skills"
    fi
  fi
fi

if [[ $err_count -gt 0 ]]; then
  echo
  err "Bootstrap finished with $err_count error(s), $warn_count warning(s)"
  exit 1
fi

echo
say "Bootstrap finished successfully with $warn_count warning(s)"
exit 0
