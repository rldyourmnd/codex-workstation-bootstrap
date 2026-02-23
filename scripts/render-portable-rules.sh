#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURATED_MANIFEST="$ROOT_DIR/codex/skills/curated-manifest.txt"
OUTPUT_FILE="${1:-}"

err() { echo "[ERROR] $*" >&2; }

if [[ ! -f "$CURATED_MANIFEST" ]]; then
  err "Missing curated manifest: $CURATED_MANIFEST"
  exit 1
fi

mapfile -t curated_paths < <(grep -Ev '^\s*#|^\s*$' "$CURATED_MANIFEST")
if [[ ${#curated_paths[@]} -eq 0 ]]; then
  err "Curated manifest is empty: $CURATED_MANIFEST"
  exit 1
fi

render_rules() {
  echo "prefix_rule(pattern=[\"python3\", \"__HOME__/.codex/skills/.system/skill-installer/scripts/list-skills.py\", \"--format\", \"json\"], decision=\"allow\")"
  printf "prefix_rule(pattern=[\"python3\", \"__HOME__/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py\", \"--repo\", \"openai/skills\", \"--path\""
  for p in "${curated_paths[@]}"; do
    printf ", \"%s\"" "$p"
  done
  echo "], decision=\"allow\")"
  echo "prefix_rule(pattern=[\"codex\", \"mcp\"], decision=\"allow\")"
  echo "prefix_rule(pattern=[\"set\", \"-e\"], decision=\"allow\")"
  echo "prefix_rule(pattern=[\"gh\"], decision=\"allow\", justification=\"Run GitHub CLI unsandboxed for reliable auth and repository access.\")"
}

if [[ -n "$OUTPUT_FILE" ]]; then
  mkdir -p "$(dirname "$OUTPUT_FILE")"
  render_rules > "$OUTPUT_FILE"
else
  render_rules
fi

