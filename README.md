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
- `scripts/export-from-local.sh`: refresh repo from current local `~/.codex`
- `scripts/install.sh`: install config + AGENTS + rules + skills to target machine
- `scripts/verify.sh`: validate MCP state and installed skill set
- `scripts/codex-activate.sh`: health check for MCP/skills
- `scripts/audit-codex-agents.sh`: validate codex-agent profile consistency
- `scripts/bootstrap.sh`: one-command install + verify + activation check
- `scripts/self-test.sh`: clean-room smoke test of the transfer flow

## Security

Secrets are not committed to git.

Provide at install time:

- `CONTEXT7_API_KEY`
- `GITHUB_MCP_TOKEN`

## Source machine: refresh snapshot

```bash
scripts/export-from-local.sh
scripts/self-test.sh
```

Optional source path:

```bash
scripts/export-from-local.sh /path/to/.codex
```

## Target machine: restore full state

1. Install Codex CLI:

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

## Quick commands

- Dry-run install:

```bash
scripts/install.sh --dry-run --force --skip-curated --clean-skills
```

- Verify current setup:

```bash
scripts/verify.sh
scripts/codex-activate.sh --check-only
scripts/audit-codex-agents.sh
```
