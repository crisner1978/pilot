#!/bin/bash
set -euo pipefail

# PILOT — Plan, Iterate, Loop, Observe, Test
# Shared plugin-owned autonomous loop script
# Usage: ./pilot-loop.sh [iterations] [--sandbox] [--verbose]

ITERATIONS=20
SANDBOX=false
VERBOSE=false

if [ "${1:-}" != "" ] && [[ "${1:-}" =~ ^[0-9]+$ ]]; then
  ITERATIONS="$1"
  shift
fi

for arg in "$@"; do
  case "$arg" in
    --sandbox) SANDBOX=true ;;
    --verbose) VERBOSE=true ;;
  esac
done

CLAUDE_CMD="claude"
if [ "$SANDBOX" = true ]; then
  CLAUDE_CMD="docker sandbox run claude"
fi

# `.claude/pilot-prompt.md` is PILOT-owned runtime scratch space, not durable user config.
PROMPT_FILE=".claude/pilot-prompt.md"
PILOT_PROMPT_OWNED="${PILOT_PROMPT_OWNED:-false}"
PILOT_PRE_LOOP_STASHED=false
PILOT_PRE_LOOP_STASH_OID=""
PILOT_LAST_ITERATION=0

cleanup_prompt_override() {
  if [ "$PILOT_PROMPT_OWNED" = true ] && [ -f "$PROMPT_FILE" ]; then
    rm -f "$PROMPT_FILE"
  fi
}

restore_pre_loop_stash() {
  if [ "$PILOT_PRE_LOOP_STASHED" != true ] || [ -z "$PILOT_PRE_LOOP_STASH_OID" ]; then
    return
  fi

  local stash_ref
  stash_ref=$(git stash list --format='%gd %H' | awk -v oid="$PILOT_PRE_LOOP_STASH_OID" '$2 == oid { print $1; exit }')

  if [ -z "$stash_ref" ]; then
    echo ""
    echo "Pre-loop stash $PILOT_PRE_LOOP_STASH_OID not found. Restore manually if needed."
    return
  fi

  echo ""
  echo "Restoring stashed changes from $stash_ref..."
  if git stash apply --index "$stash_ref"; then
    git stash drop "$stash_ref" >/dev/null 2>&1 || true
  else
    echo "Failed to restore $stash_ref automatically. It remains in git stash."
  fi
}

