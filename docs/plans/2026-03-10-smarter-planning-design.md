# Smarter Planning — Design

**Date:** 2026-03-10
**Status:** Approved
**Goal:** Make `/pilot:plan` analyze the codebase before generating tasks, using specialized subagents for focused analysis.

## Architecture

`/pilot:plan` becomes an orchestrator dispatching three specialized agents. Each agent has a focused role, clear input/output contract, and a system prompt tailored to its expertise.

```
User describes what to build
  → ScoutAgent (targeted scan of relevant codebase areas)
  → GapAgent (toolchain coverage — parallel with Scout)
  → User confirms gaps + provides task details
  → ArchitectAgent (orders tasks, adds dependencies + context + parallel groups)
  → Orchestrator generates PRD + config
```

## Agents

### ScoutAgent

**Persona:** Senior engineer doing code review of an unfamiliar codebase.

**Purpose:** Scan the parts of the codebase relevant to the planned work. Extract patterns, conventions, key files, and anti-patterns.

**Input:**
- File tree (full repo)
- Task description from user
- Stack detection results

**Output:** Compact context block:
```yaml
codebase:
  scanned: [src/middleware/, src/api/, src/models/]
  patterns:
    - "middleware uses express-style (req, res, next)"
    - "tests colocated as *.test.ts"
    - "zod schemas in src/schemas/ for validation"
  conventions:
    - "camelCase functions, PascalCase components"
    - "barrel exports via index.ts"
  key_files:
    - "src/app.ts — entry point"
    - "src/middleware/auth.ts — pattern reference for middleware"
  avoid:
    - "src/legacy/ — deprecated, don't follow its patterns"
```

**Targeted scan — hybrid approach:**

The agent uses a heuristic table to determine which directories to scan, then adjusts based on the actual file tree.

| Task Type | Heuristic Globs |
|-----------|----------------|
| UI / frontend | `**/components/**`, `**/hooks/**`, `**/styles/**`, `**/app/**`, `**/pages/**` |
| API / backend | `**/api/**`, `**/routes/**`, `**/middleware/**`, `**/controllers/**` |
| Data / models | `**/models/**`, `**/schemas/**`, `**/db/**`, `**/prisma/**` |
| CLI / tooling | `**/commands/**`, `**/cli/**`, `bin/**` |
| Tests | `**/__tests__/**`, `**/*.test.*`, `**/*.spec.*` |
| Config / infra | `**/config/**`, `**/infrastructure/**`, `docker*` |

The agent reads the file tree first and adapts — e.g., if the repo uses `app/` (Next.js app router) instead of `pages/`, it scans `app/`.

**File:** `skills/plan/agents/scout.md`

### ArchitectAgent

**Persona:** Staff engineer planning a sprint.

**Purpose:** Analyze raw tasks, build a dependency graph, add context hints, identify parallel groups, and reorder for optimal execution.

**Input:**
- Raw task list from user
- ScoutAgent output (codebase context)
- Quality bar setting

**Output:** Reordered task list with enriched fields:
```markdown
- [ ] **1.** Set up Vitest with jsdom
  - Acceptance: vitest run exits 0 with a passing smoke test
  - Context: toolchain setup — must be first, all other tasks depend on test runner
  - Validation: typecheck, test
  - Files: vitest.config.ts, src/__tests__/smoke.test.ts
  - Depends: none

- [ ] **3.** Add auth middleware
  - Acceptance: requests without valid JWT return 401
  - Context: first middleware in codebase — establish pattern for future middleware
  - Validation: typecheck, test, lint
  - Files: src/middleware/auth.ts, src/middleware/auth.test.ts
  - Depends: 1
```

Plus parallel group analysis:
```
parallel_groups:
  - [1, 3, 5]    # sequential chain A
  - [2, 4]        # sequential chain B
  - [6, 7, 8]     # all independent — can each run in own worktree
```

