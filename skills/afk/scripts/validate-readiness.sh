#!/bin/bash
# PILOT AFK — Readiness Validation
# Checks that all prerequisites are met before launching AFK mode.
# Usage: ./validate-readiness.sh

set -e

echo "PILOT AFK — Readiness Check"
echo "============================"
echo ""

READY=true

# 1. Check required files
echo "Files:"
for file in PRD.md .claude/pilot.yaml progress.txt afk-loop.sh; do
  if test -f "$file"; then
    echo "  $file ✓"
  else
    echo "  $file ✗ — MISSING"
    READY=false
  fi
done
echo ""

# 2. Count remaining tasks
if test -f PRD.md; then
  TOTAL=$(grep -c '^\- \[.\]' PRD.md 2>/dev/null || echo 0)
  DONE=$(grep -c '^\- \[x\]' PRD.md 2>/dev/null || echo 0)
  REMAINING=$((TOTAL - DONE))
  echo "PRD status: $DONE/$TOTAL tasks complete, $REMAINING remaining"
  if [ "$REMAINING" -eq 0 ]; then
    echo "  All tasks complete — nothing to run."
    READY=false
  fi
  echo ""
fi

# 3. Dry-run feedback loops
if test -f .claude/pilot.yaml; then
  echo "Feedback loop dry-run:"

  # Extract feedback commands from pilot.yaml (simple grep-based parsing)
  for loop in typecheck test lint browser; do
    CMD=$(grep "^  $loop:" .claude/pilot.yaml 2>/dev/null | sed 's/^  [a-z]*: *//' | sed 's/ *#.*//')
    if [ -n "$CMD" ] && [ "$CMD" != "null" ] && [ "$CMD" != "~" ]; then
      if eval "$CMD" > /dev/null 2>&1; then
        echo "  $loop ($CMD): ✓ exit 0"
      else
        echo "  $loop ($CMD): ✗ exit $?"
        READY=false
      fi
    fi
  done
  echo ""
fi

# 4. Summary
if [ "$READY" = true ]; then
  echo "✓ All checks passed — ready to launch."
  exit 0
else
  echo "✗ Some checks failed — fix issues before launching."
  exit 1
fi
