# Codex Environment Runbook (macOS-first)

## Source machine update

```bash
scripts/export-from-local.sh
scripts/check-toolchain.sh --strict-codex-only
scripts/audit-codex-agents.sh
```

## Target machine restore (exact mirror)

```bash
export CONTEXT7_API_KEY='ctx7sk-...'
export GITHUB_MCP_TOKEN='gho_...'
scripts/bootstrap.sh --skip-curated
```

## Validation gates

```bash
scripts/check-toolchain.sh --strict-codex-only
scripts/verify.sh
scripts/audit-codex-agents.sh
scripts/codex-activate.sh --check-only
```

## Parity model

- 6 MCP in config template
- direct custom skills (`codex/os/macos/runtime/skills/custom/*`)
- codex-agent skills (`codex/os/common/agents/codex-agents/*`)
- global AGENTS snapshot from source machine

## Rollback

Install creates backups in `~/.codex` for overwritten files:

- `config.toml.bak.<timestamp>`
- `AGENTS.md.bak.<timestamp>`
- `rules/default.rules.bak.<timestamp>`
