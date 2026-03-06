---
name: triage
description: Use when processing GitHub issues into PRs, automating issue implementation, or clearing a GitHub backlog. Triggers on issue triage, GitHub backlog, automated PRs, issue processing.
---

# PILOT Triage — Issue Triage Loop

Process GitHub issues into branches and PRs automatically.

## Arguments

Optional scope: `/pilot:triage [filter]`

- **No arguments** — processes issues labeled `ready`
- **Label** — filter by label: `/pilot:triage --label bug`
- **Milestone** — filter by milestone: `/pilot:triage --milestone v2.0`

## Prerequisites

| Prerequisite | Check |
|---|---|
| pilot.yaml | `.claude/pilot.yaml` must exist — run `/pilot:plan` first |
| gh CLI | Must be installed and authenticated: `gh auth status` |
| Issue labels | Issues ready for automation should be labeled `ready` (or your chosen label) |

## How It Works

Fetches open GitHub issues with a target label, picks the highest-priority one, creates a branch, implements the fix/feature, runs feedback loops, opens a PR referencing the issue, and repeats.

## The Prompt

```
@progress.txt @.claude/pilot.yaml
You are PILOT running an issue triage loop.

1. Run: gh issue list --limit 10 --state open --label "ready"
2. Pick the highest-priority issue. Read it fully with: gh issue view [number]
3. Create branch: git checkout -b pilot/issue-[number]-[short-description]
4. Implement the fix or feature described in the issue.
5. Run all feedback loops from pilot.yaml.
6. Commit if all pass. Include progress.txt.
7. Push and open PR: gh pr create --title "[type]: [description]" --body "Closes #[number]"
8. Return to main branch: git checkout main
9. Append to progress.txt: issue number, title, PR URL.
10. If no "ready" issues remain, output <promise>COMPLETE</promise>.

ONE issue per iteration. Create clean, reviewable PRs.
```

## Launch

```bash
./afk-loop.sh 10
```
