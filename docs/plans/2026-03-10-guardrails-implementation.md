# Guardrails & Safety — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add three safety guardrails (protected paths, auto-stash, rollback on failure) so `/pilot:loop` is safe to run unsupervised.

**Architecture:** Config-driven guardrails in `pilot.yaml`. Protected paths enforced at the skill level (run/loop). Auto-stash is bash-level in `pilot-loop.sh`. Rollback stashes failed attempts for human review.

**Tech Stack:** Bash (pilot-loop.sh), Markdown (SKILL.md files), YAML (pilot.yaml template)

---

### Task 1: Add sensitive file detection to stack-detection.md

**Files:**
- Modify: `skills/plan/references/stack-detection.md`

**Step 1: Add the sensitive file detection table**

Append after the existing "Feedback Loop Mapping" table:

```markdown
## Sensitive File Detection

Files and directories the agent should never modify without explicit permission.

| Pattern | Category | Why |
|---------|----------|-----|
| `.env*` | Secrets | Environment variables, API keys |
| `*.pem`, `*.key`, `*.cert` | Secrets | SSL/TLS certificates and keys |
| `*.secret`, `credentials.*` | Secrets | Credential files |
| `migrations/`, `db/migrate/` | Database | Migration files — order-sensitive, destructive |
| `docker-compose.prod.*`, `*.production.*` | Production | Production-specific config |
| `infrastructure/`, `terraform/`, `*.tf` | Infrastructure | Infra-as-code — affects live systems |
| `.github/workflows/`, `.gitlab-ci.yml`, `ci/` | CI/CD | Pipeline config — affects deployment |
| `*.lock` | Lockfiles | Package lockfiles — should only change via package manager |

Detection: During `/pilot:plan` Phase 1, glob for these patterns. If any exist, add them to `guardrails.protected_paths` in `pilot.yaml`.
```

**Step 2: Commit**

```bash
git add skills/plan/references/stack-detection.md
git commit -m "docs: add sensitive file detection table to stack-detection reference"
```

---

### Task 2: Add guardrails section to pilot.yaml template

**Files:**
- Modify: `skills/plan/assets/pilot-yaml-template.yaml`

**Step 1: Add the guardrails section**

Insert after the `loop:` section and before `quality:`:

```yaml
guardrails:
  protected_paths: [auto-detected patterns, e.g. ".env*", "migrations/"]
```

**Step 2: Commit**

```bash
git add skills/plan/assets/pilot-yaml-template.yaml
git commit -m "feat: add guardrails.protected_paths to pilot.yaml template"
```

---

### Task 3: Update /pilot:plan to detect and configure protected paths

**Files:**
- Modify: `skills/plan/SKILL.md`

**Step 1: Add protected path detection to Phase 1**

In Phase 1 (Context Scan), after the stack detection output block, add:

```markdown
**Also detect sensitive files** — glob for patterns in `references/stack-detection.md` "Sensitive File Detection" table. If any matches exist, collect them for the guardrails config.

Present detected protected paths:
\```
Protected paths detected:
  .env, .env.local          — secrets
  migrations/               — database migrations
  .github/workflows/        — CI/CD pipelines
\```
```

**Step 2: Add AskUserQuestion for protected paths**

After the detection output, add a question letting the user review/edit:

```markdown
Use AskUserQuestion to confirm protected paths:

\```json
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
\```
```

**Step 3: Update Phase 4 instructions**

In Phase 4 (Generate Artifacts), for the pilot.yaml generation, add a note:

```markdown
Include `guardrails.protected_paths` from Phase 1 detection. If no paths were detected, omit the section.
```

**Step 4: Commit**

```bash
git add skills/plan/SKILL.md
git commit -m "feat: detect and configure protected paths in /pilot:plan"
```

---

### Task 4: Add auto-stash to pilot-loop.sh

**Files:**
- Modify: `scripts/pilot-loop.sh`

**Step 1: Add stash logic at the top of the script**

After the `CLAUDE_CMD` setup block (line 20) and before the `PROMPT` variable, add:

```bash
# --- Guardrail: Auto-stash uncommitted changes ---
PILOT_STASHED=false
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Stashing uncommitted changes..."
  git stash --include-untracked -m "pilot/pre-loop-stash"
  PILOT_STASHED=true
fi

cleanup() {
  if [ "$PILOT_STASHED" = true ]; then
    echo ""
    echo "Restoring stashed changes..."
    git stash pop
  fi
}
trap cleanup EXIT
```

**Step 2: Verify the trap works with existing exit paths**

The script has `exit 0` on COMPLETE and implicit exit at end. The `trap cleanup EXIT` catches both. No changes needed to exit paths.

**Step 3: Commit**

```bash
git add scripts/pilot-loop.sh
git commit -m "feat: auto-stash uncommitted changes before loop starts"
```

