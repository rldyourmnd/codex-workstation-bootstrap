# AGENTS.md - Global Development Rules (Codex)

This root AGENTS.md governs the entire repository tree unless a deeper AGENTS.md overrides parts of it.

## 0. Instruction Precedence and Scope

1. Direct system/developer/user instructions override AGENTS.md.
2. More deeply nested AGENTS.md files override this file for their subtree.
3. This file is the primary Codex behavior contract for this repository.
4. `~/.claude/CLAUDE.md` is a high-value context source for quality standards and tool discipline; use it as a strong reference unless it conflicts with higher-priority instructions.

## 1. Core Principles - Apply to Every Request

1. Think step by step, deeply, and with explicit reasoning.
2. Optimize for correctness, consistency, and maintainability over speed.
3. Use clean architecture and reversible changes; avoid hacks and temporary shortcuts.
4. Keep outputs operational: concrete actions, verifiable checks, and clear tradeoffs.
5. Maintain high signal: concise where possible, detailed where needed.

## 2. Project Context Snapshot

- Project: portable Codex environment backup/bootstrap (`better-codex`).
- Platform: Linux (primary), cross-machine replication target.
- Primary goal: keep Codex config, MCP setup, skills, and agent workflows synchronized across PCs.
- Architecture anchor: `README.md`, `codex/config/*`, `codex/skills/*`, `scripts/*`, `skills/codex-agents/*`.

## 3. Key Paths (Source of Truth)

- `scripts/`: install/export/verify/bootstrap entrypoints.
- `codex/config/`: portable Codex config template.
- `codex/skills/`: custom skills bundle + curated manifest.
- `skills/codex-agents/`: source-tracked custom agent skills.
- `docs/agents/`: operational profiles for custom agents.
- `.serena/memories/`: project memories.
- `~/.claude/CLAUDE.md`: global engineering baseline and quality reference.

## 4. Session Startup - Mandatory

Run at session start for MCP-heavy, skills-heavy, or environment-sensitive tasks:

```bash
scripts/codex-activate.sh --check-only
```

If required MCP entries are disabled:

```bash
scripts/codex-activate.sh
```

For complex planning tasks, use sequential reasoning before implementation.

### 4.1 Execution Mode Baseline (Fixed For This Repo)

Default operating mode is full-auto for trusted local workflows:

- `approval_policy = "never"`
- `sandbox_mode = "danger-full-access"`

Equivalent launch:

```bash
codex --ask-for-approval never --sandbox danger-full-access
```

Use stricter sandbox/approval only when explicitly requested for a task.

## 5. MCP Tools - Operational Policy

### 5.1 Required MCP Servers

- `context7`
- `github`
- `sequential-thinking`
- `shadcn`
- `serena`
- `playwright`

### 5.2 Tool Priority Matrix

| Task | Primary | Fallback | Policy |
|---|---|---|---|
| Symbol discovery | Serena (`find_symbol`) | `rg` | Prefer semantic search first |
| Symbol references | Serena (`find_referencing_symbols`) | `rg` | Prove usage before refactor/delete |
| Code editing | Serena symbolic ops | `apply_patch` | Keep edits structurally coherent |
| External docs/APIs | Context7 | Web search | Query before unfamiliar API usage |
| Planning | Sequential Thinking | Manual plan | Use for high-impact decisions |
| Browser/UI validation | Playwright MCP | scripted checks | Collect evidence (screenshots/errors) |
| GitHub metadata/actions | GitHub MCP | `gh` CLI | Prefer MCP first; when using `gh`, run unsandboxed because sandboxed mode can break auth/network/repo access |

### 5.3 Context7 Rule

Query Context7 before introducing or changing usage of:

- new dependencies,
- unfamiliar APIs,
- version-sensitive behavior,
- potentially breaking options.

### 5.4 Web Search and Documentation Policy

1. For technical APIs/libraries, use Context7 first.
2. Web search is allowed only for trusted, current sources:
   - official vendor docs,
   - official GitHub repositories/releases/changelogs,
   - standards bodies and primary specifications,
   - authoritative package registries.
3. Always prefer the most recent stable documentation and include concrete dates when freshness matters.
4. Avoid random blogs/SEO mirrors unless there is no primary source.

## 6. Serena Workflow (Codex)

### 6.1 Investigation Flow

1. `activate_project`
2. `list_memories`
3. `read_memory` (relevant only)
4. `get_symbols_overview`
5. `find_symbol` (`include_body=false` first)
6. `find_symbol` (`include_body=true` only for needed symbols)
7. `find_referencing_symbols`
8. `search_for_pattern` (targeted)

### 6.2 Editing Flow

1. `find_symbol` (`include_body=true`) on target.
2. `replace_symbol_body` for full-symbol updates.
3. `insert_before_symbol` / `insert_after_symbol` for additive changes.
4. `rename_symbol` for semantic renames.
5. Use `apply_patch` for non-symbolic or multi-file text-level updates.

### 6.3 Efficiency Rules

1. Do not read full files when symbolic overview is sufficient.
2. Expand scope only when evidence requires it.
3. Validate dead-code assumptions via references, not intuition.
4. Parallelize independent lookups whenever safe.

## 7. Skills Routing (Codex)

Use matching installed skills when intent is clear or user names them explicitly.

