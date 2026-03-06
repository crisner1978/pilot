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
│   ├── plan/SKILL.md               # /pilot:plan — interactive setup
│   ├── once/SKILL.md               # /pilot:once — HITL, one task
│   └── afk/SKILL.md                # /pilot:afk — autonomous loop
├── scripts/
│   └── afk-loop.sh                 # bash loop template
└── README.md
```

**Installation:**
```bash
# Add marketplace (one time)
/plugin marketplace add github:crisner1978/pilot

# Install
/plugin install pilot
```

**Usage:** `/pilot:plan`, `/pilot:once`, `/pilot:afk`

## Goals

- **Portable CLI-first** — works in any codebase with just Claude Code CLI + bash, no platform dependency
- **Zero-config start** — auto-detects toolchain, generates config through questions, never requires manual authoring
- **Pluggable task sources** — local PRD files, GitHub Issues, or both, with adapter interface for others
- **Context-driven feedback** — auto-detects available tools, recommends and bootstraps missing ones
- **Two modes** — HITL (one task, human watches) and AFK (autonomous loop with iteration cap)

## System Architecture

### Components

| Component | Purpose | Mode |
|-----------|---------|------|
| `/pilot:plan` | Interactive setup — generates PRD + config from questions + auto-detection | HITL |
| `/pilot:once` | Execute one task from the PRD, commit, update progress | HITL |
| `/pilot:afk` | Validate readiness and launch the AFK loop script | AFK |
| `afk-loop.sh` | Bash loop calling `claude -p` with iteration cap + sentinel | AFK |

### File Convention

Files generated into the user's project:

```
.claude/
├── pilot.yaml             # Generated config (toolchain, sources, feedback loops)
PRD.md                     # Generated task backlog (checklist format)
progress.txt               # Append-only structured log of completed work
afk-loop.sh                # Pre-configured bash loop script
```

### Flow

```
/pilot:plan (interactive)
    ├── Asks: What are we building? Where are tasks? Quality bar?
    ├── Auto-detects: vitest, tsc, eslint, biome, playwright, jest, pytest...
    ├── Gap analysis: identifies missing feedback loops, web searches for best tool
    ├── Recommends: "No linter — Biome recommended for this stack. Add setup to PRD?"
    ├── Generates: PRD.md + .claude/pilot.yaml + progress.txt + afk-loop.sh
    └── Verifies: feedback loops actually run (dry run)

/pilot:once (one task)
    ├── Reads: PRD.md + progress.txt + pilot.yaml
    ├── Picks highest-priority incomplete task
    ├── Implements it
    ├── Runs feedback loops (typecheck → test → lint → browser → custom)
    ├── Commits only if all pass (retries up to 3x, then escalates)
    └── Appends structured entry to progress.txt

/pilot:afk (autonomous)
    ├── Validates PRD.md and pilot.yaml exist
    ├── Dry-runs feedback loops
    ├── Confirms iteration cap and sandbox preference
    └── Launches afk-loop.sh
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
- `afk-loop.sh` — pre-configured with iteration cap from config

### Phase 5 — Readiness Check

- Verify feedback loops actually run (e.g., `vitest run` doesn't error on empty suite)
- Flag any issues before the first iteration starts

## Execution Skill (`/pilot:once`)

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
  Yes → output <promise>COMPLETE</promise>
  No  → done, human decides whether to run again
```

Key behaviors:

- **One task per invocation** — prevents context rot
- **Feedback loops are blocking** — no commit without green
- **Retry is bounded** — 3 attempts to fix a failing loop, then escalate to human
- **Progress is committed** — progress.txt and PRD.md included in every commit
- **Progress is concise** — sacrifice grammar for concision, future iterations skip exploration

## AFK Loop (`/pilot:afk` + `afk-loop.sh`)

The skill validates readiness and launches the script:

1. Confirm PRD.md and pilot.yaml exist
2. Confirm feedback loops work (dry run)
3. Ask for iteration cap (default from config)
4. Ask: Docker sandbox? (recommended for AFK)
5. Launch `afk-loop.sh`

### Script

```bash
#!/bin/bash
set -e

ITERATIONS=${1:-20}

for ((i=1; i<=$ITERATIONS; i++)); do
  echo "=== PILOT Iteration $i/$ITERATIONS ==="

  result=$(claude -p "@PRD.md @progress.txt @.claude/pilot.yaml \
    Read the PRD, progress, and pilot config. \
    Pick the highest-priority incomplete task. \
    Implement it. Run all feedback loops from pilot.yaml. \
    Only commit if all pass. Update progress.txt. \
    If all tasks complete, output <promise>COMPLETE</promise>.")

  echo "$result"

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PILOT complete after $i iterations."
    exit 0
  fi
done

echo "Reached iteration cap ($ITERATIONS). Review progress.txt."
```

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
  iterations: 20                 # max iterations for AFK
  sandbox: true                  # use Docker sandbox for AFK
  retries: 3                     # max fix attempts per feedback loop

quality:
  bar: production                # prototype | production | library
  notes: "Follow existing patterns. No any types. Tests for new functions."
```

## Progress File Format

Keep entries concise. Sacrifice grammar for the sake of concision. This file helps future iterations skip exploration.

Committed to the repo after each iteration — it belongs in git history so future iterations and humans can trace what happened.

```markdown
## 1 — PRD #1: Set up Vitest with jsdom
files: vitest.config.ts, src/__tests__/smoke.test.ts, package.json
decisions: jsdom over happy-dom, Next.js compat
feedback: typecheck ✓ test ✓ lint ✓
commit: a1b2c3d

## 2 — PRD #3: Add user authentication endpoint
files: src/api/auth.ts, src/api/auth.test.ts, src/middleware/session.ts
decisions: JWT over sessions, stateless for edge runtime
feedback: typecheck ✓ test ✓ lint ✓
commit: d4e5f6g
```

For failures:
```markdown
## 3 — PRD #4: Add rate limiting middleware
status: FAILED — test
error: vitest timeout on concurrent request test
attempted: increased timeout, simplified test, mocked timer
needs: human to review test design for race condition
```

**Cleanup:** Delete `progress.txt` after the sprint is done. It's session-specific context, not permanent documentation.

## Alternative Loop Types

Configured via `loop.type` in pilot.yaml:

| Loop Type | Task Source | Feedback |
|-----------|-----------|----------|
| `feature` | PRD checklist | typecheck + test + lint |
| `test-coverage` | Uncovered lines (lcov) | coverage threshold |
| `lint-fix` | Lint violations | lint passes |
| `refactor` | Code duplication (jscpd) | duplication score |
| `issues` | GitHub Issues | typecheck + test + lint |

## HITL vs AFK Guidance

- **Start with HITL** — run `/pilot:once` 5-10 times to refine the PRD and verify feedback loops catch issues
- **Graduate to AFK** — once confident the loops work, use `/pilot:afk` for bulk execution
- **Risky tasks stay HITL** — architecture, design, integration points
- **Routine tasks go AFK** — bug fixes, refactors, test coverage, lint fixes

## Key Principles (from RALPH)

1. **Feedback loops are non-negotiable** — they block low-quality code propagation
2. **Small steps over speed** — one task per iteration, context rot is real
3. **Progress tracking eliminates re-exploration** — each iteration reuses prior context
4. **Scope explicitness prevents shortcuts** — vague requirements lead to premature completion
5. **Codebase quality sets the ceiling** — agents amplify existing patterns, good and bad
