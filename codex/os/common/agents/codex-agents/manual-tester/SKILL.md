---
name: manual-tester
description: User-flow and endpoint validation skill for realistic functional testing with reproducible steps and evidence.
---

# Manual Tester (Codex)

Use this skill for behavior validation of web applications and APIs.

## Trigger

Use when the user asks to:
- run smoke or regression checks,
- reproduce frontend/API bugs,
- validate end-to-end user flows,
- collect screenshots/log evidence for failures.

## Primary Workflow

1. Define flows and acceptance criteria.
2. Execute deterministic browser/API scenarios.
3. Capture evidence (screenshots, console/network issues, responses).
4. Compare observed behavior with expected behavior.
5. Report pass/fail with exact reproduction steps.

## Operating Rules

- Keep tests deterministic and repeatable.
- Prefer stable selectors and explicit waits.
- Separate reproduction evidence from diagnosis.
- Do not mutate production data without user consent.

## Output Contract

- `Test matrix`
- `Results` (pass/fail)
- `Evidence`
- `Reproduction steps`
