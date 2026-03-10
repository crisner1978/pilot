# Smarter Planning — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor `/pilot:plan` into an orchestrator that dispatches ScoutAgent, GapAgent, and ArchitectAgent for smarter codebase-aware planning.

**Architecture:** Three agent prompt files in `skills/plan/agents/`. Plan skill becomes orchestrator that dispatches agents and assembles their output into PRD + config.

**Tech Stack:** Markdown (agent prompts, SKILL.md), YAML (pilot.yaml template)

---

### Task 1: Add scan heuristic table to stack-detection.md

**Files:**
- Modify: `skills/plan/references/stack-detection.md`

**Step 1: Add the scan heuristic table**

Append after the "Sensitive File Detection" section:

```markdown
## Scan Heuristics

Maps task types to likely relevant directories. ScoutAgent uses this as a starting point, then adapts based on the actual file tree.

| Task Type | Heuristic Globs |
|-----------|----------------|
| UI / frontend | `**/components/**`, `**/hooks/**`, `**/styles/**`, `**/app/**`, `**/pages/**` |
| API / backend | `**/api/**`, `**/routes/**`, `**/middleware/**`, `**/controllers/**`, `**/services/**` |
| Data / models | `**/models/**`, `**/schemas/**`, `**/db/**`, `**/prisma/**`, `**/entities/**` |
| CLI / tooling | `**/commands/**`, `**/cli/**`, `bin/**`, `**/scripts/**` |
| Tests | `**/__tests__/**`, `**/*.test.*`, `**/*.spec.*`, `**/fixtures/**` |
| Config / infra | `**/config/**`, `**/infrastructure/**`, `docker*`, `**/deploy/**` |
| Auth / security | `**/auth/**`, `**/middleware/**`, `**/guards/**`, `**/policies/**` |
| Shared / utils | `**/utils/**`, `**/helpers/**`, `**/lib/**`, `**/shared/**`, `**/common/**` |

The agent reads the full file tree first. If the repo uses non-standard directories (e.g., `app/` instead of `pages/` for Next.js), the agent adapts. The table is a starting point, not a constraint.
```

**Step 2: Commit**

```bash
git add skills/plan/references/stack-detection.md
git commit -m "docs: add scan heuristic table for targeted codebase analysis"
```

---

### Task 2: Create ScoutAgent prompt

**Files:**
- Create: `skills/plan/agents/scout.md`

**Step 1: Create the agents directory and scout prompt**

```markdown
# ScoutAgent — Targeted Codebase Scanner

You are a senior engineer doing code review of an unfamiliar codebase. Your job is to quickly understand the parts of the codebase relevant to the planned work — patterns, conventions, key files, and anti-patterns to avoid.

## Input

You receive:
- **File tree** of the full repo
- **Task description** from the user (what they want to build)
- **Stack detection results** (language, framework, toolchain)
- **Scan heuristic table** (task type → likely directories)

## Process

1. Read the file tree and identify what type of work this is (UI, API, data, CLI, etc.)
2. Use the scan heuristic table as a starting point — adapt if the repo uses non-standard directory names
3. Read 3-5 representative source files from the relevant directories to extract patterns
4. Look for:
   - **Naming conventions** — camelCase vs snake_case, file naming patterns
   - **Architecture patterns** — how modules are structured, how they communicate
   - **Common abstractions** — shared utilities, base classes, middleware patterns
   - **Test patterns** — where tests live, what testing library, assertion style
   - **Anti-patterns** — legacy code, deprecated modules, inconsistent patterns to avoid
5. Check for pattern reference files: README.md, CONTRIBUTING.md, CLAUDE.md, .editorconfig

## Output

Return a compact YAML context block:

```yaml
codebase:
  scanned: [list of directories scanned]
  patterns:
    - "description of pattern 1"
    - "description of pattern 2"
  conventions:
    - "naming convention"
    - "file organization convention"
  key_files:
    - "path — why it's a good reference"
  avoid:
    - "path or pattern — why to avoid it"
```

## Rules

- **Be concise** — each pattern/convention is one line. This block goes into pilot.yaml and is read every iteration.
- **Be specific** — "uses express-style middleware (req, res, next)" not "uses middleware"
- **Prioritize relevance** — only include patterns relevant to the planned work
- **Max 3-5 items per field** — enough to guide, not enough to bloat context
- **Read actual code** — don't guess from file names alone. Open files and verify patterns.
```

**Step 2: Commit**

```bash
git add skills/plan/agents/scout.md
git commit -m "feat: create ScoutAgent prompt — targeted codebase scanner"
```

---

### Task 3: Create GapAgent prompt

**Files:**
- Create: `skills/plan/agents/gap.md`

**Step 1: Create the gap agent prompt**

```markdown
# GapAgent — Toolchain Gap Analyst

You are a DevOps engineer auditing a project's CI/CD readiness and feedback loop coverage. Your job is to identify missing tools in the development toolchain and recommend the best current options.

## Input

You receive:
- **Stack detection results** (language, framework, detected tools)
- **Feedback loop config** (what's already configured)
- **Stack detection reference** (the full detection table and feedback loop mapping)

## Process

1. Map the detected stack against the four core feedback loops: typecheck, test, lint, browser
2. For each **missing** loop:
   - Use WebSearch to find the best current tool for this specific stack
   - Identify 2-3 options with trade-offs
   - Mark one as recommended with clear reasoning
3. For each **present** loop:
   - Verify the command looks correct for the detected version/config
   - Flag any obvious misconfigurations
4. Check for gaps that aren't relevant to the planned work — note them but don't push setup

## Output

Return a structured gap analysis:

```
gaps:
  - loop: test
    status: missing
    recommended: "Vitest"
    reason: "Fast, ESM-native, jsdom for Next.js component testing"
    alternatives:
      - "Jest — mature ecosystem, ts-jest transform"
    setup_task: "Install vitest + jsdom, create vitest.config.ts, add smoke test"
  - loop: browser
    status: missing
    relevant: false
    note: "No browser tests. Backend-only work — not needed for current PRD."
```

## Rules

- **Research current tools** — use WebSearch, don't recommend outdated options
- **Stack-specific recommendations** — "Vitest for Next.js" not "any test runner"
- **Include setup as a task** — if a tool needs installing, that becomes PRD task #1
- **Be honest about gaps** — if something isn't needed for this work, say so
- **One recommendation per gap** — don't overwhelm with options, lead with the best choice
```

**Step 2: Commit**

```bash
git add skills/plan/agents/gap.md
git commit -m "feat: create GapAgent prompt — toolchain gap analyst"
```

---

### Task 4: Create ArchitectAgent prompt

**Files:**
- Create: `skills/plan/agents/architect.md`

**Step 1: Create the architect agent prompt**

```markdown
# ArchitectAgent — Task Analyst & Dependency Planner

You are a staff engineer planning a sprint. Your job is to take a raw list of tasks, analyze their dependencies, add context hints, identify parallel execution groups, and produce an optimally ordered task list.

## Input

You receive:
- **Raw task list** from the user (descriptions + acceptance criteria)
- **ScoutAgent output** (codebase context — patterns, conventions, key files)
- **Quality bar** (prototype / production / library)
- **Gap analysis** (setup tasks that need to come first)

## Process

1. **Analyze dependencies** — for each task, determine which other tasks it genuinely depends on. A dependency means "would fail its feedback loops without the other task completed." Not just logical preference — actual build/test failure.

2. **Add context hints** — for each task, add a `Context:` field noting:
   - Is this the first of its kind? ("first middleware — establish pattern")
   - Does it touch shared code? ("modifies auth module — 5 files import this")
   - Does it follow an existing pattern? ("follows CRUD pattern in src/api/users.ts")
   - Is there no existing pattern? ("new abstraction — no existing pattern, keep simple")

3. **Reorder tasks** — sort to respect dependencies while maximizing parallelism:
   - Gap-filling setup tasks first (always)
   - Architectural/foundational tasks before tasks that depend on them
   - Independent tasks grouped together

4. **Identify parallel groups** — tasks that can run simultaneously in separate worktrees:
   - Group sequential chains (A depends on B depends on C)
   - Identify fully independent tasks
   - Chains that share no dependencies can run in parallel

## Output

Return the reordered task list with enriched fields:

```markdown
- [ ] **1.** [Task description]
  - Acceptance: [one-liner — testable]
  - Context: [pattern notes, integration hints]
  - Validation: [feedback loops]
  - Files: [expected files]
  - Depends: none

- [ ] **2.** [Task description]
  - Acceptance: [one-liner]
  - Context: [notes]
  - Validation: [feedback loops]
  - Files: [expected files]
  - Depends: 1
```

Plus a parallel groups section:

```markdown
## Parallel Groups

Groups can run in separate worktrees simultaneously.

- Group A: 1 → 3 → 5 (sequential)
- Group B: 2 → 4 (sequential)
- Group C: 6, 7, 8 (independent)
```

## Rules

- **Validate dependencies** — ask: "would task N actually fail without task M?" Remove false dependencies.
- **Keep context hints to one line** — they're read every iteration, must be concise
- **Don't add tasks** — you reorder and enrich, you don't create new work
- **Don't remove tasks** — even if they seem redundant, the user added them for a reason
- **Maximize parallelism** — fewer sequential chains = faster autonomous execution
- **Setup first, always** — toolchain/config tasks are always #1 regardless of other ordering
```

**Step 2: Commit**

```bash
git add skills/plan/agents/architect.md
git commit -m "feat: create ArchitectAgent prompt — task analyst and dependency planner"
```

---

### Task 5: Update PRD template with Context field and parallel groups

**Files:**
- Modify: `skills/plan/assets/prd-template.md`

**Step 1: Add Context field to task format and parallel groups section**

Update the task template to include the `Context:` field, and add a parallel groups section at the bottom:

The task entries should look like:
```markdown
- [ ] **1.** [Task description]
  - Acceptance: [one-liner — what "done" looks like, testable]
  - Context: [pattern notes, integration hints from ArchitectAgent]
  - Validation: [feedback loops]
  - Files: [expected files]

- [ ] **2.** [Task description]
  - Acceptance: [one-liner]
  - Context: [notes]
  - Validation: [feedback loops]
  - Files: [expected files]
  - Depends: [task #, only if blocked without it]
```

Add at the bottom, before or after the Quality Bar section:
```markdown
## Parallel Groups

Groups can run in separate worktrees simultaneously.

- Group A: [task chain]
- Group B: [task chain]
- Group C: [independent tasks]
```

**Step 2: Commit**

```bash
git add skills/plan/assets/prd-template.md
git commit -m "feat: add Context field and parallel groups to PRD template"
```

---

### Task 6: Add codebase section to pilot.yaml template

**Files:**
- Modify: `skills/plan/assets/pilot-yaml-template.yaml`

**Step 1: Add codebase section**

Insert after the `project:` section and before `source:`:

```yaml
codebase:
  scanned: [directories ScoutAgent analyzed]
  patterns: [key patterns discovered]
  conventions: [naming, file organization]
  key_files: [reference files for the agent to follow]
  avoid: [anti-patterns, legacy code to avoid]
```

**Step 2: Commit**

```bash
git add skills/plan/assets/pilot-yaml-template.yaml
git commit -m "feat: add codebase context section to pilot.yaml template"
```

---

### Task 7: Refactor plan SKILL.md into orchestrator

**Files:**
- Modify: `skills/plan/SKILL.md`

This is the biggest change. The plan skill needs to dispatch agents instead of doing inline analysis.

**Step 1: Update the checklist**

Replace the current checklist with:
```markdown
## Checklist

You MUST complete these phases in order:

1. **Context scan** — detect stack, toolchain, existing config
2. **Targeted codebase analysis** — dispatch ScoutAgent to scan relevant areas
3. **Gap analysis** — dispatch GapAgent to identify missing feedback loops
4. **Task source** — gather tasks from user, GitHub Issues, or both
5. **Task analysis** — dispatch ArchitectAgent to order tasks, add dependencies + context
6. **Generate artifacts** — PRD.md, .claude/pilot.yaml, progress.txt, pilot-loop.sh
7. **Readiness check** — dry-run feedback loops, flag issues
```

**Step 2: Add Phase 2 — Targeted Codebase Analysis (new)**

After Phase 1, add a new phase:

```markdown
## Phase 2 — Targeted Codebase Analysis

After the user describes what they want to build (or after GitHub Issues are selected), dispatch the **ScoutAgent** to analyze the relevant parts of the codebase.

Read `agents/scout.md` for the full agent prompt. Dispatch it as a subagent with:
- The full file tree (run `find . -type f -not -path './.git/*' -not -path './node_modules/*' | head -200` or equivalent)
- The task description from the user
- The stack detection results from Phase 1
- The scan heuristic table from `references/stack-detection.md`

The ScoutAgent returns a `codebase:` YAML block. Store this for Phase 6 (generate artifacts) — it goes into `pilot.yaml`.

Present the results to the user:
\```
Codebase analysis complete:
  Scanned: src/middleware/, src/api/, src/models/
  Patterns: express-style middleware, zod validation, colocated tests
  Key files: src/middleware/auth.ts (middleware pattern reference)
\```
```

**Step 3: Refactor Phase 2 → Phase 3 (Gap Analysis)**

Rename the current "Phase 2 — Gap Analysis" to "Phase 3 — Gap Analysis". Update it to dispatch the **GapAgent** instead of doing inline analysis:

```markdown
## Phase 3 — Gap Analysis

Dispatch the **GapAgent** to analyze toolchain coverage. Read `agents/gap.md` for the full agent prompt. Dispatch it as a subagent with:
- Stack detection results from Phase 1
- Current feedback loop config
- The stack detection reference (`references/stack-detection.md`)

The GapAgent returns a structured gap analysis. For each gap with `relevant: true`, use AskUserQuestion to present options to the user (same UX as before — one question per gap).

If the GapAgent identifies setup tasks (e.g., "Install vitest"), these become the first tasks in the PRD.
```

Keep the existing AskUserQuestion examples for gaps — they still apply. The difference is the agent researches the recommendations instead of inline logic.

**Step 4: Renumber Phase 3 → Phase 4 (Task Source)**

The current Phase 3 (Task Source) becomes Phase 4. No changes to content — just renumber.

**Step 5: Add Phase 5 — Task Analysis (new)**

After the task source phase, add:

```markdown
## Phase 5 — Task Analysis

After gathering raw tasks, dispatch the **ArchitectAgent** to analyze and enrich them. Read `agents/architect.md` for the full agent prompt. Dispatch it as a subagent with:
- The raw task list from Phase 4
- The ScoutAgent codebase context from Phase 2
- The quality bar setting
- Any setup tasks from GapAgent (Phase 3)

The ArchitectAgent returns:
- Reordered task list with `Context:` and `Depends:` fields
- Parallel execution groups

Use the ArchitectAgent's output directly as the task list for the PRD. Present the reordered tasks to the user for confirmation before generating artifacts.
```

**Step 6: Renumber remaining phases**

- Current Phase 4 (Generate Artifacts) → Phase 6
- Current Phase 5 (Readiness Check) → Phase 7

Update Phase 6 to include: "Include the `codebase:` section from ScoutAgent in `pilot.yaml`. Include the parallel groups section from ArchitectAgent in `PRD.md`."

**Step 7: Commit**

```bash
git add skills/plan/SKILL.md
git commit -m "feat: refactor plan skill into orchestrator — dispatch Scout, Gap, Architect agents"
```

---

### Task 8: Update design.md with agent architecture

**Files:**
- Modify: `docs/design.md`

**Step 1: Add Agents section**

After the "## Observability" section and before "## Recipe Skills", add:

```markdown
## Planning Agents

`/pilot:plan` dispatches specialized agents for codebase-aware planning.

| Agent | Persona | Purpose |
|-------|---------|---------|
| ScoutAgent | Senior engineer reviewing unfamiliar code | Targeted scan of relevant codebase areas — extracts patterns, conventions, key files |
| GapAgent | DevOps engineer auditing CI/CD | Analyzes toolchain gaps, researches best tools, recommends setup |
| ArchitectAgent | Staff engineer planning a sprint | Orders tasks, adds dependencies + context hints, identifies parallel groups |

Planning flow:
1. Context scan (detect stack, toolchain)
2. ScoutAgent (targeted codebase analysis)
3. GapAgent (toolchain gap analysis) — can run parallel with Scout
4. Task source (gather from user / GitHub)
5. ArchitectAgent (order, enrich, parallelize tasks)
6. Generate artifacts
7. Readiness check

Agent prompts live in `skills/plan/agents/`. They are dispatched as subagents by the plan orchestrator.
```

**Step 2: Update directory structure**

In the directory tree near the top of the file, add the `agents/` directory under `plan/`:

```
│   ├── plan/                       # /pilot:plan — interactive setup
│   │   ├── SKILL.md
│   │   ├── agents/                 # specialized planning agents
│   │   │   ├── scout.md
│   │   │   ├── architect.md
│   │   │   └── gap.md
│   │   ├── assets/                 # PRD, yaml, progress templates
│   │   └── references/             # stack detection table
```

**Step 3: Commit**

```bash
git add docs/design.md
git commit -m "docs: add planning agents architecture to design doc"
```
