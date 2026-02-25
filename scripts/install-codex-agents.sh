#!/usr/bin/env bash
set -euo pipefail

# Installs shared Codex agent profiles into ~/.codex/skills.
# Usage:
#   scripts/install-codex-agents.sh
#   scripts/install-codex-agents.sh --dry-run

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/os/common/platform.sh"
source "$ROOT_DIR/scripts/os/common/layout.sh"

SRC_DIR="$(common_agent_skills_root)"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
DEST_DIR="$CODEX_HOME_DIR/skills"

say() { echo "[INFO] $*"; }
err() { echo "[ERROR] $*"; }

if [[ ! -d "$SRC_DIR" ]]; then
  err "Source skills directory not found: $SRC_DIR"
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  err "Missing required tool: rsync"
  exit 1
fi

agent_dirs=()
while IFS= read -r dir; do
  agent_dirs+=("$dir")
done < <(list_top_level_dirs "$SRC_DIR")

if [[ ${#agent_dirs[@]} -eq 0 ]]; then
  err "No agent skill directories found in $SRC_DIR"
  exit 1
fi

if $DRY_RUN; then
  say "Dry-run mode enabled"
fi

mkdir -p "$DEST_DIR"

for agent in "${agent_dirs[@]}"; do
  if [[ "$agent" == "README.md" ]]; then
    continue
  fi

  src_agent="$SRC_DIR/$agent"
  if [[ ! -f "$src_agent/SKILL.md" ]]; then
    err "Missing SKILL.md for $agent"
    exit 1
  fi

  if $DRY_RUN; then
    echo "[DRY-RUN] rsync -a '$src_agent/' '$DEST_DIR/$agent/'"
  else
    rsync -a "$src_agent/" "$DEST_DIR/$agent/"
    say "Installed agent skill: $agent"
  fi
done

if ! $DRY_RUN; then
  say "Agent-skill install complete."
  say "Run: scripts/codex-activate.sh --check-only"
fi
