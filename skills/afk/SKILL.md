---
name: afk
description: Use when launching an autonomous PILOT loop to execute multiple PRD tasks without human intervention. Triggers on AFK mode, autonomous execution, batch coding, unattended development.
---

# PILOT AFK — Autonomous Loop

Validate readiness and launch the autonomous execution loop.

**Announce at start:** "Preparing to launch PILOT in AFK mode."

## Prerequisites

Before launching AFK mode, ALL of these must be true:

| Check | How |
|-------|-----|
| PRD.md exists | Read `PRD.md` — must have unchecked tasks |
| pilot.yaml exists | Read `.claude/pilot.yaml` — must have feedback loops configured |
| progress.txt exists | Read `progress.txt` — should exist (even if empty) |
| afk-loop.sh exists | Check for `afk-loop.sh` in project root |
| Feedback loops work | Dry-run each command from pilot.yaml |

If any prerequisite fails, tell the user what's missing and suggest: "Run `/pilot:plan` to set up PILOT."

## Readiness Validation

### 1. Check Files Exist

```bash
test -f PRD.md && echo "PRD.md ✓" || echo "PRD.md ✗ — MISSING"
test -f .claude/pilot.yaml && echo "pilot.yaml ✓" || echo "pilot.yaml ✗ — MISSING"
test -f progress.txt && echo "progress.txt ✓" || echo "progress.txt ✗ — MISSING"
test -f afk-loop.sh && echo "afk-loop.sh ✓" || echo "afk-loop.sh ✗ — MISSING"
```

### 2. Count Remaining Tasks

Read PRD.md and count unchecked (`- [ ]`) vs checked (`- [x]`) tasks. Report:
```
PRD status: 3/10 tasks complete, 7 remaining
```

If all tasks are complete, there's nothing to do: "All PRD tasks are complete. Nothing to run."

### 3. Dry-Run Feedback Loops

Run each configured command from pilot.yaml. Report results:
```
Feedback loop dry-run:
  typecheck (tsc --noEmit): ✓ exit 0
  test (vitest run): ✓ exit 0
  lint (biome check .): ✗ exit 1 — 3 pre-existing violations
```

If any loop fails, warn: "Pre-existing failures will block every iteration. Fix these first, or AFK mode will burn iterations retrying."

### 4. Confirm Settings

Ask the user to confirm before launching:

"Ready to launch PILOT AFK mode:
- **Tasks remaining:** [N]
- **Iteration cap:** [from pilot.yaml, default 20]
- **Docker sandbox:** [from pilot.yaml, default recommended]
- **Feedback loops:** [list of configured loops]

Launch with these settings?"

Also ask:
- "Override iteration cap? (default: [N])"
- "Use Docker sandbox? (recommended for AFK, default: [yes/no from config])"

## Launch

After confirmation, provide the launch command:

```bash
# Standard launch
./afk-loop.sh [iterations]

# With Docker sandbox
./afk-loop.sh [iterations] --sandbox
```

Tell the user:
```
PILOT AFK mode launching.

Monitor:
  tail -f progress.txt        — watch iteration logs
  git log --oneline            — watch commits

Stop:
  Ctrl+C                       — stop after current iteration

The loop will stop automatically when:
  - All PRD tasks are complete
  - Iteration cap ([N]) is reached
```

## After Completion

When the user returns, suggest:
```
Welcome back! Review what PILOT did:

  cat progress.txt             — full iteration log
  git log --oneline            — commit history
  cat PRD.md                   — task completion status

If tasks remain, run /pilot:afk again or /pilot:once for HITL mode.

Cleanup (after sprint is done):
  rm progress.txt PRD.md afk-loop.sh .claude/pilot.yaml
  These are session-specific — not permanent documentation.
```

## Safety Notes

- **Always recommend Docker sandbox for AFK mode** — the agent has full file system access
- **Iteration cap is a safety net** — prevents runaway cost. 20 is a reasonable default for most PRDs
- **Pre-existing failures burn iterations** — fix them before launching
- **Review progress.txt after each AFK run** — verify the agent made good decisions
