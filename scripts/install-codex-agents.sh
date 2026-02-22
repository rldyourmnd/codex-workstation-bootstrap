#!/usr/bin/env bash
set -euo pipefail

# Installs local Codex agent-skills into ~/.codex/skills.
# Usage:
#   scripts/install-codex-agents.sh
#   scripts/install-codex-agents.sh --dry-run

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT_DIR/skills/codex-agents"
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

mapfile -t agent_dirs < <(find "$SRC_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
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
