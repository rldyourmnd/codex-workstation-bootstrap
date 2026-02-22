# AGENTS.md - Global Development Rules (Codex)

## CORE PRINCIPLES - APPLY TO EVERY REQUEST
Please think step by step, very deep and very hard. Work with surgical precision. Deliver a fully synchronized, consistent system. Use correct development patterns, clean code, and clean architecture. Follow best practices at all times. Priority is ALWAYS quality and accuracy over speed - never use hacks, temporary solutions, or simplifications. Your work and attention to detail are very important to me.

## MCP TOOLS - CRITICAL

### Session Startup - MANDATORY
1. Serena: follow Serena Workflow below (activate, memories, context)
2. Context7: query ALL project dependencies before coding
3. Sequential Thinking: plan task (minimum 5 rounds)

### Tool Priority
| Task | Primary Tool | Fallback | Notes |
| Symbol search | Serena find_symbol | Grep | Never raw grep for code symbols |
| Code editing | Serena symbolic tools | Edit | Prefer replace_symbol_body |
| File creation | Serena insert_after_symbol | Write | Maintain code structure |
| External libraries | Context7 query-docs | WebSearch | Query BEFORE any usage |
| Planning | Sequential Thinking | - | All decisions require this |
| Project knowledge | Serena memories | - | Source of truth for project |
| Code relationships | Serena find_referencing_symbols | Grep | Trace symbol usage via LSP |
| Codebase research | better-explorer agent | Explore agent | Deep investigation with Serena semantic tools |
| GitHub actions | GitHub MCP | gh CLI | Prefer MCP first |

### Context7
Query docs before using ANY external library: new deps, unfamiliar APIs, version features, breaking changes.

### Web Search Policy
1. Use Context7 first for technical docs and APIs.
2. Web search only on trusted, current, primary sources:
   - official vendor documentation,
   - official GitHub repositories/releases/changelogs,
   - standards/specification sources,
   - authoritative package registries.
3. Prefer latest stable docs and concrete dates for freshness-sensitive facts.
4. Avoid low-quality mirrors and SEO blogs when primary sources exist.

### Serena Workflow - FOLLOW THIS ORDER
Serena provides LSP-powered semantic code tools. Always prefer over raw grep/read for code operations.

**Reading code (investigation, exploration):**
```
1. activate_project           -> establish LSP connection for the project
2. list_memories              -> discover what project knowledge exists
3. read_memory (relevant)     -> understand conventions, architecture, patterns
4. get_symbols_overview       -> map symbols in target files WITHOUT reading full content
5. find_symbol (include_body=false, depth=1) -> discover children of key classes/modules
6. find_symbol (include_body=true)           -> read only the specific implementations you need
7. find_referencing_symbols   -> trace usage chains, detect dead code, map callers
8. search_for_pattern         -> sweep for specific patterns across codebase (regex)
```

**Editing code (modifications):**
```
1. find_symbol (include_body=true) -> read current implementation
2. replace_symbol_body             -> replace entire symbol definition
3. insert_after_symbol             -> add new code after existing symbol
4. insert_before_symbol            -> add new code before existing symbol
5. rename_symbol                   -> rename with LSP-aware refactoring
6. replace_content                 -> regex-based partial edits within files
```

**Key efficiency rules:**
- NEVER read full files when `get_symbols_overview` + targeted `find_symbol` suffices
- Use `find_symbol` with `include_body=false` first, then `include_body=true` only for symbols you need
- Use `find_referencing_symbols` to PROVE dead code, not guess
- Use `search_for_pattern` with `file_pattern` to narrow scope
- Spawn parallel tool calls when querying multiple independent symbols/files

### Sequential Thinking
Use for all planning decisions. Minimum 5 rounds. Set `nextThoughtNeeded: true` until resolved.

## SERENA MEMORIES

### Location
| Directory | Purpose | Managed by |
| `.serena/memories/` | Project knowledge, architecture, patterns, conventions | serena-sync agent |
| `.serena/reasoning/` | Deep reasoning artifacts, architecture decisions, design docs | better-think agent |
| `.serena/plans/` | Tactical implementation plans, step-by-step blueprints | better-plan agent |
| `.claude/agent-memory/serena-sync/` | Persistent operation log, memory registry, change history | serena-sync (memory: project) |
| `.claude/agent-memory/better-debugger/` | Past bugs, root causes, recurring error patterns | better-debugger (memory: project) |
| `.claude/agent-memory/manual-tester/` | Test scenarios, past failures, regression suite, test data | manual-tester (memory: project) |
| `~/.claude/agent-memory/better-code-review/` | Developer error patterns across ALL projects | better-code-review (memory: user) |

### Naming Convention
Format: `[AREA]_[NN]_[name].md`

| Area | Usage |
| CORE | Project-wide, overview, conventions |
| BACKEND | Server, API, database |
| FRONTEND | UI, components, state |
| MOBILE | Flutter/Dart specific |
| INFRA | DevOps, CI/CD, deployment |
| API | Endpoints, contracts, schemas |
| AUTH | Authentication, authorization |
| DATA | Models, migrations, seeds |

### Update Triggers
| Event | Action |
| Merge to main | Update changelog, technical docs |
| New feature | Create/update feature memory |
| Architecture change | Update architecture memory |
| New pattern introduced | Document in patterns memory |
| Before delivery | Verify all memories current |

