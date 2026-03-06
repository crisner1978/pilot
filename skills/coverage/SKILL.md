---
name: coverage
description: Use when improving test coverage, finding untested code paths, or targeting a coverage percentage. Triggers on coverage gaps, uncovered lines, missing tests.
---

# PILOT Coverage — Test Coverage Loop

Iteratively write tests for uncovered code paths until coverage hits your target.

## Arguments

Optional scope: `/pilot:coverage [path] [--target N]`

- **No arguments** — covers entire codebase, default 80% target
- **Directory** — scope to directory: `/pilot:coverage src/lib/`
- **Target** — custom target: `/pilot:coverage --target 90`
- **Both** — `/pilot:coverage src/lib/ --target 95`

## Prerequisites

| Prerequisite | Check |
|---|---|
| pilot.yaml | `.claude/pilot.yaml` must exist — run `/pilot:plan` first |
| Coverage tool | Your test runner must support coverage (vitest, jest, pytest-cov, etc.) |

## How It Works

Generates a coverage report, finds the most critical uncovered code paths, writes tests for ONE area per iteration, re-runs coverage to verify improvement, commits, and repeats until the target is met.

## Setup

Generate an initial coverage report:
```bash
# JavaScript/TypeScript
vitest run --coverage > coverage-report.txt
# or
jest --coverage > coverage-report.txt

# Python
pytest --cov=src --cov-report=text > coverage-report.txt
```

## The Prompt

Replace the prompt in your `afk-loop.sh` with:

```
@coverage-report.txt @progress.txt @.claude/pilot.yaml
You are PILOT running a test coverage loop.

SCOPE: [if path provided, insert here; otherwise "entire codebase"]
TARGET: [if --target provided, use that; otherwise 80%]

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

## Launch

```bash
# HITL — one test file at a time
./afk-loop.sh 1

# AFK — grind to 80%
./afk-loop.sh 30
```
