#!/bin/bash
set -e

# PILOT — Plan, Iterate, Loop, Observe, Test
# Autonomous loop script
# Usage: ./pilot-loop.sh [iterations] [--sandbox] [--verbose]

ITERATIONS=${1:-20}
SANDBOX=false
VERBOSE=false

for arg in "$@"; do
  case $arg in
    --sandbox) SANDBOX=true ;;
    --verbose) VERBOSE=true ;;
  esac
done

CLAUDE_CMD="claude"
if [ "$SANDBOX" = true ]; then
  CLAUDE_CMD="docker sandbox run claude"
fi

# --- Guardrail: Auto-stash uncommitted changes ---
PILOT_STASHED=false
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Stashing uncommitted changes..."
  git stash --include-untracked -m "pilot/pre-loop-stash"
  PILOT_STASHED=true
fi

cleanup() {
  generate_report "${i:-0}"
  if [ "$PILOT_STASHED" = true ]; then
    echo ""
    echo "Restoring stashed changes..."
    git stash pop
  fi
}

generate_report() {
  local end_time=$(date +%s)
  local elapsed=$(( (end_time - PILOT_START_TIME) / 60 ))
  local end_hash=$(git rev-parse HEAD 2>/dev/null || echo "none")
  local report_date=$(date +%Y-%m-%d)

  local report="PILOT Report — $report_date
═══════════════════════════════════════
Iterations: $1 | Tasks: $PILOT_TASKS_DONE done, $PILOT_TASKS_FAILED failed, $PILOT_TASKS_SKIPPED skipped
Time: ~${elapsed} minutes
"

  if [ "$PILOT_START_HASH" != "$end_hash" ] && [ "$PILOT_START_HASH" != "none" ]; then
    report="$report
Tasks:
"
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

  echo ""
  echo "$report"
  echo "$report" > pilot-report.md
  echo ""
  echo "Report saved to pilot-report.md"
}

trap cleanup EXIT

# --- Observability: capture baseline ---
PILOT_START_TIME=$(date +%s)
PILOT_START_HASH=$(git rev-parse HEAD 2>/dev/null || echo "none")
PILOT_TASKS_DONE=0
PILOT_TASKS_FAILED=0
PILOT_TASKS_SKIPPED=0

PROMPT='@PRD.md @progress.txt @.claude/pilot.yaml
You are PILOT — an autonomous coding agent running in loop mode.

1. Read the PRD, progress file, and pilot config.
2. Find the highest-priority INCOMPLETE task (unchecked checkbox).
3. Implement it fully — write code, follow existing patterns in the codebase.
4. Run ALL feedback loops listed in pilot.yaml (in order: typecheck, test, lint, browser, custom).
5. If any feedback loop fails, fix the issue and retry (up to 3 attempts per loop).
GUARDRAILS: Check guardrails.protected_paths in pilot.yaml before modifying ANY file. If a file matches a protected pattern, SKIP the task — log as escalation in progress.txt and move on. Do NOT modify protected files in loop mode.
If a task fails all retries, stash the failed attempt: git stash push -m "pilot/failed-task-N: [description]" — then continue to next task.
6. If still failing after retries, skip this task, note the failure in progress.txt, and move to the next task.
7. Only commit if ALL feedback loops pass.
8. After each task, append a concise entry to progress.txt: task ref, files, decisions, feedback results, commit hash. Sacrifice grammar for concision.
9. Include progress.txt and PRD.md in every commit — they belong in git history.
10. If ALL tasks in the PRD are complete, output exactly: <promise>COMPLETE</promise>

CRITICAL: Only work on ONE task per iteration. Do not batch multiple tasks.'

if [ "$VERBOSE" = true ]; then
  PROMPT="$PROMPT
VERBOSITY: Write decisions in progress.txt at MEDIUM verbosity (2-3 sentences per task — what was considered, what was chosen, why)."
fi

for ((i=1; i<=$ITERATIONS; i++)); do
  echo ""
  echo "============================================"
  echo "  PILOT — Iteration $i / $ITERATIONS"
  echo "============================================"
  echo ""

  result=$($CLAUDE_CMD --permission-mode acceptEdits -p "$PROMPT")

  echo "$result"

  # Track task outcomes
  if [[ "$result" == *"FAILED"* ]]; then
    ((PILOT_TASKS_FAILED++)) || true
  elif [[ "$result" == *"SKIPPED"* ]] || [[ "$result" == *"escalation"* ]]; then
    ((PILOT_TASKS_SKIPPED++)) || true
  else
    ((PILOT_TASKS_DONE++)) || true
  fi

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    exit 0
  fi
done

echo "Reached iteration cap ($ITERATIONS)."
