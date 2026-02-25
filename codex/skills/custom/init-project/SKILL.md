---
name: init-project
description: Fast onboarding for an existing repository. Builds a verified architecture snapshot, initializes Serena context, and produces actionable next steps for Codex workflows.
metadata:
  short-description: Existing project onboarding and readiness report
---

# Init Project (Codex)

Use this skill when a user opens an unfamiliar repository and wants fast, evidence-based onboarding.

## Goals

1. Classify project type, stack, and structure.
2. Initialize Serena context for semantic navigation.
3. Produce a concise architecture map with key files.
4. Audit major dependency freshness risks.
5. Suggest concrete next actions.

## Workflow

1. Collect quick repository context:
- `pwd`, `git remote -v`, `git branch --show-current`
- root structure (`ls`, shallow `find`)
- manifests (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pubspec.yaml`, `composer.json`)

2. Initialize Serena (if available):
- `activate_project`
- `check_onboarding_performed`
- `list_memories`

3. Run semantic exploration:
- Use `better-explorer` flow (Serena-first) for architecture and execution boundaries.
- Build a list of 5-10 key files with one-line explanations.

4. Run dependency freshness check:
- Use `version-patrol` flow for CRITICAL/HIGH issues only.
- Focus on major-version lag and EOL signals.

5. If memories are missing/stale:
- Use `serena-sync` flow in CREATE or AUDIT mode as appropriate.

## Output Contract

Return a single structured report:
- `Project`: type, stack, architecture style
- `Key Files`: 5-10 files with purpose
- `Memory State`: existing/fresh/stale/missing
- `Version Risks`: only CRITICAL/HIGH
- `Next Actions`: numbered, practical, and short

## Guardrails

- Do not modify source code unless user explicitly asks.
- Do not claim architecture facts without file evidence.
- Keep report concise and operational.
