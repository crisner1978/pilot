# PILOT — Plan, Iterate, Loop, Observe, Test

**Date:** 2026-03-06
**Status:** Approved
**Inspired by:** [RALPH (AI Hero)](https://www.aihero.dev/getting-started-with-ralph)

## Overview

A portable Claude Code plugin that turns AI agents into autonomous software engineers. Install the plugin, run `/pilot:plan`, and get a self-driving development loop with structured PRDs, auto-detected feedback loops, and pluggable task sources.

**Core principle:** The agent chooses the task, implements it, validates it, commits it, and moves on — no human prompting between iterations.

## Distribution

Packaged as a Claude Code plugin, distributed via GitHub:

```
pilot/                              # github.com/crisner1978/pilot
├── .claude-plugin/
│   └── plugin.json                 # manifest (name, version, description)
├── skills/
│   ├── plan/                       # /pilot:plan — interactive setup
│   │   ├── SKILL.md
│   │   ├── agents/                 # specialized planning agents
│   │   │   ├── scout.md
│   │   │   ├── architect.md
│   │   │   └── gap.md
│   │   ├── assets/                 # PRD, yaml, progress templates
│   │   └── references/             # stack detection table
│   ├── run/                        # /pilot:run — execute one task
│   │   ├── SKILL.md
│   │   └── agents/
│   │       ├── implementer.md
│   │       ├── reviewer.md
│   │       └── healer.md
│   ├── loop/                       # /pilot:loop — autonomous loop
│   │   ├── SKILL.md
│   │   └── scripts/                # readiness validation
│   ├── status/SKILL.md             # /pilot:status — sprint dashboard
│   ├── add/SKILL.md                # /pilot:add — insert task mid-sprint
│   ├── migrate/                    # /pilot:migrate — pattern migration
│   │   ├── SKILL.md
│   │   └── assets/                 # MIGRATION.md template
│   └── [9 more recipe skills]/    # coverage, lint-fix, duplication, entropy,
│       └── SKILL.md                # deps, types, docs, a11y, security, triage
├── scripts/
│   └── pilot-loop.sh                 # shared plugin-owned loop script (never copied into user repos)
├── docs/
│   ├── design.md
│   └── recipes.md                  # recipe reference + custom recipe guide
└── README.md
```

**Installation:**
```bash
# Add marketplace (one time)
claude plugin marketplace add github:crisner1978/pilot

# Install
claude plugin install pilot
```

**Usage:** `/pilot:plan`, `/pilot:run`, `/pilot:loop`, plus 11 recipe skills (see `docs/recipes.md`)

## Goals

- **Portable CLI-first** — works in any codebase with just Claude Code CLI + bash, no platform dependency
- **Zero-config start** — auto-detects toolchain, generates config through questions, never requires manual authoring
- **Pluggable task sources** — local PRD files, GitHub Issues, or both, with adapter interface for others
- **Context-driven feedback** — auto-detects available tools, recommends and bootstraps missing ones
- **Two modes** — manual (one task, human watches) and autonomous (loop with iteration cap)

## System Architecture

### Components

| Component | Purpose | Mode |
|-----------|---------|------|
| `/pilot:plan` | Interactive setup — generates PRD + config from questions + auto-detection | HITL |
| `/pilot:run` | Execute one task from the PRD, commit, update progress | Manual |
| `/pilot:loop` | Validate readiness and launch the loop script | Autonomous |
| `/pilot:status` | Sprint dashboard — progress, last run, blockers, next actions | HITL |
| `/pilot:add` | Insert a task into an existing PRD mid-sprint | HITL |
| `pilot-loop.sh` | Shared plugin-owned bash loop calling `claude -p` with iteration cap + result markers | Autonomous |

### File Convention

Files generated into the user's project:

```
.claude/
├── pilot.yaml             # Generated config (toolchain, sources, feedback loops)
PRD.md                     # Generated task backlog (checklist format)
progress.txt               # Append-only structured log of completed work
```

Durable project artifacts stop there.

**Ephemeral runtime state:** Recipe skills may write `.claude/pilot-prompt.md` before launching the shared loop. When the launch sets `PILOT_PROMPT_OWNED=true`, the loop treats that file as PILOT-owned scratch state and deletes it on exit. Durable customization belongs in `CLAUDE.md`, `quality.notes`, and `loop.notes` in `pilot.yaml`.

### Flow

```
/pilot:plan (interactive)
    ├── Asks: What are we building? Where are tasks? Quality bar?
    ├── Auto-detects: vitest, tsc, eslint, biome, playwright, jest, pytest...
    ├── Gap analysis: identifies missing feedback loops, web searches for best tool
    ├── Recommends: "No linter — Biome recommended for this stack. Add setup to PRD?"
    ├── Generates: PRD.md + .claude/pilot.yaml + progress.txt
    └── Verifies: feedback loops actually run (dry run)

/pilot:run (one task, manual)
    ├── Reads: PRD.md + progress.txt + pilot.yaml
    ├── Picks highest-priority incomplete task
    ├── Dispatches ImplementerAgent / ReviewerAgent / HealerAgent via Task tool
    ├── Runs feedback loops (typecheck → test → lint → browser → custom)
    ├── Commits only if all pass (retries up to 3x, then escalates)
    └── Emits one PILOT_RESULT marker + appends structured entry to progress.txt

/pilot:loop (autonomous loop)
    ├── Validates PRD.md and pilot.yaml exist
    ├── Dry-runs feedback loops
    ├── Confirms iteration cap and sandbox preference
    └── Launches the shared plugin-owned pilot-loop.sh
```

## Planning Skill (`/pilot:plan`)

The brain of the system. Interactive, one-question-at-a-time.

### Phase 1 — Context Gathering

- Scan repo: `package.json`, `tsconfig.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, etc.
- Detect stack: language, framework, test runner, linter, formatter, build tool
- Check for existing PRD.md, CLAUDE.md, GitHub Issues

### Phase 2 — Gap Analysis + Recommendations

- Map detected toolchain against required feedback loops
- For each gap: web search for best tool given the stack
- Present gaps with recommendations as questions:
  - *"No test runner found. This is a Next.js 15 project — Vitest with jsdom is recommended. Add test setup to PRD?"*
  - *"No type checking. You have .js files — want to add tsconfig with checkJs, or convert to TypeScript?"*
  - *"No linter. For this ESM TypeScript project, Biome is fastest. ESLint if you need plugin ecosystem. Preference?"*

### Phase 3 — Task Source

- Ask: local PRD, GitHub Issues, or both?
- If GitHub: fetch open issues, let user select which to include
- If local: ask what we're building, break into atomic tasks
- Either way: output prioritized checklist with risky/architectural tasks first

### Phase 4 — Generate Artifacts

- `PRD.md` — prioritized task checklist with validation criteria per task
- `.claude/pilot.yaml` — toolchain config, feedback loops, task source, iteration limits, gaps
- `progress.txt` — empty, ready to go
- Loop infrastructure stays in the plugin's `scripts/` directory — never copied into the user's project

### Phase 5 — Readiness Check

- Verify standard feedback loops actually run (e.g., `vitest run` doesn't error on empty suite). Custom feedback commands are recorded but not executed during readiness checks because they may be non-idempotent.
- Flag any issues before the first iteration starts

## Run Skill (`/pilot:run`)

```
Read PRD.md + progress.txt + pilot.yaml
         ↓
Pick highest-priority incomplete task
         ↓
Implement it (write code, follow existing patterns)
         ↓
Run feedback loops from pilot.yaml (in order):
  typecheck → test → lint → browser → custom
         ↓
All pass? → Commit + append to progress.txt
Any fail? → Fix and retry (up to 3 attempts per loop)
Still failing? → Stop, report what's broken, ask human
         ↓
Check: was that the last task?
  Yes → output PILOT_RESULT=done + <promise>COMPLETE</promise>
  No  → output PILOT_RESULT=done, human decides whether to run again
```

Key behaviors:

- **One task per invocation** — prevents context rot
- **Feedback loops are blocking** — no commit without green
- **Retry is bounded** — 3 attempts to fix a failing loop, then escalate to human
- **Agent orchestration is explicit** — ImplementerAgent, ReviewerAgent, and HealerAgent are dispatched via the Task tool with parseable JSON output blocks
- **Progress is committed** — progress.txt and PRD.md included in every commit
- **Progress is concise** — sacrifice grammar for concision, future iterations skip exploration

## Loop Skill (`/pilot:loop` + `pilot-loop.sh`)

The skill validates readiness and launches the script:

1. Confirm PRD.md and pilot.yaml exist
2. Confirm feedback loops work (dry run)
3. Ask for iteration cap (default from config)
4. Ask: Docker sandbox? (recommended for autonomous)
5. Launch the shared `pilot-loop.sh` from plugin `scripts/` directory

### Script

See [`scripts/pilot-loop.sh`](../scripts/pilot-loop.sh) for the canonical version. Key features:
- Iteration cap with machine-readable `PILOT_RESULT=...` markers and `<promise>COMPLETE</promise>` completion detection
- Auto-stash of uncommitted changes with exact-stash restoration on exit
- Guardrails instructions in the agent prompt (protected paths, rollback on failure)
- Prompt override cleanup only when the launch owns the override file
- Optional `--sandbox` flag for Docker isolation

## Config File (`.claude/pilot.yaml`)

Generated by `/pilot:plan`, never hand-authored:

```yaml
# Auto-generated by /pilot:plan — edit if needed
project:
  name: my-project
  stack: typescript, next.js, vitest
  detected: 2026-03-06

source:
  type: local                    # local | github | both
  github:
    repo: null                   # owner/repo
    labels: []                   # filter by labels
    milestone: null              # filter by milestone

feedback:
  typecheck: tsc --noEmit
  test: vitest run
  lint: biome check .
  browser: null                  # e.g., "npx playwright test"
  custom: []                     # arbitrary commands

gaps:
  - browser: "No browser tests. UI tasks rely on typecheck + lint only."

loop:
  type: feature                  # feature | test-coverage | lint-fix | refactor | issues
  output: commit                 # commit (default) | pr (branch + PR per task)
  iterations: 20                 # max iterations for loop mode
  sandbox: true                  # use Docker sandbox for loop mode
  retries: 3                     # max fix attempts per feedback loop
  notes: null                    # optional durable loop guidance

guardrails:
  protected_paths:
    - ".env*"
    - "*.pem"
    - "*.key"
    - "migrations/"

observability:
  verbosity: light              # light | medium

quality:
  bar: production                # prototype | production | library
  notes: "Follow existing patterns. No any types. Tests for new functions."
```

## Progress File Format

Keep entries concise. Sacrifice grammar for the sake of concision. This file helps future iterations skip exploration.

Committed to the repo after each iteration — it belongs in git history so future iterations and humans can trace what happened.

```markdown
## 1 — PRD #1: Set up Vitest with jsdom
time: 2026-03-06 14:32
files: vitest.config.ts, src/__tests__/smoke.test.ts, package.json
decisions: jsdom over happy-dom, Next.js compat
feedback: typecheck ✓ test ✓ lint ✓
commit: a1b2c3d

## 2 — PRD #3: Add user authentication endpoint
time: 2026-03-06 15:01
files: src/api/auth.ts, src/api/auth.test.ts, src/middleware/session.ts
decisions: JWT over sessions, stateless for edge runtime
feedback: typecheck ✓ test ✓ lint ✓
commit: d4e5f6g
```

For failures:
```markdown
## 3 — PRD #4: Add rate limiting middleware
time: 2026-03-06 15:45
status: FAILED — test
error: vitest timeout on concurrent request test
attempted: increased timeout, simplified test, mocked timer
needs: human to review test design for race condition
stash: pilot/failed-task-3: Add rate limiting middleware
```

**Cleanup:** Delete `progress.txt` after the sprint is done. It's session-specific context, not permanent documentation.

## Output Modes

Configured via `loop.output` in pilot.yaml:

| Mode | Behavior |
|------|----------|
| `commit` (default) | Commit directly to current branch after each task |
| `pr` | Create a branch (`pilot/task-N`) and open a PR per task via `gh pr create` |

PR mode is useful for teams with review processes — PILOT triages, implements, and opens the PR. You review when ready.

When `output: pr`, the commit step becomes:
1. `git checkout -b pilot/task-N-[short-description]`
2. Commit changes (including progress.txt and PRD.md)
3. `git push -u origin pilot/task-N-[short-description]`
4. `gh pr create --title "[type]: [description]" --body "PILOT automated PR for PRD #N"`
5. `git checkout [original branch]` — return for next task

## Guardrails

Safety features that make loop mode safe to run unsupervised.

| Guardrail | Where | Behavior |
|-----------|-------|----------|
| Protected paths | `pilot.yaml` + run/loop skills | Auto-detected during `/pilot:plan`. Hard-blocked in loop mode, prompted in manual mode. |
| Auto-stash | `pilot-loop.sh` | Stashes uncommitted work before loop starts, restores that exact stash on exit via bash trap. |
| Rollback on failure | `/pilot:run` skill | Failed attempts stashed as `pilot/failed-task-N` for human review. Working tree stays clean. |

## Observability

Transparency features so you know what happened during a loop run.

| Feature | Where | Details |
|---------|-------|---------|
| Summary report | `pilot-loop.sh` → `pilot-report.md` + terminal | Task count, diff stats, decisions, git diff commands. Generated on loop exit. |
| Decision verbosity | `pilot.yaml` + `--verbose` flag | `light` (default, one-liner) or `medium` (2-3 sentences). CLI overrides config. |
| Diff visualization | `pilot-report.md` | Per-task `git diff --stat` + copy-paste commands for full diffs. |

`pilot-report.md` is ephemeral — overwritten each loop run, not committed to git.

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

## Run-Phase Agents

`/pilot:run` dispatches specialized agents for implementation, review, and failure recovery.

| Agent | Persona | Purpose |
|-------|---------|---------|
| ImplementerAgent | Senior developer | Implements the task — code + tests, states approach, self-reviews |
| ReviewerAgent | Tech lead | Reviews spec compliance + codebase fit before feedback loops |
| HealerAgent | Senior debugger | Diagnoses feedback loop failures, applies targeted fixes |

Execution flow:
1. ImplementerAgent codes the task
2. ReviewerAgent verifies spec + codebase fit (max 2 rounds)
3. Feedback loops run (typecheck, test, lint, browser)
4. On failure: HealerAgent attempt 1 → attempt 2 → fresh ImplementerAgent rethink → escalate to human

Agent prompts live in `skills/run/agents/`.

## Proof of Work

Every PILOT commit carries structured evidence in the commit body:

```
[type]: [short description]

PILOT Task #[N] — [description]
Acceptance: [criteria] ✓

Approach: [what was done]
Considered: [alternatives rejected]

Files: [N] changed, +[added]/-[removed]
Feedback: typecheck ✓  test ✓  lint ✓
Reviewed: spec ✓  codebase-fit ✓
```

Assembled by the orchestrator from ImplementerAgent (approach, alternatives) + ReviewerAgent (findings) + feedback loop results. `git log` tells the full story.

## Recipe Skills

Beyond the core `plan`/`run`/`loop` workflow, PILOT ships 11 recipe skills — each a self-executing specialized loop. Recipe skills write an ephemeral prompt override, launch the shared plugin loop with `PILOT_PROMPT_OWNED=true`, and rely on shared cleanup:

| Skill | Command | What It Does |
|-------|---------|-------------|
| Coverage | `/pilot:coverage` | Write tests for uncovered code paths |
| Lint Fix | `/pilot:lint-fix` | Fix lint violations one by one |
| Duplication | `/pilot:duplication` | Find code clones, refactor into shared utilities |
| Entropy | `/pilot:entropy` | Clean up code smells and dead code |
| Deps | `/pilot:deps` | Update outdated dependencies one at a time |
| Types | `/pilot:types` | Remove `any` types, tighten TypeScript strictness |
| Docs | `/pilot:docs` | Generate JSDoc/docstrings for public APIs |
| Migrate | `/pilot:migrate` | Apply pattern migration across files |
| A11y | `/pilot:a11y` | Fix accessibility violations |
| Security | `/pilot:security` | Find and fix security vulnerabilities |
| Triage | `/pilot:triage` | Process GitHub issues into branches and PRs |

Each recipe is a self-executing SKILL.md: validate prerequisites → optional setup → write owned prompt override → confirm with user → launch shared loop → owned cleanup. See `docs/recipes.md` for details and a guide to writing custom recipes.

## Manual vs Autonomous Guidance

- **Start manual** — run `/pilot:run` 5-10 times to refine the PRD and verify feedback loops catch issues
- **Graduate to autonomous** — once confident the loops work, use `/pilot:loop` for bulk execution
- **Risky tasks stay manual** — architecture, design, integration points
- **Routine tasks go autonomous** — bug fixes, refactors, test coverage, lint fixes

## v0.2 Roadmap

- **npx CLI installer** — `npx @crisner1978/pilot init` to install skills from any terminal without being inside Claude Code
- **Custom recipe authoring** — `/pilot:recipe create` to scaffold a new recipe skill from a template
- **Parallel worktree execution** — run independent tasks in separate git worktrees simultaneously

## Key Principles (from RALPH)

1. **Feedback loops are non-negotiable** — they block low-quality code propagation
2. **Small steps over speed** — one task per iteration, context rot is real
3. **Progress tracking eliminates re-exploration** — each iteration reuses prior context
4. **Scope explicitness prevents shortcuts** — vague requirements lead to premature completion
5. **Codebase quality sets the ceiling** — agents amplify existing patterns, good and bad
