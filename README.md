# PILOT

**Plan, Iterate, Loop, Observe, Test**

A Claude Code plugin that turns AI agents into autonomous software engineers. Drop into any codebase, run `/pilot:plan`, and get a self-driving development loop.

Inspired by [RALPH](https://www.aihero.dev/getting-started-with-ralph).

## Install

```bash
/plugin marketplace add github:crisner1978/pilot
/plugin install pilot
```

## Usage

```bash
/pilot:plan   # Interactive setup — generates PRD + config from questions + auto-detection
/pilot:once   # Execute one task (HITL — human in the loop)
/pilot:afk    # Launch autonomous loop (AFK — away from keyboard)
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

See [docs/design.md](docs/design.md) for the full design document.
