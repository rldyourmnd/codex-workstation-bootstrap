# Portable Codex Setup (Direct Files)

This repository restores Codex state from direct files, not archives.

## Scope

- `codex/os/macos/runtime/config/config.template.toml`
- `codex/os/macos/runtime/agents/global.AGENTS.md`
- `codex/os/macos/runtime/rules/default.rules`
- `codex/os/macos/runtime/rules/default.rules.source.snapshot`
- `codex/os/macos/runtime/skills/custom/*`
- `codex/os/macos/runtime/skills/manifests/custom-skills.manifest.txt`
- `codex/os/common/agents/codex-agents/*`

## Restore on target machine

```bash
export CONTEXT7_API_KEY='ctx7sk-...'
export GITHUB_MCP_TOKEN='gho_...'
scripts/bootstrap.sh --skip-curated
```

## Deterministic install only

```bash
scripts/install.sh --force --skip-curated --clean-skills --rules-mode exact
```

## Optional curated refresh

```bash
scripts/install.sh --force --clean-skills --rules-mode exact
```

## Validate

```bash
scripts/check-toolchain.sh --strict-codex-only
scripts/verify.sh
scripts/audit-codex-agents.sh
scripts/codex-activate.sh --check-only
```

## Refresh repository from local machine

```bash
scripts/export-from-local.sh
```
