---
name: types
description: Use when tightening TypeScript types, removing any types, adding type annotations, or improving type safety. Triggers on any types, type errors, type strictness, TypeScript migration.
---

# PILOT Types — Type Strictness Loop

Incrementally tighten TypeScript types across a codebase.

## Arguments

Optional scope: `/pilot:types [path]`

- **No arguments** — searches entire codebase for `any` types
- **File path** — fix types in one file: `/pilot:types src/api/auth.ts`
- **Directory** — scope to directory: `/pilot:types src/api/`

## Prerequisites

| Prerequisite | Check |
|---|---|
| pilot.yaml | `.claude/pilot.yaml` must exist — run `/pilot:plan` first |
| TypeScript | `feedback.typecheck` must be set in pilot.yaml |

## How It Works

Finds files with `any` types or type errors, fixes ONE file per iteration, verifies with typecheck and tests, and repeats until the codebase is strictly typed.

If arguments were provided, scope all operations to the specified path.

## The Prompt

```
@progress.txt @.claude/pilot.yaml
You are PILOT running a type strictness loop.
SCOPE: [if arguments provided, insert path here; otherwise "entire codebase"]

1. Search for files using `any` type or with type errors within SCOPE.
2. Pick ONE file — prioritize core business logic over utilities.
3. Replace `any` with proper types. Add missing type annotations.
4. Run typecheck (from pilot.yaml) to verify — must pass with no new errors.
5. Run all other feedback loops.
6. Commit if all pass. Include progress.txt.
7. Append to progress.txt: file, number of `any` removed, types added.
8. If no `any` types or type errors remain in SCOPE, output <promise>COMPLETE</promise>.

ONE file per iteration.
```

## Launch

```bash
# Whole codebase
./afk-loop.sh 30

# Scoped to a directory
# Edit the SCOPE line in afk-loop.sh prompt to: src/api/
./afk-loop.sh 10
```
