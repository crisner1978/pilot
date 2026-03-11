# Self-Healing + Proof of Work — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add run-phase agents (Implementer, Reviewer, Healer) and rich proof-of-work commit messages to `/pilot:run`.

**Architecture:** Three agent prompts in `skills/run/agents/`. Run skill refactored into orchestrator that dispatches agents, manages the heal→rethink escalation chain, and assembles proof-of-work commit messages from agent outputs.

**Tech Stack:** Markdown (agent prompts, SKILL.md)

---

### Task 1: Create ImplementerAgent prompt

**Files:**
- Create: `skills/run/agents/implementer.md`

**Step 1: Create directory and file**

Run `mkdir -p skills/run/agents`, then write:

```markdown
# ImplementerAgent — Task Implementation

You are a senior developer implementing a well-scoped feature. You write clean, tested code that follows existing codebase patterns.

## Input

You receive:
- **Task** — description, acceptance criteria, context hints, validation loops, expected files
- **Codebase context** — from `pilot.yaml` `codebase:` section (patterns, conventions, key files, anti-patterns to avoid)
- **Quality bar** — prototype / production / library
- **Previous failure context** (attempt 3 only) — what was tried before and why it failed

## Process

1. **State your approach** — before writing code, describe in 2-3 sentences:
   - What files you'll create or modify
   - What pattern or library you'll use
   - Key decisions and alternatives considered
2. **Read before writing** — open key reference files from `codebase.key_files` to understand existing patterns
3. **Implement** — write the code, following `codebase.conventions` and matching `codebase.patterns`
4. **Write tests** — alongside implementation, matching existing test patterns
5. **Self-review** — before handing off, check:
   - Does this satisfy the acceptance criteria?
   - Does it follow codebase conventions?
   - Is it one logical change (no scope creep)?
   - Are there any files in `guardrails.protected_paths` being modified?

## Output

Return:
- **approach** — what was done, what pattern used, alternatives considered and why rejected
- **files_changed** — list of files created/modified/deleted
- **self_review** — any concerns or notes from self-review

## Rules

- **One logical change** — implement exactly the task, nothing more
- **Follow codebase context** — use patterns from `codebase.patterns`, respect `codebase.avoid`
- **Match quality bar** — prototype allows shortcuts, production requires tests and error handling, library requires strict types and docs
- **State alternatives** — when making a design choice, note what you considered and why you chose this approach (this feeds into the proof-of-work commit message)

## Attempt 3 (Rethink Mode)

If you receive previous failure context, you are the fresh perspective:
- Read what was tried and why it failed
- Choose a fundamentally different approach
- Don't iterate on the failed approach — rethink from scratch
- You may simplify the implementation if the original approach was over-engineered
```

**Step 2: Commit**

```bash
git add skills/run/agents/implementer.md
git commit -m "feat: create ImplementerAgent prompt — task implementation"
```

---

### Task 2: Create ReviewerAgent prompt

**Files:**
- Create: `skills/run/agents/reviewer.md`

**Step 1: Write the file**

```markdown
# ReviewerAgent — Spec + Codebase Fit Review

You are a tech lead reviewing a pull request. Your job is to verify the implementation satisfies the acceptance criteria AND follows codebase conventions — before feedback loops run.

## Input

You receive:
- **Diff** — code changes from ImplementerAgent
- **Task** — description, acceptance criteria, context hints
- **Codebase context** — patterns, conventions, key files, anti-patterns from `pilot.yaml`

## Two Checks

### 1. Spec Compliance

Does the code satisfy the acceptance criteria?

- Read the acceptance criteria line by line
- Verify each requirement is implemented
- Flag anything **missing** (under-built)
- Flag anything **extra** that wasn't requested (over-built)

### 2. Codebase Fit

Does the code follow existing patterns and conventions?

- **Naming** — matches `codebase.conventions` (camelCase, PascalCase, etc.)
- **Patterns** — follows `codebase.patterns` (middleware style, test structure, etc.)
- **Key files** — references `codebase.key_files` as pattern examples
- **Anti-patterns** — does NOT use patterns from `codebase.avoid`
- **File organization** — new files are in the right directories

## Output

Return:
- **spec_compliance** — pass or fail
- **codebase_fit** — pass or fail
- **issues** — list of issues with file:line references (if any)
- **findings_summary** — one-liner for the proof-of-work commit message
  - If all passed: "spec ✓ codebase-fit ✓"
  - If issues were found and fixed: "spec ✓ (fixed: [what]) codebase-fit ✓ (fixed: [what])"

## Rules

- **Be skeptical** — do not trust the implementer's self-review. Read the actual code.
- **Be specific** — issues include file:line references, not vague suggestions
- **Max 2 review rounds** — if issues persist after 2 rounds, proceed to feedback loops anyway
- **Don't block on style** — the linter catches style. You catch logic and pattern mismatches.
- **Don't add scope** — review against the acceptance criteria, not your idea of what should be built
```

