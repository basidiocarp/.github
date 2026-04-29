# Cap: Canopy Stale Cache Integrity

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/server/routes/canopy.ts`, `cap/server/__tests__/`, `cap/server/canopy.ts`
- **Cross-repo edits:** none
- **Non-goals:** no Canopy API redesign and no frontend cache rewrite
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cap/verify-canopy-stale-cache-integrity.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** Canopy server route stale snapshot cache and route tests
- **Reference seams:** existing stale-on-error tests and Canopy route adapter
- **Spawn gate:** do not launch an implementer until the parent agent identifies the normalized cache key fields for snapshot queries

## Problem

Cap keeps a single global stale Canopy snapshot and returns it for any failed request. Because snapshot requests are parameterized by project and filters, a failure for one project/filter can return stale state from another project/filter.

## What needs doing

1. Key stale snapshot cache by normalized project/filter/sort/view query options.
2. Only serve stale snapshots when the failed request matches the cached request key.
3. Add two-project/two-filter stale fallback tests.

## Verification

```bash
cd cap && npx vitest run server/__tests__/canopy*.test.ts
bash .handoffs/cap/verify-canopy-stale-cache-integrity.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] stale snapshot fallback is isolated by request key
- [ ] project/filter mismatch does not return unrelated stale data
- [ ] tests cover same-key fallback and different-key rejection
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 4 data integrity audit. Severity: medium.
