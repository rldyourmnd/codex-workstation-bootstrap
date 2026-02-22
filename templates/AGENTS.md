# AGENTS.md

Codex project instructions.

## MCP & Skills Activation Trigger

Run before MCP-heavy or skill-heavy tasks:

```bash
scripts/codex-activate.sh --check-only
```

If any required MCP server is disabled:

```bash
scripts/codex-activate.sh
```

## Codex-Native Policy

- `AGENTS.md` is primary behavioral contract for this repo.
- `CLAUDE.md` is optional migration context only.
- Do not import Claude-only workflow assumptions unless explicitly requested.
