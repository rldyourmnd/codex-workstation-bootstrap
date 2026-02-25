---
name: codex-md-improver
description: Audit and optimize AGENTS.md for Codex projects, with optional cross-check against CLAUDE.md if present. Use when user asks to improve agent instructions, remove stale guidance, align workflow docs with real tooling, or harden operational guardrails.
---

# Codex MD Improver

Prioritize `AGENTS.md` as the source of truth for Codex behavior.
Treat `CLAUDE.md` as optional context only.
Do not import Claude Code plugin workflows into Codex instructions.

## Workflow
1. Discover instruction files: `AGENTS.md`, optional `CLAUDE.md`, related workflow docs.
2. Build a contradiction map: conflicting rules, duplicate guidance, stale commands.
3. Normalize around Codex execution model:
- shell-driven automation
- repository checks (lint/test/CI)
- explicit approval and safety boundaries
4. Rewrite `AGENTS.md` to be concise, testable, and command-oriented.
5. Preserve useful knowledge from `CLAUDE.md` only when tool-agnostic.
6. Output a change summary with risks and follow-up actions.

## Acceptance Criteria
- `AGENTS.md` has clear priorities and no conflicting rules.
- Commands/paths are current and executable.
- Safety-critical actions have explicit guardrails.
- No Claude-only runtime assumptions.
