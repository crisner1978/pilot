---
name: docs
description: Use when generating API documentation, adding JSDoc comments, documenting public interfaces, or filling documentation gaps. Triggers on missing docs, JSDoc, docstrings, API documentation.
---

# PILOT Docs — API Documentation Loop

Generate or update API documentation from source code.

**Announce at start:** "Running PILOT documentation loop."

## Arguments

Optional scope: `/pilot:docs [path]`

- **No arguments** — documents all undocumented public APIs
- **File** — document one file: `/pilot:docs src/api/auth.ts`
- **Directory** — scope to directory: `/pilot:docs src/lib/`

## Execution

### 1. Validate Prerequisites

Check that these exist:
- `.claude/pilot.yaml` — must exist. If missing: "Run `/pilot:plan` first."

Ensure `progress.txt` exists (create empty if not).

### 2. Write Ephemeral Prompt

Parse arguments to determine SCOPE, then write the prompt file. Use the Write tool to create `.claude/pilot-prompt.md` with this content (replacing SCOPE with actual value):

```
@progress.txt @.claude/pilot.yaml
You are PILOT running a documentation loop.
SCOPE: [resolved scope — path or "entire codebase"]

1. Find ONE public function, class, method, or API endpoint missing documentation within SCOPE.
2. Prioritize: exported functions > public methods > internal utilities.
3. Write clear, concise JSDoc/docstring:
   - @param for each parameter with type and description
   - @returns with type and description
   - One usage example
   - @throws if applicable
4. Run all feedback loops from pilot.yaml.
5. Commit if all pass. Include progress.txt.
6. Append to progress.txt: function/class name, file.
7. If all public APIs in SCOPE are documented, output <promise>COMPLETE</promise>.

ONE function/class per iteration. Keep docs concise — not novels.
```

### 3. Confirm and Launch

Use AskUserQuestion to confirm:

```json
{
  "questions": [{
    "question": "Launch documentation loop?\n  Scope: [scope]",
    "header": "Docs",
    "options": [
      {"label": "Launch (Recommended)", "description": "Start documentation loop"},
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

`pilot-loop.sh` auto-deletes `.claude/pilot-prompt.md` on exit. Report functions/classes documented.
