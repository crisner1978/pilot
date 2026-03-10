#!/bin/bash
set -e

# PILOT — Plan, Iterate, Loop, Observe, Test
# Autonomous loop script
# Usage: ./pilot-loop.sh [iterations] [--sandbox]

ITERATIONS=${1:-20}
SANDBOX=false

for arg in "$@"; do
  case $arg in
    --sandbox) SANDBOX=true ;;
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
  if [ "$PILOT_STASHED" = true ]; then
    echo ""
    echo "Restoring stashed changes..."
    git stash pop
  fi
}
trap cleanup EXIT

PROMPT='@PRD.md @progress.txt @.claude/pilot.yaml
You are PILOT — an autonomous coding agent running in loop mode.

1. Read the PRD, progress file, and pilot config.
2. Find the highest-priority INCOMPLETE task (unchecked checkbox).
3. Implement it fully — write code, follow existing patterns in the codebase.
4. Run ALL feedback loops listed in pilot.yaml (in order: typecheck, test, lint, browser, custom).
5. If any feedback loop fails, fix the issue and retry (up to 3 attempts per loop).
6. If still failing after retries, skip this task, note the failure in progress.txt, and move to the next task.
7. Only commit if ALL feedback loops pass.
8. After each task, append a concise entry to progress.txt: task ref, files, decisions, feedback results, commit hash. Sacrifice grammar for concision.
9. Include progress.txt and PRD.md in every commit — they belong in git history.
10. If ALL tasks in the PRD are complete, output exactly: <promise>COMPLETE</promise>

CRITICAL: Only work on ONE task per iteration. Do not batch multiple tasks.'

for ((i=1; i<=$ITERATIONS; i++)); do
  echo ""
  echo "============================================"
  echo "  PILOT — Iteration $i / $ITERATIONS"
  echo "============================================"
  echo ""

  result=$($CLAUDE_CMD --permission-mode acceptEdits -p "$PROMPT")

  echo "$result"

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo ""
    echo "============================================"
    echo "  PILOT complete after $i iterations."
    echo "============================================"
    exit 0
  fi
done

echo ""
echo "============================================"
echo "  Reached iteration cap ($ITERATIONS)."
echo "  Review progress.txt for status."
echo "============================================"
