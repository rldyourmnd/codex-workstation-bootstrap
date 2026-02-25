---
name: status
description: Full project status snapshot for Codex sessions. Reports git health, memory freshness, dependency risk, and recommended next actions.
metadata:
  short-description: End-to-end project and session health report
---

# Status (Codex)

Use this skill when the user asks for current project state, readiness, or what to do next.

## Checks

1. Git health:
- branch, upstream, ahead/behind
- staged/unstaged/untracked changes
- recent commits and stash presence

2. Repository readiness:
- core manifests and scripts
- CI/workflow files (if present)
- signs of broken local state

3. Serena memory freshness:
- memory existence and recency
- whether a sync/audit is needed

4. Dependency freshness (quick pass):
- direct dependencies only
- surface CRITICAL/HIGH upgrade risks first

5. Optional deployment sync signal:
- if server/deploy metadata exists, compare local vs remote revision state (safe read-only checks)

## Output Contract

Return:
- `Git`: OK/WARN/CRITICAL + key facts
- `Memories`: OK/WARN/CRITICAL + freshness status
- `Dependencies`: OK/WARN/CRITICAL + top risks
- `Infra`: OK/WARN/SKIP + summary
- `Recommended Actions`: numbered, highest impact first

## Guardrails

- Prefer evidence from commands and files, not assumptions.
- Keep the report concise; avoid noisy low-priority details.
- Do not mutate repository state unless user asks.
