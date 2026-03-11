# PILOT Recipes

PILOT ships with 11 recipe skills beyond the core `plan`/`run`/`loop` workflow. Each recipe is a self-executing specialized loop — validate prerequisites, write an ephemeral prompt, confirm with the user, launch the loop, and clean up automatically.

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
3. **Write prompt** — create `.claude/pilot-prompt.md` with the skill's iteration prompt
4. **Confirm** — ask the user to confirm settings via `AskUserQuestion`
5. **Launch** — run `pilot-loop.sh` which iterates the prompt
6. **Cleanup** — `pilot-loop.sh` auto-deletes the prompt file on exit

Each iteration of the loop:
1. **Look** at something (code, metrics, reports, issues)
2. **Pick ONE** thing to improve
3. **Fix** it
4. **Verify** the fix (feedback loops from `pilot.yaml`)
5. **Commit** + log progress
6. **Check** if done — output `<promise>COMPLETE</promise>` if so

## Running Recipes

Just run the skill command. Each recipe is self-executing:

```
/pilot:coverage src/ 90          # write tests until 90% coverage
/pilot:lint-fix                   # fix all lint violations
/pilot:deps @types/               # update @types/ packages
/pilot:a11y http://localhost:3000 # audit and fix accessibility
```

The skill handles everything — prerequisite checks, prompt generation, user confirmation, loop launch, and cleanup. No manual steps needed.

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

### 2. Write Ephemeral Prompt

Parse arguments, then write `.claude/pilot-prompt.md`:

\```
@progress.txt @.claude/pilot.yaml
You are PILOT running a [name] loop.
SCOPE: [resolved from arguments]

1. Find ONE thing to fix within SCOPE.
2. Fix it.
3. Run all feedback loops from pilot.yaml.
4. Commit if all pass. Include progress.txt.
5. Append to progress.txt: what was fixed.
6. If nothing left in SCOPE, output <promise>COMPLETE</promise>.

ONE fix per iteration.
\```

### 3. Confirm and Launch

Use AskUserQuestion to confirm, then launch:

\```bash
PILOT_LOOP="${CLAUDE_SKILL_DIR}/../../scripts/pilot-loop.sh"
bash "$PILOT_LOOP" 20
\```

### 4. Results

`pilot-loop.sh` auto-deletes `.claude/pilot-prompt.md` on exit. Report results.
```

Key constraints:
- **ONE action per iteration** — prevents context rot, ensures clean commits
- **Always validate `pilot.yaml`** — recipes depend on feedback loops
- **Use `AskUserQuestion`** — let the user confirm before launching
- **Prompt file is ephemeral** — written before launch, auto-deleted on exit
