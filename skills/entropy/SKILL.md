---
name: entropy
description: Use when cleaning up code smells, removing dead code, fixing inconsistent patterns, or reducing technical debt. Triggers on code smell, dead code, unused exports, tech debt.
---

# PILOT Entropy — Code Smell Cleanup

Software entropy in reverse. Scan for code smells and clean them up one at a time.

**Announce at start:** "Running PILOT entropy cleanup loop."

## Arguments

Optional scope: `/pilot:entropy [path]`

- **No arguments** — scans entire codebase
- **Directory** — scope to directory: `/pilot:entropy src/legacy/`

## Execution

### 1. Validate Prerequisites

Check that these exist:
- `.claude/pilot.yaml` — must exist. If missing: "Run `/pilot:plan` first."

Ensure `progress.txt` exists (create empty if not).

### 2. Write Ephemeral Prompt

Parse arguments to determine SCOPE, then write the prompt file. Use the Write tool to create `.claude/pilot-prompt.md` with this content (replacing SCOPE with actual value):

```
@progress.txt @.claude/pilot.yaml
You are PILOT running an entropy cleanup loop.
SCOPE: [resolved scope — path or "entire codebase"]

1. Scan the codebase within SCOPE for ONE code smell:
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
6. If no code smells remain in SCOPE, output <promise>COMPLETE</promise>.

ONE smell per iteration. Don't scope-creep into refactoring.
```

### 3. Confirm and Launch

Use AskUserQuestion to confirm:

```json
{
  "questions": [{
    "question": "Launch entropy cleanup loop?\n  Scope: [scope]",
    "header": "Entropy",
    "options": [
      {"label": "Launch (Recommended)", "description": "Start entropy cleanup loop"},
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

`pilot-loop.sh` auto-deletes `.claude/pilot-prompt.md` on exit. Report code smells cleaned.
