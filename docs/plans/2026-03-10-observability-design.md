# Observability — Design

**Date:** 2026-03-10
**Status:** Approved
**Goal:** Make the loop transparent — know what happened, what decisions were made, and what changed while you were away.

## Features

### 1. Summary Report

Generated when `pilot-loop.sh` exits (success, cap reached, or interrupted).

**Two outputs:**
- **Terminal** — printed to stdout when the loop ends
- **File** — written to `pilot-report.md` in project root

**Report format:**
```
PILOT Report — YYYY-MM-DD
═══════════════════════════════════════
Iterations: [N] | Tasks: [done] done, [failed] failed, [skipped] skipped
Time: ~[minutes] minutes

#1 ✓ [description]        +[N] files  +[added]/-[removed]    [hash]
#2 ✓ [description]        +[N] files  +[added]/-[removed]    [hash]
#3 ✗ [description]         — FAILED ([which loop]: [reason])
     stash: pilot/failed-task-3
#4 ⊘ [description]         — SKIPPED (protected path)
#5 ✓ [description]        +[N] files  +[added]/-[removed]    [hash]

Decisions:
  #1: [one-liner from progress.txt decisions field]
  #2: [one-liner]

Full diff: git diff [start-hash]..[end-hash]
Per-task: git diff [hash]~1..[hash]
```

**Data sources:**
- Task list + status: `PRD.md` (checkboxes) + `progress.txt` (entries)
- Diff stats: `git diff --stat [hash]~1..[hash]` per committed task
- Decisions: `decisions:` field from `progress.txt`
- Timing: captured by `pilot-loop.sh` (start/end timestamps)

### 2. Decision Log Verbosity

Configurable verbosity for the `decisions:` field in `progress.txt`.

**Levels:**
- **`light`** (default) — one-liner: "JWT over sessions — edge runtime constraint"
- **`medium`** — 2-3 sentences: "Considered JWT and server sessions. Chose JWT because the app deploys to edge runtime which has no persistent state. Used existing jose library."

**Config** (`pilot.yaml`):
```yaml
observability:
  verbosity: light          # light | medium
```

**CLI override:**
```bash
./pilot-loop.sh 20 --verbose    # overrides to medium for this run
```

### 3. Diff Visualization

Per-task diff stats in the report — not full diffs (too large), but enough to see the shape of each change.

**Format:** `+[N] files  +[added]/-[removed]    [hash]`

**Drill-in command:** each task in the report includes a `git diff` command to see the full diff:
```
Per-task: git diff [hash]~1..[hash]
```

Full-run diff command also included:
```
Full diff: git diff [start-hash]..[end-hash]
```

### Not Included (deferred)

- **Notifications** (Slack, webhooks, desktop) — separate brainstorm, different problem domain

## Changes Required

| File | Change |
|------|--------|
| `scripts/pilot-loop.sh` | Capture start time, collect per-task results, generate report on exit |
| `skills/plan/assets/pilot-yaml-template.yaml` | Add `observability.verbosity` field |
| `skills/run/SKILL.md` | Reference verbosity config for decisions field |
| `skills/loop/SKILL.md` | Document report generation, verbosity flag |
| `docs/design.md` | Add observability section |

## Implementation Notes

- Report generation happens in `pilot-loop.sh` (bash) — it parses `progress.txt` and runs `git diff --stat` per commit hash found in entries
- The `--verbose` flag is passed through to the prompt so the agent knows to write medium-verbosity decisions
- `pilot-report.md` is overwritten each loop run (not append-only like progress.txt) — it's a snapshot of the latest run
- `pilot-report.md` should be added to `.gitignore` or treated as ephemeral — it's not committed
