---
name: deps
description: Use when updating outdated dependencies, upgrading packages, or patching security vulnerabilities in dependencies. Triggers on npm outdated, dependency update, package upgrade.
---

# PILOT Deps — Dependency Update Loop

Upgrade dependencies one at a time with verification between each.

## Arguments

Optional scope: `/pilot:deps [filter]`

- **No arguments** — checks all outdated dependencies
- **Package name** — update one package: `/pilot:deps react`
- **Scope** — filter by scope: `/pilot:deps @types/`

## Prerequisites

| Prerequisite | Check |
|---|---|
| pilot.yaml | `.claude/pilot.yaml` must exist — run `/pilot:plan` first |

## How It Works

Checks for outdated dependencies, picks one (prioritizing security patches), updates it, runs feedback loops to catch breaking changes, and commits. Reverts if unfixable.

## The Prompt

```
@progress.txt @.claude/pilot.yaml
You are PILOT running a dependency update loop.

1. Run: npm outdated (or pnpm outdated, pip list --outdated, cargo outdated).
2. Pick ONE outdated dependency. Priority: security patches > major versions > minor > patch.
3. Update it to latest compatible version.
4. Run all feedback loops from pilot.yaml.
5. If breaking changes, try to fix them (update imports, adjust API calls).
6. If unfixable, revert the update and note in progress.txt why.
7. Commit if all loops pass. Include progress.txt.
8. Append to progress.txt: package, old version, new version, any breaking changes.
9. If all dependencies are current, output <promise>COMPLETE</promise>.

ONE dependency per iteration. Never batch updates.
```

## Launch

```bash
./afk-loop.sh 20
```
