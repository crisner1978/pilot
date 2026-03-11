---
name: triage
description: Use when processing GitHub issues into PRs, automating issue implementation, or clearing a GitHub backlog. Triggers on issue triage, GitHub backlog, automated PRs, issue processing.
---

# PILOT Triage — Issue Triage Loop

Process GitHub issues into branches and PRs automatically.

**Announce at start:** "Running PILOT issue triage loop."

## Arguments

Optional scope: `/pilot:triage [filter]`

- **No arguments** — processes issues labeled `ready`
- **Label** — filter by label: `/pilot:triage --label bug`
- **Milestone** — filter by milestone: `/pilot:triage --milestone v2.0`

## Execution

### 1. Validate Prerequisites

Check that these exist:
- `.claude/pilot.yaml` — must exist. If missing: "Run `/pilot:plan` first."
- `gh` CLI — must be installed and authenticated: run `gh auth status`

Ensure `progress.txt` exists (create empty if not).

### 2. Create Owned Prompt Override

Parse arguments to determine the issue filter (label, milestone, or default "ready"), then create an ephemeral prompt override. Use the Write tool to create `.claude/pilot-prompt.md` with this content (replacing FILTER with actual value):

```
@progress.txt @.claude/pilot.yaml
You are PILOT running an issue triage loop.

Use the shared `/pilot:run` execution contract for implementation, review, feedback loops, heal/retry/escalate behavior, progress logging, and top-level `PILOT_RESULT=...` output. Respect `loop.output` from `pilot.yaml` for commit vs PR behavior.

1. Run: gh issue list --limit 10 --state open --label "FILTER"
2. Pick the highest-priority issue. Read it fully with: gh issue view [number]
3. Implement the fix or feature described in the issue.
4. If no matching issues remain, emit PILOT_RESULT=done and <promise>COMPLETE</promise>.

ONE issue per iteration. Create clean, reviewable PRs.
```

### 3. Confirm and Launch

Use AskUserQuestion to confirm:

```json
{
  "questions": [{
    "question": "Launch issue triage loop?\n  Filter: [filter]\n  GitHub auth: [status]",
    "header": "Triage",
    "options": [
      {"label": "Launch (Recommended)", "description": "Start issue triage loop"},
      {"label": "Change filter", "description": "Use a different label or milestone"},
      {"label": "Cancel", "description": "Don't launch"}
    ],
    "multiSelect": false
  }]
}
```

After confirmation, launch the loop:

```bash
PILOT_LOOP="${CLAUDE_SKILL_DIR}/../../scripts/pilot-loop.sh"
PILOT_PROMPT_OWNED=true bash "$PILOT_LOOP" 10
```

### 4. Results

Because the launch sets `PILOT_PROMPT_OWNED=true`, the shared loop deletes only the override created for this run. Report issues processed and PRs created.
