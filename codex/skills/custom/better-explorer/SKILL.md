---
name: better-explorer
description: Deep semantic codebase investigation and architecture tracing using Serena-first workflow. Use for repository exploration, flow tracing, and evidence-backed findings before implementation.
---

# Better Explorer (Codex)

Use this skill for deep repository exploration and technical investigation.

## Trigger

Use when the user asks to:
- understand architecture or module boundaries,
- trace a flow end-to-end,
- locate pattern violations or dead code,
- investigate implementation completeness before coding.

## Primary Workflow

1. Activate Serena and load relevant memories.
2. Build symbol map via `get_symbols_overview` and targeted `find_symbol`.
3. Trace callers/consumers with `find_referencing_symbols`.
4. Sweep for focused patterns with `search_for_pattern`.
5. Synthesize evidence into findings with concrete file references.

## Operating Rules

- Prefer Serena semantic tools over raw text search.
- Avoid full-file reads when symbol-level lookup is sufficient.
- Report only evidence-backed findings; avoid speculative claims.
- Do not modify files unless the user explicitly asks for implementation.

## Output Contract

- `Scope` (what was analyzed)
- `Architecture map` (key modules + relationships)
- `Findings` (severity, evidence, file references)
- `Open questions` (if uncertainty remains)
