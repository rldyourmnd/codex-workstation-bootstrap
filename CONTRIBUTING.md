# Contributing to better-codex

## Scope

This repository maintains a production-ready Codex baseline with strict OS-first hierarchy.

## Rules

- Keep payload structure under `codex/os/*` strict and deterministic.
- Never commit real credentials, tokens, cookies, or machine-local auth files.
- Preserve the split:
- `codex/os/common/agents/codex-agents` for shared agent profiles.
- `codex/os/macos/runtime/skills/custom` for custom skills only.
- No overlap between shared and custom skill names.
- Keep scripts idempotent and shell-safe (`set -euo pipefail`).

## Local workflow

```bash
scripts/check-toolchain.sh --strict-codex-only
scripts/audit-codex-agents.sh
scripts/self-test.sh
```

## Commit style

Use Conventional Commits, for example:

- `feat(scope): add capability`
- `fix(scope): resolve bug`
- `docs(scope): update docs`
- `refactor(scope): improve structure`

## Pull requests

- Keep PRs focused and atomic.
- Explain what changed and why.
- Include before/after behavior and risk notes.
- Reference linked issue(s) when relevant.
