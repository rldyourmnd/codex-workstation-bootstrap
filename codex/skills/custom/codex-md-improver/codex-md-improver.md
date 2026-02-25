# codex-md-improver

## Goal
Keep repository instruction memory accurate for Codex by optimizing `AGENTS.md` first.

## Inputs
- Primary: `AGENTS.md`
- Optional: `CLAUDE.md`
- Supporting: `CONTRIBUTING.md`, `README.md`, runbooks, CI config

## Operating Rules
1. Prefer Codex-native workflows over product-specific plugin patterns.
2. Keep guidance minimal, actionable, and verifiable.
3. Remove stale commands and dead references.
4. Preserve only cross-tool knowledge from legacy files.

## Update Checklist
- Commands validated against project scripts/tooling
- File paths and env vars verified
- Risky operations explicitly guarded
- Review/QA expectations documented
- Duplicates and contradictions removed
