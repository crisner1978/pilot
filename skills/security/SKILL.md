---
name: security
description: Use when auditing code for security vulnerabilities, fixing npm audit issues, hardening against OWASP top 10, or removing hardcoded secrets. Triggers on security audit, npm audit, vulnerabilities, OWASP, hardcoded secrets.
---

# PILOT Security — Security Audit Loop

Find and fix security issues one at a time.

**Announce at start:** "Running PILOT security audit loop."

## Arguments

Optional scope: `/pilot:security [path]`

- **No arguments** — audits entire codebase
- **Directory** — scope to directory: `/pilot:security src/routes/`

## Execution

### 1. Validate Prerequisites

Check that these exist:
- `.claude/pilot.yaml` — must exist. If missing: "Run `/pilot:plan` first."

Ensure `progress.txt` exists (create empty if not).

### 2. Create Owned Prompt Override

Parse arguments to determine SCOPE, then create an ephemeral prompt override. Use the Write tool to create `.claude/pilot-prompt.md` with this content (replacing SCOPE with actual value):

```
@progress.txt @.claude/pilot.yaml
You are PILOT running a security audit loop.
SCOPE: [resolved scope — path or "entire codebase"]

Use the shared `/pilot:run` execution contract for implementation, review, feedback loops, heal/retry/escalate behavior, commit handling, progress logging, and top-level `PILOT_RESULT=...` output.

1. Run: npm audit (or pip audit, cargo audit, etc.).
2. Also scan for common OWASP issues within SCOPE:
   - Hardcoded secrets, API keys, tokens
   - SQL injection (string concatenation in queries)
   - XSS (unescaped user input in HTML)
   - Missing input validation at system boundaries
   - Insecure dependencies
   - Missing authentication/authorization checks
3. Pick ONE issue — prioritize: critical > high > medium > low.
4. Fix it with the minimal secure change needed.
5. If no security issues remain in SCOPE, emit PILOT_RESULT=done and <promise>COMPLETE</promise>.

ONE vulnerability per iteration. Never introduce new vulnerabilities.
```

### 3. Confirm and Launch

Use AskUserQuestion to confirm:

```json
{
  "questions": [{
    "question": "Launch security audit loop?\n  Scope: [scope]",
    "header": "Security",
    "options": [
      {"label": "Launch (Recommended)", "description": "Start security audit loop"},
      {"label": "Cancel", "description": "Don't launch"}
    ],
    "multiSelect": false
  }]
}
```

After confirmation, launch the loop:

```bash
PILOT_LOOP="${CLAUDE_SKILL_DIR}/../../scripts/pilot-loop.sh"
PILOT_PROMPT_OWNED=true bash "$PILOT_LOOP" 20
```

### 4. Results

Because the launch sets `PILOT_PROMPT_OWNED=true`, the shared loop deletes only the override created for this run. Report vulnerabilities fixed.
