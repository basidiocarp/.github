# Cap: Server And UI Verification Hardening

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/server/__tests__/`, `cap/server/lib/canopy-validators.ts`, `cap/server/routes/`, `cap/src/pages/Canopy.test.tsx`, `cap/src/pages/canopy/`, `cap/src/lib/`
- **Cross-repo edits:** none
- **Non-goals:** no auth policy redesign and no new dashboard feature work
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cap/verify-server-and-ui-verification-hardening.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** server route tests, Canopy validators, Cap Canopy page tests, API/query tests
- **Reference seams:** `api-auth-and-webhook-defaults.md`, `cross-tool-consumer-contracts.md`, existing `Canopy.test.tsx`
- **Spawn gate:** do not launch an implementer until the parent agent decides which UI assertions should move from hook-call internals to observable behavior

## Problem

Cap has verification gaps beyond the underlying auth/webhook defaults. Server tests currently prove some fail-open behavior, validator tests miss malformed bodies and blank identity strings, contract tests use hand-built payloads instead of Septa-backed fixtures, and Canopy page tests assert hook internals more than user-visible outcomes.

## What needs doing

1. Add malformed body tests for action/write routes: `null`, arrays, scalars, and whitespace-only identity fields.
2. Add fixture-backed contract tests that read Septa enums/fixtures for Cap consumer allowlists.
3. Ensure rejected auth/validation paths do not call downstream adapters.
4. Move Canopy page tests toward visible behavior: hidden/disabled actions, rendered errors, refetch/invalidation, and auth/retry states.
5. Keep a thin query/API payload-mapping layer test for exact payload shape.

## Verification

```bash
cd cap && npx vitest run server/__tests__/canopy-validators.test.ts server/__tests__/api.test.ts
cd cap && npx vitest run server/__tests__/canopy-client.test.ts server/__tests__/annulus.test.ts
cd cap && npx vitest run --config vitest.frontend.config.ts src/pages/Canopy.test.tsx
bash .handoffs/cap/verify-server-and-ui-verification-hardening.sh
```

**Output:**
<!-- PASTE START -->
PASS: Cap validator and API tests run
PASS: Cap contract consumer tests run
PASS: Canopy UI behavior tests run
PASS: tests mention malformed/blank payload coverage
Results: 4 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] malformed write/action bodies return `400` instead of throwing
- [x] rejected requests do not call downstream adapters
- [x] Cap consumer tests use Septa-backed enum/fixture coverage where practical
- [x] Canopy UI tests assert observable behavior and error states
- [x] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 3 verification quality audit. Severity: medium/high.
