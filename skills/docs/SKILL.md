---
name: docs
description: Use when generating API documentation, adding JSDoc comments, documenting public interfaces, or filling documentation gaps. Triggers on missing docs, JSDoc, docstrings, API documentation.
---

# PILOT Docs — API Documentation Loop

Generate or update API documentation from source code.

## Arguments

Optional scope: `/pilot:docs [path]`

- **No arguments** — documents all undocumented public APIs
- **File** — document one file: `/pilot:docs src/api/auth.ts`
- **Directory** — scope to directory: `/pilot:docs src/lib/`

## Prerequisites

| Prerequisite | Check |
|---|---|
| pilot.yaml | `.claude/pilot.yaml` must exist — run `/pilot:plan` first |

## How It Works

Finds public functions, classes, or endpoints missing documentation, writes clear JSDoc/docstrings with params, return types, and examples, verifies with feedback loops, and repeats.

## The Prompt

```
@progress.txt @.claude/pilot.yaml
You are PILOT running a documentation loop.

1. Find ONE public function, class, method, or API endpoint missing documentation.
2. Prioritize: exported functions > public methods > internal utilities.
3. Write clear, concise JSDoc/docstring:
   - @param for each parameter with type and description
   - @returns with type and description
   - One usage example
   - @throws if applicable
4. Run all feedback loops from pilot.yaml.
5. Commit if all pass. Include progress.txt.
6. Append to progress.txt: function/class name, file.
7. If all public APIs are documented, output <promise>COMPLETE</promise>.

ONE function/class per iteration. Keep docs concise — not novels.
```

## Launch

```bash
./pilot-loop.sh 30
```
