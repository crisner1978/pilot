---
name: duplication
description: Use when reducing code duplication, finding copy-pasted code, or refactoring clones into shared utilities. Triggers on DRY violations, jscpd, code clones.
---

# PILOT Duplication — Code Clone Cleanup

Find duplicate code and refactor into shared utilities.

**Announce at start:** "Running PILOT duplication cleanup loop."

## Arguments

Optional scope: `/pilot:duplication [path]`

- **No arguments** — scans entire codebase
- **Directory** — scope to directory: `/pilot:duplication src/`

## Execution

### 1. Validate Prerequisites

Check that these exist:
- `.claude/pilot.yaml` — must exist. If missing: "Run `/pilot:plan` first."
- `jscpd` — must be installed: `npm i -D jscpd`

Ensure `progress.txt` exists (create empty if not).

### 2. Write Ephemeral Prompt

Parse arguments to determine SCOPE, then write the prompt file. Use the Write tool to create `.claude/pilot-prompt.md` with this content (replacing SCOPE with actual value):

```
@progress.txt @.claude/pilot.yaml
You are PILOT running a duplication cleanup loop.
SCOPE: [resolved scope — path or "entire codebase"]

1. Run: npx jscpd --min-lines 5 --min-tokens 50 --reporters console SCOPE
2. Pick the highest-impact duplicate (most lines, most copies).
3. Refactor into a shared utility — extract function, module, or component.
4. Update all call sites to use the shared utility.
5. Run all feedback loops from pilot.yaml.
6. Commit if all pass. Include progress.txt.
7. Append to progress.txt: what was duplicated, where, new shared location.
8. If no significant duplicates remain in SCOPE, output <promise>COMPLETE</promise>.

ONE refactor per iteration.
```

### 3. Confirm and Launch

Use AskUserQuestion to confirm:

```json
{
  "questions": [{
    "question": "Launch duplication cleanup loop?\n  Scope: [scope]",
    "header": "Duplication",
    "options": [
      {"label": "Launch (Recommended)", "description": "Start duplication cleanup loop"},
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

`pilot-loop.sh` auto-deletes `.claude/pilot-prompt.md` on exit. Report duplications resolved.
