# better-codex

Clean OS-structured Codex mirror with macOS production payload.

This repository stores Codex baseline as plain files (no tar/base64 snapshots).

## Canonical layout

- `codex/os/macos/runtime/config/*` - config template + project trust snapshot
- `codex/os/macos/runtime/agents/global.AGENTS.md` - global AGENTS snapshot
- `codex/os/macos/runtime/rules/*` - portable + exact rules snapshots
- `codex/os/macos/runtime/skills/custom/*` - direct custom skills
- `codex/os/macos/runtime/skills/manifests/*` - skill manifests
- `codex/os/macos/runtime/meta/toolchain.lock` - toolchain lock
- `codex/os/common/agents/codex-agents/*` - shared codex-agent profiles

Linux/Windows payload folders are kept as placeholders for clean expansion.

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
- `codex/os/macos/runtime/skills/custom/*`
- `codex/os/macos/runtime/skills/manifests/custom-skills.manifest.txt`
- `codex/os/macos/runtime/meta/toolchain.lock`
- matching shared profiles in `codex/os/common/agents/codex-agents/*`

## OS structure

- macOS scripts: `scripts/os/macos/install/*`
- Linux scripts: `scripts/os/linux/install/*`
- Windows scripts: `scripts/os/windows/install/*`
- Runtime payload selector: `scripts/os/common/layout.sh` (`BETTER_CODEX_PROFILE_OS=<os>`)
