# Observability — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Generate a summary report when the loop ends, support configurable decision verbosity, and include per-task diff stats.

**Architecture:** Report generation in `pilot-loop.sh` (bash). Verbosity config in `pilot.yaml` with CLI override. Report written to `pilot-report.md` (ephemeral, not committed).

**Tech Stack:** Bash (pilot-loop.sh), Markdown (SKILL.md files, report output), YAML (pilot.yaml template)

---

### Task 1: Add observability config to pilot.yaml template

**Files:**
- Modify: `skills/plan/assets/pilot-yaml-template.yaml`

**Step 1: Add observability section**

Insert after the `guardrails:` section and before `quality:`:

```yaml
observability:
  verbosity: light              # light | medium — controls decisions field detail
```

**Step 2: Commit**

```bash
git add skills/plan/assets/pilot-yaml-template.yaml
git commit -m "feat: add observability.verbosity to pilot.yaml template"
```

---

### Task 2: Add --verbose flag to pilot-loop.sh

**Files:**
- Modify: `scripts/pilot-loop.sh`

**Step 1: Add verbose flag parsing**

In the argument parsing block (the `for arg in "$@"` loop, around lines 11-15), add a case for `--verbose`:

```bash
for arg in "$@"; do
  case $arg in
    --sandbox) SANDBOX=true ;;
    --verbose) VERBOSE=true ;;
  esac
done
```

Add `VERBOSE=false` initialization next to `SANDBOX=false` (around line 9).

**Step 2: Add verbosity to the prompt**

At the end of the PROMPT variable (before the closing single quote), add:

```
VERBOSITY: Write decisions in progress.txt at MEDIUM verbosity (2-3 sentences per task — what was considered, what was chosen, why).
```

But only when `$VERBOSE` is true. Since the prompt is a single-quoted string, we need to construct it conditionally. After the PROMPT variable, add:

```bash
if [ "$VERBOSE" = true ]; then
  PROMPT="$PROMPT
VERBOSITY: Write decisions in progress.txt at MEDIUM verbosity (2-3 sentences per task — what was considered, what was chosen, why)."
fi
```

**Step 3: Update usage comment**

Change line 6 from:
```bash
# Usage: ./pilot-loop.sh [iterations] [--sandbox]
```
to:
```bash
# Usage: ./pilot-loop.sh [iterations] [--sandbox] [--verbose]
```

**Step 4: Commit**

```bash
git add scripts/pilot-loop.sh
git commit -m "feat: add --verbose flag for medium decision verbosity"
```

---

### Task 3: Add report generation to pilot-loop.sh

**Files:**
- Modify: `scripts/pilot-loop.sh`

**Step 1: Capture start time and start commit hash**

After the `trap cleanup EXIT` line and before the PROMPT variable, add:

```bash
# --- Observability: capture baseline ---
PILOT_START_TIME=$(date +%s)
PILOT_START_HASH=$(git rev-parse HEAD 2>/dev/null || echo "none")
PILOT_TASKS_DONE=0
PILOT_TASKS_FAILED=0
PILOT_TASKS_SKIPPED=0
```

**Step 2: Track task results per iteration**

Inside the for loop, after `echo "$result"`, add tracking logic:

```bash
  # Track task outcomes from progress.txt
  if [[ "$result" == *"FAILED"* ]]; then
    ((PILOT_TASKS_FAILED++)) || true
  elif [[ "$result" == *"SKIPPED"* ]] || [[ "$result" == *"escalation"* ]]; then
    ((PILOT_TASKS_SKIPPED++)) || true
  else
    ((PILOT_TASKS_DONE++)) || true
  fi
```

**Step 3: Add report generation function**

After the `cleanup()` function and before `trap cleanup EXIT`, add a `generate_report()` function:

```bash
generate_report() {
  local end_time=$(date +%s)
  local elapsed=$(( (end_time - PILOT_START_TIME) / 60 ))
  local end_hash=$(git rev-parse HEAD 2>/dev/null || echo "none")
  local report_date=$(date +%Y-%m-%d)
  local total=$((PILOT_TASKS_DONE + PILOT_TASKS_FAILED + PILOT_TASKS_SKIPPED))

  # Build report
  local report="PILOT Report — $report_date
═══════════════════════════════════════
Iterations: $1 | Tasks: $PILOT_TASKS_DONE done, $PILOT_TASKS_FAILED failed, $PILOT_TASKS_SKIPPED skipped
Time: ~${elapsed} minutes
"

  # Per-task details from git log
  if [ "$PILOT_START_HASH" != "$end_hash" ] && [ "$PILOT_START_HASH" != "none" ]; then
    report="$report
Tasks:
"
    # Get commits since start
    while IFS= read -r line; do
      local hash=$(echo "$line" | cut -d' ' -f1)
      local msg=$(echo "$line" | cut -d' ' -f2-)
      local stat=$(git diff --stat "$hash~1".."$hash" 2>/dev/null | tail -1 | sed 's/^ */  /')
      report="$report  $hash $msg
$stat
"
    done < <(git log --oneline "$PILOT_START_HASH".."$end_hash" --reverse 2>/dev/null)

    report="$report
Full diff: git diff $PILOT_START_HASH..$end_hash
Per-task:  git diff <hash>~1..<hash>"
  fi

  # Print to terminal
  echo ""
  echo "$report"

  # Write to file
  echo "$report" > pilot-report.md
  echo ""
  echo "Report saved to pilot-report.md"
}
```