| Task Type | Skill |
|---|---|
| AGENTS/policy optimization | `codex-md-improver`, `writing-rules` |
| Existing repo onboarding | `init-project` |
| New project bootstrap | `create-project` |
| Session/project health snapshot | `status` |
| Code review/risk detection | `code-reviewer` |
| Command automation | `command-development` |
| Guardrails/checks/policies | `hook-development` |
| UI/UX and frontend polish | `frontend-design` |
| Browser test flows | `webapp-testing`, `playwright` |
| SQL authoring/optimization | `sql-queries` |
| Multi-source investigation | `search-strategy` |
| Deep exploration agent | `better-explorer` |
| Tactical planner agent | `better-plan` |
| Deep reasoning agent | `better-think` |
| Semantic review agent | `better-code-review` |
| Debugging agent | `better-debugger` |
| Manual QA agent | `manual-tester` |
| Memory synchronization agent | `serena-sync` |
| Version audit agent | `version-patrol` |
| GitHub sync agent | `github-server-sync` |
| Cloudflare deployment | `cloudflare-deploy` |
| Security-oriented analyses | `security-best-practices`, `security-ownership-map`, `security-threat-model` |
| Data/office artifacts | `spreadsheet`, `pptx`, `pdf` |
| GH comments and PR flow | `gh-address-comments`, `yeet` |

## 8. Custom Agents (Codex-Native Profiles)

These agents are active as Codex skills and are ready for routing.
Source definitions live under `skills/codex-agents/*` and operational profiles under `docs/agents/*`.

### 8.1 Global Agent Constraints

1. No external CLI orchestration as a required dependency for agent behavior.
2. No mandatory `exec` wrappers for agent logic.
3. Prefer MCP tools + skills + repository scripts.
4. Each agent must produce auditable outputs (artifacts, checklists, logs, or diffs).

### 8.2 Agent Registry (Active)

- `better-explorer` -> deep codebase investigation
- `serena-sync` -> memory management and freshness
- `version-patrol` -> dependency/version freshness checks
- `better-think` -> deep multi-pass reasoning
- `better-plan` -> tactical implementation planning
- `better-code-review` -> semantic risk-focused review
- `manual-tester` -> live API and workflow validation
- `better-debugger` -> production/root-cause debugging
- `github-server-sync` -> safe GitHub + deployment sync flow

Detailed profiles live in `docs/agents/`.
Install/sync command:

```bash
scripts/install-codex-agents.sh
```

## 9. Serena Memories Policy

### 9.1 Locations

- `.serena/memories/`: project memories and architecture facts.
- `.serena/reasoning/`: deep reasoning artifacts (create when needed).
- `.serena/plans/`: tactical plans (create when needed).

### 9.2 Naming Convention

`[AREA]_[NN]_[name].md`

Areas:

- `CORE`, `BACKEND`, `FRONTEND`, `MOBILE`, `INFRA`, `API`, `AUTH`, `DATA`

### 9.3 Required Metadata Header

```html
<!-- Memory Metadata
Last updated: YYYY-MM-DD
Last commit: <short-hash> <commit-message>
Scope: <files/directories this memory covers>
Area: <AREA tag>
-->
```

### 9.4 Update Triggers

- Merge to `main`
- New feature
- Architecture change
- New reusable pattern
- Before delivery when facts changed

## 10. Git Workflow

### 10.1 Branch Strategy

- `main`: production-ready
- `dev`: integration
- `feature/*`: feature work -> `dev`
- `bugfix/*`: fixes -> `dev`
- `hotfix/*`: critical fixes -> `main` and back-merge

### 10.2 Commit Policy

Use Conventional Commits:

```text
type(scope): description
```

Types:

- `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `style`

Rules:

1. English only.
2. Atomic logical change per commit.
3. No secrets, no generated noise unless intentional.
4. Self-review before commit/push.

### 10.3 Never / Always

Never:

- force-push protected branches,
- skip validation knowingly,
- commit secrets,
- commit broken builds.

Always:

- pull/rebase consciously,
- run relevant checks before commit,
- keep diffs focused and reversible,
- document non-obvious decisions.

## 11. Code Standards

### 11.1 Shell Scripts

1. Start with `#!/usr/bin/env bash` and `set -euo pipefail`.
2. Keep operations idempotent.
3. Fail with actionable messages.

### 11.2 Comments and Error Handling

1. Explain why, not what.
2. Use explicit, meaningful errors.
3. Do not silently swallow failures.

### 11.3 Security Baseline

1. Validate inputs.
2. Avoid credential leakage in logs/output.
3. Use parameterized queries where applicable.
4. Avoid hardcoded secrets/config values.

### 11.4 Testing Baseline

1. Test real behavior where practical.
2. Cover edge cases and failure paths.
3. Keep assertions specific and useful.

### 11.5 Language Rules Reference

Host-level language rules are available at:

- `~/.claude/rules/typescript.md`
- `~/.claude/rules/javascript.md`
- `~/.claude/rules/python.md`
- `~/.claude/rules/rust.md`
- `~/.claude/rules/cpp.md`
- `~/.claude/rules/c.md`
- `~/.claude/rules/dart.md`
- `~/.claude/rules/php.md`
- `~/.claude/rules/css.md`
- `~/.claude/rules/shell.md`
- `~/.claude/rules/docker.md`

Use them as style references when relevant to touched files.

## 12. Quality Gates (Before Final Delivery)

1. Relevant lint/type/test checks pass or explicitly explain why not run.
2. New/changed behavior validated at appropriate level.
3. No secrets added.
4. Docs/memories updated when architecture or workflows changed.
5. MCP/skills assumptions validated for environment-sensitive tasks.
6. Final response includes what changed, where, and residual risks.

## 13. Quick Commands

```bash
# MCP + skills quick health check
scripts/codex-activate.sh --check-only

# Attempt auto-enable + validate
scripts/codex-activate.sh

# Install source-tracked Codex agents
scripts/install-codex-agents.sh

# Explicit full-auto session
codex --ask-for-approval never --sandbox danger-full-access

# Inspect MCP table
codex mcp list

# Full local installer
./scripts/install.sh
```
