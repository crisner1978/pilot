---
name: deps
description: Use when updating outdated dependencies, upgrading packages, or patching security vulnerabilities in dependencies. Triggers on npm outdated, dependency update, package upgrade.
---

# PILOT Deps — Dependency Update Loop

Upgrade dependencies one at a time with verification between each.

**Announce at start:** "Running PILOT dependency update loop."

## Arguments

Optional scope: `/pilot:deps [filter]`

- **No arguments** — checks all outdated dependencies
- **Package name** — update one package: `/pilot:deps react`
- **Scope** — filter by scope: `/pilot:deps @types/`

## Execution

### 1. Validate Prerequisites

Check that these exist:
- `.claude/pilot.yaml` — must exist. If missing: "Run `/pilot:plan` first."

Ensure `progress.txt` exists (create empty if not).

### 2. Create Owned Prompt Override

Parse arguments to determine FILTER, then create an ephemeral prompt override. Use the Write tool to create `.claude/pilot-prompt.md` with this content (replacing FILTER with actual value):

```
@progress.txt @.claude/pilot.yaml
You are PILOT running a dependency update loop.
FILTER: [resolved filter — package name, scope, or "all"]

Use the shared `/pilot:run` execution contract for implementation, review, feedback loops, heal/retry/escalate behavior, commit handling, progress logging, and top-level `PILOT_RESULT=...` output.

1. Run: npm outdated (or pnpm outdated, pip list --outdated, cargo outdated).
2. Pick ONE outdated dependency matching FILTER. Priority: security patches > major versions > minor > patch.
3. Update it to latest compatible version.
4. If breaking changes appear, use the shared heal/retry/escalate flow instead of inventing a recipe-specific one.
5. If all matching dependencies are current, emit PILOT_RESULT=done and <promise>COMPLETE</promise>.

ONE dependency per iteration. Never batch updates.
```

### 3. Confirm and Launch

Use AskUserQuestion to confirm:

```json
{
  "questions": [{
    "question": "Launch dependency update loop?\n  Filter: [filter]",
    "header": "Deps",
    "options": [
      {"label": "Launch (Recommended)", "description": "Start dependency update loop"},
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

Because the launch sets `PILOT_PROMPT_OWNED=true`, the shared loop deletes only the override created for this run. Report dependencies updated.
