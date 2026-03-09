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

Run the validation script to check all prerequisites at once:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/validate-readiness.sh
```

If `${CLAUDE_SKILL_DIR}` is not available, perform the checks manually:

1. **Check files exist** — verify `PRD.md`, `.claude/pilot.yaml`, `progress.txt`, `afk-loop.sh` are all present
2. **Count remaining tasks** — read PRD.md, count unchecked (`- [ ]`) vs checked (`- [x]`) tasks. If all complete, nothing to run.
3. **Dry-run feedback loops** — run each configured command from pilot.yaml, report pass/fail for each

If any check fails, warn the user. Pre-existing failures will burn iterations — fix them before launching.

## Confirm Settings

After validation passes, present a summary and use AskUserQuestion to confirm:

"Ready to launch PILOT AFK mode:
- **Tasks remaining:** [N]
- **Iteration cap:** [from pilot.yaml, default 20]
- **Docker sandbox:** [from pilot.yaml, default recommended]
- **Feedback loops:** [list of configured loops]"

```json
{
  "questions": [
    {
      "question": "Launch AFK mode with these settings?",
      "header": "Launch",
      "options": [
        {"label": "Launch (Recommended)", "description": "Start autonomous loop with settings shown above"},
        {"label": "Change iterations", "description": "Override the iteration cap before launching"},
        {"label": "Cancel", "description": "Don't launch — return to manual mode"}
      ],
      "multiSelect": false
    },
    {
      "question": "Use Docker sandbox?",
      "header": "Sandbox",
      "options": [
        {"label": "Yes (Recommended)", "description": "Run in Docker sandbox — safer for unattended execution"},
        {"label": "No", "description": "Run directly on host — faster but less isolated"}
      ],
      "multiSelect": false
    }
  ]
}
```

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
