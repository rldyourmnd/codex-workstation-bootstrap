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
DEST_RULES_TEMPLATE="$ROOT_DIR/codex/rules/default.rules.template"
DEST_RULES_SOURCE_SNAPSHOT="$ROOT_DIR/codex/rules/default.rules.source.snapshot"
DEST_CUSTOM_ARCHIVE_B64="$ROOT_DIR/codex/skills/custom-skills.tar.gz.b64"
DEST_CUSTOM_ARCHIVE_SHA256="$ROOT_DIR/codex/skills/custom-skills.sha256"
DEST_CUSTOM_MANIFEST="$ROOT_DIR/codex/skills/custom-skills.manifest.txt"
DEST_PROJECT_TRUST_SNAPSHOT="$ROOT_DIR/codex/config/projects.trust.snapshot.toml"
DEST_TOOLCHAIN_LOCK="$ROOT_DIR/codex/meta/toolchain.lock"
RULES_RENDERER="$ROOT_DIR/scripts/render-portable-rules.sh"
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

if [[ ! -x "$RULES_RENDERER" ]]; then
  err "Missing executable rules renderer: $RULES_RENDERER"
  exit 1
fi

if [[ ! -f "$SOURCE_CONFIG" ]]; then
  err "Missing source config: $SOURCE_CONFIG"
  exit 1
fi

if [[ ! -d "$SOURCE_SKILLS_DIR" ]]; then
  err "Missing source skills dir: $SOURCE_SKILLS_DIR"
  exit 1
fi

mkdir -p "$ROOT_DIR/codex/agents" "$ROOT_DIR/codex/rules" "$ROOT_DIR/codex/skills" "$ROOT_DIR/codex/meta"

cp "$SOURCE_CONFIG" "$DEST_CONFIG_TEMPLATE"

# Sanitize secrets for portable template.
# 1) Generic redaction for key/value settings that look secret-like.
sed -i -E \
  -e 's#^([[:space:]]*[A-Za-z0-9_]*(KEY|TOKEN|SECRET|PASSWORD)[A-Za-z0-9_]*[[:space:]]*=[[:space:]]*").*(".*)$#\1__REDACTED__\3#' \
  "$DEST_CONFIG_TEMPLATE"

# 2) Stable placeholders used by install.sh.
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

source_home="$(dirname "$SOURCE_CODEX_HOME")"
escaped_source_home="$(printf '%s' "$source_home" | sed 's/[.[\\*^$()+?{|]/\\&/g')"

# Preserve local trust entries separately for optional exact restore.
awk '
  /^\[projects\./ { in_projects=1 }
  in_projects && /^\[/ && !/^\[projects\./ { in_projects=0 }
  in_projects { print }
' "$SOURCE_CONFIG" > "$TMP_DIR/projects.trust.raw.toml"

if [[ -s "$TMP_DIR/projects.trust.raw.toml" ]]; then
  cp "$TMP_DIR/projects.trust.raw.toml" "$DEST_PROJECT_TRUST_SNAPSHOT"
  sed -i "s|$escaped_source_home|__HOME__|g" "$DEST_PROJECT_TRUST_SNAPSHOT"
else
  cat > "$DEST_PROJECT_TRUST_SNAPSHOT" <<'PROJECTS'
# No project trust entries were found during last export.
# This file remains for deterministic structure across machines.
PROJECTS
fi

if [[ -f "$SOURCE_GLOBAL_AGENTS" ]]; then
  cp "$SOURCE_GLOBAL_AGENTS" "$DEST_GLOBAL_AGENTS"
  say "Updated: $DEST_GLOBAL_AGENTS"
else
  err "Missing global AGENTS source: $SOURCE_GLOBAL_AGENTS"
  exit 1
fi

if [[ -f "$SOURCE_RULES" ]]; then
  cp "$SOURCE_RULES" "$DEST_RULES_SOURCE_SNAPSHOT"
  sed -i "s|$escaped_source_home|__HOME__|g" "$DEST_RULES_SOURCE_SNAPSHOT"
  "$RULES_RENDERER" "$DEST_RULES"
  "$RULES_RENDERER" "$DEST_RULES_TEMPLATE"
  say "Updated: $DEST_RULES"
  say "Updated: $DEST_RULES_TEMPLATE"
  say "Updated: $DEST_RULES_SOURCE_SNAPSHOT"
else
  err "Missing source rules: $SOURCE_RULES"
  exit 1
fi

if grep -Eq 'Bearer [A-Za-z0-9]' "$DEST_CONFIG_TEMPLATE"; then
  err "Unsafe bearer token detected after sanitization in $DEST_CONFIG_TEMPLATE"
  exit 1
fi
if grep -Eq '(ctx7sk-|ghp_|gho_|github_pat_|sk-[A-Za-z0-9])' "$DEST_CONFIG_TEMPLATE"; then
  err "Unsafe API token-like value detected after sanitization in $DEST_CONFIG_TEMPLATE"
  exit 1
fi

codex_version="$(codex --version 2>/dev/null | awk '{print $2}' || true)"
node_version="$(node --version 2>/dev/null | sed 's/^v//' || true)"
npm_version="$(npm --version 2>/dev/null || true)"
python_version="$(python3 --version 2>/dev/null | awk '{print $2}' || true)"
uv_version="$(uv --version 2>/dev/null | awk '{print $2}' || true)"
uvx_version="$(uvx --version 2>/dev/null | awk '{print $2}' || true)"
gh_version="$(gh --version 2>/dev/null | head -n1 | awk '{print $3}' || true)"
os_name="$(uname -s 2>/dev/null || true)"
arch_name="$(uname -m 2>/dev/null || true)"

cat > "$DEST_TOOLCHAIN_LOCK" <<EOF
# Generated by scripts/export-from-local.sh
GENERATED_AT_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
OS_NAME=${os_name:-unknown}
ARCH_NAME=${arch_name:-unknown}
CODEX_VERSION=${codex_version:-unknown}
NODE_VERSION=${node_version:-unknown}
NPM_VERSION=${npm_version:-unknown}
PYTHON_VERSION=${python_version:-unknown}
UV_VERSION=${uv_version:-unknown}
UVX_VERSION=${uvx_version:-unknown}
GH_VERSION=${gh_version:-unknown}
EOF

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

if tar --help 2>/dev/null | grep -q -- '--sort'; then
  tar --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 --numeric-owner -C "$TMP_DIR/custom" -czf "$TMP_DIR/custom-skills.tar.gz" .
else
  tar -C "$TMP_DIR/custom" -czf "$TMP_DIR/custom-skills.tar.gz" .
fi
base64_nolinewrap "$TMP_DIR/custom-skills.tar.gz" > "$DEST_CUSTOM_ARCHIVE_B64"

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$TMP_DIR/custom-skills.tar.gz" | awk '{print $1}' > "$DEST_CUSTOM_ARCHIVE_SHA256"
fi

say "Export complete"
say "Updated: $DEST_CONFIG_TEMPLATE"
say "Updated: $DEST_PROJECT_TRUST_SNAPSHOT"
say "Updated: $DEST_TOOLCHAIN_LOCK"
say "Updated: $DEST_CUSTOM_MANIFEST"
say "Updated: $DEST_CUSTOM_ARCHIVE_B64"
if [[ -f "$DEST_CUSTOM_ARCHIVE_SHA256" ]]; then
  say "Updated: $DEST_CUSTOM_ARCHIVE_SHA256"
fi
say "Packed skills: ${#skills_to_pack[@]}"
