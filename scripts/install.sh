#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
TEMPLATE_CONFIG="$ROOT_DIR/codex/config/config.template.toml"
TARGET_CONFIG="$CODEX_HOME_DIR/config.toml"
TARGET_RULES_DIR="$CODEX_HOME_DIR/rules"
TARGET_SKILLS_DIR="$CODEX_HOME_DIR/skills"
CUSTOM_SKILLS_SRC="$ROOT_DIR/codex/skills/custom"
CUSTOM_SKILLS_ARCHIVE_B64="$ROOT_DIR/codex/skills/custom-skills.tar.gz.b64"
CUSTOM_SKILLS_SHA256="$ROOT_DIR/codex/skills/custom-skills.sha256"
CURATED_MANIFEST="$ROOT_DIR/codex/skills/curated-manifest.txt"
SKILL_INSTALLER="$CODEX_HOME_DIR/skills/.system/skill-installer/scripts/install-skill-from-github.py"

FORCE=false
DRY_RUN=false
SKIP_CURATED=false

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
    *)
      echo "[ERROR] Unknown argument: $1"
      echo "Usage: scripts/install.sh [--force] [--dry-run] [--skip-curated]"
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

if [[ ! -f "$TEMPLATE_CONFIG" ]]; then
  err "Missing template config: $TEMPLATE_CONFIG"
  exit 1
fi

for tool in sed tar base64 rsync; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    err "Missing required tool: $tool"
    exit 1
  fi
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
  BACKUP="$TARGET_CONFIG.bak.$(date +%Y%m%d_%H%M%S)"
  run "cp '$TARGET_CONFIG' '$BACKUP'"
  say "Backed up existing config to $BACKUP"
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

if [[ -f "$ROOT_DIR/codex/rules/default.rules.template" && ! -f "$TARGET_RULES_DIR/default.rules" ]]; then
  run "cp '$ROOT_DIR/codex/rules/default.rules.template' '$TARGET_RULES_DIR/default.rules'"
  say "Installed optional rules template to $TARGET_RULES_DIR/default.rules"
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

if ! $SKIP_CURATED; then
  if [[ -f "$SKILL_INSTALLER" ]]; then
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
    warn "Skill installer not found at $SKILL_INSTALLER. Skipping curated skills install."
  fi
fi

if command -v codex >/dev/null 2>&1 && ! $DRY_RUN; then
  codex mcp list >/dev/null || warn "Unable to query MCP list after install"
fi

say "Install complete"
