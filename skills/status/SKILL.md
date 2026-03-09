---
name: status
description: Use when checking PILOT progress, reviewing what happened during a loop run, or getting a quick pulse on the current sprint. Triggers on status check, progress review, what happened, sprint overview.
---

# PILOT Status — Sprint Dashboard

Quick pulse check on your PILOT sprint without reading multiple files.

**Announce at start:** "Checking PILOT status."

## Prerequisites

At least one of these must exist:
- `PRD.md` — task backlog
- `progress.txt` — iteration log
- `.claude/pilot.yaml` — config

If none exist: "No PILOT session found. Run `/pilot:plan` to set up."

## What to Report

Read all three files and present a single dashboard:

```
PILOT Status
═══════════════════════════════════════

PRD:        5/12 tasks complete
Next:       #6 — Add auth middleware
Quality:    production

Last run:   #5 — Add user model
            ✓ committed (a1b2c3d) — 2026-03-09 14:32
            files: src/models/user.ts, src/models/user.test.ts

Feedback:   typecheck ✓  test ✓  lint ✓  browser —

Blockers:   none
```

### Reading PRD.md

- Count unchecked (`- [ ]`) and checked (`- [x]`) tasks
- Identify the next unchecked task (first one)
- If all complete: "All tasks complete! Nothing remaining."

### Reading progress.txt

- Find the most recent entry (last `##` section)
- Extract: task description, status (committed or failed), commit hash, timestamp, files changed
- If the last entry was a failure, highlight it prominently:

```
⚠ Last run FAILED:
  #4 — Add rate limiting middleware
  Failed: test — vitest timeout on concurrent request test
  Needs: human to review test design for race condition
```

### Reading pilot.yaml

- Report quality bar
- Report configured feedback loops
- Report any gaps

## After Reporting

Use AskUserQuestion to offer next actions:

```json
{
  "questions": [{
    "question": "What would you like to do?",
    "header": "Next",
    "options": [
      {"label": "/pilot:run", "description": "Execute the next task manually"},
      {"label": "/pilot:loop", "description": "Launch autonomous loop for remaining tasks"},
      {"label": "/pilot:add", "description": "Add a new task to the PRD"},
      {"label": "Done", "description": "Just checking — no action needed"}
    ],
    "multiSelect": false
  }]
}
```

If the user selects a skill, invoke it.
