# Codex Environment Runbook

This runbook is for operating this repository as a production-grade Codex environment mirror.

## 1. Source machine update flow

```bash
scripts/export-from-local.sh
scripts/check-toolchain.sh --strict-codex-only
scripts/audit-codex-agents.sh
scripts/self-test.sh
```

Expected result: all commands succeed.
Export now hard-fails on empty source `AGENTS.md` or empty non-system skills snapshot to prevent drift/corruption.

Absolute mirror variant:

```bash
scripts/export-from-local.sh --with-full-home
scripts/self-test.sh
```

## 2. Target machine restore flow (exact parity)

```bash
export CONTEXT7_API_KEY='ctx7sk-...'
export GITHUB_MCP_TOKEN="$(gh auth token)"
scripts/bootstrap.sh --skip-curated
```

Restore guarantees:
- installs repository baseline 9 agent skills (`skills/codex-agents`),
- installs full snapshot skill set from `codex/skills/custom-skills.*`.

Codex install by OS:

macOS:

```bash
brew install --cask codex
```

Linux:

```bash
npm i -g @openai/codex
```

Full-home restore (absolute mirror, same OS family):

```bash
scripts/bootstrap.sh --skip-curated --full-home
```

## 3. Target machine restore flow (portable-safe)

```bash
export CONTEXT7_API_KEY='ctx7sk-...'
export GITHUB_MCP_TOKEN="$(gh auth token)"
scripts/bootstrap.sh --skip-curated --portable-rules --skip-project-trust --no-sync-codex-version --no-strict-toolchain
```

## 4. Validation gates

Run all gates after restore:

```bash
scripts/check-toolchain.sh --strict-codex-only
scripts/verify.sh
scripts/audit-codex-agents.sh
scripts/codex-activate.sh --check-only
```

Full-home validation:

```bash
scripts/verify.sh --full-home
```

## 5. Rollback

Install script creates timestamped backups in `~/.codex`:

- `config.toml.bak.<timestamp>`
- `AGENTS.md.bak.<timestamp>`
- `rules/default.rules.bak.<timestamp>`

Rollback example:

```bash
cp ~/.codex/config.toml.bak.<timestamp> ~/.codex/config.toml
cp ~/.codex/AGENTS.md.bak.<timestamp> ~/.codex/AGENTS.md
cp ~/.codex/rules/default.rules.bak.<timestamp> ~/.codex/rules/default.rules
```

## 6. Drift management

- `scripts/render-portable-rules.sh` keeps portable rules synchronized with `codex/skills/curated-manifest.txt`.
- `scripts/check-toolchain.sh` detects toolchain drift against `codex/meta/toolchain.lock`.
- `scripts/sync-codex-version.sh --apply` pins Codex CLI to exported version.
