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

  # Parse progress.txt for per-task details and decisions
  if [ -f progress.txt ]; then
    local tasks_section=""
    local decisions_section=""
    local current_task=""
    local current_status=""
    local current_commit=""
    local current_decisions=""
    local current_stash=""
    local current_files=""
    local task_num=0

    while IFS= read -r line; do
      if [[ "$line" =~ ^##\ ([0-9]+)\ —\ (.+) ]]; then
        # Flush previous task
        if [ -n "$current_task" ]; then
          local icon="✓"
          local detail=""
          if [[ "$current_status" == *"FAILED"* ]]; then
            icon="✗"
            detail=" — $current_status"
            [ -n "$current_stash" ] && detail="$detail
     stash: $current_stash"
          elif [[ "$current_status" == *"SKIPPED"* ]] || [[ "$current_status" == *"escalation"* ]]; then
            icon="⊘"
            detail=" — $current_status"
          elif [ -n "$current_commit" ]; then
            # Get diff stat for committed tasks
            local stat=$(git diff --stat "$current_commit~1".."$current_commit" 2>/dev/null | tail -1 | sed 's/^ *//')
            detail="  $stat    $current_commit"
          fi
          tasks_section="$tasks_section  $icon #$task_num $current_task$detail
"
          [ -n "$current_decisions" ] && decisions_section="$decisions_section  #$task_num: $current_decisions
"
        fi
        task_num="${BASH_REMATCH[1]}"
        current_task="${BASH_REMATCH[2]}"
        current_status=""
        current_commit=""
        current_decisions=""
        current_stash=""
        current_files=""
      elif [[ "$line" =~ ^status:\ (.+) ]]; then
        current_status="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^commit:\ (.+) ]]; then
        current_commit="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^decisions:\ (.+) ]]; then
        current_decisions="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^stash:\ (.+) ]]; then
        current_stash="${BASH_REMATCH[1]}"
      fi
    done < progress.txt

    # Flush last task
    if [ -n "$current_task" ]; then
      local icon="✓"
      local detail=""
      if [[ "$current_status" == *"FAILED"* ]]; then
        icon="✗"
        detail=" — $current_status"
        [ -n "$current_stash" ] && detail="$detail
     stash: $current_stash"
      elif [[ "$current_status" == *"SKIPPED"* ]] || [[ "$current_status" == *"escalation"* ]]; then
        icon="⊘"
        detail=" — $current_status"
      elif [ -n "$current_commit" ]; then
        local stat=$(git diff --stat "$current_commit~1".."$current_commit" 2>/dev/null | tail -1 | sed 's/^ *//')
        detail="  $stat    $current_commit"
      fi
      tasks_section="$tasks_section  $icon #$task_num $current_task$detail
"
      [ -n "$current_decisions" ] && decisions_section="$decisions_section  #$task_num: $current_decisions
"
    fi

    [ -n "$tasks_section" ] && report="$report
$tasks_section"
    [ -n "$decisions_section" ] && report="$report
Decisions:
$decisions_section"
  fi

  # Add diff commands
  if [ "$PILOT_START_HASH" != "$end_hash" ] && [ "$PILOT_START_HASH" != "none" ]; then
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
3. Implement it using agents: dispatch ImplementerAgent for code, ReviewerAgent for spec+codebase review.
4. Run ALL feedback loops listed in pilot.yaml (in order: typecheck, test, lint, browser, custom).
5. If any feedback loop fails: dispatch HealerAgent for targeted fix (attempt 1), try different fix (attempt 2), then dispatch fresh ImplementerAgent to rethink (attempt 3). If still failing, stash and move on.
GUARDRAILS: Check guardrails.protected_paths before modifying ANY file. Skip tasks that touch protected files — log as escalation.
6. Only commit if ALL feedback loops pass. Assemble proof-of-work commit message from agent outputs.
7. After each task, append a concise entry to progress.txt: task ref, files, decisions, feedback results, commit hash. Sacrifice grammar for concision.
8. Include progress.txt and PRD.md in every commit — they belong in git history.
9. If ALL tasks in the PRD are complete, output exactly: <promise>COMPLETE</promise>

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
