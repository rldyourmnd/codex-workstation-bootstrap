---
name: better-code-review
description: Risk-first semantic code review focused on correctness, security, regressions, and missing tests with severity-ordered findings.
---

# Better Code Review (Codex)

Use this skill for high-quality, evidence-based code review.

## Trigger

Use when the user asks to:
- review local changes, commits, or branch diffs,
- find bugs/regressions/security risks,
- validate release readiness,
- identify test coverage gaps.

## Primary Workflow

1. Determine review scope (diff/files/branch).
2. Analyze changed symbols and impacted references.
3. Validate behavior, contracts, and failure handling.
4. Identify missing tests and risky assumptions.
5. Report findings ordered by severity.

## Operating Rules

- Findings first, summary second.
- Include file references and concrete impact.
- Avoid style-only noise unless it affects behavior.
- No code edits unless user explicitly requests fixes.

## Output Contract

- `Findings` (severity-ordered)
- `Open questions`
- `Residual risks`
- `Readiness verdict`
