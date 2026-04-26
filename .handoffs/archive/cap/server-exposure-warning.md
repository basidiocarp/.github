# Cap: Server Exposure Startup Warning

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/server/index.ts`, `cap/server/__tests__/`
- **Cross-repo edits:** `none`
- **Non-goals:** does not add `CAP_API_KEY` enforcement when unset (that's a policy decision, not a warning); does not change CORS policy; does not add any new config variables
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cap/verify-server-exposure-warning.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:**
  - `server/index.ts` — `startServer()` function at line 118; add the warning after the existing `logger.info(...)` call
  - `server/__tests__/` — add a test for the warning condition
- **Reference seams:**
  - `server/index.ts:121-123` — existing `logger.info({ apiKeyConfigured, authMode, host, port }, ...)` call to imitate
  - `server/__tests__/canopy-stale-cache.test.ts` — pattern for server-layer tests
- **Spawn gate:** seam confirmed, exact line identified

## Problem

When `CAP_HOST` is set to `0.0.0.0` (or any address other than `127.0.0.1`) and `CAP_API_KEY` is not set, the cap server binds publicly but accepts all requests without authentication. There is no startup warning for this combination. An operator changing `CAP_HOST` for LAN access could unknowingly expose all write routes.

## What exists (state)

- **`server/index.ts:118-125`**: `startServer()` logs a single info line with host, port, and auth mode, then calls `serve()`. No warning for the unsafe combination.
- **`getApiKey()`**: already defined at line 25 — returns `undefined` when `CAP_API_KEY` is unset.
- **`CAP_HOST`**: imported from `./lib/config.ts` at line 6 — already available in `startServer()`.
- **Auth middleware**: correctly gates all `/api/*` routes when `CAP_API_KEY` is set; allows all when unset.

## What needs doing (intent)

Add a single `logger.warn(...)` call in `startServer()` that fires when `host !== '127.0.0.1'` and `getApiKey()` is falsy. The warning message should name the risk concretely: the server is reachable beyond localhost and has no authentication. Add a test that asserts the warning is emitted in that configuration.

## Scope

- **Primary seam:** `server/index.ts` `startServer()`
- **Allowed files:** `server/index.ts`, `server/__tests__/server-exposure-warning.test.ts` (new)
- **Explicit non-goals:**
  - No behavior change — this is a warning only, not a block or auto-config
  - No new env variables
  - No changes to auth middleware

---

### Step 1: Add the startup warning

**Project:** `cap/`
**Effort:** tiny
**Depends on:** nothing

In `server/index.ts`, inside `startServer()`, add after the existing `logger.info(...)` line:

```typescript
if (host !== '127.0.0.1' && !getApiKey()) {
  logger.warn(
    { host },
    'CAP_HOST is set beyond localhost but CAP_API_KEY is not configured — ' +
    'all write routes are accessible without authentication'
  )
}
```

The full `startServer()` body becomes:

```typescript
export function startServer() {
  const port = Number(process.env.PORT ?? 3001)
  const host = CAP_HOST
  const authMode = isUnauthenticatedDevMode() ? 'explicit-unauthenticated-dev' : 'protected'

  logger.info({ apiKeyConfigured: !!getApiKey(), authMode, host, port }, 'Cap server started')

  if (host !== '127.0.0.1' && !getApiKey()) {
    logger.warn(
      { host },
      'CAP_HOST is set beyond localhost but CAP_API_KEY is not configured — ' +
      'all write routes are accessible without authentication'
    )
  }

  serve({ fetch: app.fetch, hostname: host, port })
}
```

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `npm run build` succeeds with no TypeScript errors

---

### Step 2: Add a test for the warning

**Project:** `cap/`
**Effort:** small
**Depends on:** Step 1

Create `server/__tests__/server-exposure-warning.test.ts`. Test that the warning is emitted when the unsafe combination is present, and that it is NOT emitted for safe combinations:

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

describe('startServer exposure warning', () => {
  let warnSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    // spy on the logger used in index.ts
    // import logger and spy, or capture console.warn depending on how logger is structured
  })

  afterEach(() => {
    vi.restoreAllMocks()
    delete process.env.CAP_HOST
    delete process.env.CAP_API_KEY
  })

  it('warns when CAP_HOST is 0.0.0.0 and CAP_API_KEY is unset', () => {
    process.env.CAP_HOST = '0.0.0.0'
    delete process.env.CAP_API_KEY
    // trigger the warning check logic directly or re-import startServer
    // assert warnSpy was called with message containing 'all write routes'
  })

  it('does not warn when CAP_HOST is 127.0.0.1 even without CAP_API_KEY', () => {
    process.env.CAP_HOST = '127.0.0.1'
    delete process.env.CAP_API_KEY
    // assert warnSpy not called
  })

  it('does not warn when CAP_HOST is 0.0.0.0 and CAP_API_KEY is set', () => {
    process.env.CAP_HOST = '0.0.0.0'
    process.env.CAP_API_KEY = 'secret-key'
    // assert warnSpy not called
  })
})
```

Note: adapt the spy to whatever logger pattern `server/index.ts` uses. The test structure above is a skeleton — follow the existing test patterns in `server/__tests__/` exactly.

#### Verification

```bash
cd cap && npm test 2>&1 | tail -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] All 3 test cases pass
- [ ] No other tests regressed

---

### Step 3: Full suite

**Project:** `cap/`
**Effort:** small
**Depends on:** Step 2

```bash
cd cap && npm run build 2>&1 | tail -10
cd cap && npm test 2>&1 | tail -20
cd cap && npm run lint 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Build passes
- [ ] All tests pass
- [ ] Lint clean

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cap/verify-server-exposure-warning.sh`
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` is updated to reflect completion

### Final Verification

```bash
bash .handoffs/cap/verify-server-exposure-warning.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Spawned from U4 auth and access control audit (2026-04-23). The audit found that the cap server has no startup warning when `CAP_HOST != 127.0.0.1` and `CAP_API_KEY` is unset. This combination silently exposes all write routes to LAN access without authentication. The fix is a single log warning that makes the misconfiguration visible before the operator is surprised.

Related: `cross-project/auth-audit-findings.md` item #1.
