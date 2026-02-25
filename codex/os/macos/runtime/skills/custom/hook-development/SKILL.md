---
name: hook-development
description: Design and implement Codex guardrail hooks and policy checks using repository automation (scripts/CI/pre-commit) plus AGENTS.md rules. Use when user asks to prevent risky actions, enforce standards, or validate operations before/after changes.
---

# Hook Development (Codex)

Codex does not use Claude plugin hooks directly. Build equivalent guardrails with repository-native tooling.

## Preferred Mechanisms
1. `AGENTS.md` for behavioral policy.
2. Pre-commit/CI checks for enforcement.
3. Wrapper scripts or Make targets for safe workflows.

## Workflow
1. Define the exact unsafe behavior to catch.
2. Add deterministic checks (lint/static/security/tests) with clear failure output.
3. Keep checks fast and scoped.
4. Add bypass policy only if necessary and auditable.
5. Document remediation steps for each failure.
