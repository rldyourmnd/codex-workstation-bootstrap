---
name: webapp-testing
description: Test local web applications through realistic browser flows. Use when user asks to validate UI behavior, reproduce frontend bugs, run end-to-end checks, collect screenshots, or verify regressions.
---

# Web App Testing (Codex)

Use this skill for browser-level validation.

## Workflow
1. Identify target URLs, auth needs, and critical user flows.
2. Build a minimal test matrix: smoke path, edge case, failure path.
3. Run browser automation and collect evidence (screenshots, console errors, failed assertions).
4. Reproduce flaky behavior with deterministic steps.
5. Report outcomes with exact repro steps.

## Good Practice
- Prefer stable selectors and deterministic waits.
- Keep tests small and composable.
- Avoid hiding failures behind retries unless justified.
