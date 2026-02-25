#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/os/common/platform.sh"
source "$ROOT_DIR/scripts/os/common/layout.sh"

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
TARGET_CONFIG="$CODEX_HOME_DIR/config.toml"
TARGET_GLOBAL_AGENTS="$CODEX_HOME_DIR/AGENTS.md"
TARGET_RULES_DIR="$CODEX_HOME_DIR/rules"
TARGET_RULES_FILE="$TARGET_RULES_DIR/default.rules"
TARGET_SKILLS_DIR="$CODEX_HOME_DIR/skills"
RULES_MODE_FILE="$CODEX_HOME_DIR/.better-codex-rules-mode"
SKILL_INSTALLER="$CODEX_HOME_DIR/skills/.system/skill-installer/scripts/install-skill-from-github.py"

FORCE=false
DRY_RUN=false
SKIP_CURATED=false
CLEAN_SKILLS=false
RULES_MODE="exact"
APPLY_PROJECT_TRUST=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --skip-curated)
      SKIP_CURATED=true
      shift
      ;;
    --clean-skills)
      CLEAN_SKILLS=true
      shift
      ;;
    --rules-mode)
      if [[ $# -lt 2 ]]; then
        echo "[ERROR] --rules-mode requires value: portable|exact"
        exit 1
      fi
      RULES_MODE="$2"
      shift 2
      ;;
    --skip-project-trust)
      APPLY_PROJECT_TRUST=false
      shift
      ;;
    *)
      echo "[ERROR] Unknown argument: $1"
      echo "Usage: scripts/install.sh [--force] [--dry-run] [--skip-curated] [--clean-skills] [--rules-mode portable|exact] [--skip-project-trust]"
      exit 1
      ;;
  esac
done

say() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
err() { echo "[ERROR] $*"; }

if [[ "$RULES_MODE" != "portable" && "$RULES_MODE" != "exact" ]]; then
  err "Invalid --rules-mode value: $RULES_MODE (expected portable|exact)"
  exit 1
fi

REQUESTED_PROFILE="$(detect_profile_os)"
PROFILE_OS="$(resolve_profile_os "$REQUESTED_PROFILE")"
PROFILE_ROOT="$(resolve_runtime_root "$REQUESTED_PROFILE")"

TEMPLATE_CONFIG="$PROFILE_ROOT/config/config.template.toml"
GLOBAL_AGENTS_SRC="$PROFILE_ROOT/agents/global.AGENTS.md"
RULES_PORTABLE_SRC="$PROFILE_ROOT/rules/default.rules"
RULES_SOURCE_SNAPSHOT="$PROFILE_ROOT/rules/default.rules.source.snapshot"
RULES_TEMPLATE_SRC="$PROFILE_ROOT/rules/default.rules.template"
PROJECT_TRUST_SNAPSHOT="$PROFILE_ROOT/config/projects.trust.snapshot.toml"
CUSTOM_SKILLS_DIR="$PROFILE_ROOT/skills/custom"
CUSTOM_SKILLS_MANIFEST="$PROFILE_ROOT/skills/manifests/custom-skills.manifest.txt"
CURATED_MANIFEST="$PROFILE_ROOT/skills/manifests/curated-manifest.txt"
AGENT_SKILLS_SRC="$(common_agent_skills_root)"

run() {
  if $DRY_RUN; then
    printf "[DRY-RUN]"
    printf " %q" "$@"
    printf "\n"
  else
    "$@"
  fi
}

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    err "Missing required tool: $tool"
    exit 1
  fi
}

is_nonempty_text_file() {
  local file="$1"
  [[ -f "$file" ]] && grep -q '[^[:space:]]' "$file"
}

backup_if_exists() {
  local target="$1"
  if [[ -f "$target" ]]; then
    local backup="$target.bak.$(date +%Y%m%d_%H%M%S)"
    run cp "$target" "$backup"
    say "Backed up: $target -> $backup"
  fi
}

install_skill_dir() {
  local src_root="$1"
  local skill="$2"
  local src="$src_root/$skill"
  local dst="$TARGET_SKILLS_DIR/$skill"

  if [[ ! -f "$src/SKILL.md" ]]; then
    err "Skill missing SKILL.md: $src"
    exit 1
  fi

  if [[ -d "$dst" && ! $FORCE ]]; then
    warn "Skill exists, skipping (use --force to overwrite): $skill"
    return
  fi

  if $DRY_RUN; then
    echo "[DRY-RUN] rm -rf '$dst'"
    echo "[DRY-RUN] rsync -a '$src/' '$dst/'"
  else
    rm -rf "$dst"
    rsync -a "$src/" "$dst/"
  fi
  say "Installed skill: $skill"
}

for tool in sed rsync awk; do
  require_tool "$tool"
done

