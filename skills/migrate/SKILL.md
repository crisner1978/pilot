---
name: migrate
description: Use when migrating code patterns across a codebase, converting class components to hooks, CommonJS to ESM, or applying any systematic code transformation. Triggers on migration, codemod, pattern conversion.
---

# PILOT Migrate — Pattern Migration Loop

Apply a systematic code migration across a codebase, one file at a time.

**Announce at start:** "Running PILOT pattern migration loop."

## Arguments

Optional scope: `/pilot:migrate [path]`

- **No arguments** — migrates across entire codebase
- **Directory** — scope to directory: `/pilot:migrate src/components/`

## Execution

### 1. Validate Prerequisites

Check that these exist:
- `.claude/pilot.yaml` — must exist. If missing: "Run `/pilot:plan` first."
- `MIGRATION.md` — must exist in project root with before/after code examples

If `MIGRATION.md` is missing, tell the user: "Create a `MIGRATION.md` with before/after code examples. Use the template at `assets/migration-template.md`."

Ensure `progress.txt` exists (create empty if not).

### 2. Write Ephemeral Prompt

Parse arguments to determine SCOPE, then write the prompt file. Use the Write tool to create `.claude/pilot-prompt.md` with this content (replacing SCOPE with actual value):

```
@MIGRATION.md @progress.txt @.claude/pilot.yaml
You are PILOT running a pattern migration loop.
SCOPE: [resolved scope — path or "entire codebase"]

1. Read MIGRATION.md for the before/after pattern.
2. Find ONE file still using the old pattern within SCOPE.
3. Migrate it to the new pattern following the rules in MIGRATION.md.
4. Run all feedback loops from pilot.yaml.
5. Commit if all pass. Include progress.txt.
6. Append to progress.txt: file migrated, any edge cases encountered.
7. If no files use the old pattern in SCOPE, output <promise>COMPLETE</promise>.

ONE file per iteration. Follow MIGRATION.md exactly.
```

### 3. Confirm and Launch

Use AskUserQuestion to confirm:

```json
{
  "questions": [{
    "question": "Launch pattern migration loop?\n  Scope: [scope]\n  Migration: [summary from MIGRATION.md]",
    "header": "Migrate",
    "options": [
      {"label": "Launch (Recommended)", "description": "Start migration loop"},
      {"label": "Cancel", "description": "Don't launch"}
    ],
    "multiSelect": false
  }]
}
```

After confirmation, launch the loop:

```bash
PILOT_LOOP="${CLAUDE_SKILL_DIR}/../../scripts/pilot-loop.sh"
bash "$PILOT_LOOP" 20
```

### 4. Results

`pilot-loop.sh` auto-deletes `.claude/pilot-prompt.md` on exit. Report files migrated.
