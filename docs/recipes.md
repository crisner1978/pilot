# PILOT Recipes

PILOT ships with 11 recipe skills beyond the core `plan`/`run`/`loop` workflow. Each recipe is a self-executing specialized loop — validate prerequisites, optionally generate setup artifacts, write an owned prompt override, confirm with the user, launch the shared plugin loop, and clean up automatically.

## Available Recipes

| Skill | Command | What It Does |
|-------|---------|-------------|
| Coverage | `/pilot:coverage` | Write tests for uncovered code paths until target % is met |
| Lint Fix | `/pilot:lint-fix` | Fix lint violations one by one |
| Duplication | `/pilot:duplication` | Find code clones (jscpd), refactor into shared utilities |
| Entropy | `/pilot:entropy` | Clean up code smells: dead code, unused exports, inconsistent patterns |
| Deps | `/pilot:deps` | Update outdated dependencies one at a time |
| Types | `/pilot:types` | Remove `any` types, add type annotations, tighten TypeScript strictness |
| Docs | `/pilot:docs` | Generate JSDoc/docstrings for undocumented public APIs |
| Migrate | `/pilot:migrate` | Apply a pattern migration across files (requires MIGRATION.md) |
| A11y | `/pilot:a11y` | Fix accessibility violations using axe audit |
| Security | `/pilot:security` | Find and fix security vulnerabilities (npm audit + OWASP scan) |
| Triage | `/pilot:triage` | Process GitHub issues into branches and PRs automatically |

## How Recipes Work

Every recipe follows the same execution pattern:

1. **Validate** — check `.claude/pilot.yaml` exists, check skill-specific tools
2. **Setup** (if needed) — generate initial report (e.g., coverage baseline)
3. **Write owned override** — create `.claude/pilot-prompt.md` with the recipe-specific selection logic
4. **Confirm** — ask the user to confirm settings via `AskUserQuestion`
5. **Launch** — run the shared plugin `pilot-loop.sh` with `PILOT_PROMPT_OWNED=true`
6. **Cleanup** — the loop deletes only the override created for that launch

`.claude/pilot-prompt.md` is runtime scratch space for PILOT, not a durable user-facing configuration surface. Put long-lived project guidance in `CLAUDE.md`, `quality.notes`, or `loop.notes` in `.claude/pilot.yaml`.

Each iteration of the loop:
1. **Look** at something (code, metrics, reports, issues)
2. **Pick ONE** thing to improve
3. **Run the shared `/pilot:run` contract** — implement, review, verify, heal/retry, commit/log progress
4. **Emit one machine-readable result marker** — `PILOT_RESULT=done|failed|skipped|escalated`
5. **Check** if done — also output `<promise>COMPLETE</promise>` if so

## Running Recipes

Just run the skill command. Each recipe is self-executing:

```
/pilot:coverage src/ 90          # write tests until 90% coverage
/pilot:lint-fix                   # fix all lint violations
/pilot:deps @types/               # update @types/ packages
/pilot:a11y http://localhost:3000 # audit and fix accessibility
```

The skill handles everything — prerequisite checks, prompt generation, user confirmation, loop launch, and cleanup. No manual prompt swapping or separate `/pilot:loop` step is required.

Some recipes have prerequisites (jscpd, axe-cli, gh). The skill will tell you what's needed and offer to install it.

## Writing Your Own Recipe

Create a new skill at `skills/<name>/SKILL.md` following the self-executing pattern:

```markdown
---
name: my-recipe
description: Use when [trigger conditions]. Triggers on [keywords].
---

# PILOT My Recipe — [Description]

[One-line summary.]

**Announce at start:** "Running PILOT [name] loop."

## Arguments

Optional scope: `/pilot:my-recipe [args]`

- **No arguments** — [default behavior]
- **With args** — [scoped behavior]

## Execution

### 1. Validate Prerequisites

Check that these exist:
- `.claude/pilot.yaml` — must exist. If missing: "Run `/pilot:plan` first."
- [Skill-specific tools]

Ensure `progress.txt` exists (create empty if not).

### 2. Write Owned Prompt Override

Parse arguments, then write `.claude/pilot-prompt.md`:

\```
@progress.txt @.claude/pilot.yaml
You are PILOT running a [name] loop.
SCOPE: [resolved from arguments]

Use the shared `/pilot:run` execution contract for implementation, review, feedback loops, heal/retry/escalate behavior, commit or PR behavior, and progress logging.

1. Find ONE thing to fix within SCOPE.
2. If nothing remains, emit `PILOT_RESULT=done` and `<promise>COMPLETE</promise>`.
3. Otherwise execute exactly one iteration of that work and emit exactly one top-level `PILOT_RESULT=...` line.

ONE fix per iteration.
\```

### 3. Confirm and Launch

Use AskUserQuestion to confirm, then launch:

\```bash
PILOT_LOOP="${CLAUDE_SKILL_DIR}/../../scripts/pilot-loop.sh"
PILOT_PROMPT_OWNED=true bash "$PILOT_LOOP" 20
\```

### 4. Results

Because the launch sets `PILOT_PROMPT_OWNED=true`, the shared loop cleans up only the override created for that run. Report results.
```

Key constraints:
- **ONE action per iteration** — prevents context rot, ensures clean commits
- **Always validate `pilot.yaml`** — recipes depend on feedback loops
- **Use `AskUserQuestion`** — let the user confirm before launching
- **Prompt override is ephemeral runtime state** — recipes own it for one launch; durable project artifacts remain `PRD.md`, `.claude/pilot.yaml`, and `progress.txt`
- **Durable customization stays structured** — use `CLAUDE.md`, `quality.notes`, and `loop.notes` instead of maintaining a persistent prompt file
