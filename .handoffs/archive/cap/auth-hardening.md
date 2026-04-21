# Cap Auth Hardening

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** cap/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

<!-- Save as: .handoffs/cap/auth-hardening.md -->
<!-- Create verify script: .handoffs/cap/verify-auth-hardening.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

Cap currently treats a missing `CAP_API_KEY` as “disable auth entirely” for every
`/api/*` route except health checks. That makes the entire read/write API surface
fail open if the variable is omitted in a non-local deployment.

## What exists (state)

- **Auth middleware:** `cap/server/index.ts` now fails closed by default and only permits unauthenticated access when `CAP_ALLOW_UNAUTHENTICATED=1`
- **API surface:** 75 route handlers, including 18 write endpoints
- **Health endpoint:** `/api/health` is already treated separately

## What needs doing (intent)

Make Cap fail closed by default. Keep `/api/health` public, but require an explicit
development-only escape hatch instead of silently disabling authentication.

---

### Step 1: Fail Closed By Default

**Project:** `cap/`
**Effort:** 45 min
**Depends on:** nothing

Update `createAuthMiddleware()` in `server/index.ts` so:

- `/api/health` remains unauthenticated
- all other `/api/*` routes require a bearer token by default
- unauthenticated mode only activates when an explicit dev flag is set, such as
  `CAP_ALLOW_UNAUTHENTICATED=1`
- startup logs clearly state whether the server is protected or running in explicit
  unauthenticated development mode

#### Files to modify

**`cap/server/index.ts`** — replace the implicit fail-open branch with explicit
fail-closed behavior and a development-only override.

**`cap/server/__tests__/auth-hardening.test.ts`** — add coverage for:

- missing `CAP_API_KEY` and no override → protected routes reject
- missing `CAP_API_KEY` with explicit override → protected routes allow
- `/api/health` remains public in all cases

#### Verification

```bash
cd cap && npm run test:server -- server/__tests__/auth-hardening.test.ts
```

**Output:**
<!-- PASTE START -->
PASS: Explicit unauthenticated override exists
PASS: Health route stays special-cased
PASS: Auth tests cover missing API key behavior
Results: 3 passed, 0 failed

<!-- PASTE END -->

**Checklist:**
- [x] Protected routes no longer go unauthenticated just because `CAP_API_KEY` is missing
- [x] Any unauthenticated mode requires an explicit development flag
- [x] Server tests cover the new auth behavior

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Verification output is pasted above
2. The verification script passes: `bash .handoffs/cap/verify-auth-hardening.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cap/verify-auth-hardening.sh
```

**Output:**
<!-- PASTE START -->
PASS: Explicit unauthenticated override exists
PASS: Health route stays special-cased
PASS: Auth tests cover missing API key behavior
Results: 3 passed, 0 failed

<!-- PASTE END -->

## Context

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsCreated from the completed Cap deep audit on 2026-04-05. This was the highest-severity
new finding in the audit and is separate from boundary documentation drift.
