---
name: plan
description: Use when starting a new development workflow, setting up autonomous coding loops, or preparing a codebase for PILOT execution. Triggers on project setup, PRD generation, toolchain detection, feedback loop configuration.
---

# PILOT Plan — Interactive Setup

**Announce at start:** "Using PILOT to set up your autonomous development workflow."

Generate a PRD, detect your toolchain, identify feedback loop gaps, and configure PILOT — all through guided questions.

## Asking Questions

**ALWAYS use the `AskUserQuestion` tool** to present choices. This gives the native Claude Code selection UI where users can arrow-key through options, select one, or choose "Other" to type freeform context. One question at a time. Keep labels short (1-5 words), put rationale in the description. Mark recommended options with "(Recommended)" in the label.

## Checklist

You MUST complete these phases in order:

1. **Context scan** — detect stack, toolchain, existing config
2. **Targeted codebase analysis** — dispatch ScoutAgent to scan relevant areas
3. **Gap analysis** — dispatch GapAgent to identify missing feedback loops
4. **Task source** — gather tasks from user, GitHub Issues, or both
5. **Task analysis** — dispatch ArchitectAgent to order tasks, add dependencies + context
6. **Generate artifacts** — PRD.md, .claude/pilot.yaml, progress.txt
7. **Readiness check** — dry-run feedback loops, flag issues

## Phase 1 — Context Scan

Scan the repo to detect the development stack. Read `references/stack-detection.md` for the full detection table and feedback loop mapping.

**Also check for `CLAUDE.md`** — if it exists, read it and extract project conventions (naming, patterns, style rules, architecture notes). Carry these into `pilot.yaml` under `quality.notes` so the agent respects existing project standards during implementation.

**Output:** Present a summary of what was detected:
```
Detected stack:
  Language: TypeScript
  Framework: Next.js 15
  Test runner: Vitest (vitest.config.ts)
  Typecheck: tsc --noEmit (tsconfig.json)
  Linter: ESLint (eslint.config.js)
  Formatter: Prettier (.prettierrc)
  Browser tests: not detected
  CI: GitHub Actions (.github/workflows/ci.yml)
```

**Also detect sensitive files** — glob for patterns in `references/stack-detection.md` "Sensitive File Detection" table. If any matches exist, collect them for the guardrails config.

Present detected protected paths:
```
Protected paths detected:
  .env, .env.local          — secrets
  migrations/               — database migrations
  .github/workflows/        — CI/CD pipelines
```

Use AskUserQuestion to confirm protected paths:

```json
{
  "questions": [{
    "question": "These files/dirs will be protected from autonomous changes. Edit?",
    "header": "Protected paths",
    "options": [
      {"label": "Looks good", "description": "Use the detected paths as-is"},
      {"label": "Add more", "description": "I want to add additional paths to protect"},
      {"label": "Skip", "description": "No protected paths needed"}
    ],
    "multiSelect": false
  }]
}
```

## Phase 2 — Targeted Codebase Analysis

This phase executes after Phase 4 (Task Source) provides the task description. However, GapAgent (Phase 3) only needs stack detection results and can run immediately after Phase 1 — **dispatch Phases 2 and 3 in parallel** when possible.

Dispatch the **ScoutAgent** to analyze the relevant parts of the codebase.

Read `agents/scout.md` for the full agent prompt. Dispatch it as a subagent with:
- The full file tree (run `find . -type f -not -path './.git/*' -not -path './node_modules/*' | head -200` or equivalent)
- The task description from the user
- The stack detection results from Phase 1
- The scan heuristic table from `references/stack-detection.md`

The ScoutAgent returns a `codebase:` YAML block. Store this for Phase 6 (generate artifacts) — it goes into `pilot.yaml`.

Present the results to the user:
```
Codebase analysis complete:
  Scanned: src/middleware/, src/api/, src/models/
  Patterns: express-style middleware, zod validation, colocated tests
  Key files: src/middleware/auth.ts (middleware pattern reference)
```

