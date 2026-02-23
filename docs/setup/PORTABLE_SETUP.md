# Portable Codex Setup (Full Mirror)

This document describes how to reproduce the same Codex environment on another machine from this repository.

## Scope

The snapshot intentionally includes only reproducible settings:

- Global Codex config (`config.toml` template)
- Global AGENTS policy (`~/.codex/AGENTS.md`)
- Global rules (`~/.codex/rules/default.rules`)
- All non-system installed skills (`~/.codex/skills/*`, excluding `.system`)

The snapshot intentionally excludes runtime/session files such as auth/session/history/log files.
Export also redacts secret-like values in `config.toml` and keeps only a portable baseline in `default.rules`.

## Export from source machine

```bash
scripts/export-from-local.sh
scripts/self-test.sh
```

Optional custom source path:

```bash
scripts/export-from-local.sh /path/to/.codex
```

## Restore on target machine

Set required environment variables:

```bash
export CONTEXT7_API_KEY='ctx7sk-...'
export GITHUB_MCP_TOKEN="$(gh auth token)"
```

Run one-command restore:

```bash
scripts/bootstrap.sh --skip-curated
```

## Deterministic vs latest restore

- Deterministic restore: `scripts/bootstrap.sh --skip-curated`
- Snapshot + curated refresh: `scripts/bootstrap.sh`

## Validation

```bash
scripts/verify.sh
scripts/audit-codex-agents.sh
scripts/codex-activate.sh --check-only
```

## Troubleshooting

- If `verify.sh` reports missing MCP auth, check env vars and `~/.codex/config.toml`.
- If `codex mcp list` is unavailable, install/upgrade Codex CLI first.
- If curated install fails, rerun with `--skip-curated`.
