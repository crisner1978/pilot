---
name: add
description: Use when adding a new task to an existing PILOT PRD mid-sprint, inserting work into the backlog without re-running plan. Triggers on add task, new task, backlog addition, insert task.
---

# PILOT Add — Insert Task into PRD

Add a task to an existing PRD without re-running `/pilot:plan`.

**Announce at start:** "Adding a task to the PRD."

## Arguments

`/pilot:add [description]`

- **With description** — `/pilot:add "Add retry logic to the API client"` — adds directly
- **No description** — prompts for what to add

## Prerequisites

| Prerequisite | Check |
|---|---|
| PRD.md | Must exist — run `/pilot:plan` first |

## How It Works

### 1. Get the Task

If arguments were provided, use them as the task description.

Otherwise, ask: "What task should be added? Describe the feature, fix, or goal."

### 2. Read Current PRD

Read `PRD.md` to understand:
- How many tasks exist
- What numbering scheme is used
- What format tasks follow (validation, files fields)
- Where in the priority order this task belongs

### 3. Determine Priority

Use AskUserQuestion to ask where it should go:

```json
{
  "questions": [{
    "question": "Where should this task be prioritized?",
    "header": "Priority",
    "options": [
      {"label": "Next up", "description": "Insert as the next task to be executed"},
      {"label": "End of backlog", "description": "Add to the bottom — do it last"},
      {"label": "After current", "description": "Insert after the currently in-progress task"}
    ],
    "multiSelect": false
  }]
}
```

### 4. Generate Task Entry

Format the task to match the existing PRD style:

```markdown
- [ ] **N.** [Task description]
  - Acceptance: [one-liner — what "done" looks like]
  - Validation: [infer from pilot.yaml feedback loops]
  - Files: [estimate if possible, or "TBD"]
```

### 5. Insert into PRD

Use the Edit tool to insert the task at the chosen position. Renumber subsequent tasks if inserting in the middle.

### 6. Confirm

Report what was added:
```
Added to PRD.md:
  - [ ] **7.** Add retry logic to the API client
    Position: next up (before task #7, which is now #8)

Run /pilot:run to start working on it.
```

## Notes

- Do NOT re-run `/pilot:plan` — this is a lightweight addition
- Do NOT modify `.claude/pilot.yaml` or `progress.txt`
- If the user describes something complex, break it into multiple tasks and confirm before adding
