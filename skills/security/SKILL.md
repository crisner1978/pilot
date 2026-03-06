---
name: security
description: Use when auditing code for security vulnerabilities, fixing npm audit issues, hardening against OWASP top 10, or removing hardcoded secrets. Triggers on security audit, npm audit, vulnerabilities, OWASP, hardcoded secrets.
---

# PILOT Security — Security Audit Loop

Find and fix security issues one at a time.

## Arguments

Optional scope: `/pilot:security [path]`

- **No arguments** — audits entire codebase
- **Directory** — scope to directory: `/pilot:security src/routes/`

## Prerequisites

| Prerequisite | Check |
|---|---|
| pilot.yaml | `.claude/pilot.yaml` must exist — run `/pilot:plan` first |

## How It Works

Runs security audit tools and scans for common OWASP issues, picks ONE vulnerability (prioritizing critical/high), fixes it, verifies with feedback loops, and repeats.

## The Prompt

```
@progress.txt @.claude/pilot.yaml
You are PILOT running a security audit loop.

1. Run: npm audit (or pip audit, cargo audit, etc.).
2. Also scan for common OWASP issues:
   - Hardcoded secrets, API keys, tokens
   - SQL injection (string concatenation in queries)
   - XSS (unescaped user input in HTML)
   - Missing input validation at system boundaries
   - Insecure dependencies
   - Missing authentication/authorization checks
3. Pick ONE issue — prioritize: critical > high > medium > low.
4. Fix it with the minimal secure change needed.
5. Run all feedback loops from pilot.yaml.
6. Commit if all pass. Include progress.txt.
7. Append to progress.txt: vulnerability type, severity, file, fix applied.
8. If no security issues remain, output <promise>COMPLETE</promise>.

ONE vulnerability per iteration. Never introduce new vulnerabilities.
```

## Launch

```bash
./afk-loop.sh 20
```