### Memory Metadata Header - REQUIRED
Every memory MUST start with a metadata block for freshness tracking:
```
<!-- Memory Metadata
Last updated: YYYY-MM-DD
Last commit: <short-hash> <commit-message>
Scope: <files/directories this memory covers>
Area: <AREA tag>
-->
```

### Memory Content Structure
- Metadata header first (see above)
- Sections: Overview, Architecture, Key Files, Patterns, Dependencies, Current State
- Use only sections relevant to the memory's scope
- Facts only, no opinions or recommendations
- Cross-reference related memories by name
- Use exact file paths from the project
- Keep focused - split large memories into smaller ones

## CUSTOM AGENTS

Always prefer specialized agents over built-in agents and direct tool calls. Agents use Serena LSP and MCP tools.

### Agent Routing
| Task | Agent | Model | Color | When to Use |
| Codebase exploration | better-explorer | Sonnet | blue | ANY code investigation, research, architecture analysis, quality audit, tracing implementations, finding patterns |
| Memory management | serena-sync | Sonnet | green | Create, update, audit, delete Serena memories. Persistent operation tracking |
| Version freshness | version-patrol | Sonnet | yellow | Check ALL deps, runtimes, tooling, infra against latest stable. Uses WebSearch + Context7 |
| Deep reasoning | better-think | Sonnet | purple | Multi-pass reasoning with Sequential Thinking + Context7 + code evidence |
| Implementation planning | better-plan | Sonnet | cyan | Tactical plans with Serena + Sequential Thinking + Context7. ALWAYS enter plan mode first |
| Code review | better-code-review | Sonnet | orange | Semantic review via Serena LSP. Scope: git diff, files, branches. Bugs, security, breaking changes |
| Live API testing | manual-tester | Sonnet | magenta | QA via curl + SSH. Auto-discovers endpoints from code, tests live server, monitors logs |
| Production debugging | better-debugger | Sonnet | white | SSH logs + Serena LSP code tracing + git blame. Root cause analysis |
| Deploy pipeline | github-server-sync | Sonnet | red | Commits, PR to dev, auto-merge, SSH server sync, verification. GitHub MCP |

### Agent Notes
- **better-explorer**: Primary exploration agent. Always prefer over built-in Explore agent.
- **serena-sync**: 4 modes: CREATE, UPDATE, AUDIT, DELETE. `memory: project` for operation tracking.
- **version-patrol**: Dynamic tool selection: WebSearch or Context7 depending on availability.
- **better-plan**: ALWAYS enter plan mode (EnterPlanMode) BEFORE invoking. Tactical HOW, not strategic WHY (that's better-think). Saves to `.serena/plans/`.
- **better-think**: Strictly sequential: Sequential Thinking -> Context7 -> synthesis. Saves to `.serena/reasoning/`.
- **better-code-review**: Read-only semantic review. Pass scope in prompt: git diff, branch diff, or files. `memory: user`.

SSH agents share base params: `SSH_HOST`, `SSH_USER`, `SSH_PORT`, `SERVER_PROJECT_PATH`.
- **manual-tester**: SSH base + `API_BASE_URL`. `memory: project`.
- **better-debugger**: SSH base + optional `LOG_PATH`, `SYMPTOM`. `memory: project`.
- **github-server-sync**: SSH base + `RESTART_CMD`. Never force pushes, never restarts server.

## GIT WORKFLOW

### Branch Strategy
| Branch | Purpose | Merge Target |
| main | Production-ready code | - |
| dev | Development integration | main |
| feature/* | New features | dev |
| bugfix/* | Bug fixes | dev |
| hotfix/* | Critical production fixes | main, dev |

### Commit Messages
Format: Conventional Commits
```
type(scope): description

[optional body]
```

Types: feat, fix, refactor, docs, test, chore, perf, style

Rules: English only, descriptive, atomic (one logical change), no emojis.

### Workflow Rules
| NEVER | ALWAYS |
| Force push main/dev | Pull before push |
| Skip tests | Test before commit |
| Commit secrets | Self-review changes |
| Large uncommented changes | Keep commits atomic |
| Commit broken code | Verify build passes |

## CODE STANDARDS

### Language-Specific Rules
Detailed rules per language in `~/.claude/rules/` (loaded conditionally via `paths:` frontmatter - only when working with matching files):
TS/TSX, JS/JSX, Python, Rust, C++, C, Dart, PHP, CSS/SCSS, Shell, Docker.
Includes naming conventions, patterns, FSD (frontend), VSA (backend).

### Absolute Rules - NO EXCEPTIONS
- No AI attribution or co-authorship anywhere - user is sole author of ALL output
- No hardcoded secrets or configs - all in .env (SCREAMING_SNAKE_CASE)
- No emojis, stickers, marketing language
- No .md files unless explicitly requested
- English only: code, comments, commits, docs

### Code Quality Rules
**Comments**: Complex logic only, explain WHY not WHAT, technical language, no separators (`---`), no em dashes (use hyphen)
**Errors**: Try-catch at boundaries, custom error classes, meaningful messages, log levels (debug/info/warn/error), never swallow
**Security**: Input validation, parameterized queries, no secrets in logs, sanitize output, OWASP top 10
**Testing**: Real behavior tests, mock only external services, meaningful assertions, edge cases, descriptive names

## QUALITY GATES

Before any commit: type checks pass, linter passes, tests pass, project patterns followed, Serena memories updated if applicable.
