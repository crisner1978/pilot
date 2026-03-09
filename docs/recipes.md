# PILOT Recipes

PILOT ships with 11 recipe skills beyond the core `plan`/`run`/`loop` workflow. Each recipe is a specialized loop that uses the same mechanics — only the prompt changes.

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

Every recipe follows the same pattern:

1. **Look** at something (code, metrics, reports, issues)
2. **Pick ONE** thing to improve
3. **Fix** it
4. **Verify** the fix (feedback loops)
5. **Commit** + log progress
6. **Check** if done — output `<promise>COMPLETE</promise>` if so

The loop is always the same. Only the prompt changes.

## Writing Your Own Recipe

Create a new skill at `skills/<name>/SKILL.md` with:

1. YAML frontmatter (`name`, `description` starting with "Use when...")
2. Prerequisites table
3. The prompt (what the agent does each iteration)
4. Setup instructions (one-time)
5. Launch commands

Use any existing recipe skill as a template. The key constraint: **ONE action per iteration**. This prevents context rot and ensures clean commits.

## Running Recipes

All recipes use the same `pilot-loop.sh` script. Each recipe skill explains how to configure the prompt. You can run any recipe manually (one iteration) or autonomously:

```bash
# Manual — watch and learn
./pilot-loop.sh 1

# Autonomous — let it grind
./pilot-loop.sh 20
```

Some recipes have prerequisites (jscpd, axe-cli, gh). The skill will tell you what's needed.