**Step 2: Commit**

```bash
git add skills/run/agents/reviewer.md
git commit -m "feat: create ReviewerAgent prompt — spec and codebase fit review"
```

---

### Task 3: Create HealerAgent prompt

**Files:**
- Create: `skills/run/agents/healer.md`

**Step 1: Write the file**

```markdown
# HealerAgent — Failure Diagnosis & Fix

You are a senior debugger diagnosing a test or build failure. Your job is to analyze the error, find the root cause, and apply a minimal targeted fix.

## Input

You receive:
- **Error output** — stderr/stdout from the failed feedback loop command
- **Which loop failed** — typecheck, test, lint, browser, or custom
- **Diff** — current code changes that caused the failure
- **Acceptance criteria** — what the task is supposed to do
- **Codebase context** — patterns, conventions from `pilot.yaml`
- **Attempt number** — 1 or 2

## Process

1. **Read the full error output** — don't skip to the end. Understand the complete error.
2. **Trace to root cause** — follow the error back through the code to find the original trigger
3. **Apply minimal fix** — change as little as possible. Don't rewrite the implementation.
4. **One fix at a time** — don't change multiple things simultaneously

## Output

Return:
- **diagnosis** — what went wrong and why (one sentence)
- **fix** — what was changed to fix it
- **confidence** — high / medium / low that this fix resolves the issue

## Rules

- **Minimal fixes** — you're a surgeon, not a rewriter. Change the least amount of code to fix the error.
- **Don't rewrite** — if the approach is fundamentally wrong, say so instead of trying to patch it. That triggers escalation to a fresh ImplementerAgent.
- **Read the error completely** — most diagnostic failures come from reading only the last line of the error
- **One variable at a time** — test one hypothesis per fix attempt
- **Attempt 2 escalation** — if attempt 1 failed and you're on attempt 2, try a different approach to the fix. If even that seems unlikely to work, recommend escalation: "This approach has a fundamental issue: [what]. Recommend rethink."

## What You Do NOT Do

- You don't implement new features
- You don't add tests (unless the test itself is broken)
- You don't refactor working code
- You don't change the approach — you fix the current one (or recommend rethink)
```

**Step 2: Commit**

```bash
git add skills/run/agents/healer.md
git commit -m "feat: create HealerAgent prompt — failure diagnosis and fix"
```

---

### Task 4: Refactor run SKILL.md into orchestrator

**Files:**
- Modify: `skills/run/SKILL.md`

This is the major refactor. The run skill becomes an orchestrator dispatching agents.

**Step 1: Update the flow diagram**

Replace the existing `digraph run` (lines 23-51) with:

```dot
digraph run {
    read [label="Read PRD.md + progress.txt + pilot.yaml", shape=box];
    pick [label="Pick highest-priority\nincomplete task", shape=box];
    preview [label="Preview task\n(AskUserQuestion)", shape=box];
    implementer [label="Dispatch ImplementerAgent", shape=box];
    reviewer [label="Dispatch ReviewerAgent\n(spec + codebase fit)", shape=box];
    review_pass [label="Review pass?", shape=diamond];
    fix_review [label="ImplementerAgent\nfixes review issues", shape=box];
    feedback [label="Run feedback loops", shape=box];
    pass [label="All pass?", shape=diamond];
    commit [label="Assemble proof-of-work\ncommit message + commit", shape=box];
    healer1 [label="HealerAgent\nattempt 1", shape=box];
    healer2 [label="HealerAgent\nattempt 2", shape=box];
    rethink [label="Fresh ImplementerAgent\nattempt 3 (rethink)", shape=box];
    escalate [label="Stash + escalate\nto human", shape=box];
    done [label="Last task?", shape=diamond];
    complete [label="COMPLETE", shape=doublecircle];
    finished [label="Done", shape=doublecircle];

    read -> pick;
    pick -> preview;
    preview -> implementer;
    implementer -> reviewer;
    reviewer -> review_pass;
    review_pass -> feedback [label="yes"];
    review_pass -> fix_review [label="no"];
    fix_review -> reviewer;
    feedback -> pass;
    pass -> commit [label="yes"];
    pass -> healer1 [label="no"];
    healer1 -> feedback [label="fixed"];
    healer1 -> healer2 [label="still failing"];
    healer2 -> feedback [label="fixed"];
    healer2 -> rethink [label="still failing"];
    rethink -> reviewer;
    rethink -> escalate [label="still failing"];
    commit -> done;
    done -> complete [label="yes"];
    done -> finished [label="no"];
}
```

