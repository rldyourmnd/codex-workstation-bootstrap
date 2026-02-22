#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
TEMPLATE_CONFIG="$ROOT_DIR/codex/config/config.template.toml"
TARGET_CONFIG="$CODEX_HOME_DIR/config.toml"
TARGET_GLOBAL_AGENTS="$CODEX_HOME_DIR/AGENTS.md"
TARGET_RULES_DIR="$CODEX_HOME_DIR/rules"
TARGET_RULES_FILE="$TARGET_RULES_DIR/default.rules"
TARGET_SKILLS_DIR="$CODEX_HOME_DIR/skills"

GLOBAL_AGENTS_SRC="$ROOT_DIR/codex/agents/global.AGENTS.md"
RULES_FULL_SRC="$ROOT_DIR/codex/rules/default.rules"
RULES_TEMPLATE_SRC="$ROOT_DIR/codex/rules/default.rules.template"
CUSTOM_SKILLS_SRC="$ROOT_DIR/codex/skills/custom"
CUSTOM_SKILLS_ARCHIVE_B64="$ROOT_DIR/codex/skills/custom-skills.tar.gz.b64"
CUSTOM_SKILLS_SHA256="$ROOT_DIR/codex/skills/custom-skills.sha256"
CUSTOM_SKILLS_MANIFEST="$ROOT_DIR/codex/skills/custom-skills.manifest.txt"
CURATED_MANIFEST="$ROOT_DIR/codex/skills/curated-manifest.txt"
SKILL_INSTALLER="$CODEX_HOME_DIR/skills/.system/skill-installer/scripts/install-skill-from-github.py"

FORCE=false
DRY_RUN=false
SKIP_CURATED=false
CLEAN_SKILLS=false

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
    *)
      echo "[ERROR] Unknown argument: $1"
      echo "Usage: scripts/install.sh [--force] [--dry-run] [--skip-curated] [--clean-skills]"
      exit 1
      ;;
  esac
done

say() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
err() { echo "[ERROR] $*"; }

run() {
  if $DRY_RUN; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    err "Missing required tool: $tool"
    exit 1
  fi
}

backup_if_exists() {
  local target="$1"
  if [[ -f "$target" ]]; then
    local backup="$target.bak.$(date +%Y%m%d_%H%M%S)"
    run "cp '$target' '$backup'"
    say "Backed up: $target -> $backup"
  fi
}

if [[ ! -f "$TEMPLATE_CONFIG" ]]; then
  err "Missing template config: $TEMPLATE_CONFIG"
  exit 1
fi

for tool in sed tar base64 rsync; do
  require_tool "$tool"
done

if ! command -v codex >/dev/null 2>&1; then
  warn "codex CLI not found in PATH. Install it first (npm i -g @openai/codex)."
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
  warn "CONTEXT7_API_KEY is empty. Context7 MCP auth may fail."
fi
if [[ -z "$GITHUB_MCP_TOKEN_VALUE" ]]; then
  warn "GITHUB_MCP_TOKEN is empty. GitHub MCP auth may fail."
fi

TMP_CONFIG="$(mktemp)"
cp "$TEMPLATE_CONFIG" "$TMP_CONFIG"

safe_c7="${CONTEXT7_API_KEY_VALUE//\\/\\\\}"
safe_c7="${safe_c7//&/\\&}"
safe_gh="${GITHUB_MCP_TOKEN_VALUE//\\/\\\\}"
safe_gh="${safe_gh//&/\\&}"

sed -i \
  -e "s|__CONTEXT7_API_KEY__|$safe_c7|g" \
  -e "s|__GITHUB_MCP_TOKEN__|$safe_gh|g" \
  "$TMP_CONFIG"

run "cp '$TMP_CONFIG' '$TARGET_CONFIG'"
rm -f "$TMP_CONFIG"
say "Installed config to $TARGET_CONFIG"

if [[ -f "$GLOBAL_AGENTS_SRC" ]]; then
  if [[ -f "$TARGET_GLOBAL_AGENTS" && ! $FORCE ]]; then
    warn "$TARGET_GLOBAL_AGENTS exists; skipping (use --force to overwrite)."
  else
    if [[ -f "$TARGET_GLOBAL_AGENTS" ]]; then
      backup_if_exists "$TARGET_GLOBAL_AGENTS"
    fi
    run "cp '$GLOBAL_AGENTS_SRC' '$TARGET_GLOBAL_AGENTS'"
    say "Installed global AGENTS to $TARGET_GLOBAL_AGENTS"
  fi
else
  warn "Global AGENTS source not found: $GLOBAL_AGENTS_SRC"
fi

if [[ -f "$RULES_FULL_SRC" ]]; then
  TMP_RULES="$(mktemp)"
  cp "$RULES_FULL_SRC" "$TMP_RULES"
  escaped_home="$(printf '%s' "$HOME" | sed 's/[.[\\*^$()+?{|]/\\&/g')"
  sed -i "s|__HOME__|$escaped_home|g" "$TMP_RULES"
  if [[ -f "$TARGET_RULES_FILE" ]]; then
    if $FORCE; then
      backup_if_exists "$TARGET_RULES_FILE"
    else
      warn "$TARGET_RULES_FILE exists; skipping full rules install (use --force to overwrite)."
      rm -f "$TMP_RULES"
      TMP_RULES=""
    fi
  fi
  if [[ -n "${TMP_RULES:-}" ]]; then
    run "cp '$TMP_RULES' '$TARGET_RULES_FILE'"
    rm -f "$TMP_RULES"
    say "Installed full rules to $TARGET_RULES_FILE"
  fi
