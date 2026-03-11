---
name: lint-fix
description: Use when fixing lint errors, resolving linting violations, or cleaning up code style issues iteratively. Triggers on lint failures, ESLint errors, Biome violations.
---

# PILOT Lint Fix — Linting Loop

Fix lint violations one by one with verification between each fix.

**Announce at start:** "Running PILOT lint fix loop."

## Arguments

Optional scope: `/pilot:lint-fix [path]`

- **No arguments** — fixes all lint errors across codebase
- **File** — fix one file: `/pilot:lint-fix src/api/auth.ts`
- **Directory** — scope to directory: `/pilot:lint-fix src/components/`

## Execution

### 1. Validate Prerequisites

Check that these exist:
- `.claude/pilot.yaml` — must exist. If missing: "Run `/pilot:plan` first."
- `feedback.lint` must be set in pilot.yaml

Ensure `progress.txt` exists (create empty if not).

### 2. Create Owned Prompt Override

Parse arguments to determine SCOPE, then create an ephemeral prompt override. Use the Write tool to create `.claude/pilot-prompt.md` with this content (replacing SCOPE with actual value):

```
@progress.txt @.claude/pilot.yaml
You are PILOT running a lint fix loop.
SCOPE: [resolved scope — path or "entire codebase"]

Use the shared `/pilot:run` execution contract for implementation, review, feedback loops, heal/retry/escalate behavior, commit handling, progress logging, and top-level `PILOT_RESULT=...` output.

1. Run the lint command from pilot.yaml, scoped to SCOPE if provided.
2. Pick ONE lint error within SCOPE — prioritize errors over warnings.
3. Fix it with the minimal change needed.
4. Run lint again to verify the fix didn't introduce new errors.
5. If no lint errors remain, emit PILOT_RESULT=done and <promise>COMPLETE</promise>.

ONE fix per iteration. Do not batch fixes.
```

### 3. Confirm and Launch

Use AskUserQuestion to confirm:

```json
{
  "questions": [{
    "question": "Launch lint fix loop?\n  Scope: [scope]\n  Linter: [from pilot.yaml]",
    "header": "Lint fix",
    "options": [
      {"label": "Launch (Recommended)", "description": "Start lint fix loop"},
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

Because the launch sets `PILOT_PROMPT_OWNED=true`, the shared loop deletes only the override created for this run. Report how many lint errors were fixed.
