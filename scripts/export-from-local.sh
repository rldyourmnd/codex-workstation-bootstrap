#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/os/common/platform.sh"

SOURCE_CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
SOURCE_PATH_SET=false
EXPORT_FULL_HOME=false
ALLOW_EMPTY_AGENTS=false
ALLOW_EMPTY_SKILLS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      if [[ $# -lt 2 ]]; then
        echo "[ERROR] --source requires a value"
        exit 1
      fi
      SOURCE_CODEX_HOME="$2"
      SOURCE_PATH_SET=true
      shift 2
      ;;
    --with-full-home)
      EXPORT_FULL_HOME=true
      shift
      ;;
    --allow-empty-agents)
      ALLOW_EMPTY_AGENTS=true
      shift
      ;;
    --allow-empty-skills)
      ALLOW_EMPTY_SKILLS=true
      shift
      ;;
    --help)
      echo "Usage: scripts/export-from-local.sh [--source <path-to-codex-home>] [--with-full-home] [--allow-empty-agents] [--allow-empty-skills]"
      exit 0
      ;;
    *)
      if [[ "$1" == --* ]]; then
        echo "[ERROR] Unknown argument: $1"
        exit 1
      fi
      if $SOURCE_PATH_SET; then
        echo "[ERROR] Multiple source paths provided"
        exit 1
      fi
      SOURCE_CODEX_HOME="$1"
      SOURCE_PATH_SET=true
      shift
      ;;
  esac
done

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

SOURCE_PLATFORM="$(platform_id)"
DEST_OS_DIR="$ROOT_DIR/codex/os/$SOURCE_PLATFORM"
DEST_FULL_HOME_ARCHIVE_B64="$DEST_OS_DIR/full-codex-home.tar.gz.b64"
DEST_FULL_HOME_ARCHIVE_SHA256="$DEST_OS_DIR/full-codex-home.sha256"
DEST_FULL_HOME_MANIFEST="$DEST_OS_DIR/full-codex-home.manifest.txt"

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

say() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
err() { echo "[ERROR] $*"; }

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    err "Missing required tool: $tool"
    exit 1
  fi
}

for tool in awk sed rsync tar base64; do
  require_tool "$tool"
done

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

mkdir -p \
  "$ROOT_DIR/codex/agents" \
  "$ROOT_DIR/codex/rules" \
  "$ROOT_DIR/codex/skills" \
  "$ROOT_DIR/codex/meta" \
  "$DEST_OS_DIR"

cp "$SOURCE_CONFIG" "$DEST_CONFIG_TEMPLATE"

# Sanitize secrets for portable template.
sed_inplace "$DEST_CONFIG_TEMPLATE" -E \
  -e 's#^([[:space:]]*[A-Za-z0-9_-]*([Kk][Ee][Yy]|[Tt][Oo][Kk][Ee][Nn]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd])[A-Za-z0-9_-]*[[:space:]]*=[[:space:]]*").*(".*)$#\1__REDACTED__\3#'
sed_inplace "$DEST_CONFIG_TEMPLATE" \
  -e 's|CONTEXT7_API_KEY = ".*"|CONTEXT7_API_KEY = "__CONTEXT7_API_KEY__"|g' \
  -e 's|"x-context7-api-key"[[:space:]]*=[[:space:]]*".*"|"x-context7-api-key" = "__CONTEXT7_API_KEY__"|g' \
  -e 's|Authorization = "Bearer .*"|Authorization = "Bearer __GITHUB_MCP_TOKEN__"|g' \
  -e 's|"Authorization"[[:space:]]*=[[:space:]]*"Bearer .*"|"Authorization" = "Bearer __GITHUB_MCP_TOKEN__"|g'

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
  sed_inplace "$DEST_PROJECT_TRUST_SNAPSHOT" -e "s|$escaped_source_home|__HOME__|g"
else
  cat > "$DEST_PROJECT_TRUST_SNAPSHOT" <<'PROJECTS'
# No project trust entries were found during last export.
# This file remains for deterministic structure across machines.
PROJECTS
fi

if [[ -f "$SOURCE_GLOBAL_AGENTS" ]]; then
  if ! grep -q '[^[:space:]]' "$SOURCE_GLOBAL_AGENTS"; then
    if $ALLOW_EMPTY_AGENTS; then
      warn "Source global AGENTS is empty. Keeping empty snapshot due --allow-empty-agents."
    else
      err "Source global AGENTS is empty: $SOURCE_GLOBAL_AGENTS"
      err "Refusing to overwrite codex/agents/global.AGENTS.md with empty content."
      err "Use --allow-empty-agents only if this is intentional."
      exit 1
    fi
  fi
  cp "$SOURCE_GLOBAL_AGENTS" "$DEST_GLOBAL_AGENTS"
  say "Updated: $DEST_GLOBAL_AGENTS"
