# better-codex

Portable Codex environment backup and bootstrap.

This repository is designed to replicate your Codex setup across PCs with minimal manual steps.

## Included

- `codex/config/config.template.toml`: sanitized Codex config template
- `codex/skills/custom-skills.tar.gz.b64`: archive of custom/adapted skills
- `codex/skills/custom-skills.sha256`: integrity hash for packed custom skills
- `codex/skills/curated-manifest.txt`: curated OpenAI skills list
- `scripts/install.sh`: install/sync config + skills on target machine
- `scripts/verify.sh`: verify required MCP + custom skills
- `scripts/codex-activate.sh`: MCP/skills health check
- `scripts/export-from-local.sh`: refresh this repo from local `~/.codex`
- `scripts/self-test.sh`: clean-room transfer smoke test
- `templates/AGENTS.md`: Codex-first AGENTS template

## Security

Secrets are not stored in git.

Provide at install time:

- `CONTEXT7_API_KEY`
- `GITHUB_MCP_TOKEN`

## Source machine workflow (this PC)

Update the portable package from current Codex state:

```bash
scripts/export-from-local.sh
```

Optional custom source path:

```bash
scripts/export-from-local.sh /path/to/.codex
```

Run transfer smoke test before push:

```bash
scripts/self-test.sh
```

## Target machine workflow

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

4. Install config and skills:

```bash
scripts/install.sh --force
```

5. Verify:

```bash
scripts/verify.sh
scripts/codex-activate.sh --check-only
```

## Notes

- `scripts/install.sh` does not modify `~/.codex/auth.json`.
- Curated skills are installed from `openai/skills` via local skill-installer if available.
- `scripts/install.sh` verifies packed custom skill integrity when `sha256sum` is available.
- If curated installer is unavailable, use:

```bash
scripts/install.sh --force --skip-curated
```
