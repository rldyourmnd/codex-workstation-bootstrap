---
name: serena-sync
description: Keep `.serena/memories` accurate and current by auditing code changes and synchronizing memory files with verified facts.
---

# Serena Sync (Codex)

Use this skill to maintain repository memory quality.

## Trigger

Use when the user asks to:
- create or update Serena memories,
- audit memory freshness,
- sync memories after refactors/features,
- validate metadata and scope correctness.

## Primary Workflow

1. Read existing memories and determine staleness from recent changes.
2. Investigate affected code with Serena tools.
3. Update/create memory files using fact-only language.
4. Ensure metadata header is present and current.
5. Report updated memory list and freshness status.

## Operating Rules

- Memory content must be factual, concise, and path-accurate.
- Do not introduce recommendations in memory files.
- Avoid source-code edits unless user separately requests coding.
- If uncertainty remains, mark it explicitly as unresolved.

## Output Contract

- `Freshness audit` summary
- `Updated memories` list
- `New memories` (if created)
- `Unresolved gaps` requiring follow-up
