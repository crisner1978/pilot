---
name: entropy
description: Use when cleaning up code smells, removing dead code, fixing inconsistent patterns, or reducing technical debt. Triggers on code smell, dead code, unused exports, tech debt.
---

# PILOT Entropy — Code Smell Cleanup

Software entropy in reverse. Scan for code smells and clean them up one at a time.

## Arguments

Optional scope: `/pilot:entropy [path]`

- **No arguments** — scans entire codebase
- **Directory** — scope to directory: `/pilot:entropy src/legacy/`

## Prerequisites

| Prerequisite | Check |
|---|---|
| pilot.yaml | `.claude/pilot.yaml` must exist — run `/pilot:plan` first |

## How It Works

Scans for one code smell per iteration: unused exports, dead code, inconsistent naming, orphaned files, deprecated API usage. Fixes it, verifies with feedback loops, and repeats.

## The Prompt

```
@progress.txt @.claude/pilot.yaml
You are PILOT running an entropy cleanup loop.

1. Scan the codebase for ONE code smell:
   - Unused exports or imports
   - Dead code (unreachable, commented out)
   - Inconsistent naming patterns
   - Orphaned files (not imported anywhere)
   - Deprecated API usage
   - Unnecessary type assertions or casts
2. Fix it with the minimal change needed.
3. Run all feedback loops from pilot.yaml.
4. Commit if all pass. Include progress.txt.
5. Append to progress.txt: smell type, file, what was cleaned.
6. If the codebase is clean, output <promise>COMPLETE</promise>.

ONE smell per iteration. Don't scope-creep into refactoring.
```

## Launch

```bash
./pilot-loop.sh 30
```
