# macOS Setup

## 1. Install Codex

```bash
scripts/os/macos/install/ensure-codex.sh
```

## 2. Optional: Install Claude Code

```bash
scripts/os/macos/install/ensure-claude-code.sh
```

## 3. Restore Codex mirror

```bash
export CONTEXT7_API_KEY='ctx7sk-...'
export GITHUB_MCP_TOKEN='gho_...'
scripts/bootstrap.sh --skip-curated
```

## 4. Validate

```bash
scripts/verify.sh
scripts/codex-activate.sh --check-only
```
