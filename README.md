# better-codex

[![Release](https://img.shields.io/github/v/release/rldyourmnd/better-codex?sort=semver)](https://github.com/rldyourmnd/better-codex/releases)
[![CI](https://github.com/rldyourmnd/better-codex/actions/workflows/ci.yml/badge.svg)](https://github.com/rldyourmnd/better-codex/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Stars](https://img.shields.io/github/stars/rldyourmnd/better-codex)](https://github.com/rldyourmnd/better-codex/stargazers)
[![Forks](https://img.shields.io/github/forks/rldyourmnd/better-codex)](https://github.com/rldyourmnd/better-codex/network/members)
[![Issues](https://img.shields.io/github/issues/rldyourmnd/better-codex)](https://github.com/rldyourmnd/better-codex/issues)

Production-ready Codex bootstrap and mirror for macOS with strict OS hierarchy, deterministic installs, and clean export/import flows.

## Why this repository

- Enterprise-grade baseline for fast workstation bootstrap.
- Strict separation of runtime payload by OS.
- Secret-safe templates with placeholders only.
- Reproducible install, verify, and export pipelines.
- Optimized structure for humans and GenAI retrieval systems.

## Core baseline

- MCP servers: `context7`, `sequential-thinking`, `github`, `shadcn`, `playwright`, `serena`
- Skills: `24` custom + `9` shared agent profiles (`33` total non-system)
- Global policy snapshot: `codex/os/macos/runtime/agents/global.AGENTS.md`
- Config defaults: `approval_policy = "never"`, `sandbox_mode = "danger-full-access"`

All sensitive values remain placeholders:

- `__CONTEXT7_API_KEY__`
- `__GITHUB_MCP_TOKEN__`

## Repository hierarchy

```text
codex/
  os/
    common/
      agents/codex-agents/            # 9 shared profiles
    macos/
      runtime/
        config/                        # config.template + trust snapshot
        agents/                        # global.AGENTS.md
        rules/                         # portable/exact rules
        skills/
          custom/                      # 24 custom skills
          manifests/                   # canonical skill manifests
        meta/                          # toolchain lock
    linux/runtime/.gitkeep
    windows/runtime/.gitkeep
scripts/
  install.sh
  verify.sh
  export-from-local.sh
  bootstrap.sh
```

## Quick start (macOS)

```bash
export CONTEXT7_API_KEY='ctx7sk-...'
export GITHUB_MCP_TOKEN='gho_...'
scripts/bootstrap.sh --skip-curated
```

## Deterministic install

```bash
scripts/install.sh --force --skip-curated --clean-skills --rules-mode exact
scripts/verify.sh
scripts/codex-activate.sh --check-only
```

## Export local Codex into repository

```bash
scripts/export-from-local.sh
```

## Validation gates

- `scripts/check-toolchain.sh --strict-codex-only`
- `scripts/audit-codex-agents.sh`
- `scripts/self-test.sh`

## OSS and security

- [Contributing](./CONTRIBUTING.md)
- [Security policy](./SECURITY.md)
- [Code of Conduct](./CODE_OF_CONDUCT.md)
- [Support](./SUPPORT.md)
- [Changelog](./CHANGELOG.md)

## GenAI indexing

- [`llms.txt`](./llms.txt) for concise machine-readable discovery.
- [`llms-full.txt`](./llms-full.txt) for expanded technical retrieval context.
