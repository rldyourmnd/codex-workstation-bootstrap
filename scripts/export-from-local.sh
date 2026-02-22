#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_CODEX_HOME="${1:-${CODEX_HOME:-$HOME/.codex}}"
SOURCE_CONFIG="$SOURCE_CODEX_HOME/config.toml"
SOURCE_GLOBAL_AGENTS="$SOURCE_CODEX_HOME/AGENTS.md"
SOURCE_RULES="$SOURCE_CODEX_HOME/rules/default.rules"
SOURCE_SKILLS_DIR="$SOURCE_CODEX_HOME/skills"

DEST_CONFIG_TEMPLATE="$ROOT_DIR/codex/config/config.template.toml"
DEST_GLOBAL_AGENTS="$ROOT_DIR/codex/agents/global.AGENTS.md"
DEST_RULES="$ROOT_DIR/codex/rules/default.rules"
DEST_CUSTOM_ARCHIVE_B64="$ROOT_DIR/codex/skills/custom-skills.tar.gz.b64"
DEST_CUSTOM_ARCHIVE_SHA256="$ROOT_DIR/codex/skills/custom-skills.sha256"
DEST_CUSTOM_MANIFEST="$ROOT_DIR/codex/skills/custom-skills.manifest.txt"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

say() { echo "[INFO] $*"; }
err() { echo "[ERROR] $*"; }

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    err "Missing required tool: $tool"
    exit 1
  fi
}

base64_nolinewrap() {
  local src="$1"
  if base64 --help 2>/dev/null | grep -q -- '-w'; then
    base64 -w 0 "$src"
  else
    base64 "$src" | tr -d '\n'
  fi
}

require_tool awk
require_tool sed
require_tool rsync
require_tool tar
require_tool base64

if [[ ! -f "$SOURCE_CONFIG" ]]; then
  err "Missing source config: $SOURCE_CONFIG"
  exit 1
fi

if [[ ! -d "$SOURCE_SKILLS_DIR" ]]; then
  err "Missing source skills dir: $SOURCE_SKILLS_DIR"
  exit 1
fi

mkdir -p "$ROOT_DIR/codex/agents" "$ROOT_DIR/codex/rules" "$ROOT_DIR/codex/skills"

cp "$SOURCE_CONFIG" "$DEST_CONFIG_TEMPLATE"

# Sanitize secrets for portable template.
sed -i \
  -e 's|CONTEXT7_API_KEY = ".*"|CONTEXT7_API_KEY = "__CONTEXT7_API_KEY__"|g' \
  -e 's|Authorization = "Bearer .*"|Authorization = "Bearer __GITHUB_MCP_TOKEN__"|g' \
  "$DEST_CONFIG_TEMPLATE"

# Drop machine-specific project trust entries.
awk '
  BEGIN { skip=0 }
  /^\[projects\./ { skip=1; next }
  /^\[/ { if (skip==1) skip=0 }
  { if (skip==0) print $0 }
' "$DEST_CONFIG_TEMPLATE" > "$TMP_DIR/config.cleaned.toml"
mv "$TMP_DIR/config.cleaned.toml" "$DEST_CONFIG_TEMPLATE"

if [[ -f "$SOURCE_GLOBAL_AGENTS" ]]; then
  cp "$SOURCE_GLOBAL_AGENTS" "$DEST_GLOBAL_AGENTS"
  say "Updated: $DEST_GLOBAL_AGENTS"
else
  err "Missing global AGENTS source: $SOURCE_GLOBAL_AGENTS"
  exit 1
fi

if [[ -f "$SOURCE_RULES" ]]; then
  cp "$SOURCE_RULES" "$DEST_RULES"
  source_home="$(dirname "$SOURCE_CODEX_HOME")"
  escaped_source_home="$(printf '%s' "$source_home" | sed 's/[.[\\*^$()+?{|]/\\&/g')"
  sed -i "s|$escaped_source_home|__HOME__|g" "$DEST_RULES"
  say "Updated: $DEST_RULES"
else
  err "Missing source rules: $SOURCE_RULES"
  exit 1
fi

mapfile -t skills_to_pack < <(
  find "$SOURCE_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
    | grep -Ev '^\.system$' \
    | sort
)

if [[ ${#skills_to_pack[@]} -eq 0 ]]; then
  err "No non-system skills found under $SOURCE_SKILLS_DIR"
  exit 1
fi

mkdir -p "$TMP_DIR/custom"
for skill in "${skills_to_pack[@]}"; do
  if [[ ! -f "$SOURCE_SKILLS_DIR/$skill/SKILL.md" ]]; then
    err "Skill missing SKILL.md: $skill"
    exit 1
  fi
  rsync -a --delete "$SOURCE_SKILLS_DIR/$skill" "$TMP_DIR/custom/"
done

printf '%s\n' "${skills_to_pack[@]}" > "$DEST_CUSTOM_MANIFEST"

# Keep artifact compact.
find "$TMP_DIR/custom" -type d -name '__pycache__' -prune -exec rm -rf {} +
find "$TMP_DIR/custom" -type d -name '.git' -prune -exec rm -rf {} +

tar -C "$TMP_DIR/custom" -czf "$TMP_DIR/custom-skills.tar.gz" .
base64_nolinewrap "$TMP_DIR/custom-skills.tar.gz" > "$DEST_CUSTOM_ARCHIVE_B64"

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$TMP_DIR/custom-skills.tar.gz" | awk '{print $1}' > "$DEST_CUSTOM_ARCHIVE_SHA256"
fi

say "Export complete"
say "Updated: $DEST_CONFIG_TEMPLATE"
say "Updated: $DEST_CUSTOM_MANIFEST"
say "Updated: $DEST_CUSTOM_ARCHIVE_B64"
if [[ -f "$DEST_CUSTOM_ARCHIVE_SHA256" ]]; then
  say "Updated: $DEST_CUSTOM_ARCHIVE_SHA256"
fi
say "Packed skills: ${#skills_to_pack[@]}"
