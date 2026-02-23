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

## 2. Target machine restore flow (exact parity)

```bash
export CONTEXT7_API_KEY='ctx7sk-...'
export GITHUB_MCP_TOKEN="$(gh auth token)"
scripts/bootstrap.sh --skip-curated
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

