#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT_DIR/skills/codex-agents"
DOCS_DIR="$ROOT_DIR/docs/agents"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
QUICK_VALIDATE="$CODEX_HOME_DIR/skills/.system/skill-creator/scripts/quick_validate.py"

say() { echo "[AUDIT] $*"; }
warn() { echo "[AUDIT][WARN] $*"; }
err() { echo "[AUDIT][ERROR] $*"; }

errors=0
warnings=0

if [[ ! -d "$SKILLS_DIR" ]]; then
  err "Skills directory not found: $SKILLS_DIR"
  exit 1
fi
if [[ ! -d "$DOCS_DIR" ]]; then
  err "Docs directory not found: $DOCS_DIR"
  exit 1
fi

mapfile -t skill_profiles < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
mapfile -t doc_profiles < <(find "$DOCS_DIR" -mindepth 1 -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sed 's/\.md$//' | grep -v '^README$' | sort)

if [[ ${#skill_profiles[@]} -eq 0 ]]; then
  err "No skill profiles found"
  exit 1
fi

if [[ ${#skill_profiles[@]} -ne 9 ]]; then
  warn "Expected 9 codex-agent profiles, found ${#skill_profiles[@]}"
  warnings=$((warnings + 1))
fi

declare -A skill_set=()
declare -A doc_set=()
for s in "${skill_profiles[@]}"; do
  skill_set["$s"]=1
done
for d in "${doc_profiles[@]}"; do
  doc_set["$d"]=1
done

for s in "${skill_profiles[@]}"; do
  if [[ -z "${doc_set[$s]:-}" ]]; then
    err "Missing docs profile for skill: docs/agents/$s.md"
    errors=$((errors + 1))
  fi
done
for d in "${doc_profiles[@]}"; do
  if [[ -z "${skill_set[$d]:-}" ]]; then
    err "Missing skill profile for docs entry: skills/codex-agents/$d"
    errors=$((errors + 1))
  fi
done

for profile in "${skill_profiles[@]}"; do
  skill_md="$SKILLS_DIR/$profile/SKILL.md"
  agent_yaml="$SKILLS_DIR/$profile/agents/openai.yaml"
  doc_md="$DOCS_DIR/$profile.md"

  if [[ ! -f "$skill_md" ]]; then
    err "Missing SKILL.md: $skill_md"
    errors=$((errors + 1))
    continue
  fi
  if [[ ! -f "$agent_yaml" ]]; then
    err "Missing agent config: $agent_yaml"
    errors=$((errors + 1))
    continue
  fi

  declared_name="$(grep -E '^name:' "$skill_md" | head -n1 | sed -E 's/^name:\s*//')"
  if [[ "$declared_name" != "$profile" ]]; then
    err "Frontmatter name mismatch in $skill_md (expected $profile, got $declared_name)"
    errors=$((errors + 1))
  fi

  if ! grep -Eq '^description:' "$skill_md"; then
    err "Missing frontmatter description in $skill_md"
    errors=$((errors + 1))
  fi

  if ! grep -Eq 'default_prompt:' "$agent_yaml"; then
    err "Missing default_prompt in $agent_yaml"
    errors=$((errors + 1))
  elif ! grep -Fq "\$$profile" "$agent_yaml"; then
    err "default_prompt does not reference \$$profile in $agent_yaml"
    errors=$((errors + 1))
  fi

  if [[ -f "$doc_md" ]]; then
    mapfile -t mcps < <(grep -E 'value:\s*"[^"]+"' "$agent_yaml" | sed -E 's/.*value:\s*"([^"]+)".*/\1/' | sort -u)
    for mcp in "${mcps[@]}"; do
      case "$mcp" in
        context7) token="Context7" ;;
        serena) token="Serena" ;;
        sequential-thinking) token="Sequential Thinking" ;;
        github) token="GitHub MCP" ;;
        playwright) token="Playwright MCP" ;;
        *) token="" ;;
      esac
      if [[ -n "$token" ]] && ! grep -qi "$token" "$doc_md"; then
        err "Docs missing MCP mention '$token' for profile '$profile' ($doc_md)"
        errors=$((errors + 1))
      fi
    done
  fi

done

if [[ -f "$QUICK_VALIDATE" ]] && command -v python3 >/dev/null 2>&1; then
  for profile in "${skill_profiles[@]}"; do
    profile_dir="$SKILLS_DIR/$profile"
    if ! python3 "$QUICK_VALIDATE" "$profile_dir" >/dev/null 2>&1; then
      err "quick_validate.py failed for $profile_dir"
      errors=$((errors + 1))
    fi
  done
else
  warn "quick_validate.py not available at $QUICK_VALIDATE; skipping OpenAI skill-creator validation"
  warnings=$((warnings + 1))
fi

forbidden_hits="$(rg -n "codex exec|gemini-cli|\bgemini\b" "$SKILLS_DIR" "$DOCS_DIR" -i || true)"
if [[ -n "$forbidden_hits" ]]; then
  err "Forbidden internal-run references found (codex exec / gemini):"
  echo "$forbidden_hits"
  errors=$((errors + 1))
fi

if [[ $errors -gt 0 ]]; then
  err "Agent audit failed with $errors error(s), $warnings warning(s)"
  exit 1
fi

say "Agent audit passed (${#skill_profiles[@]} profiles), warnings: $warnings"