elif [[ -f "$RULES_TEMPLATE_SRC" && ! -f "$TARGET_RULES_FILE" ]]; then
  run "cp '$RULES_TEMPLATE_SRC' '$TARGET_RULES_FILE'"
  say "Installed fallback rules template to $TARGET_RULES_FILE"
else
  warn "No rules source found in repository"
fi

if $CLEAN_SKILLS; then
  if $DRY_RUN; then
    echo "[DRY-RUN] remove all existing non-system skills from $TARGET_SKILLS_DIR"
  else
    find "$TARGET_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d ! -name '.system' -exec rm -rf {} +
  fi
  say "Cleaned existing non-system skills"
fi

if [[ -f "$CUSTOM_SKILLS_ARCHIVE_B64" ]]; then
  TMP_ARCHIVE="$(mktemp --suffix=.tar.gz)"
  TMP_EXTRACT_DIR="$(mktemp -d)"

  verify_archive_cmd="true"
  if [[ -f "$CUSTOM_SKILLS_SHA256" ]] && command -v sha256sum >/dev/null 2>&1; then
    verify_archive_cmd="echo \"$(cat "$CUSTOM_SKILLS_SHA256")  $TMP_ARCHIVE\" | sha256sum -c -"
  fi

  if $DRY_RUN; then
    echo "[DRY-RUN] base64 -d '$CUSTOM_SKILLS_ARCHIVE_B64' > '$TMP_ARCHIVE'"
    if [[ -f "$CUSTOM_SKILLS_SHA256" ]]; then
      echo "[DRY-RUN] verify sha256 from '$CUSTOM_SKILLS_SHA256'"
    fi
    echo "[DRY-RUN] tar -xzf '$TMP_ARCHIVE' -C '$TMP_EXTRACT_DIR'"
    echo "[DRY-RUN] rsync extracted skills to '$TARGET_SKILLS_DIR/'"
  else
    base64 -d "$CUSTOM_SKILLS_ARCHIVE_B64" > "$TMP_ARCHIVE"
    eval "$verify_archive_cmd" >/dev/null || {
      err "Custom skills archive checksum verification failed"
      rm -f "$TMP_ARCHIVE"
      rm -rf "$TMP_EXTRACT_DIR"
      exit 1
    }
    tar -xzf "$TMP_ARCHIVE" -C "$TMP_EXTRACT_DIR"
    if [[ -d "$TMP_EXTRACT_DIR/custom" ]]; then
      rsync -a "$TMP_EXTRACT_DIR/custom/" "$TARGET_SKILLS_DIR/"
    else
      rsync -a "$TMP_EXTRACT_DIR/" "$TARGET_SKILLS_DIR/"
    fi
  fi

  rm -f "$TMP_ARCHIVE"
  rm -rf "$TMP_EXTRACT_DIR"
  say "Custom skills archive extracted to $TARGET_SKILLS_DIR"
elif [[ -d "$CUSTOM_SKILLS_SRC" ]]; then
  run "rsync -a '$CUSTOM_SKILLS_SRC/' '$TARGET_SKILLS_DIR/'"
  say "Custom skills synced to $TARGET_SKILLS_DIR"
else
  warn "No custom skills source found in repository"
fi

if [[ -f "$CUSTOM_SKILLS_MANIFEST" ]]; then
  mapfile -t expected_custom < <(grep -Ev '^\s*#|^\s*$' "$CUSTOM_SKILLS_MANIFEST" || true)
  if [[ ${#expected_custom[@]} -gt 0 ]]; then
    missing_custom=0
    for skill in "${expected_custom[@]}"; do
      if [[ ! -f "$TARGET_SKILLS_DIR/$skill/SKILL.md" ]]; then
        warn "Expected skill not found after install: $skill"
        missing_custom=$((missing_custom + 1))
      fi
    done
    if [[ $missing_custom -eq 0 ]]; then
      say "Installed all skills from snapshot manifest (${#expected_custom[@]})"
    fi
  fi
fi

if ! $SKIP_CURATED; then
  if [[ -f "$SKILL_INSTALLER" && -f "$CURATED_MANIFEST" ]]; then
    mapfile -t curated_paths < <(grep -Ev '^\s*#|^\s*$' "$CURATED_MANIFEST")
    if [[ ${#curated_paths[@]} -gt 0 ]]; then
      if $DRY_RUN; then
        echo "[DRY-RUN] python3 '$SKILL_INSTALLER' --repo openai/skills --path ${curated_paths[*]}"
      else
        python3 "$SKILL_INSTALLER" --repo openai/skills --path "${curated_paths[@]}"
      fi
      say "Curated skills install attempted from openai/skills"
    fi
  else
    warn "Skill installer or curated manifest not found. Skipping curated skills install."
  fi
fi

if command -v codex >/dev/null 2>&1 && ! $DRY_RUN; then
  codex mcp list >/dev/null || warn "Unable to query MCP list after install"
fi

say "Install complete"
