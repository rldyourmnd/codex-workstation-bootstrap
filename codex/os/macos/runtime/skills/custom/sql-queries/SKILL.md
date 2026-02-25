---
name: sql-queries
description: Write and optimize SQL across major dialects (PostgreSQL, MySQL, BigQuery, Snowflake, Databricks, SQL Server). Use when user asks for query authoring, debugging, optimization, translation between dialects, or analytical SQL patterns.
---

# SQL Queries

## Workflow
1. Clarify schema, keys, and required output columns.
2. Start with correct baseline query.
3. Add performance improvements (indexes, predicate pushdown, join strategy, window usage).
4. Validate edge cases: nulls, duplicates, timezone/date handling.
5. Provide explainability: why this shape, tradeoffs, and alternatives.

## Output Standard
- Correct query.
- Dialect notes if non-portable.
- Optional optimized variant for large datasets.
