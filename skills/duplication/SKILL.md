---
name: duplication
description: Use when reducing code duplication, finding copy-pasted code, or refactoring clones into shared utilities. Triggers on DRY violations, jscpd, code clones.
---

# PILOT Duplication — Code Clone Cleanup

Find duplicate code and refactor into shared utilities.

## Arguments

Optional scope: `/pilot:duplication [path]`

- **No arguments** — scans entire codebase
- **Directory** — scope to directory: `/pilot:duplication src/`

## Prerequisites

| Prerequisite | Check |
|---|---|
| pilot.yaml | `.claude/pilot.yaml` must exist — run `/pilot:plan` first |
| jscpd | Install: `npm i -D jscpd` |

## How It Works

Runs jscpd to find code clones, picks the highest-impact duplicate, refactors it into a shared utility, verifies with feedback loops, and repeats until duplication is minimal.

## The Prompt

```
@progress.txt @.claude/pilot.yaml
You are PILOT running a duplication cleanup loop.

1. Run: npx jscpd --min-lines 5 --min-tokens 50 --reporters console .
2. Pick the highest-impact duplicate (most lines, most copies).
3. Refactor into a shared utility — extract function, module, or component.
4. Update all call sites to use the shared utility.
5. Run all feedback loops from pilot.yaml.
6. Commit if all pass. Include progress.txt.
7. Append to progress.txt: what was duplicated, where, new shared location.
8. If no significant duplicates remain, output <promise>COMPLETE</promise>.

ONE refactor per iteration.
```

## Launch

```bash
./afk-loop.sh 20
```
