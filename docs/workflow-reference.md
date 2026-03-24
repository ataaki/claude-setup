# Workflow Reference

Detailed checklists referenced by CLAUDE.md. Consult these during STANDARD workflow steps — do not memorize, read when needed.

---

## Edge cases checklist (IMPLEMENT step)

For each feature, systematically test:
- Empty, null, undefined inputs
- Boundary values (0, -1, MAX_INT, empty string, very long string)
- Unauthenticated / unauthorized user
- Network timeout, service unavailable
- Malformed data / injection attempts
- Pagination: first page, last page, out of bounds
- Concurrency: double-submit, race conditions

---

## Security checklist (SECURE step)

- [ ] Inputs validated/sanitized at system boundaries
- [ ] No hardcoded secrets (use environment variables)
- [ ] Auth verified on every protected route
- [ ] CORS configured restrictively
- [ ] Security headers present (X-Content-Type-Options, X-Frame-Options, Strict-Transport-Security)
- [ ] Dependencies scanned (npm audit / pip audit / cargo audit)
- [ ] Rate limiting on sensitive endpoints (login, signup, public API)
- [ ] Errors logged without leaking sensitive info (no stack traces in prod)
- [ ] SQL/NoSQL injection impossible (ORM or parameterized queries only)
- [ ] XSS impossible (systematic escaping, basic CSP)
- [ ] CSRF protection active on mutations
- [ ] Uploaded files validated (type, size, sanitized name)

---

## Accessibility checklist (web projects)

- [ ] All interactive elements keyboard-accessible (tab, enter, escape)
- [ ] All inputs have associated labels (not placeholder as sole label)
- [ ] Images have descriptive alt text
- [ ] Color contrast meets WCAG AA (4.5:1 ratio for text)
- [ ] aria-labels used when visual context is insufficient
- [ ] Navigation is logical and predictable (DOM order = visual order)
- [ ] Error messages associated with fields (aria-describedby)
- [ ] Usable at 200% zoom
- [ ] Animations respect prefers-reduced-motion

Skip if: no web UI or user says "skip a11y"

---

## Performance checklist

### Backend
- [ ] No N+1 queries (use eager loading / joins / includes)
- [ ] Pagination on any list that can exceed 50 items
- [ ] DB indexes on columns used in WHERE, ORDER BY, JOIN
- [ ] No heavy computation inside request loops (defer to background jobs)
- [ ] DB queries logged in dev

### Frontend
- [ ] Lazy loading for non-critical components/routes
- [ ] Optimized images (format, size, lazy loading)
- [ ] No unnecessary re-renders (memo/useMemo/useCallback where measured, not by default)
- [ ] Bundle size: no full library imports when only one module is used

Skip if: prototype/script or user says "skip perf"

---

## Error strategy

Define at BRAINSTORM, not ad hoc:

1. **User-facing errors**: clear, actionable messages. Never stack traces or technical details.
2. **Internal errors**: logged with context (request ID, user ID, timestamp, stack trace)
3. **Architecture**:
   - Backend: global error middleware (catch-all). Typed custom errors (NotFoundError, ValidationError, AuthError)
   - Frontend: error boundaries (React) or equivalent. Fallback UI for critical sections.
   - API: consistent error format (`{ error: { code, message, details? } }`)
4. **Never silent errors**: every catch must re-throw or log. Empty `catch {}` is forbidden.

---

## Structured logging (backend projects)

1. Use a structured logger (not console.log): winston, pino, structlog, slog
2. Log levels: error (action needed), warn (unexpected but handled), info (business events), debug (dev detail, disabled in prod)
3. Required context: timestamp, request ID, user ID (if authenticated), action
4. Never log sensitive data: no passwords, tokens, credit cards, unnecessary PII

Skip if: script/CLI without server or user says "skip logging"

---

## Comment format

**Functions/methods:**
```
/**
 * Brief description of what the function does.
 *
 * @param paramName - Description of the parameter
 * @returns Description of the return value
 */
```

**Complex logic (inline):**
```
// Explanation of WHY this approach, not WHAT it does
```

**TODO / FIXME / HACK:**
```
// TODO: description of what needs to be done
// FIXME: description of the bug to fix
// HACK: explanation of why this workaround exists
```

---

## PROGRESS.md template

```markdown
# Project Progress

## Status: IN PROGRESS
## Last session: YYYY-MM-DD
## Resume context: [short description of where we are]

## Features
| # | Feature | Status | Tests | Security | Notes |
|---|---------|--------|-------|----------|-------|
| 1 | Example | planned | - | - | |

## Architecture Decisions
- [YYYY-MM-DD] Decision — reason

## Blockers / Notes
- ...
```

---

## Local CLAUDE.md template

```markdown
# [Project name]

## Stack
- [tech] v[version] (LTS verified on YYYY-MM-DD)

## Commands
- Install: [command]
- Dev: [command]
- Test: [command]
- Build: [command]
- Lint: [command]

## Structure
- [directory tree description]

## Conventions
- [project-specific conventions]
```
