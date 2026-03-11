#!/bin/bash
# PILOT Loop — Readiness Validation
# Checks project readiness before launching the shared plugin-owned loop.

set -euo pipefail

READY=true
FEEDBACK_COUNT=0
CUSTOM_COUNT=0

extract_feedback_commands() {
  awk '
    /^feedback:[[:space:]]*$/ { in_feedback=1; in_custom=0; next }
    in_feedback {
      if ($0 ~ /^[^[:space:]]/) exit
      if ($0 ~ /^  custom:[[:space:]]*$/) { in_custom=1; next }
      if ($0 ~ /^  [A-Za-z0-9_-]+:[[:space:]]*/) {
        in_custom=0
        line=$0
        sub(/^  /, "", line)
        key=line
        sub(/:.*/, "", key)
        value=$0
        sub(/^  [^:]+:[[:space:]]*/, "", value)
        if (value != "" && value != "null" && value != "~" && value != "[]") {
          print key "|" value
        }
        next
      }
      if (in_custom && $0 ~ /^    - /) {
        cmd=$0
        sub(/^    - /, "", cmd)
        if (cmd != "") {
          print "custom|" cmd
        }
      }
    }
  ' .claude/pilot.yaml
}

echo "PILOT Loop — Readiness Check"
echo "============================="
echo ""
echo "Loop infrastructure: shared plugin script (not a project artifact)"
echo ""

echo "Project artifacts:"
for file in PRD.md .claude/pilot.yaml progress.txt; do
  if [ -f "$file" ]; then
    echo "  $file ✓"
  else
    echo "  $file ✗ — MISSING"
    READY=false
  fi
done
echo ""

if [ -f PRD.md ]; then
  read -r TOTAL DONE <<EOF
$(awk '
  /^- \[[ xX]\]/ { total++ }
  /^- \[[xX]\]/ { done++ }
  END { printf "%d %d\n", total + 0, done + 0 }
' PRD.md)
EOF
  REMAINING=$((TOTAL - DONE))
  echo "PRD status: $DONE/$TOTAL tasks complete, $REMAINING remaining"
  if [ "$TOTAL" -eq 0 ]; then
    echo "  No checklist tasks found in PRD.md."
    READY=false
  elif [ "$REMAINING" -le 0 ]; then
    echo "  All tasks complete — nothing to run."
    READY=false
  fi
  echo ""
fi

if [ -f .claude/pilot.yaml ]; then
  echo "Feedback loop dry-run:"

  while IFS='|' read -r loop_name loop_cmd; do
    [ -n "$loop_cmd" ] || continue
    FEEDBACK_COUNT=$((FEEDBACK_COUNT + 1))

    if [ "$loop_name" = "custom" ]; then
      CUSTOM_COUNT=$((CUSTOM_COUNT + 1))
      echo "  custom ($loop_cmd): ! skipped dry-run"
      continue
    fi

    if bash -lc "$loop_cmd" > /dev/null 2>&1; then
      echo "  $loop_name ($loop_cmd): ✓ exit 0"
    else
      status=$?
      echo "  $loop_name ($loop_cmd): ✗ exit $status"
      READY=false
    fi
  done < <(extract_feedback_commands)

  if [ "$FEEDBACK_COUNT" -eq 0 ]; then
    echo "  No runnable feedback commands configured under feedback:."
    READY=false
  elif [ "$CUSTOM_COUNT" -gt 0 ]; then
    echo "  Note: custom feedback commands are configured but not executed during readiness checks."
  fi

  echo ""
fi

if [ "$READY" = true ]; then
  echo "✓ All checks passed — ready to launch."
  exit 0
else
  echo "✗ Some checks failed — fix issues before launching."
  exit 1
fi
