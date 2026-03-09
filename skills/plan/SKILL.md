---
name: plan
description: Use when starting a new development workflow, setting up autonomous coding loops, or preparing a codebase for PILOT execution. Triggers on project setup, PRD generation, toolchain detection, feedback loop configuration.
---

# PILOT Plan — Interactive Setup

**Announce at start:** "Using PILOT to set up your autonomous development workflow."

Generate a PRD, detect your toolchain, identify feedback loop gaps, and configure PILOT — all through guided questions.

## Asking Questions

Always present choices as numbered options. One question at a time. The user can select a number or type a freeform answer to add context. Example format:

```
[Brief context about what's being decided]

1. Option A (short rationale)
2. Option B (short rationale)
3. Option C (short rationale)
```

## Checklist

You MUST complete these phases in order:

1. **Context scan** — detect stack, toolchain, existing config
2. **Gap analysis** — identify missing feedback loops, research + recommend tools
3. **Task source** — gather tasks from user, GitHub Issues, or both
4. **Generate artifacts** — PRD.md, .claude/pilot.yaml, progress.txt, afk-loop.sh
5. **Readiness check** — dry-run feedback loops, flag issues

## Phase 1 — Context Scan

Scan the repo to detect the development stack. Read `references/stack-detection.md` for the full detection table and feedback loop mapping.

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
2. Present the gap with a recommendation, one at a time. Use numbered options the user can select:

Example:
```
No test runner detected. For this Next.js 15 + TypeScript project:

1. Vitest with jsdom (recommended — fast, ESM-native)
2. Jest with ts-jest (mature, large ecosystem)
3. Skip — not needed for this work
```

Example:
```
No linter found. For ESM TypeScript:

1. Biome (fastest — lint + format in one tool)
2. ESLint (plugin ecosystem, more configurable)
3. Skip — not needed for this work
```

If a gap exists but isn't relevant to the planned work (e.g., no browser tests but the work is purely backend), note it in the config but don't push setup:
```yaml
gaps:
  - browser: "No browser tests. Backend-only work — not needed for current PRD."
```

## Phase 3 — Task Source

Ask the user one question at a time. Present options as numbered choices:

```
Where should tasks come from?

1. Local — describe what to build
2. GitHub Issues — pull from open issues
3. Both — issues as backlog + local description for immediate focus
```

```
How should completed tasks be delivered?

1. Commit to current branch (default — good for solo work)
2. Branch + PR per task (good for teams with review processes)
```

**If Local:** Ask "What are we building? Describe the feature, fix, or goal." Break the response into atomic tasks. Prioritize: gap-filling setup first, then architectural/risky tasks, then features, then polish.

**If GitHub Issues:** Run `gh issue list --limit 30 --state open`, present the issues, let user select which to include, ask about priority ordering.

**If Both:** Combine GitHub Issues as backlog + user description for immediate focus.

**For each task, generate:**
```markdown
- [ ] **Task N:** [Clear description]
  - Validation: [What feedback loops verify this]
  - Files: [Expected files to create/modify, if known]
```

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

**File 4: `afk-loop.sh`** — Copy the plugin's script into the project root and make it executable:

Run: `cp ${CLAUDE_SKILL_DIR}/../../scripts/afk-loop.sh ./afk-loop.sh && chmod +x afk-loop.sh`

If `${CLAUDE_SKILL_DIR}` is not available, write the script inline (see scripts/afk-loop.sh in the plugin repo for the canonical version).

## Phase 5 — Readiness Check

For each configured feedback loop, do a dry run:

```bash
# Example for a TypeScript + Vitest project:
tsc --noEmit          # Should exit 0 or show only pre-existing errors
vitest run            # Should exit 0 (or show only pre-existing failures)
biome check .         # Should exit 0 or show only pre-existing issues
```

Report results:
- All pass → "PILOT is ready. Run `/pilot:once` to start, or `/pilot:afk` to go autonomous."
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
  afk-loop.sh         — autonomous loop script

Next:
  /pilot:once         — run one task (recommended to start)
  /pilot:afk          — launch autonomous loop

Tip: Start with /pilot:once for 5-10 iterations to verify
feedback loops catch issues before going AFK.
```