## Phase 3 — Gap Analysis

Dispatch the **GapAgent** to analyze toolchain coverage. Read `agents/gap.md` for the full agent prompt. Dispatch it as a subagent with:
- Stack detection results from Phase 1
- Current feedback loop config
- The stack detection reference (`references/stack-detection.md`)

The GapAgent returns a structured gap analysis with recommendations (it uses WebSearch internally to research current tools). For each gap with a recommended tool, use AskUserQuestion to present options to the user (one question per gap). The GapAgent may also identify setup tasks — these become the first tasks in the PRD.

Example — no test runner:
```json
{
  "questions": [{
    "question": "No test runner detected. Which test runner for this Next.js 15 + TypeScript project?",
    "header": "Test runner",
    "options": [
      {"label": "Vitest (Recommended)", "description": "Fast, ESM-native, jsdom for component testing"},
      {"label": "Jest", "description": "Mature ecosystem, ts-jest transform, widely documented"},
      {"label": "Skip", "description": "Not needed for this work — note as gap in config"}
    ],
    "multiSelect": false
  }]
}
```

Example — no linter:
```json
{
  "questions": [{
    "question": "No linter found. Which linter for ESM TypeScript?",
    "header": "Linter",
    "options": [
      {"label": "Biome (Recommended)", "description": "Fastest — lint + format in one tool"},
      {"label": "ESLint", "description": "Plugin ecosystem, more configurable"},
      {"label": "Skip", "description": "Not needed for this work — note as gap in config"}
    ],
    "multiSelect": false
  }]
}
```

If a gap exists but isn't relevant to the planned work (e.g., no browser tests but the work is purely backend), note it in the config but don't push setup:
```yaml
gaps:
  - browser: "No browser tests. Backend-only work — not needed for current PRD."
```

## Phase 4 — Task Source

Use AskUserQuestion for each decision:

```json
{
  "questions": [{
    "question": "Where should tasks come from?",
    "header": "Task source",
    "options": [
      {"label": "Local", "description": "Describe what to build — I'll break it into atomic tasks"},
      {"label": "GitHub Issues", "description": "Pull from open issues in this repo"},
      {"label": "Both", "description": "Issues as backlog + local description for immediate focus"}
    ],
    "multiSelect": false
  }]
}
```

```json
{
  "questions": [{
    "question": "How should completed tasks be delivered?",
    "header": "Delivery",
    "options": [
      {"label": "Commit (Recommended)", "description": "Commit directly to current branch — good for solo work"},
      {"label": "Branch + PR", "description": "Create a branch and PR per task — good for teams with review"}
    ],
    "multiSelect": false
  }]
}
```

**If Local:** Ask "What are we building? Describe the feature, fix, or goal." Break the response into atomic tasks. Prioritize: gap-filling setup first, then architectural/risky tasks, then features, then polish.

**If GitHub Issues:** Run `gh issue list --limit 30 --state open`, present the issues, let user select which to include, ask about priority ordering.

**If Both:** Combine GitHub Issues as backlog + user description for immediate focus.

After gathering tasks, ask about quality expectations:

```json
{
  "questions": [{
    "question": "What quality bar should PILOT target?",
    "header": "Quality",
    "options": [
      {"label": "Prototype", "description": "Fast iteration, minimal tests, skip edge cases — ship something quickly"},
      {"label": "Production (Recommended)", "description": "Tests for new code, error handling, follow existing patterns"},
      {"label": "Library", "description": "Strict types, full test coverage, thorough docs, defensive coding"}
    ],
    "multiSelect": false
  }]
}
```

**For each task, generate:**
```markdown
- [ ] **Task N:** [Clear description]
  - Acceptance: [One-liner — what "done" looks like, testable]
  - Validation: [Which feedback loops verify this]
  - Files: [Expected files to create/modify, if known]
  - Depends: [Task #, only if genuinely blocked without it — omit otherwise]
```