---

### Task 5: Add protected path checking + rollback to /pilot:run

**Files:**
- Modify: `skills/run/SKILL.md`

**Step 1: Add protected path check to step 5 (Implement)**

In "### 5. Implement", add a new rule to the existing list:

```markdown
- **Check protected paths** — before modifying any file, check `guardrails.protected_paths` in `pilot.yaml`. If the file matches a protected pattern:
  - **In loop mode** (no human present): skip this task, log as escalation in progress.txt, do NOT modify the file
  - **In manual mode** (human present): use AskUserQuestion to ask permission:
    ```json
    {
      "questions": [{
        "question": "Task requires modifying a protected path: [path]. Allow?",
        "header": "Protected path",
        "options": [
          {"label": "Allow", "description": "Proceed — I understand the risk"},
          {"label": "Skip task", "description": "Skip this task and move to the next one"}
        ],
        "multiSelect": false
      }]
    }
    ```
```

**Step 2: Add rollback to step 7 (Handle Failures)**

In "### 7. Handle Failures", update the "When stopping on failure" block to add stash cleanup:

```markdown
When stopping on failure:
- Do NOT commit broken code
- **Stash the failed attempt** for human review: `git stash push -m "pilot/failed-task-[N]: [description]"`
- Report exactly what failed and why
- Suggest what the human should look at
- Append a failure entry to progress.txt (include `stash: pilot/failed-task-[N]`)
```

**Step 3: Update failure entry format in step 9**

Add `stash:` field to the failure template:

```markdown
## [N] — PRD #[N]: [Task description]
time: YYYY-MM-DD HH:MM
status: FAILED — [which loop]
error: [concise error description]
attempted: [what you tried]
needs: [what the human should look at]
stash: pilot/failed-task-[N]: [description]
```

**Step 4: Commit**

```bash
git add skills/run/SKILL.md
git commit -m "feat: add protected path checking and rollback-on-failure to /pilot:run"
```

---

### Task 6: Add protected paths to loop prompt + document guardrails in loop skill

**Files:**
- Modify: `skills/loop/SKILL.md`
- Modify: `scripts/pilot-loop.sh` (add to prompt)

**Step 1: Add guardrails reminder to the loop prompt in pilot-loop.sh**

In the `PROMPT` variable, add after line 6 ("Run ALL feedback loops..."):

```
GUARDRAILS: Check guardrails.protected_paths in pilot.yaml before modifying ANY file. If a file matches a protected pattern, SKIP the task — log as escalation in progress.txt and move on. Do NOT modify protected files in loop mode.
If a task fails all retries, stash the failed attempt: git stash push -m "pilot/failed-task-N: [description]" — then continue to next task.
```

**Step 2: Add guardrails section to loop SKILL.md**

After "## Safety Notes", add:

```markdown
## Guardrails

The loop enforces these safety guardrails automatically:

- **Auto-stash** — `pilot-loop.sh` stashes uncommitted changes before starting and restores them on exit (success, failure, or Ctrl+C)
- **Protected paths** — files matching `guardrails.protected_paths` in `pilot.yaml` are never modified in loop mode. Tasks requiring protected files are skipped and logged as escalations.
- **Rollback on failure** — failed task attempts are stashed (`pilot/failed-task-N`) for human review. The working tree stays clean for the next iteration.

Review guardrails config: `cat .claude/pilot.yaml | grep -A 10 guardrails`
```

**Step 3: Commit**

```bash
git add skills/loop/SKILL.md scripts/pilot-loop.sh
git commit -m "feat: add guardrails to loop prompt and document in loop skill"
```

---

### Task 7: Update design.md and commit

**Files:**
- Modify: `docs/design.md`

**Step 1: Add guardrails to the Config File section**

In the pilot.yaml example block (around line 220), add the guardrails section after `loop:`:

```yaml
guardrails:
  protected_paths:
    - ".env*"
    - "*.pem"
    - "*.key"
    - "migrations/"
```

**Step 2: Add a Guardrails section**

After "## Output Modes" and before "## Recipe Skills", add:

```markdown
## Guardrails

Safety features that make loop mode safe to run unsupervised.

| Guardrail | Where | Behavior |
|-----------|-------|----------|
| Protected paths | `pilot.yaml` + run/loop skills | Auto-detected during `/pilot:plan`. Hard-blocked in loop mode, prompted in manual mode. |
| Auto-stash | `pilot-loop.sh` | Stashes uncommitted work before loop starts, restores on exit via bash trap. |
| Rollback on failure | `/pilot:run` skill | Failed attempts stashed as `pilot/failed-task-N` for human review. Working tree stays clean. |
```

**Step 3: Commit**

```bash
git add docs/design.md
git commit -m "docs: add guardrails section to design doc"
```
