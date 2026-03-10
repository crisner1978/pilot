# Self-Healing — Design

**Date:** 2026-03-10
**Status:** Approved
**Goal:** Replace blind retries with specialized agents that diagnose, fix, and rethink — plus a reviewer that catches issues before feedback loops run.

## Architecture

`/pilot:run` becomes an orchestrator dispatching run-phase agents. Applies to both manual and loop mode — one code path.

```
ImplementerAgent (codes the task)
  → ReviewerAgent (spec + codebase fit check)
  → Feedback loops (typecheck, test, lint, etc.)
  → Pass? → Orchestrator builds commit → Commit
  → Fail? → HealerAgent attempt 1 (targeted fix from error)
           → Feedback loops
  → Fail? → HealerAgent attempt 2 (different approach)
           → Feedback loops
  → Fail? → Fresh ImplementerAgent attempt 3 (rethink with failure context)
           → ReviewerAgent → Feedback loops
  → Fail? → Stash + escalate to human
```

## Agents

### ImplementerAgent

**Persona:** Senior developer implementing a well-scoped feature.

**System prompt traits:**
- Read before writing — understand existing patterns
- Follow codebase conventions from ScoutAgent context
- Write tests alongside implementation
- State approach before coding (what files, what pattern, key decisions)
- Self-review before handing off

**Input:**
- Task description + acceptance criteria + context hints
- Codebase context (from ScoutAgent, stored in pilot.yaml `codebase:`)
- Quality bar setting
- Previous failure context (attempt 3 only): "Attempts 1-2 tried X and Y. Both failed because Z."

**Output:**
- Code changes + tests
- Approach summary (what was done, what was considered, key decisions)
- Files changed list

**File:** `skills/run/agents/implementer.md`

### ReviewerAgent

**Persona:** Tech lead reviewing a pull request.

**Purpose:** Catch issues before feedback loops run. Two checks:

1. **Spec compliance** — does the code satisfy the acceptance criteria? Missing anything? Over-built anything?
2. **Codebase fit** — does it follow the patterns, naming, and conventions identified by ScoutAgent?

**Input:**
- Diff (code changes from ImplementerAgent)
- Acceptance criteria from PRD task
- Codebase context (patterns, conventions, key files, anti-patterns)

**Output:**
- Pass/fail for spec compliance
- Pass/fail for codebase fit
- List of issues (if any) with file:line references
- Findings summary (for proof of work commit message)

**Behavior on failure:**
- Issues go back to ImplementerAgent (same subagent) for fixes
- ReviewerAgent re-reviews after fixes
- Loop until pass or 2 review rounds (then proceed to feedback loops anyway — don't block forever on review)

**File:** `skills/run/agents/reviewer.md`

### HealerAgent

**Persona:** Senior debugger diagnosing a test/build failure.

**Purpose:** When a feedback loop fails, analyze the error and apply a targeted fix instead of blind retry.

**System prompt traits:**
- Read the full error output carefully
- Trace the error back to root cause
- Apply minimal fix — don't rewrite the implementation
- If the error suggests a fundamental approach problem, say so (attempt 2)
- One fix at a time — don't change multiple things

**Input:**
- Error output (stderr/stdout from failed feedback loop command)
- Diff (current code changes)
- Acceptance criteria
- Codebase context
- Which feedback loop failed (typecheck, test, lint, etc.)
- Attempt number (1 or 2)

**Output:**
- Targeted fix (code changes)
- Diagnosis summary (what went wrong, why, what was fixed)

**Escalation rules:**
- Attempt 1: targeted fix based on error analysis
- Attempt 2: if same loop fails again, try a different approach to the fix
- After attempt 2: hand off to fresh ImplementerAgent (attempt 3) with context: "Attempts 1-2 tried X and Y. Both failed because Z. Try a different approach entirely."
- After attempt 3: stash + escalate to human (existing behavior)

Maps to existing `retries: 3` config — same budget, smarter allocation.

**File:** `skills/run/agents/healer.md`

## Agent File Structure

```
skills/run/
├── SKILL.md              # orchestrator — dispatches agents, manages flow
└── agents/
    ├── implementer.md    # codes the task
    ├── reviewer.md       # spec + codebase fit review
    └── healer.md         # diagnoses and fixes failures
```

## Changes Required

| File | Change |
|------|--------|
| `skills/run/agents/implementer.md` | NEW — ImplementerAgent system prompt |
| `skills/run/agents/reviewer.md` | NEW — ReviewerAgent system prompt |
| `skills/run/agents/healer.md` | NEW — HealerAgent system prompt |
| `skills/run/SKILL.md` | Refactor into orchestrator — dispatch agents, manage retry chain |
| `scripts/pilot-loop.sh` | Update prompt to reference agent-based execution |
| `docs/design.md` | Add run-phase agents section |

## Not Included (deferred)

- **Model selection per agent** — v1 inherits parent model
- **Parallel implementation** — agents run sequentially per task (parallel is cross-task, handled by worktrees)
