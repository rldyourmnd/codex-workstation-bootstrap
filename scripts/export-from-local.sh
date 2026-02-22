#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_CODEX_HOME="${1:-${CODEX_HOME:-$HOME/.codex}}"
SOURCE_CONFIG="$SOURCE_CODEX_HOME/config.toml"
DEST_CONFIG_TEMPLATE="$ROOT_DIR/codex/config/config.template.toml"
DEST_CUSTOM_ARCHIVE_B64="$ROOT_DIR/codex/skills/custom-skills.tar.gz.b64"
DEST_CUSTOM_ARCHIVE_SHA256="$ROOT_DIR/codex/skills/custom-skills.sha256"
TMP_DIR="$(mktemp -d)"

CUSTOM_SKILLS=(
  "agent-development"
  "better-code-review"
  "better-debugger"
  "better-explorer"
  "better-plan"
  "better-think"
  "code-reviewer"
  "codex-md-improver"
  "command-development"
  "frontend-design"
  "github-server-sync"
  "hook-development"
  "init-project"
  "create-project"
  "manual-tester"
  "search-strategy"
  "serena-sync"
  "sql-queries"
  "status"
  "version-patrol"
  "webapp-testing"
  "writing-rules"
  "pptx"
)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

say() { echo "[INFO] $*"; }
err() { echo "[ERROR] $*"; }

if [[ ! -f "$SOURCE_CONFIG" ]]; then
  err "Missing source config: $SOURCE_CONFIG"
  exit 1
fi

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

mkdir -p "$TMP_DIR/custom"
for skill in "${CUSTOM_SKILLS[@]}"; do
  if [[ ! -d "$SOURCE_CODEX_HOME/skills/$skill" ]]; then
    err "Missing skill in source: $skill"
    exit 1
  fi
  rsync -a --delete "$SOURCE_CODEX_HOME/skills/$skill" "$TMP_DIR/custom/"
done

# Keep artifact compact.
find "$TMP_DIR/custom" -type d -name '__pycache__' -prune -exec rm -rf {} +

tar -C "$TMP_DIR/custom" -czf "$TMP_DIR/custom-skills.tar.gz" .
base64 -w 0 "$TMP_DIR/custom-skills.tar.gz" > "$DEST_CUSTOM_ARCHIVE_B64"
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$TMP_DIR/custom-skills.tar.gz" | awk '{print $1}' > "$DEST_CUSTOM_ARCHIVE_SHA256"
fi

say "Export complete"
say "Updated: $DEST_CONFIG_TEMPLATE"
say "Updated: $DEST_CUSTOM_ARCHIVE_B64"
if [[ -f "$DEST_CUSTOM_ARCHIVE_SHA256" ]]; then
  say "Updated: $DEST_CUSTOM_ARCHIVE_SHA256"
fi