**Step 4: Call generate_report on exit**

Update the `cleanup()` function to also call `generate_report`:

```bash
cleanup() {
  generate_report "$i"
  if [ "$PILOT_STASHED" = true ]; then
    echo ""
    echo "Restoring stashed changes..."
    git stash pop
  fi
}
```

Note: `$i` is the loop counter — it tells the report how many iterations ran. If the script exits before the loop starts, `$i` will be empty, which is fine (report shows 0 iterations).

**Step 5: Remove the old exit messages**

The existing "PILOT complete after $i iterations" and "Reached iteration cap" messages are now redundant — the report covers this. Remove the echo blocks at lines 69-74 and 77-81, keeping just `exit 0` for the COMPLETE case.

**Step 6: Commit**

```bash
git add scripts/pilot-loop.sh
git commit -m "feat: generate pilot-report.md with task summary and diff stats on loop exit"
```

---

### Task 4: Update run skill to reference verbosity config

**Files:**
- Modify: `skills/run/SKILL.md`

**Step 1: Update step 9 (Update Progress)**

In the progress entry section, after "Keep entries concise. Sacrifice grammar for the sake of concision.", add:

```markdown
Check `observability.verbosity` in `pilot.yaml` (or `--verbose` flag in loop mode):
- **`light`** (default) — `decisions:` is a one-liner: key choice + reason
- **`medium`** — `decisions:` is 2-3 sentences: what was considered, what was chosen, why
```

**Step 2: Commit**

```bash
git add skills/run/SKILL.md
git commit -m "feat: reference verbosity config in run skill progress entries"
```

---

### Task 5: Update loop skill with observability docs

**Files:**
- Modify: `skills/loop/SKILL.md`

**Step 1: Update the "After Completion" section**

Replace the existing "After Completion" section (which suggests `cat progress.txt`, `git log`, `cat PRD.md`) with:

```markdown
## After Completion

When the loop finishes, `pilot-loop.sh` automatically generates a report:
- **Terminal** — summary printed to stdout
- **File** — full report saved to `pilot-report.md`

The report includes: task count (done/failed/skipped), per-task diff stats, decision log, and git diff commands for drill-in.

Review commands:
\```
cat pilot-report.md              — loop summary + diff stats
cat progress.txt                 — full iteration log
git log --oneline                — commit history
\```

If tasks remain, run `/pilot:loop` again or `/pilot:run` for manual mode.
```

**Step 2: Add --verbose to the Launch section**

In the Launch section, update the launch commands to include the verbose option:

```bash
# Standard launch
./pilot-loop.sh [iterations]

# With verbose decisions (medium verbosity)
./pilot-loop.sh [iterations] --verbose

# With Docker sandbox
./pilot-loop.sh [iterations] --sandbox

# Combined
./pilot-loop.sh [iterations] --sandbox --verbose
```

**Step 3: Commit**

```bash
git add skills/loop/SKILL.md
git commit -m "feat: document report generation and --verbose flag in loop skill"
```

---

### Task 6: Update design.md with observability section

**Files:**
- Modify: `docs/design.md`

**Step 1: Add Observability section**

After the "## Guardrails" section and before "## Recipe Skills", add:

```markdown
## Observability

Transparency features so you know what happened during a loop run.

| Feature | Where | Details |
|---------|-------|---------|
| Summary report | `pilot-loop.sh` → `pilot-report.md` + terminal | Task count, diff stats, decisions, git diff commands. Generated on loop exit. |
| Decision verbosity | `pilot.yaml` + `--verbose` flag | `light` (default, one-liner) or `medium` (2-3 sentences). CLI overrides config. |
| Diff visualization | `pilot-report.md` | Per-task `git diff --stat` + copy-paste commands for full diffs. |

`pilot-report.md` is ephemeral — overwritten each loop run, not committed to git.
```

**Step 2: Update the pilot.yaml example**

In the pilot.yaml example block, add the observability section after `guardrails:` and before `quality:`:

```yaml
observability:
  verbosity: light              # light | medium
```

**Step 3: Commit**

```bash
git add docs/design.md
git commit -m "docs: add observability section to design doc"
```
