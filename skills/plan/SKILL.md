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
2. **Gap analysis** — identify missing feedback loops, research + recommend tools
3. **Task source** — gather tasks from user, GitHub Issues, or both
4. **Generate artifacts** — PRD.md, .claude/pilot.yaml, progress.txt, pilot-loop.sh
5. **Readiness check** — dry-run feedback loops, flag issues

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

## Phase 2 — Gap Analysis + Recommendations

Map the detected toolchain against the four core feedback loops (see `references/stack-detection.md` for the full mapping table).

For each **missing** feedback loop:
1. Use WebSearch to find the best current tool for the detected stack
2. Use AskUserQuestion to present the gap with tool options. One gap per question.

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

## Phase 3 — Task Source

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

## Phase 4 — Generate Artifacts

Generate all four files using the templates in this skill's `assets/` directory. Use the Write tool for each.

**File 1: `PRD.md`** — Read `assets/prd-template.md`, fill in task details from Phase 3, write to project root.

**File 2: `.claude/pilot.yaml`** — Read `assets/pilot-yaml-template.yaml`, fill in detected values from Phase 1-2, write to `.claude/pilot.yaml`.

**File 3: `progress.txt`** — Read `assets/progress-template.txt`, fill in today's date, write to project root.

**File 4: `pilot-loop.sh`** — Copy the plugin's script into the project root and make it executable:

Run: `cp ${CLAUDE_SKILL_DIR}/../../scripts/pilot-loop.sh ./pilot-loop.sh && chmod +x pilot-loop.sh`

If `${CLAUDE_SKILL_DIR}` is not available, write the script inline (see scripts/pilot-loop.sh in the plugin repo for the canonical version).

## Phase 5 — Readiness Check

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

Present the user with next steps:
```
PILOT setup complete!

Generated:
  PRD.md              — [N] tasks, prioritized
  .claude/pilot.yaml  — toolchain config
  progress.txt        — ready for iteration logs
  pilot-loop.sh         — autonomous loop script

Next:
  /pilot:run         — run one task (recommended to start)
  /pilot:loop          — launch autonomous loop

Tip: Start with /pilot:run for 5-10 iterations to verify
feedback loops catch issues before going autonomous.
```