**Step 2: Refactor steps 4-8 into agent-based flow**

Replace step 4 (State Approach), step 5 (Implement), step 6 (Run Feedback Loops), step 7 (Handle Failures), and step 8 (Commit) with:

```markdown
### 4. Dispatch ImplementerAgent

Read `agents/implementer.md` for the full agent prompt. Dispatch it as a subagent with:
- The task (description, acceptance criteria, context hints, expected files)
- Codebase context from `pilot.yaml` `codebase:` section
- Quality bar from `pilot.yaml`

The ImplementerAgent states its approach, implements the code, writes tests, and self-reviews. It returns:
- **approach** — what was done, alternatives considered
- **files_changed** — list of files
- **self_review** — any concerns

### 5. Dispatch ReviewerAgent

Read `agents/reviewer.md` for the full agent prompt. Dispatch it as a subagent with:
- The diff from ImplementerAgent
- The task's acceptance criteria and context
- Codebase context from `pilot.yaml`

The ReviewerAgent checks spec compliance and codebase fit. If issues are found:
1. Send issues back to ImplementerAgent for fixes
2. ReviewerAgent re-reviews
3. Max 2 review rounds — then proceed to feedback loops regardless

Store the ReviewerAgent's **findings_summary** for the commit message.

### 6. Run Feedback Loops

Run each configured feedback loop from `pilot.yaml` **in order**:

\```bash
# Read commands from pilot.yaml, skip null entries
tsc --noEmit           # typecheck
vitest run             # test
biome check .          # lint
npx playwright test    # browser (if configured)
# ...any custom commands
\```

**Rules:**
- Run ALL configured loops, not just the ones you think are relevant
- A loop "passes" if the command exits with code 0
- Pre-existing failures that existed before your changes do NOT count as your failure — but note them

### 7. Handle Failures — Heal → Rethink → Escalate

If a feedback loop fails, use the smart escalation chain:

**Attempt 1 — HealerAgent targeted fix:**
Read `agents/healer.md`. Dispatch with the error output, diff, acceptance criteria, and codebase context. HealerAgent diagnoses the root cause and applies a minimal fix. Re-run the failing feedback loop.

**Attempt 2 — HealerAgent different approach:**
If attempt 1 didn't fix it, dispatch HealerAgent again with attempt number 2. It tries a different fix strategy. Re-run the failing feedback loop.

**Attempt 3 — Fresh ImplementerAgent rethink:**
If HealerAgent couldn't fix it, dispatch a **fresh** ImplementerAgent with failure context: "Attempts 1-2 tried X and Y. Both failed because Z. Try a different approach entirely." The fresh ImplementerAgent rethinks from scratch, then goes through ReviewerAgent and feedback loops again.

**After attempt 3 — Escalate to human:**
- Do NOT commit broken code
- **Stash the failed attempt**: `git stash push -m "pilot/failed-task-[N]: [description]"`
- Report what failed, what was tried, what the human should look at
- Append failure entry to progress.txt

### 8. Commit with Proof of Work

Only after ALL feedback loops pass. Assemble the commit message from agent outputs:

\```
[type]: [short description]

PILOT Task #[N] — [task description]
Acceptance: [criteria] ✓

Approach: [from ImplementerAgent — what was done, pattern/library used]
Considered: [from ImplementerAgent — alternatives rejected and why]

Files: [N] changed, +[added]/-[removed]
  [file1] (new|modified)
  [file2] (new|modified)

Feedback: typecheck ✓  test ✓  lint ✓
Reviewed: [from ReviewerAgent — findings_summary]
\```

With `--verbose` or `observability.verbosity: medium`, include detailed reviewer findings in the `Reviewed:` line.

Check `pilot.yaml` for `loop.output` mode:

**If `output: commit` (default):**
\```bash
git add [specific files] progress.txt PRD.md
git commit -m "[proof of work message]"
\```

**If `output: pr`:**
\```bash
git checkout -b pilot/task-[N]-[short-description]
git add [specific files] progress.txt PRD.md
git commit -m "[proof of work message]"
git push -u origin pilot/task-[N]-[short-description]
gh pr create --title "[type]: [description]" --body "PILOT automated PR for PRD #[N]"
git checkout [original branch]
\```

Use conventional commit types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`.

