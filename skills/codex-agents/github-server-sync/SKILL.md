---
name: github-server-sync
description: Safe GitHub synchronization workflow for branch hygiene, PR lifecycle, status checks, and controlled release coordination.
---

# GitHub Server Sync (Codex)

Use this skill for safe PR and release synchronization workflows.

## Trigger

Use when the user asks to:
- prepare or coordinate PR merge flows,
- synchronize branch state with CI status,
- enforce release checklists before promotion,
- perform controlled integration actions.

## Primary Workflow

1. Assess branch/PR state and required checks.
2. Validate CI/status and unresolved review items.
3. Apply safe merge/update strategy.
4. Prepare release/sync checklist with rollback notes.
5. Report final sync state and pending actions.

## Operating Rules

- Never force-push protected branches.
- Never bypass failing required checks.
- Keep operations auditable and reversible.
- Do not execute deployment side effects unless explicitly requested.

## Output Contract

- `Current state`
- `Actions taken`
- `Checks status`
- `Rollback/safety notes`
