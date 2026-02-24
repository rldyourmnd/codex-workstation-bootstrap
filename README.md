# better-codex

Production-ready, portable Codex environment mirror.

This repository captures your local Codex setup and restores it on another machine in a few commands.

## What is mirrored

- `codex/config/config.template.toml`: sanitized global Codex config template
- `codex/agents/global.AGENTS.md`: global `~/.codex/AGENTS.md` snapshot
- `codex/rules/default.rules`: global rules snapshot (home path tokenized as `__HOME__`)
- `codex/skills/custom-skills.tar.gz.b64`: packed non-system skills snapshot
- `codex/skills/custom-skills.sha256`: integrity checksum for packed skills
- `codex/skills/custom-skills.manifest.txt`: exact skill list from snapshot
- `codex/skills/curated-manifest.txt`: optional curated skill refresh list
- `codex/os/<os>/full-codex-home.tar.gz.b64`: optional full `~/.codex` snapshot per OS
- `codex/os/<os>/full-codex-home.sha256`: checksum for full snapshot
- `codex/os/<os>/full-codex-home.manifest.txt`: manifest for full snapshot
- `codex/meta/toolchain.lock`: exported versions (`codex/node/npm/python/uv/gh`)
- `codex/config/projects.trust.snapshot.toml`: optional exported `[projects.*]` trust entries
- `codex/rules/default.rules.source.snapshot`: exported source-machine rules snapshot
- `scripts/export-from-local.sh`: refresh repo from current local `~/.codex`
- `scripts/install.sh`: install config + AGENTS + rules + skills to target machine
- `scripts/check-toolchain.sh`: parity check against `codex/meta/toolchain.lock`
- `scripts/sync-codex-version.sh`: pin Codex CLI to exported version
- `scripts/render-portable-rules.sh`: generate portable rules from curated manifest
- `scripts/verify.sh`: validate MCP state and installed skill set
- `scripts/codex-activate.sh`: health check for MCP/skills
- `scripts/audit-codex-agents.sh`: validate codex-agent profile consistency
- `scripts/bootstrap.sh`: one-command install + verify + activation check
- `scripts/self-test.sh`: clean-room smoke test of the transfer flow
- `scripts/os/common/platform.sh`: shared cross-platform shell helpers
- `scripts/os/macos/ensure-codex.sh`: macOS bootstrap (`brew install --cask codex`)
- `scripts/os/linux/ensure-codex.sh`: Linux bootstrap (`npm i -g @openai/codex`)

## Security

Secrets are not committed to git in default export mode.
Export redacts generic secret-like config keys (`*KEY*`, `*TOKEN*`, `*SECRET*`, `*PASSWORD*`), while preserving install placeholders for Context7 and GitHub MCP.

Provide at install time:

- `CONTEXT7_API_KEY`
- `GITHUB_MCP_TOKEN`

If you use `--with-full-home`, the snapshot includes runtime/session data and secret values from `~/.codex`.

## Source machine: refresh snapshot

```bash
scripts/export-from-local.sh
scripts/self-test.sh
```

Optional source path:

```bash
scripts/export-from-local.sh /path/to/.codex
```

Absolute mirror (includes full `~/.codex`):

```bash
scripts/export-from-local.sh --with-full-home
```

## Target machine: restore full state

1. Install Codex CLI:

macOS:

```bash
brew install --cask codex
```

Linux:

```bash
npm i -g @openai/codex
```

2. Clone this repo.

3. Export secrets:

```bash
export CONTEXT7_API_KEY='ctx7sk-...'
export GITHUB_MCP_TOKEN="$(gh auth token)"
```

4. Run full bootstrap:

```bash
scripts/bootstrap.sh --skip-curated
```

`--skip-curated` keeps restore deterministic from the committed snapshot.

If you want an additional curated refresh from `openai/skills`, run without `--skip-curated`.
Operational runbook: `docs/setup/PROD_RUNBOOK.md`.

Absolute mirror restore (full `~/.codex` snapshot, same OS family):

```bash
scripts/bootstrap.sh --skip-curated --full-home
```

## Parity modes

- Exact parity mode (default):
  - uses source-machine rules snapshot when available,
  - applies exported project trust entries when available,
  - syncs Codex CLI version to `codex/meta/toolchain.lock`,
  - enforces toolchain parity checks.

- Portable-safe mode:

```bash
scripts/bootstrap.sh --skip-curated --portable-rules --skip-project-trust --no-sync-codex-version --no-strict-toolchain
```

## Quick commands

- Dry-run install:

```bash
scripts/install.sh --dry-run --force --skip-curated --clean-skills --rules-mode exact
```

- Verify current setup:

```bash
scripts/check-toolchain.sh --strict-codex-only
scripts/verify.sh
scripts/audit-codex-agents.sh
scripts/codex-activate.sh --check-only
```

- Verify full-home restore:

```bash
scripts/verify.sh --full-home
```

- Pin Codex version from lock:

```bash
scripts/sync-codex-version.sh --apply
```