**Dependency rules:**
- Dependency means "would fail without" — not just logical ordering preference
- Validate each dependency: would task N actually fail its feedback loops without task M?
- Remove false dependencies that would unnecessarily serialize the loop
- Reorder tasks to respect dependencies while maximizing parallelism

**File:** `skills/plan/agents/architect.md`

### GapAgent

**Persona:** DevOps engineer auditing CI/CD readiness.

**Purpose:** Analyze detected toolchain against required feedback loops, research best tools for gaps, generate recommendations.

**Input:**
- Stack detection results
- Existing feedback loop config
- `references/stack-detection.md` detection tables

**Output:** Gap analysis with recommendations:
```
Gaps found:
  test: No test runner detected
    → Vitest (recommended for Next.js 15 + TypeScript)
    → Jest (alternative — mature ecosystem)
  browser: No browser tests
    → Playwright (recommended)
    → Skip (backend-only work)
```

This agent replaces the current inline gap analysis logic in Phase 2 of the plan skill. Uses WebSearch to find current best tools for the detected stack.

**File:** `skills/plan/agents/gap.md`

## PRD Format Changes

Two new fields per task:

```markdown
- [ ] **N.** [Task description]
  - Acceptance: [one-liner — testable]
  - Context: [pattern notes, integration hints, conventions to follow]
  - Validation: [feedback loops]
  - Files: [expected files]
  - Depends: [task numbers or "none"]
```

`Context:` replaces risk tagging — informs the agent without restricting it. Examples:
- "first middleware — establish pattern for future middleware"
- "modifies shared auth module — 5 files import this"
- "follows existing CRUD pattern in src/api/users.ts"
- "new abstraction — no existing pattern to follow, keep simple"

## Config Changes

**`pilot.yaml`** gains a `codebase:` section (output of ScoutAgent):

```yaml
codebase:
  scanned: [src/middleware/, src/api/, src/models/]
  patterns: ["middleware uses express-style (req, res, next)"]
  conventions: ["camelCase functions, PascalCase components"]
  key_files: ["src/app.ts — entry point"]
  avoid: ["src/legacy/ — deprecated"]
```

**PRD.md** gains a `parallel_groups:` section at the bottom (output of ArchitectAgent):

```markdown
## Parallel Groups

Groups can run in separate worktrees simultaneously.

- Group A: 1 → 3 → 5 (sequential)
- Group B: 2 → 4 (sequential)
- Group C: 6, 7, 8 (independent)
```

## Agent File Structure

```
skills/plan/
├── SKILL.md              # orchestrator — dispatches agents
├── agents/
│   ├── scout.md          # targeted codebase scanner
│   ├── architect.md      # task analyst + dependency graph
│   └── gap.md            # toolchain gap analysis
├── assets/
│   ├── prd-template.md
│   ├── pilot-yaml-template.yaml
│   └── progress-template.txt
└── references/
    └── stack-detection.md
```

## Changes Required

| File | Change |
|------|--------|
| `skills/plan/agents/scout.md` | NEW — ScoutAgent system prompt |
| `skills/plan/agents/architect.md` | NEW — ArchitectAgent system prompt |
| `skills/plan/agents/gap.md` | NEW — GapAgent system prompt |
| `skills/plan/SKILL.md` | Refactor into orchestrator — dispatch agents instead of inline logic |
| `skills/plan/assets/prd-template.md` | Add `Context:` and `Depends:` fields, parallel groups section |
| `skills/plan/assets/pilot-yaml-template.yaml` | Add `codebase:` section |
| `skills/plan/references/stack-detection.md` | Add scan heuristic table (task type → globs) |
| `docs/design.md` | Add agents section, update planning flow |

## Not Included (deferred)

- **Run-phase agents** (Implementer, Reviewer, Healer) — separate feature, part of self-healing brainstorm
- **Model selection per agent** — v1 inherits parent model, per-agent model config comes later
- **Parallel worktree execution** — ArchitectAgent identifies groups, actual execution is v0.2 roadmap