Keep acceptance criteria to one sentence. The agent uses these to know what to implement and what test to write. Don't front-load context — the agent can spawn sub-agents to research specifics during implementation.

**Prioritization order (from RALPH):**
1. Toolchain setup (gap-filling) — must be first
2. Architectural decisions and abstractions
3. Integration points between modules
4. Unknown unknowns and spike work
5. Standard features
6. Polish and quick wins

## Phase 5 — Task Analysis

After gathering raw tasks, dispatch the **ArchitectAgent** to analyze and enrich them. Read `agents/architect.md` for the full agent prompt. Dispatch it as a subagent with:
- The raw task list from Phase 4
- The ScoutAgent codebase context from Phase 2
- The quality bar setting
- Any setup tasks from GapAgent (Phase 3)

The ArchitectAgent returns:
- Reordered task list with `Context:` and `Depends:` fields enriched
- Parallel execution groups

Use the ArchitectAgent's output as the task list for the PRD. Present the reordered tasks to the user for confirmation before generating artifacts.

## Phase 6 — Generate Artifacts

Generate all three files using the templates in this skill's `assets/` directory. Use the Write tool for each.

**File 1: `PRD.md`** — Read `assets/prd-template.md`, fill in task details from Phase 3, write to project root.

**File 2: `.claude/pilot.yaml`** — Read `assets/pilot-yaml-template.yaml`, fill in detected values from Phase 1-2, write to `.claude/pilot.yaml`.

Include `guardrails.protected_paths` from Phase 1 detection. If no paths were detected, omit the section.

Include the `codebase:` section from ScoutAgent (Phase 2) in `pilot.yaml`. Include the parallel groups section from ArchitectAgent (Phase 5) in `PRD.md`.

**File 3: `progress.txt`** — Read `assets/progress-template.txt`, fill in today's date, write to project root.

**Note:** `pilot-loop.sh` lives in the PILOT plugin at `scripts/pilot-loop.sh` and is invoked from there by `/pilot:loop`. Do **not** copy it into the user's project — this avoids version drift and repo pollution. The loop script contains a default prompt for PRD-based execution. Recipe skills (coverage, lint-fix, etc.) write an ephemeral `.claude/pilot-prompt.md` before launching the loop — the script reads it if present and auto-deletes it on exit.

## Phase 7 — Readiness Check

For each configured feedback loop, do a dry run:

```bash
# Example for a TypeScript + Vitest project:
tsc --noEmit          # Should exit 0 or show only pre-existing errors
vitest run            # Should exit 0 (or show only pre-existing failures)
biome check .         # Should exit 0 or show only pre-existing issues
```

Report results:
- All pass → "PILOT is ready. Run `/pilot:run` to start, or `/pilot:loop` to go autonomous."
- Some fail → "These feedback loops have pre-existing failures: [list]. Fix these first, or they'll block every iteration."
- Missing command → "Command `[cmd]` not found. Install it or update `.claude/pilot.yaml`."

## After Setup

Present the summary, then use AskUserQuestion to let the user choose how to proceed:

```
PILOT setup complete!

Generated:
  PRD.md                  — [N] tasks, prioritized
  .claude/pilot.yaml      — toolchain config
  progress.txt            — ready for iteration logs
```

```json
{
  "questions": [{
    "question": "How would you like to execute?",
    "header": "Execute",
    "options": [
      {"label": "Run one task (Recommended)", "description": "Execute the first task manually — verify feedback loops work before going autonomous"},
      {"label": "Launch loop", "description": "Start autonomous loop — grinds through the backlog unattended"},
      {"label": "Done for now", "description": "I'll run it later"}
    ],
    "multiSelect": false
  }]
}
```

If the user selects "Run one task", invoke `/pilot:run`. If "Launch loop", invoke `/pilot:loop`.
