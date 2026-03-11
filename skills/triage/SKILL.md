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

### 2. Write Ephemeral Prompt

Parse arguments to determine the issue filter (label, milestone, or default "ready"), then write the prompt file. Use the Write tool to create `.claude/pilot-prompt.md` with this content (replacing FILTER with actual value):

```
@progress.txt @.claude/pilot.yaml
You are PILOT running an issue triage loop.

1. Run: gh issue list --limit 10 --state open --label "FILTER"
2. Pick the highest-priority issue. Read it fully with: gh issue view [number]
3. Create branch: git checkout -b pilot/issue-[number]-[short-description]
4. Implement the fix or feature described in the issue.
5. Run all feedback loops from pilot.yaml.
6. Commit if all pass. Include progress.txt.
7. Push and open PR: gh pr create --title "[type]: [description]" --body "Closes #[number]"
8. Return to main branch: git checkout main
9. Append to progress.txt: issue number, title, PR URL.
10. If no matching issues remain, output <promise>COMPLETE</promise>.

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
bash "$PILOT_LOOP" 10
```

### 4. Results

`pilot-loop.sh` auto-deletes `.claude/pilot-prompt.md` on exit. Report issues processed and PRs created.
