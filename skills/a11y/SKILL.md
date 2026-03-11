---
name: a11y
description: Use when improving accessibility, fixing WCAG violations, adding ARIA attributes, or auditing frontend accessibility. Triggers on accessibility, a11y, WCAG, ARIA, axe violations.
---

# PILOT A11y — Accessibility Loop

Incrementally improve accessibility across a frontend codebase.

**Announce at start:** "Running PILOT accessibility loop."

## Arguments

Optional scope: `/pilot:a11y [url]`

- **No arguments** — audits `http://localhost:3000`
- **URL** — audit specific page: `/pilot:a11y http://localhost:3000/dashboard`

## Execution

### 1. Validate Prerequisites

Check that these exist:
- `.claude/pilot.yaml` — must exist. If missing: "Run `/pilot:plan` first."
- `axe-cli` or Chrome DevTools MCP — install: `npm i -D @axe-core/cli`
- Dev server must be running at localhost

Ensure `progress.txt` exists (create empty if not).

### 2. Create Owned Prompt Override

Parse arguments to determine URL, then create an ephemeral prompt override. Use the Write tool to create `.claude/pilot-prompt.md` with this content (replacing URL with actual value):

```
@progress.txt @.claude/pilot.yaml
You are PILOT running an accessibility improvement loop.
URL: [resolved URL — argument or "http://localhost:3000"]

Use the shared `/pilot:run` execution contract for implementation, review, feedback loops, heal/retry/escalate behavior, commit handling, progress logging, and top-level `PILOT_RESULT=...` output.

1. Run: npx axe-cli URL --exit (or use browser MCP to audit).
2. Pick ONE accessibility violation — prioritize: critical > serious > moderate > minor.
3. Fix it — add ARIA attributes, fix contrast, add alt text, fix focus order, etc.
4. Re-run the audit to verify the fix.
5. If no violations remain, emit PILOT_RESULT=done and <promise>COMPLETE</promise>.

ONE violation per iteration.
```

### 3. Confirm and Launch

Use AskUserQuestion to confirm:

```json
{
  "questions": [{
    "question": "Launch accessibility loop?\n  URL: [url]\n  Dev server: [running/not detected]",
    "header": "A11y",
    "options": [
      {"label": "Launch (Recommended)", "description": "Start accessibility loop"},
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

Because the launch sets `PILOT_PROMPT_OWNED=true`, the shared loop deletes only the override created for this run. Report violations fixed.
