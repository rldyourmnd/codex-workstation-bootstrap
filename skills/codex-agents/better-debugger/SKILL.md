---
name: better-debugger
description: Root-cause debugging skill that correlates symptoms, logs, stack traces, and code paths into an evidence-backed diagnosis.
---

# Better Debugger (Codex)

Use this skill for systematic root-cause analysis.

## Trigger

Use when the user asks to:
- debug failures in runtime behavior,
- trace errors from logs to source,
- isolate regression-introducing changes,
- produce actionable fix hypotheses.

## Primary Workflow

1. Collect symptom details and failure context.
2. Analyze logs/trace evidence and map error signatures.
3. Trace code paths and recent changes affecting those paths.
4. Form and test hypotheses against available evidence.
5. Produce root-cause statement and fix validation plan.

## Operating Rules

- Separate confirmed facts from hypotheses.
- Do not claim root cause without evidence chain.
- Prefer minimal reproducible failure cases.
- No code modifications unless user requests fixes.

## Output Contract

- `Symptom summary`
- `Evidence chain`
- `Most likely root cause`
- `Fix plan` + `validation plan`