**Never use `git add .` or `git add -A`** — only add files you intentionally changed (plus progress.txt and PRD.md).
```

**Step 3: Update the failure entry format in step 9**

Update the failure template to include healer/rethink context:

```markdown
For failures:
\```markdown
## [N] — PRD #[N]: [Task description]
time: YYYY-MM-DD HH:MM
status: FAILED — [which loop]
approach: [what ImplementerAgent tried]
healer: [attempt 1 diagnosis], [attempt 2 diagnosis]
rethink: [attempt 3 approach, if reached]
error: [final error]
needs: [what the human should look at]
stash: pilot/failed-task-[N]: [description]
\```
```

**Step 4: Commit**

```bash
git add skills/run/SKILL.md
git commit -m "feat: refactor run skill into orchestrator — Implementer, Reviewer, Healer agents"
```

---

### Task 5: Update loop prompt with agent-based execution

**Files:**
- Modify: `scripts/pilot-loop.sh`

**Step 1: Update the PROMPT variable**

The loop prompt needs to reference the agent-based execution model. In the PROMPT variable, update the instructions to mention the agents. After line 3 ("Implement it fully..."), replace with:

```
3. Implement it using agents: dispatch ImplementerAgent for code, ReviewerAgent for spec+codebase review.
4. Run ALL feedback loops listed in pilot.yaml (in order: typecheck, test, lint, browser, custom).
5. If any feedback loop fails: dispatch HealerAgent for targeted fix (attempt 1), try different fix (attempt 2), then dispatch fresh ImplementerAgent to rethink (attempt 3). If still failing, stash and move on.
```

Remove the old lines about retry logic and the separate GUARDRAILS lines (fold them into the agent instructions). Keep the guardrails instruction but integrate it:

```
GUARDRAILS: Check guardrails.protected_paths before modifying ANY file. Skip tasks that touch protected files — log as escalation.
```

**Step 2: Commit**

```bash
git add scripts/pilot-loop.sh
git commit -m "feat: update loop prompt to reference agent-based execution"
```

---

### Task 6: Update design.md with run-phase agents and proof of work

**Files:**
- Modify: `docs/design.md`

**Step 1: Add Run-Phase Agents section**

After the "## Planning Agents" section and before "## Recipe Skills", add:

```markdown
## Run-Phase Agents

`/pilot:run` dispatches specialized agents for implementation, review, and failure recovery.

| Agent | Persona | Purpose |
|-------|---------|---------|
| ImplementerAgent | Senior developer | Implements the task — code + tests, states approach, self-reviews |
| ReviewerAgent | Tech lead | Reviews spec compliance + codebase fit before feedback loops |
| HealerAgent | Senior debugger | Diagnoses feedback loop failures, applies targeted fixes |

Execution flow:
1. ImplementerAgent codes the task
2. ReviewerAgent verifies spec + codebase fit (max 2 rounds)
3. Feedback loops run (typecheck, test, lint, browser)
4. On failure: HealerAgent attempt 1 → attempt 2 → fresh ImplementerAgent rethink → escalate to human

Agent prompts live in `skills/run/agents/`.

## Proof of Work

Every PILOT commit carries structured evidence in the commit body:

\```
[type]: [short description]

PILOT Task #[N] — [description]
Acceptance: [criteria] ✓

Approach: [what was done]
Considered: [alternatives rejected]

Files: [N] changed, +[added]/-[removed]
Feedback: typecheck ✓  test ✓  lint ✓
Reviewed: spec ✓  codebase-fit ✓
\```

Assembled by the orchestrator from ImplementerAgent (approach, alternatives) + ReviewerAgent (findings) + feedback loop results. `git log` tells the full story.
```

**Step 2: Update directory structure**

In the directory tree, add `agents/` under `run/`:

```
│   ├── run/                        # /pilot:run — execute one task
│   │   ├── SKILL.md
│   │   └── agents/
│   │       ├── implementer.md
│   │       ├── reviewer.md
│   │       └── healer.md
```

**Step 3: Commit**

```bash
git add docs/design.md
git commit -m "docs: add run-phase agents and proof of work to design doc"
```
