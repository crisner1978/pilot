---
name: types
description: Use when tightening TypeScript types, removing any types, adding type annotations, or improving type safety. Triggers on any types, type errors, type strictness, TypeScript migration.
---

# PILOT Types — Type Strictness Loop

Incrementally tighten TypeScript types across a codebase.

**Announce at start:** "Running PILOT type strictness loop."

## Arguments

Optional scope: `/pilot:types [path]`

- **No arguments** — searches entire codebase for `any` types
- **File path** — fix types in one file: `/pilot:types src/api/auth.ts`
- **Directory** — scope to directory: `/pilot:types src/api/`

## Execution

### 1. Validate Prerequisites

Check that these exist:
- `.claude/pilot.yaml` — must exist. If missing: "Run `/pilot:plan` first."
- `feedback.typecheck` must be set in pilot.yaml

Ensure `progress.txt` exists (create empty if not).

### 2. Create Owned Prompt Override

Parse arguments to determine SCOPE, then create an ephemeral prompt override. Use the Write tool to create `.claude/pilot-prompt.md` with this content (replacing SCOPE with actual value):

```
@progress.txt @.claude/pilot.yaml
You are PILOT running a type strictness loop.
SCOPE: [resolved scope — path or "entire codebase"]

Use the shared `/pilot:run` execution contract for implementation, review, feedback loops, heal/retry/escalate behavior, commit handling, progress logging, and top-level `PILOT_RESULT=...` output.

1. Search for files using `any` type or with type errors within SCOPE.
2. Pick ONE file — prioritize core business logic over utilities.
3. Replace `any` with proper types. Add missing type annotations.
4. Run typecheck (from pilot.yaml) to verify — must pass with no new errors.
5. If no `any` types or type errors remain in SCOPE, emit PILOT_RESULT=done and <promise>COMPLETE</promise>.

ONE file per iteration.
```

### 3. Confirm and Launch

Use AskUserQuestion to confirm:

```json
{
  "questions": [{
    "question": "Launch type strictness loop?\n  Scope: [scope]\n  Typecheck: [from pilot.yaml]",
    "header": "Types",
    "options": [
      {"label": "Launch (Recommended)", "description": "Start type strictness loop"},
      {"label": "Cancel", "description": "Don't launch"}
    ],
    "multiSelect": false
  }]
}
```

After confirmation, launch the loop:

```bash
PILOT_LOOP="${CLAUDE_SKILL_DIR}/../../scripts/pilot-loop.sh"
PILOT_PROMPT_OWNED=true bash "$PILOT_LOOP" 20
```

### 4. Results

Because the launch sets `PILOT_PROMPT_OWNED=true`, the shared loop deletes only the override created for this run. Report how many `any` types were removed.
