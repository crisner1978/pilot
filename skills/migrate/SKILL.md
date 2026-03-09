---
name: migrate
description: Use when migrating code patterns across a codebase, converting class components to hooks, CommonJS to ESM, or applying any systematic code transformation. Triggers on migration, codemod, pattern conversion.
---

# PILOT Migrate — Pattern Migration Loop

Apply a systematic code migration across a codebase, one file at a time.

## Arguments

Optional scope: `/pilot:migrate [path]`

- **No arguments** — migrates across entire codebase
- **Directory** — scope to directory: `/pilot:migrate src/components/`

## Prerequisites

| Prerequisite | Check |
|---|---|
| pilot.yaml | `.claude/pilot.yaml` must exist — run `/pilot:plan` first |
| MIGRATION.md | Create a `MIGRATION.md` with before/after code examples for your migration |

## Setup

Create a `MIGRATION.md` in the project root using the template at `assets/migration-template.md`. Fill in the before/after code examples and migration rules specific to your codebase.

## The Prompt

```
@MIGRATION.md @progress.txt @.claude/pilot.yaml
You are PILOT running a pattern migration loop.

1. Read MIGRATION.md for the before/after pattern.
2. Find ONE file still using the old pattern.
3. Migrate it to the new pattern following the rules in MIGRATION.md.
4. Run all feedback loops from pilot.yaml.
5. Commit if all pass. Include progress.txt.
6. Append to progress.txt: file migrated, any edge cases encountered.
7. If no files use the old pattern, output <promise>COMPLETE</promise>.

ONE file per iteration. Follow MIGRATION.md exactly.
```

## Launch

```bash
./afk-loop.sh 30
```