if [[ "$REQUESTED_PROFILE" != "$PROFILE_OS" ]]; then
  warn "Profile '$REQUESTED_PROFILE' has no payload, using '$PROFILE_OS'"
fi

if [[ ! -f "$TEMPLATE_CONFIG" ]]; then
  err "Missing template config: $TEMPLATE_CONFIG"
  exit 1
fi
if [[ ! -f "$GLOBAL_AGENTS_SRC" ]]; then
  err "Missing global AGENTS source: $GLOBAL_AGENTS_SRC"
  exit 1
fi
if [[ ! -d "$CUSTOM_SKILLS_DIR" ]]; then
  err "Missing custom skills dir: $CUSTOM_SKILLS_DIR"
  exit 1
fi
if [[ ! -f "$CUSTOM_SKILLS_MANIFEST" ]]; then
  err "Missing custom skills manifest: $CUSTOM_SKILLS_MANIFEST"
  exit 1
fi

mkdir -p "$CODEX_HOME_DIR" "$TARGET_RULES_DIR" "$TARGET_SKILLS_DIR"

if [[ -f "$TARGET_CONFIG" ]]; then
  if ! $FORCE; then
    err "$TARGET_CONFIG already exists. Re-run with --force to overwrite."
    exit 1
  fi
  backup_if_exists "$TARGET_CONFIG"
fi

CONTEXT7_API_KEY_VALUE="${CONTEXT7_API_KEY:-}"
GITHUB_MCP_TOKEN_VALUE="${GITHUB_MCP_TOKEN:-}"

if [[ -z "$CONTEXT7_API_KEY_VALUE" ]]; then
  warn "CONTEXT7_API_KEY is empty. Context7 MCP may not authenticate."
fi
if [[ -z "$GITHUB_MCP_TOKEN_VALUE" ]]; then
  warn "GITHUB_MCP_TOKEN is empty. GitHub MCP may not authenticate."
fi

TMP_CONFIG="$(mktemp)"
cp "$TEMPLATE_CONFIG" "$TMP_CONFIG"

safe_c7="${CONTEXT7_API_KEY_VALUE//\\/\\\\}"
safe_c7="${safe_c7//&/\\&}"
safe_gh="${GITHUB_MCP_TOKEN_VALUE//\\/\\\\}"
safe_gh="${safe_gh//&/\\&}"

sed_inplace "$TMP_CONFIG" \
  -e "s|__CONTEXT7_API_KEY__|$safe_c7|g" \
  -e "s|__GITHUB_MCP_TOKEN__|$safe_gh|g"

run cp "$TMP_CONFIG" "$TARGET_CONFIG"
rm -f "$TMP_CONFIG"
say "Installed config to $TARGET_CONFIG"

if $APPLY_PROJECT_TRUST; then
  if [[ -f "$PROJECT_TRUST_SNAPSHOT" ]] && grep -Eq '^\[projects\.' "$PROJECT_TRUST_SNAPSHOT"; then
    TMP_PROJECTS="$(mktemp)"
    cp "$PROJECT_TRUST_SNAPSHOT" "$TMP_PROJECTS"
    escaped_home="$(printf '%s' "$HOME" | sed 's/[.[\\*^$()+?{|]/\\&/g')"
    sed_inplace "$TMP_PROJECTS" -e "s|__HOME__|$escaped_home|g"
    if $DRY_RUN; then
      echo "[DRY-RUN] append project trust snapshot from '$PROJECT_TRUST_SNAPSHOT' to '$TARGET_CONFIG'"
    else
      {
        echo
        cat "$TMP_PROJECTS"
      } >> "$TARGET_CONFIG"
    fi
    rm -f "$TMP_PROJECTS"
    say "Applied project trust snapshot"
  else
    warn "No project trust snapshot entries to apply"
  fi
else
  say "Skipping project trust snapshot (requested)"
fi

if ! is_nonempty_text_file "$GLOBAL_AGENTS_SRC"; then
  err "Global AGENTS source is empty: $GLOBAL_AGENTS_SRC"
  exit 1
fi

if [[ -f "$TARGET_GLOBAL_AGENTS" && ! $FORCE ]]; then
  warn "$TARGET_GLOBAL_AGENTS exists; skipping (use --force to overwrite)."
else
  if [[ -f "$TARGET_GLOBAL_AGENTS" ]]; then
    backup_if_exists "$TARGET_GLOBAL_AGENTS"
  fi
  run cp "$GLOBAL_AGENTS_SRC" "$TARGET_GLOBAL_AGENTS"
  say "Installed global AGENTS to $TARGET_GLOBAL_AGENTS"
fi

rules_source=""
if [[ "$RULES_MODE" == "exact" && -f "$RULES_SOURCE_SNAPSHOT" ]]; then
  rules_source="$RULES_SOURCE_SNAPSHOT"
