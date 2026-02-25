---
name: create-project
description: Guided greenfield project setup for Codex. Captures requirements, validates versions with Context7, scaffolds structure, and prepares a clean initial delivery baseline.
metadata:
  short-description: New project specification and scaffold workflow
---

# Create Project (Codex)

Use this skill when the user wants to create a new project from scratch.

## Goals

1. Remove ambiguity before scaffolding.
2. Validate selected technologies and versions.
3. Create a clean, minimal but extensible project skeleton.
4. Establish docs and baseline quality gates.

## Workflow

1. Discovery interview (iterative):
- Ask focused questions in rounds: project type, architecture, stack, infra, QA/linting, MVP scope.
- Confirm assumptions explicitly before generating files.

2. Version and compatibility validation:
- Use Context7 for chosen frameworks/libraries.
- Cross-check runtime constraints (Node/Python/Rust/Dart/etc.) and major peer dependencies.
- Flag unstable/beta choices unless user explicitly accepts.

3. Scaffold with user-approved plan:
- Initialize repository and directory layout.
- Create minimal config files and entrypoints.
- Add `.env.example` placeholders only (no secrets).
- Add CI and container files only if requested.

4. Quality baseline:
- Add commands for lint/test/typecheck where relevant.
- Keep first commit scope clean and reversible.

5. Optional memory/bootstrap:
- Initialize Serena context and create first project memories if requested.

## Output Contract

- `Specification Summary`: confirmed decisions
- `Scaffolded Structure`: key directories/files
- `Version Matrix`: chosen versions and rationale
- `Runbook`: exact commands to start and validate
- `Next Steps`: prioritized implementation plan

## Guardrails

- Do not over-scaffold with unnecessary frameworks.
- Do not install unverified versions when Context7 indicates conflicts.
- Ask before destructive changes in non-empty directories.
