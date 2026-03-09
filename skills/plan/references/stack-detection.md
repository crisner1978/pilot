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
