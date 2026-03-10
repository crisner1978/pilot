# Stack Detection Reference

## File → Stack Detection Table

| File | Detects |
|------|---------|
| `package.json` | Node.js, dependencies, scripts (test, lint, typecheck, build) |
| `tsconfig.json` | TypeScript, compiler options |
| `vitest.config.*` | Vitest test runner |
| `jest.config.*` | Jest test runner |
| `playwright.config.*` | Playwright browser tests |
| `cypress.config.*` | Cypress browser tests |
| `.eslintrc*` / `eslint.config.*` | ESLint linter |
| `biome.json` / `biome.jsonc` | Biome linter/formatter |
| `pyproject.toml` | Python, pytest, ruff, mypy |
| `Cargo.toml` | Rust, cargo test, clippy |
| `go.mod` | Go, go test, golangci-lint |
| `Makefile` | Build commands, test targets |
| `.github/workflows/*` | CI config (reveals test/lint/typecheck commands) |

## Additional Checks

- `package.json` scripts for `test`, `typecheck`, `lint`, `check`, `build` commands
- Existing `PRD.md`, `.claude/pilot.yaml`, `CLAUDE.md`
- GitHub Issues (if `gh` CLI is available: `gh issue list --limit 20`)

## Feedback Loop Mapping

| Feedback Loop | Purpose | Required For |
|---------------|---------|-------------|
| `typecheck` | Catch type errors before runtime | All typed languages |
| `test` | Verify behavior, catch regressions | All code changes |
| `lint` | Enforce style, catch bugs | All code changes |
| `browser` | Verify rendered UI | Frontend/UI tasks |

## Sensitive File Detection

Files and directories the agent should never modify without explicit permission.

| Pattern | Category | Why |
|---------|----------|-----|
| `.env*` | Secrets | Environment variables, API keys |
| `*.pem`, `*.key`, `*.cert` | Secrets | SSL/TLS certificates and keys |
| `*.secret`, `credentials.*` | Secrets | Credential files |
| `migrations/`, `db/migrate/` | Database | Migration files — order-sensitive, destructive |
| `docker-compose.prod.*`, `*.production.*` | Production | Production-specific config |
| `infrastructure/`, `terraform/`, `*.tf` | Infrastructure | Infra-as-code — affects live systems |
| `.github/workflows/`, `.gitlab-ci.yml`, `ci/` | CI/CD | Pipeline config — affects deployment |
| `*.lock` | Lockfiles | Package lockfiles — should only change via package manager |

Detection: During `/pilot:plan` Phase 1, glob for these patterns. If any exist, add them to `guardrails.protected_paths` in `pilot.yaml`.
