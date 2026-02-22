---
name: better-think
description: Deep multi-pass technical reasoning for architecture and high-impact decisions using structured synthesis and verification.
---

# Better Think (Codex)

Use this skill for high-stakes design or decision-making.

## Trigger

Use when the user asks to:
- design system architecture,
- compare multiple solution strategies,
- make irreversible technical decisions,
- reason through complex tradeoffs.

## Primary Workflow

1. Gather constraints from codebase, Serena memories, and task context.
2. Run structured reasoning rounds (minimum 5) with sequential thinking.
3. Cross-check technology claims via Context7.
4. Evaluate alternatives across correctness, cost, risk, and operability.
5. Produce a final decision memo with assumptions and residual risks.

## Operating Rules

- Separate facts, assumptions, and recommendations.
- Prefer explicit tradeoffs over generic advice.
- Use concrete implementation implications, not only theory.
- Do not modify code unless user asks for implementation.

## Output Contract

- `Decision options` and `tradeoffs`
- `Recommended path` with rationale
- `Implementation implications`
- `Risk register` and validation checkpoints
