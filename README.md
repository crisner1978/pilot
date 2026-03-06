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
/pilot:once       # Execute one task (HITL)
/pilot:afk        # Launch autonomous loop (AFK)
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

1. **`/pilot:plan`** scans your repo, detects your toolchain, identifies gaps in your feedback loops, recommends fixes, and generates a PRD + config
2. **`/pilot:once`** picks the next task, implements it, runs feedback loops (typecheck, test, lint, browser), commits only if all pass
3. **`/pilot:afk`** runs the loop autonomously with an iteration cap — agent grinds through your backlog while you're away

## Key Principles

- **Feedback loops are non-negotiable** — no commit without green
- **One task per iteration** — prevents context rot
- **Progress tracking** — each iteration builds on the last without re-exploring
- **Start HITL, graduate to AFK** — master the loop before going autonomous

See [docs/design.md](docs/design.md) for the full design document and [docs/recipes.md](docs/recipes.md) for recipe details.