else
  err "Missing global AGENTS source: $SOURCE_GLOBAL_AGENTS"
  exit 1
fi

if [[ -f "$SOURCE_RULES" ]]; then
  cp "$SOURCE_RULES" "$DEST_RULES_SOURCE_SNAPSHOT"
  sed_inplace "$DEST_RULES_SOURCE_SNAPSHOT" -e "s|$escaped_source_home|__HOME__|g"
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
GENERATED_AT_UTC=$(utc_now_iso)
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

skills_to_pack=()
while IFS= read -r skill; do
  skills_to_pack+=("$skill")
done < <(
  find "$SOURCE_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d \
    | sed 's|.*/||' \
    | grep -Ev '^\.system$' \
    | sort
)

mkdir -p "$TMP_DIR/custom"
if [[ ${#skills_to_pack[@]} -eq 0 ]]; then
  if $ALLOW_EMPTY_SKILLS; then
    warn "No non-system skills found under $SOURCE_SKILLS_DIR (allowed by --allow-empty-skills)"
    cat > "$DEST_CUSTOM_MANIFEST" <<'MANIFEST'
# No non-system skills were found during last export.
MANIFEST
  else
    err "No non-system skills found under $SOURCE_SKILLS_DIR"
    err "Refusing to overwrite codex/skills snapshot with empty content."
    err "Use --allow-empty-skills only if this is intentional."
    exit 1
  fi
else
  for skill in "${skills_to_pack[@]}"; do
    if [[ ! -f "$SOURCE_SKILLS_DIR/$skill/SKILL.md" ]]; then
      err "Skill missing SKILL.md: $skill"
      exit 1
    fi
    rsync -a --delete "$SOURCE_SKILLS_DIR/$skill" "$TMP_DIR/custom/"
  done
  printf '%s\n' "${skills_to_pack[@]}" > "$DEST_CUSTOM_MANIFEST"
fi

# Keep artifact compact.
find "$TMP_DIR/custom" -type d -name '__pycache__' -prune -exec rm -rf {} +
find "$TMP_DIR/custom" -type d -name '.git' -prune -exec rm -rf {} +

if tar --help 2>/dev/null | grep -q -- '--sort'; then
  COPYFILE_DISABLE=1 tar --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 --numeric-owner -C "$TMP_DIR/custom" -czf "$TMP_DIR/custom-skills.tar.gz" .
else
  COPYFILE_DISABLE=1 tar -C "$TMP_DIR/custom" -czf "$TMP_DIR/custom-skills.tar.gz" .
fi
base64_encode_nolinewrap "$TMP_DIR/custom-skills.tar.gz" > "$DEST_CUSTOM_ARCHIVE_B64"
sha256_file "$TMP_DIR/custom-skills.tar.gz" > "$DEST_CUSTOM_ARCHIVE_SHA256"

if $EXPORT_FULL_HOME; then
  full_archive="$TMP_DIR/full-codex-home.tar.gz"
  if tar --help 2>/dev/null | grep -q -- '--sort'; then
    COPYFILE_DISABLE=1 tar --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 --numeric-owner -C "$SOURCE_CODEX_HOME" -czf "$full_archive" .
  else
    COPYFILE_DISABLE=1 tar -C "$SOURCE_CODEX_HOME" -czf "$full_archive" .
  fi

  base64_encode_nolinewrap "$full_archive" > "$DEST_FULL_HOME_ARCHIVE_B64"
  sha256_file "$full_archive" > "$DEST_FULL_HOME_ARCHIVE_SHA256"

  find "$SOURCE_CODEX_HOME" -mindepth 1 \
    | awk -v prefix="$SOURCE_CODEX_HOME/" '{ sub("^" prefix, "", $0); print $0 }' \
    | sort > "$DEST_FULL_HOME_MANIFEST"

  say "Updated full snapshot: $DEST_FULL_HOME_ARCHIVE_B64"
  say "Updated full snapshot checksum: $DEST_FULL_HOME_ARCHIVE_SHA256"
  say "Updated full snapshot manifest: $DEST_FULL_HOME_MANIFEST"
fi

say "Export complete"
say "Updated: $DEST_CONFIG_TEMPLATE"
say "Updated: $DEST_PROJECT_TRUST_SNAPSHOT"
say "Updated: $DEST_TOOLCHAIN_LOCK"
say "Updated: $DEST_CUSTOM_MANIFEST"
say "Updated: $DEST_CUSTOM_ARCHIVE_B64"
say "Updated: $DEST_CUSTOM_ARCHIVE_SHA256"
say "Packed skills: ${#skills_to_pack[@]}"
