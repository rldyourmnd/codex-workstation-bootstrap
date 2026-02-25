---
name: code-reviewer
description: Perform rigorous code review for local changes, commits, and pull requests. Use when user asks for review, bug/risk detection, regression analysis, missing tests, or quality gates before merge.
---

# Code Reviewer (Codex)

## Review Priorities
1. Correctness and behavioral regressions.
2. Security and data-safety risks.
3. Reliability and edge-case handling.
4. Test coverage gaps and brittle tests.
5. Maintainability and clarity.

## Process
1. Inspect changed files and infer intent.
2. Validate assumptions against code paths, not comments.
3. Flag concrete findings with severity and file references.
4. Separate findings from style nits.
5. If no major findings, state residual risk and testing gaps explicitly.

## Reporting Format
- Findings first, ordered by severity.
- Each finding: what, why, impact, file path.
- Then open questions/assumptions.
- Then short summary.
