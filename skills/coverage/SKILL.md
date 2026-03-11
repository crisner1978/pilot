---
name: coverage
description: Use when improving test coverage, finding untested code paths, or targeting a coverage percentage. Triggers on coverage gaps, uncovered lines, missing tests.
---

# PILOT Coverage — Test Coverage Loop

Iteratively write tests for uncovered code paths until coverage hits your target.

**Announce at start:** "Running PILOT coverage loop."

## Arguments

Optional scope: `/pilot:coverage [path] [--target N]`

- **No arguments** — covers entire codebase, default 80% target
- **Directory** — scope to directory: `/pilot:coverage src/lib/`
- **Target** — custom target: `/pilot:coverage --target 90`
- **Both** — `/pilot:coverage src/lib/ --target 95`

## Execution

### 1. Validate Prerequisites

Check that these exist:
- `.claude/pilot.yaml` — must exist. If missing: "Run `/pilot:plan` first."
- Coverage tool — test runner must support coverage (vitest, jest, pytest-cov, etc.)

### 2. Setup

Generate an initial coverage report:

```bash
# JavaScript/TypeScript
vitest run --coverage > coverage-report.txt
# or: jest --coverage > coverage-report.txt

# Python
pytest --cov=src --cov-report=text > coverage-report.txt
```

Ensure `progress.txt` exists (create empty if not).

### 3. Write Ephemeral Prompt

Parse arguments to determine SCOPE and TARGET, then write the prompt file. Use the Write tool to create `.claude/pilot-prompt.md` with this content (replacing SCOPE and TARGET with actual values):

```
@coverage-report.txt @progress.txt @.claude/pilot.yaml
You are PILOT running a test coverage loop.

SCOPE: [resolved scope — path or "entire codebase"]
TARGET: [resolved target — number or 80]%

1. Read the coverage report. Find the most critical uncovered code paths within SCOPE.
2. Write tests for ONE uncovered area — prioritize business logic over utilities.
3. Run the test suite to verify new tests pass.
4. Regenerate coverage report and update coverage-report.txt.
5. Run all feedback loops from pilot.yaml.
6. Commit if all pass. Include coverage-report.txt and progress.txt.
7. Append to progress.txt: what you tested, coverage before/after.
8. If coverage meets TARGET within SCOPE, output <promise>COMPLETE</promise>.

ONE test file per iteration. Sacrifice grammar for concision in progress.txt.
```

### 4. Confirm and Launch

Use AskUserQuestion to confirm:

```json
{
  "questions": [{
    "question": "Launch coverage loop?\n  Scope: [scope]\n  Target: [target]%\n  Coverage tool: [detected tool]",
    "header": "Coverage",
    "options": [
      {"label": "Launch (Recommended)", "description": "Start coverage loop with settings above"},
      {"label": "Change target", "description": "Set a different coverage target"},
      {"label": "Cancel", "description": "Don't launch"}
    ],
    "multiSelect": false
  }]
}
```

After confirmation, launch the loop:

```bash
PILOT_LOOP="${CLAUDE_SKILL_DIR}/../../scripts/pilot-loop.sh"
bash "$PILOT_LOOP" 20
```

### 5. Results

`pilot-loop.sh` auto-deletes `.claude/pilot-prompt.md` on exit. Report final coverage from `coverage-report.txt`.
