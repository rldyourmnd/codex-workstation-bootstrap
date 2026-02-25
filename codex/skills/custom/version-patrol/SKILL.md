---
name: version-patrol
description: Audit dependency/runtime/tooling freshness against current stable releases and provide risk-ranked upgrade guidance.
---

# Version Patrol (Codex)

Use this skill for dependency and runtime freshness audits.

## Trigger

Use when the user asks to:
- check outdated dependencies or runtimes,
- plan upgrade waves,
- identify breaking migration risks,
- validate compatibility after major upgrades.

## Primary Workflow

1. Inventory manifests, lockfiles, runtime/tooling versions.
2. Validate latest stable versions via web + Context7.
3. Classify gaps by severity (EOL, major, minor, patch).
4. For major upgrades, collect migration notes and breaking changes.
5. Produce prioritized upgrade plan with explicit risk.

## Operating Rules

- Do not guess versions; verify with dated sources.
- Distinguish verified vs inferred claims.
- Keep actions practical and sequenced.
- No dependency modifications unless user asks to execute upgrades.

## Output Contract

- `Inventory`
- `Findings by severity`
- `Migration notes` for major jumps
- `Prioritized upgrade plan`
