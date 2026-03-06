---
name: a11y
description: Use when improving accessibility, fixing WCAG violations, adding ARIA attributes, or auditing frontend accessibility. Triggers on accessibility, a11y, WCAG, ARIA, axe violations.
---

# PILOT A11y — Accessibility Loop

Incrementally improve accessibility across a frontend codebase.

## Arguments

Optional scope: `/pilot:a11y [url]`

- **No arguments** — audits `http://localhost:3000`
- **URL** — audit specific page: `/pilot:a11y http://localhost:3000/dashboard`

## Prerequisites

| Prerequisite | Check |
|---|---|
| pilot.yaml | `.claude/pilot.yaml` must exist — run `/pilot:plan` first |
| axe-cli or browser MCP | Install: `npm i -D @axe-core/cli` or use Chrome DevTools MCP |
| Dev server running | App must be running at localhost for auditing |

## How It Works

Runs an accessibility audit, picks ONE violation (prioritizing critical/serious), fixes it, verifies the fix, and repeats until no violations remain.

## The Prompt

```
@progress.txt @.claude/pilot.yaml
You are PILOT running an accessibility improvement loop.

1. Run: npx axe-cli http://localhost:3000 --exit (or use browser MCP to audit).
2. Pick ONE accessibility violation — prioritize: critical > serious > moderate > minor.
3. Fix it — add ARIA attributes, fix contrast, add alt text, fix focus order, etc.
4. Re-run the audit to verify the fix.
5. Run all feedback loops from pilot.yaml.
6. Commit if all pass. Include progress.txt.
7. Append to progress.txt: violation type, element, fix applied.
8. If no violations remain, output <promise>COMPLETE</promise>.

ONE violation per iteration.
```

## Launch

```bash
# Start your dev server first
npm run dev &

# Then launch
./afk-loop.sh 20
```
