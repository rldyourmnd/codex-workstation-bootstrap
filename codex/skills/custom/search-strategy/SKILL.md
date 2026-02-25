---
name: search-strategy
description: Decompose complex questions into targeted multi-source search strategies. Use when user needs high-confidence synthesis from multiple tools, docs, repositories, or APIs with clear relevance ranking and fallback logic.
---

# Search Strategy

## Workflow
1. Break request into answerable sub-questions.
2. Map each sub-question to best source/tool.
3. Query iteratively, refining terms from evidence.
4. Rank sources by authority and freshness.
5. Synthesize with explicit uncertainty and next checks.

## Quality Bar
- Traceable reasoning from source to claim.
- Conflicts called out, not hidden.
- Practical next action when evidence is incomplete.
