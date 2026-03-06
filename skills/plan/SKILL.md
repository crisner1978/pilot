---
name: plan
description: Use when starting a new development workflow, setting up autonomous coding loops, or preparing a codebase for PILOT execution. Triggers on project setup, PRD generation, toolchain detection, feedback loop configuration.
---

# PILOT Plan — Interactive Setup

**Announce at start:** "Using PILOT to set up your autonomous development workflow."

Generate a PRD, detect your toolchain, identify feedback loop gaps, and configure PILOT — all through guided questions.

## Checklist

You MUST complete these phases in order:

1. **Context scan** — detect stack, toolchain, existing config
2. **Gap analysis** — identify missing feedback loops, research + recommend tools
3. **Task source** — gather tasks from user, GitHub Issues, or both
4. **Generate artifacts** — PRD.md, .claude/pilot.yaml, progress.txt, afk-loop.sh
5. **Readiness check** — dry-run feedback loops, flag issues

## Phase 1 — Context Scan

Scan the repo to detect the development stack. Check for these files:

| File | Detects |
|------|---------|
| `package.json` | Node.js, dependencies, scripts (test, lint, typecheck, build) |
| `tsconfig.json` | TypeScript, compiler options |
| `vitest.config.*` | Vitest test runner |
| `jest.config.*` | Jest test runner |
| `playwright.config.*` | Playwright browser tests |
| `cypress.config.*` | Cypress browser tests |
| `.eslintrc*` / `eslint.config.*` | ESLint linter |
| `biome.json` / `biome.jsonc` | Biome linter/formatter |
| `pyproject.toml` | Python, pytest, ruff, mypy |
| `Cargo.toml` | Rust, cargo test, clippy |
| `go.mod` | Go, go test, golangci-lint |
| `Makefile` | Build commands, test targets |
| `.github/workflows/*` | CI config (reveals test/lint/typecheck commands) |

Also check:
- `package.json` scripts for `test`, `typecheck`, `lint`, `check`, `build` commands
- Existing `PRD.md`, `.claude/pilot.yaml`, `CLAUDE.md`
- GitHub Issues (if `gh` CLI is available: `gh issue list --limit 20`)

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

Map the detected toolchain against the four core feedback loops:

| Feedback Loop | Purpose | Required For |
|---------------|---------|-------------|
| `typecheck` | Catch type errors before runtime | All typed languages |
| `test` | Verify behavior, catch regressions | All code changes |
| `lint` | Enforce style, catch bugs | All code changes |
| `browser` | Verify rendered UI | Frontend/UI tasks |

For each **missing** feedback loop:
1. Use WebSearch to find the best current tool for the detected stack
2. Present the gap with a recommendation as a question (one at a time):

Example questions:
- "No test runner detected. For this Next.js 15 + TypeScript project, **Vitest with jsdom** is the standard choice. Add test setup as the first PRD task?"
- "No linter found. For ESM TypeScript, **Biome** is fastest (lint + format in one tool), or **ESLint** if you need the plugin ecosystem. Which do you prefer?"
- "No type checking configured. You have `.js` files — want to add `tsconfig.json` with `checkJs: true`, or convert to TypeScript?"

If a gap exists but isn't relevant to the planned work (e.g., no browser tests but the work is purely backend), note it in the config but don't push setup:
```yaml
gaps:
  - browser: "No browser tests. Backend-only work — not needed for current PRD."
```

## Phase 3 — Task Source

Ask the user one question at a time:

**Question 1:** "Where should tasks come from?"
- Options: Local (describe what to build), GitHub Issues, Both

**Question 2:** "How should completed tasks be delivered?"
- Options: Commit directly to current branch (default, good for solo work), Create a branch + PR per task (good for teams with review processes)

**If Local:**
- Ask: "What are we building? Describe the feature, fix, or goal."
- Break the response into atomic tasks (one logical change each)
- Prioritize: gap-filling setup tasks first, then architectural/risky tasks, then standard features, then polish

**If GitHub Issues:**
- Run: `gh issue list --limit 30 --state open`
- Present the issues and let user select which to include
- Ask about priority ordering

**If Both:**
- Combine: GitHub Issues as backlog + user description for immediate focus

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

Generate all four files. Use the Write tool for each.

**File 1: `PRD.md`**
```markdown
# [Project/Feature Name] — PRD

> Generated by PILOT on [date]. Edit freely — PILOT reads this on every iteration.

## Tasks

- [ ] **1.** [First task]
  - Validation: [feedback loops]
  - Files: [expected files]

- [ ] **2.** [Second task]
  - Validation: [feedback loops]
  - Files: [expected files]

[...continue for all tasks]

## Quality Bar

[From user's quality preference: prototype/production/library]

## Notes

[Any architectural decisions, constraints, or context from the planning conversation]
```

**File 2: `.claude/pilot.yaml`**
```yaml
# Auto-generated by /pilot:plan — edit if needed
project:
  name: [detected or asked]
  stack: [detected languages, frameworks]
  detected: [today's date]

source:
  type: [local | github | both]
  github:
    repo: [owner/repo or null]
    labels: [selected labels or empty]
    milestone: [selected milestone or null]

feedback:
  typecheck: [detected command or null]
  test: [detected command or null]
  lint: [detected command or null]
  browser: [detected command or null]
  custom: []

gaps: [list of {loop: reason} or empty]

loop:
  type: feature
  output: commit                 # commit (default) | pr (branch + PR per task)
  iterations: 20
  sandbox: true
  retries: 3

quality:
  bar: [prototype | production | library]
  notes: [user's quality notes or "Follow existing patterns."]
```

**File 3: `progress.txt`**
```
# PILOT Progress Log — generated [date]
# Appended after each iteration. Committed to git. Delete after sprint.
```

**File 4: `afk-loop.sh`**

Copy the script from the plugin's `scripts/afk-loop.sh` into the project root. Make it executable.

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
