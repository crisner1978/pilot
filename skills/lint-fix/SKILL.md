---
name: lint-fix
description: Use when fixing lint errors, resolving linting violations, or cleaning up code style issues iteratively. Triggers on lint failures, ESLint errors, Biome violations.
---

# PILOT Lint Fix — Linting Loop

Fix lint violations one by one with verification between each fix.

## Arguments

Optional scope: `/pilot:lint-fix [path]`

- **No arguments** — fixes all lint errors across codebase
- **File** — fix one file: `/pilot:lint-fix src/api/auth.ts`
- **Directory** — scope to directory: `/pilot:lint-fix src/components/`

## Prerequisites

| Prerequisite | Check |
|---|---|
| pilot.yaml | `.claude/pilot.yaml` must exist — run `/pilot:plan` first |
| Linter configured | `feedback.lint` must be set in pilot.yaml |

## How It Works

Runs the linter, picks ONE error, fixes it, re-runs the linter to verify the fix didn't introduce new errors, commits, and repeats until clean.

## The Prompt

Replace the prompt in your `pilot-loop.sh` with:

```
@progress.txt @.claude/pilot.yaml
You are PILOT running a lint fix loop.
SCOPE: [if path provided, insert here; otherwise "entire codebase"]

1. Run the lint command from pilot.yaml, scoped to SCOPE if provided.
2. Pick ONE lint error within SCOPE — prioritize errors over warnings.
3. Fix it with the minimal change needed.
4. Run lint again to verify the fix didn't introduce new errors.
5. Run all other feedback loops from pilot.yaml.
6. Commit if all pass. Include progress.txt.
7. Append to progress.txt: rule violated, file, fix applied.
8. If no lint errors remain, output <promise>COMPLETE</promise>.

ONE fix per iteration. Do not batch fixes.
```

## Launch

```bash
# HITL
./pilot-loop.sh 1

# Autonomous — clean up all violations
./pilot-loop.sh 50
```
