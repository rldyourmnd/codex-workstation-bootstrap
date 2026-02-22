# Codex Agent Skills

This directory contains Codex-native agent implementations as skills.

Why skills:
- Codex supports reusable specialization via `SKILL.md` (+ optional `agents/openai.yaml`).
- There is no separate stable custom-agent runtime manifest equivalent to Claude's agent files.

Each folder here is installable to `~/.codex/skills/<name>/`.

Installed agents:
- better-explorer
- serena-sync
- version-patrol
- better-think
- better-plan
- better-code-review
- manual-tester
- better-debugger
- github-server-sync

Policy:
- No external `codex exec` / `gemini` orchestration loops.
- Prefer Codex MCP tools + skills + repository scripts.
