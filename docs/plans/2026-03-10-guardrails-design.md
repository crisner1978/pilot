# Guardrails & Safety — Design

**Date:** 2026-03-10
**Status:** Approved
**Goal:** Make `/pilot:loop` safe enough to run unsupervised without anxiety.

## Features

### 1. Protected Paths

Prevent the agent from modifying sensitive files.

**Config** (`pilot.yaml`):
```yaml
guardrails:
  protected_paths:
    - ".env*"
    - "*.pem"
    - "*.key"
    - "migrations/"
    - "docker-compose.prod.*"
```

**Behavior:**
- `/pilot:plan` Phase 1 auto-detects common sensitive patterns and pre-populates the list
- User can edit during planning or later in `pilot.yaml`
- **Loop mode:** hard-block — if a task requires touching a protected path, skip it, log as escalation in `progress.txt`, move on
- **Manual mode (`/pilot:run`):** ask the user via AskUserQuestion — they're present and may intentionally need access

**Detection heuristics** (added to `references/stack-detection.md`):
- `.env*`, `*.pem`, `*.key`, `*.cert` — secrets/creds
- `migrations/`, `db/migrate/` — database migrations
- `docker-compose.prod.*`, `*.production.*` — production config
- `infrastructure/`, `terraform/`, `*.tf` — infra-as-code
- `ci/`, `.github/workflows/`, `.gitlab-ci.yml` — CI/CD pipelines

### 2. Auto-Stash

Protect uncommitted work when the loop starts.

**Where:** `pilot-loop.sh` only. Manual `/pilot:run` doesn't need it — user is present.

**Mechanics:**
```bash
# At top of pilot-loop.sh
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Stashing uncommitted changes..."
  git stash --include-untracked -m "pilot/pre-loop-stash"
  PILOT_STASHED=true
fi

# Trap on exit (success, failure, or interrupt)
cleanup() {
  if [ "$PILOT_STASHED" = true ]; then
    echo "Restoring stashed changes..."
    git stash pop
  fi
}
trap cleanup EXIT
```

If the tree is already clean, no-op.

### 3. Rollback on Failure

Keep each iteration isolated by cleaning up failed attempts.

**Where:** `/pilot:run` skill, after 3 retries exhausted.

**Mechanics:**
- After failure, stash the broken attempt: `git stash push -m "pilot/failed-task-N: [description]"`
- Working tree returns to clean state for next iteration
- Human can inspect later via `git stash list` to see what the agent tried
- Log the stash ref in `progress.txt` failure entry:
  ```
  stash: pilot/failed-task-N: [description]
  ```

**Not discarded silently** — the attempt might be 90% right. Stashing preserves it for human review without polluting the working tree.

## Changes Required

| File | Change |
|------|--------|
| `skills/plan/SKILL.md` | Phase 1: detect protected paths, Phase 4: add to yaml template |
| `skills/plan/assets/pilot-yaml-template.yaml` | Add `guardrails.protected_paths` section |
| `skills/plan/references/stack-detection.md` | Add sensitive file detection table |
| `skills/run/SKILL.md` | Check protected paths before writing, stash on failure |
| `skills/loop/SKILL.md` | Document guardrails behavior in loop context |
| `scripts/pilot-loop.sh` | Add auto-stash + trap cleanup |

## Not Included (deferred)

- **Diff size cap** — feedback loops catch most runaway changes
- **Dry-run mode** — builds on observability (next feature)
- **Kill switch** — iteration cap already exists, `.pilot-stop` file can come later
