---
name: command-development
description: Create robust repository commands for Codex-driven workflows (Makefile, npm scripts, shell scripts, task runners). Use when user asks to standardize repetitive operations, reduce manual steps, or add reliable automation entrypoints.
---

# Command Development (Codex)

## Design Rules
1. Commands must be deterministic and idempotent when possible.
2. Prefer explicit arguments over hidden behavior.
3. Fail fast with actionable error messages.
4. Keep commands composable and CI-friendly.

## Workflow
1. Define input/output contract.
2. Implement smallest useful command.
3. Add dry-run mode for destructive flows.
4. Add docs and examples in README.
5. Validate on clean workspace and typical dev state.
