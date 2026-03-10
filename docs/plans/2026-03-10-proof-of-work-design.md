# Proof of Work — Design

**Date:** 2026-03-10
**Status:** Approved
**Goal:** Every PILOT commit carries structured evidence of what was done, validated, and considered — making `git log` alone tell the full story.

## Commit Message Format

```
[type]: [short description]

PILOT Task #[N] — [task description]
Acceptance: [criteria] ✓

Approach: [what was done, what pattern/library used]
Considered: [alternatives rejected and why]

Files: [N] changed, +[added]/-[removed]
  [file1] (new|modified|deleted)
  [file2] (new|modified|deleted)

Feedback: typecheck ✓  test ✓  lint ✓
Reviewed: spec ✓  codebase-fit ✓
```

### Verbose Mode (--verbose)

When verbose is enabled, the `Reviewed:` line includes findings:

```
Reviewed: spec ✓ (fixed: missing 401 status code)  codebase-fit ✓ (fixed: used class instead of function pattern)
```

### Failure Commits (progress.txt only)

Failed tasks don't get committed, but their progress.txt entry includes proof of work:

```
## [N] — PRD #[N]: [Task description]
time: YYYY-MM-DD HH:MM
status: FAILED — [which loop]
approach: [what was attempted]
healer: [attempt 1 diagnosis], [attempt 2 diagnosis]
rethink: [attempt 3 approach if reached]
error: [final error]
stash: pilot/failed-task-[N]: [description]
```

## Assembly

The orchestrator (`/pilot:run` SKILL.md) assembles the commit message from agent outputs:

| Field | Source |
|-------|--------|
| Type + description | ImplementerAgent approach summary |
| Task + acceptance | PRD.md task entry |
| Approach + considered | ImplementerAgent approach summary |
| Files | Git diff --stat |
| Feedback | Feedback loop results (pass/fail per loop) |
| Reviewed | ReviewerAgent findings summary |

No single agent produces the full message — the orchestrator templates it from all outputs.

## Changes Required

| File | Change |
|------|--------|
| `skills/run/SKILL.md` | Update commit step to assemble proof of work message |
| `skills/run/agents/implementer.md` | Ensure output includes approach + considered alternatives |
| `skills/run/agents/reviewer.md` | Ensure output includes findings summary |
| `docs/design.md` | Add proof of work section, update commit format |

## Notes

- Proof of work makes `progress.txt` partially redundant for successful tasks — but progress.txt stays as the append-only log for the loop (it's read at the start of each iteration)
- Commit messages should stay under ~30 lines — enough to be informative, not so long they're ignored
- `git log --oneline` still shows the conventional commit first line
- `git log` shows the full proof of work
