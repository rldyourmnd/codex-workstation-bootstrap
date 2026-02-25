---
name: better-plan
description: Tactical implementation planner that produces stepwise, testable execution plans with dependencies, rollback notes, and acceptance criteria.
---

# Better Plan (Codex)

Use this skill to generate execution-ready implementation plans.

## Trigger

Use when the user asks to:
- plan feature implementation,
- plan refactors or migrations,
- sequence multi-step engineering work,
- define testing/rollout strategy before coding.

## Primary Workflow

1. Identify exact scope and touched modules.
2. Map dependencies and ordering constraints.
3. Define concrete steps with file-level intent.
4. Attach validation strategy per step.
5. Add rollback and risk mitigation notes.

## Operating Rules

- Every step must be verifiable.
- Avoid vague tasks; specify artifacts and checks.
- Highlight blockers early.
- No implementation edits unless user asks to execute plan.

## Output Contract

- `Scope`
- `Step-by-step plan`
- `Validation plan`
- `Rollback plan`
- `Risks and blockers`