generate_report() {
  local end_time
  end_time=$(date +%s)
  local elapsed=$(( (end_time - PILOT_START_TIME) / 60 ))
  local end_hash
  end_hash=$(git rev-parse HEAD 2>/dev/null || echo "none")
  local report_date
  report_date=$(date +%Y-%m-%d)

  local report="PILOT Report — $report_date
═══════════════════════════════════════
Iterations: $1 | Tasks: $PILOT_TASKS_DONE done, $PILOT_TASKS_FAILED failed, $PILOT_TASKS_SKIPPED skipped, $PILOT_TASKS_ESCALATED escalated
Time: ~${elapsed} minutes
"

  if [ -f progress.txt ]; then
    local tasks_section=""
    local decisions_section=""
    local current_task=""
    local current_status=""
    local current_commit=""
    local current_decisions=""
    local current_stash=""
    local task_num=0

    while IFS= read -r line; do
      if [[ "$line" =~ ^##\ ([0-9]+)\ —\ (.+) ]]; then
        if [ -n "$current_task" ]; then
          local icon="✓"
          local detail=""
          if [[ "$current_status" == *"FAILED"* ]]; then
            icon="✗"
            detail=" — $current_status"
            [ -n "$current_stash" ] && detail="$detail
     stash: $current_stash"
          elif [[ "$current_status" == *"SKIPPED"* ]] || [[ "$current_status" == *"escalation"* ]] || [[ "$current_status" == *"ESCALATED"* ]]; then
            icon="⊘"
            detail=" — $current_status"
          elif [ -n "$current_commit" ]; then
            local stat
            stat=$(git diff --stat "$current_commit~1".."$current_commit" 2>/dev/null | tail -1 | sed 's/^ *//')
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

    if [ -n "$current_task" ]; then
      local icon="✓"
      local detail=""
      if [[ "$current_status" == *"FAILED"* ]]; then
        icon="✗"
        detail=" — $current_status"
        [ -n "$current_stash" ] && detail="$detail
     stash: $current_stash"
      elif [[ "$current_status" == *"SKIPPED"* ]] || [[ "$current_status" == *"escalation"* ]] || [[ "$current_status" == *"ESCALATED"* ]]; then
        icon="⊘"
        detail=" — $current_status"
      elif [ -n "$current_commit" ]; then
        local stat
        stat=$(git diff --stat "$current_commit~1".."$current_commit" 2>/dev/null | tail -1 | sed 's/^ *//')
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

cleanup() {
  set +e
  generate_report "$PILOT_LAST_ITERATION"
  cleanup_prompt_override
  restore_pre_loop_stash
}

extract_result_marker() {
  printf '%s\n' "$1" | awk -F= '/^PILOT_RESULT=/{print $2; exit}'
}

normalize_result() {
  local result_text="$1"
  local result_marker
  result_marker=$(extract_result_marker "$result_text")

  if [ -n "$result_marker" ]; then
    printf '%s\n' "$result_marker"
    return
  fi

  if [[ "$result_text" == *"FAILED"* ]]; then
    printf 'failed\n'
  elif [[ "$result_text" == *"escalation"* ]] || [[ "$result_text" == *"ESCALATED"* ]]; then
    printf 'escalated\n'
  elif [[ "$result_text" == *"SKIPPED"* ]]; then
    printf 'skipped\n'
  else
    printf 'done\n'
  fi
}

trap cleanup EXIT

PILOT_START_TIME=$(date +%s)
PILOT_START_HASH=$(git rev-parse HEAD 2>/dev/null || echo "none")
PILOT_TASKS_DONE=0
PILOT_TASKS_FAILED=0
PILOT_TASKS_SKIPPED=0
PILOT_TASKS_ESCALATED=0

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Stashing uncommitted changes..."
  git stash push --include-untracked -m "pilot/pre-loop-stash $(date -u +%Y%m%dT%H%M%SZ)" >/dev/null
  PILOT_PRE_LOOP_STASHED=true
  PILOT_PRE_LOOP_STASH_OID=$(git rev-parse --verify refs/stash)
fi

if [ -f "$PROMPT_FILE" ]; then
  PROMPT=$(cat "$PROMPT_FILE")
else
  PROMPT='@PRD.md @progress.txt @.claude/pilot.yaml
You are PILOT running autonomous loop mode. Execute exactly one task using the same contract as `/pilot:run`.

Core contract:
- Pick the highest-priority incomplete PRD task. Do not batch tasks.
- Use the Task tool with `subagent_type: "general-purpose"` for ImplementerAgent, ReviewerAgent, and HealerAgent dispatch.
- Require each agent response to include a rigid `===AGENT_OUTPUT===` JSON block that matches the `/pilot:run` contract.
- Run every configured feedback loop from `pilot.yaml` in order.
- If feedback fails: HealerAgent attempt 1, HealerAgent attempt 2, fresh ImplementerAgent rethink attempt 3, then escalate.
- Commit only if all feedback loops pass. Include `progress.txt` and `PRD.md` in each successful commit.
- Respect `guardrails.protected_paths`. If a task needs a protected file or human intervention, log it and escalate instead of forcing the change.

Per iteration:
1. Read `PRD.md`, `progress.txt`, and `.claude/pilot.yaml`.
2. Execute exactly one task through the shared `/pilot:run` workflow.
3. Append a concise structured entry to `progress.txt`.
4. Emit exactly one top-level result marker on its own line:
   - `PILOT_RESULT=done`
   - `PILOT_RESULT=failed`
   - `PILOT_RESULT=skipped`
   - `PILOT_RESULT=escalated`
5. If all PRD tasks are complete, also output exactly: <promise>COMPLETE</promise>

Use `PILOT_RESULT=done` for a completed iteration, even when that completion also finishes the full PRD.'
fi

LOOP_NOTES=$(awk '
  /^loop:[[:space:]]*$/ { in_loop=1; next }
  in_loop {
    if ($0 ~ /^[^[:space:]]/) exit
    if ($0 ~ /^  notes:[[:space:]]*/) {
      note=$0
      sub(/^  notes:[[:space:]]*/, "", note)
      if (note != "" && note != "null" && note != "~") {
        print note
      }
      exit
    }
  }
' .claude/pilot.yaml 2>/dev/null || true)

if [ -n "$LOOP_NOTES" ]; then
  PROMPT="$PROMPT

DURABLE LOOP NOTES FROM pilot.yaml:
$LOOP_NOTES"
fi

if [ "$VERBOSE" = true ]; then
  PROMPT="$PROMPT
VERBOSITY: Write decisions in progress.txt at MEDIUM verbosity (2-3 sentences per task — what was considered, what was chosen, why)."
fi

for ((i=1; i<=ITERATIONS; i++)); do
  PILOT_LAST_ITERATION="$i"

  echo ""
  echo "============================================"
  echo "  PILOT — Iteration $i / $ITERATIONS"
  echo "============================================"
  echo ""

  set +e
  result=$($CLAUDE_CMD --permission-mode acceptEdits -p "$PROMPT" 2>&1)
  claude_status=$?
  set -e

  if [ "$claude_status" -ne 0 ] && ! printf '%s\n' "$result" | grep -q '^PILOT_RESULT='; then
    result="$result
PILOT_RESULT=failed"
  fi

  echo "$result"

  iteration_result=$(normalize_result "$result")
  case "$iteration_result" in
    failed) ((PILOT_TASKS_FAILED++)) || true ;;
    skipped) ((PILOT_TASKS_SKIPPED++)) || true ;;
    escalated) ((PILOT_TASKS_ESCALATED++)) || true ;;
    *) ((PILOT_TASKS_DONE++)) || true ;;
  esac

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    exit 0
  fi
done

echo "Reached iteration cap ($ITERATIONS)."
