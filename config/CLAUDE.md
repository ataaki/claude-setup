# Universal Project Framework

## Core principles
- Think like the best expert in the field, then push further
- Never settle for "it works" — aim for "best approach for this context"
- When unsure, research current best practices (WebSearch, context7) rather than relying on potentially outdated knowledge
- All code, comments, documentation, and commits MUST be in English. Only conversations stay in the user's language.

## Adaptive workflow

Classify every task, then follow the matching workflow. Skip steps with "skip [step]".

### MICRO (typo, rename, config change, simple question)
1. **IMPLEMENT** — Just do it
2. **VERIFY** — Prove it works (run tests/build if applicable)

### SMALL (bug fix, small feature, refactor < 50 lines)
1. **BRAINSTORM** — Understand the root cause / need (brief, no skill needed)
2. **IMPLEMENT** — TDD: write test first, then code. For bugs: test that reproduces it, then fix.
3. **VERIFY** — Tests pass, build OK. Show output.
4. **PROGRESS** — Update PROGRESS.md if it exists

### STANDARD (feature, large refactor, new module, architecture change)
1. **BRAINSTORM** — Use `superpowers:brainstorming`. Propose 2-3 approaches with trade-offs. Challenge your own assumptions.
2. **PLAN** — Use `superpowers:writing-plans`. Save to `docs/plans/YYYY-MM-DD-<topic>.md`.
3. **IMPLEMENT** — Use `superpowers:test-driven-development`. Tests BEFORE code. See `docs/workflow-reference.md` for edge case checklist.
4. **SECURE** — Security checklist. See `docs/workflow-reference.md`. Skip for local scripts/tools.
5. **VERIFY** — Use `superpowers:verification-before-completion`. Never say "done" without proof.
6. **REVIEW** — Use `superpowers:requesting-code-review`.
7. **PROGRESS** — Update PROGRESS.md + Claude memory.

### When in doubt: go one level UP, not down.

## Rules (always apply, all tiers)

- **Commits**: `type(scope): description` (Conventional Commits). Never add Co-Authored-By.
- **Branches**: `type/description-short` (e.g. `feature/user-auth`, `fix/payment-timeout`)
- **LTS versions**: Always verify current LTS via WebSearch before adding dependencies. Never trust internal knowledge for version numbers.
- **Documentation**: Update docs (README, CLAUDE.md, .env.example, PROGRESS.md) immediately when code changes affect them. Never "later".
- **No worktrees**: Work directly on the branch.
- **Parallel subagents**: Use them whenever tasks are independent.

## Session resume

When PROGRESS.md exists in the working directory:
1. Read it immediately
2. Read the latest plan in `docs/plans/` if it exists
3. Tell the user: "Last session: X. Remaining: Y. Resuming at Z."
4. Continue where you left off — never restart from zero

## New project init

Create these files at project start:
- `CLAUDE.md` (local, with stack/commands/structure/conventions)
- `README.md` (complete, lets someone launch the project in < 5 min)
- `.env.example` (commented placeholders, never real values)
- `.github/workflows/ci.yml` (lint, test, build, security scan)
- `PROGRESS.md` (project tracking)

## Reference

For detailed checklists (security, edge cases, a11y, performance, logging, error strategy, comment format), see `docs/workflow-reference.md`.
