# better-codex

Clean macOS-first Codex mirror with direct files only.

This repository stores your Codex baseline as plain files (no tar/base64 snapshots):

- `codex/config/config.template.toml` - sanitized config template with 6 MCP definitions
- `codex/agents/global.AGENTS.md` - global AGENTS policy snapshot
- `codex/rules/default.rules` - portable rules
- `codex/rules/default.rules.source.snapshot` - exact source rules snapshot
- `codex/skills/custom/*` - direct custom skill directories (33 skills)
- `skills/codex-agents/*` - 9 repository-owned agent skills

## MCP baseline (6)

- context7
- sequential-thinking
- github
- shadcn
- playwright
- serena

All secrets are placeholders in repo templates:

- `__CONTEXT7_API_KEY__`
- `__GITHUB_MCP_TOKEN__`

## Restore on macOS

```bash
export CONTEXT7_API_KEY='ctx7sk-...'
export GITHUB_MCP_TOKEN='gho_...'
scripts/bootstrap.sh --skip-curated
```

## Direct install (without bootstrap)

```bash
scripts/install.sh --force --skip-curated --clean-skills --rules-mode exact
scripts/verify.sh
scripts/codex-activate.sh --check-only
```

## Export from current local Codex

```bash
scripts/export-from-local.sh
```

This refreshes:

- config template (sanitized)
- AGENTS snapshot
- rules snapshots
- `codex/skills/custom/*` direct files
- `codex/skills/custom-skills.manifest.txt`
- `codex/meta/toolchain.lock`

## OS structure

- macOS: production path (`scripts/os/macos/install/*`)
- Linux: maintained installer path (`scripts/os/linux/install/*`)
- Windows: skeleton (`scripts/os/windows/install/*`)