elif [[ -f "$RULES_PORTABLE_SRC" ]]; then
  rules_source="$RULES_PORTABLE_SRC"
  if [[ "$RULES_MODE" == "exact" ]]; then
    warn "Exact rules snapshot not found, falling back to portable rules"
  fi
fi

if [[ -n "$rules_source" ]]; then
  TMP_RULES="$(mktemp)"
  cp "$rules_source" "$TMP_RULES"
  escaped_home="$(printf '%s' "$HOME" | sed 's/[.[\\*^$()+?{|]/\\&/g')"
  sed_inplace "$TMP_RULES" -e "s|__HOME__|$escaped_home|g"

  if [[ -f "$TARGET_RULES_FILE" ]]; then
    if $FORCE; then
      backup_if_exists "$TARGET_RULES_FILE"
    else
      warn "$TARGET_RULES_FILE exists; skipping full rules install (use --force to overwrite)."
      rm -f "$TMP_RULES"
      TMP_RULES=""
    fi
  fi

  if [[ -n "$TMP_RULES" ]]; then
    run cp "$TMP_RULES" "$TARGET_RULES_FILE"
    rm -f "$TMP_RULES"
    say "Installed $RULES_MODE rules to $TARGET_RULES_FILE"
  fi
elif [[ -f "$RULES_TEMPLATE_SRC" && ! -f "$TARGET_RULES_FILE" ]]; then
  run cp "$RULES_TEMPLATE_SRC" "$TARGET_RULES_FILE"
  say "Installed fallback rules template to $TARGET_RULES_FILE"
else
  warn "No rules source found in repository"
fi

if $DRY_RUN; then
  echo "[DRY-RUN] write rules mode '$RULES_MODE' to '$RULES_MODE_FILE'"
else
  printf '%s\n' "$RULES_MODE" > "$RULES_MODE_FILE"
fi

if $CLEAN_SKILLS; then
  if $DRY_RUN; then
    echo "[DRY-RUN] remove all existing non-system skills from $TARGET_SKILLS_DIR"
  else
    find "$TARGET_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d ! -name '.system' -exec rm -rf {} +
  fi
  say "Cleaned existing non-system skills"
fi

shared_skills=()
if [[ -d "$AGENT_SKILLS_SRC" ]]; then
  while IFS= read -r line; do
    shared_skills+=("$line")
  done < <(list_top_level_dirs "$AGENT_SKILLS_SRC")

  for skill in "${shared_skills[@]}"; do
    install_skill_dir "$AGENT_SKILLS_SRC" "$skill"
  done
  say "Installed shared agent profiles: ${#shared_skills[@]}"
else
  warn "Shared agent profile directory not found: $AGENT_SKILLS_SRC"
fi

custom_skills=()
while IFS= read -r line; do
  custom_skills+=("$line")
done < <(read_nonempty_lines "$CUSTOM_SKILLS_MANIFEST")

if [[ ${#custom_skills[@]} -eq 0 ]]; then
  err "No custom skills listed in manifest: $CUSTOM_SKILLS_MANIFEST"
  exit 1
fi

missing_custom=0
for skill in "${custom_skills[@]}"; do
  if [[ ! -f "$CUSTOM_SKILLS_DIR/$skill/SKILL.md" ]]; then
    err "Manifest skill missing from snapshot: $skill"
    missing_custom=$((missing_custom + 1))
    continue
  fi
  install_skill_dir "$CUSTOM_SKILLS_DIR" "$skill"
done
if [[ $missing_custom -gt 0 ]]; then
  err "Missing $missing_custom skill(s) from snapshot manifest"
  exit 1
fi
say "Installed custom skills from manifest: ${#custom_skills[@]}"

if ! $SKIP_CURATED; then
  if [[ -f "$SKILL_INSTALLER" && -f "$CURATED_MANIFEST" ]]; then
    curated_paths=()
    while IFS= read -r line; do
      curated_paths+=("$line")
    done < <(read_nonempty_lines "$CURATED_MANIFEST")

    if [[ ${#curated_paths[@]} -gt 0 ]]; then
      if ! command -v python3 >/dev/null 2>&1; then
        warn "python3 not found; skipping curated skill install"
      elif $DRY_RUN; then
        echo "[DRY-RUN] python3 '$SKILL_INSTALLER' --repo openai/skills --path ${curated_paths[*]}"
      else
        python3 "$SKILL_INSTALLER" --repo openai/skills --path "${curated_paths[@]}" || warn "Curated skills install returned non-zero status"
        say "Curated skills install attempted from openai/skills"
      fi
    fi
  else
    warn "Skill installer or curated manifest not found. Skipping curated skills install."
  fi
else
  say "Skipping curated skills (requested)"
fi

if command -v codex >/dev/null 2>&1 && ! $DRY_RUN; then
  codex mcp list >/dev/null || warn "Unable to query MCP list after install"
fi

say "Install complete (profile: $PROFILE_OS)"
