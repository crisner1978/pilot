# PILOT

**Plan, Iterate, Loop, Observe, Test**

A Claude Code plugin that turns AI agents into autonomous software engineers. Drop into any codebase, run `/pilot:plan`, and get a self-driving development loop.

Inspired by [RALPH](https://www.aihero.dev/getting-started-with-ralph).

## Install

```bash
claude plugin marketplace add github:crisner1978/pilot
claude plugin install pilot
```

For local development/testing:
```bash
claude --plugin-dir /path/to/pilot
```

## Commands

### Core
```bash
/pilot:plan       # Interactive setup — generates PRD + config
/pilot:run        # Execute one task (with preview + skip)
/pilot:loop       # Launch autonomous loop
/pilot:status     # Sprint dashboard — progress, last run, blockers
/pilot:add        # Insert a task into the PRD mid-sprint
```

### Recipes
```bash
/pilot:coverage      # Test coverage loop
/pilot:lint-fix      # Fix lint violations
/pilot:duplication   # Refactor code clones
/pilot:entropy       # Clean up code smells
/pilot:deps          # Update dependencies
/pilot:types         # Tighten TypeScript types
/pilot:docs          # Generate API documentation
/pilot:migrate       # Pattern migration
/pilot:a11y          # Accessibility audit
/pilot:security      # Security audit
/pilot:triage        # GitHub issue → PR automation
```

## How It Works

1. **`/pilot:plan`** scans your repo, detects your toolchain, identifies gaps in your feedback loops, recommends fixes, and generates the durable project artifacts: `PRD.md`, `.claude/pilot.yaml`, and `progress.txt`
2. **`/pilot:run`** picks the next task, implements it, runs feedback loops (typecheck, test, lint, browser), commits only if all pass
3. **`/pilot:loop`** launches the shared plugin-owned loop infrastructure with an iteration cap so the agent can work through your backlog autonomously

## Key Principles

- **Feedback loops are non-negotiable** — no commit without green
- **One task per iteration** — prevents context rot
- **Progress tracking** — each iteration builds on the last without re-exploring
- **Shared loop infrastructure** — `pilot-loop.sh` stays in the plugin, not in the user repo
- **Self-executing recipes** — recipe skills launch their own scoped loops; no manual prompt swapping
- **Durable guidance stays structured** — use `CLAUDE.md` and `pilot.yaml` notes, not a persistent prompt file
- **Start manual, graduate to autonomous** — master the loop before going hands-off

See [docs/design.md](docs/design.md) for the full design document and [docs/recipes.md](docs/recipes.md) for recipe details.
