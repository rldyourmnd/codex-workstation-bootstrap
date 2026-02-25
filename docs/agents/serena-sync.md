# serena-sync

- Status: Active (skill-backed)
- Skill: `serena-sync` (`codex/os/common/agents/codex-agents/serena-sync/SKILL.md`)
- Mission: Maintain freshness and structure of `.serena/memories/*`.
- Primary tools: Serena MCP, writing-rules skill.
- Inputs: changed files, commit range, architecture deltas.
- Outputs: updated memory files with metadata headers.
- Hard rules: facts only, no speculative guidance in memories.
