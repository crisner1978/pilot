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

### 2. Write Ephemeral Prompt

Parse arguments to determine FILTER, then write the prompt file. Use the Write tool to create `.claude/pilot-prompt.md` with this content (replacing FILTER with actual value):

```
@progress.txt @.claude/pilot.yaml
You are PILOT running a dependency update loop.
FILTER: [resolved filter — package name, scope, or "all"]

1. Run: npm outdated (or pnpm outdated, pip list --outdated, cargo outdated).
2. Pick ONE outdated dependency matching FILTER. Priority: security patches > major versions > minor > patch.
3. Update it to latest compatible version.
4. Run all feedback loops from pilot.yaml.
5. If breaking changes, try to fix them (update imports, adjust API calls).
6. If unfixable, revert the update and note in progress.txt why.
7. Commit if all loops pass. Include progress.txt.
8. Append to progress.txt: package, old version, new version, any breaking changes.
9. If all matching dependencies are current, output <promise>COMPLETE</promise>.

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
bash "$PILOT_LOOP" 20
```

### 4. Results

`pilot-loop.sh` auto-deletes `.claude/pilot-prompt.md` on exit. Report dependencies updated.
