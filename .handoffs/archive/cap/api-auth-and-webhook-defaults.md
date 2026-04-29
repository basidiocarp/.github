# Cap: API Auth And Webhook Defaults

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/server/index.ts`, `cap/server/lib/watchers/`, `cap/server/routes/watchers.ts`, `cap/server/routes/settings/`, `cap/server/routes/rhizome/`, `cap/server/routes/sessions.ts`, `cap/server/routes/mycelium.ts`, `cap/src/lib/api/http.ts`, `cap/server/__tests__/`, `cap/src/**/__tests__/`, `cap/README.md`, `cap/docs/api.md`, `cap/docs/getting-started.md`
- **Cross-repo edits:** none
- **Non-goals:** no frontend UI redesign and no OAuth implementation
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cap/verify-api-auth-and-webhook-defaults.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** API auth middleware, watcher signature validators, server exposure checks, route tests
- **Reference seams:** existing `auth-hardening.test.ts`, `server-exposure-warning.test.ts`, `watchers.test.ts`
- **Spawn gate:** do not launch an implementer until the parent agent chooses the local-dev bypass model for unauthenticated API access

## Problem

Cap's API auth is fail-open when `CAP_API_KEY` is unset, including write/action routes. Webhook signature checks also accept unsigned payloads when route-specific secrets are unset. Those defaults are tolerable only for a clearly local/dev server, but current behavior leaves exposed or write-capable deployments easy to misconfigure.

The security audit added three concrete abuse paths that should be covered by the same fix rather than split into duplicate handoffs:

- cross-site simple POSTs can mutate local Cap when auth is disabled or bypassed because CORS does not stop write-only CSRF-style requests
- unauthenticated network-bound Cap can expose local paths, project roots, Mycelium command history, and Hyphae session artifacts
- the browser stores the bearer key in `localStorage`; decide whether that is accepted as localhost-only risk or replace it with session/memory storage

## What needs doing

1. Refuse startup, disable write routes, or require explicit dev mode when `CAP_API_KEY` is unset outside localhost-only use.
2. Add route coverage for write/action endpoints under missing and wrong API keys.
3. Make webhook missing-secret behavior explicit and safe by default.
4. Preserve a deliberate local development bypass only when clearly configured.
5. Add malformed-body and blank-identity negative tests for write/action validators so auth and validation failures do not call downstream adapters.
6. Add fetch-metadata/origin/content-type protections for unauthenticated local-dev writes, or prove auth is always required before those routes run.
7. Make path-probing and artifact routes fail closed before filesystem probes or command-history/session data exposure when Cap is network-bound without auth.
8. Decide and document the frontend API-key storage model; if Cap is not strictly localhost-only, avoid persistent `localStorage` for bearer credentials.
9. Document `CAP_API_KEY`, `CAP_ALLOW_UNAUTHENTICATED`, `CAP_HOST`, `CORS_ORIGIN`, webhook secrets, intentionally public health/client-config routes, and local-only bypass behavior in public Cap docs.

## Verification

```bash
cd cap && npx vitest run server/__tests__/auth-hardening.test.ts server/__tests__/server-exposure-warning.test.ts
cd cap && npx vitest run server/__tests__/watchers.test.ts
bash .handoffs/cap/verify-api-auth-and-webhook-defaults.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] non-local or write-capable API mode is not open when `CAP_API_KEY` is unset
- [ ] write/action routes have auth regression tests
- [ ] malformed action bodies and blank identity fields return `400` without invoking adapters
- [ ] unsigned webhook payloads are rejected unless explicit dev bypass is set
- [ ] cross-site simple POSTs cannot mutate state in unauthenticated local-dev mode
- [ ] `/api/settings`, `/api/rhizome/project`, `/api/sessions/*`, and `/api/mycelium/history` do not expose local paths or command artifacts when auth is unset on a non-loopback bind
- [ ] frontend API-key persistence is either removed or documented as an accepted localhost-only risk
- [ ] README/API/getting-started docs describe auth, CORS, webhook secret, public route, and local-dev bypass behavior accurately
- [ ] exposure warning behavior matches the enforcement model
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 2 runtime safety audit and expanded by Phase 5 security audit and Phase 7 docs drift audit. Severity: high/medium.
