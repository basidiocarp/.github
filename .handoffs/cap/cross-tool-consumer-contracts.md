# Cap: Cross-Tool Consumer Contracts

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/server/lib/canopy-validators.ts`, `cap/server/canopy.ts`, `cap/server/annulus.ts`, `cap/server/__tests__/`, `cap/src/lib/types/`
- **Cross-repo edits:** matching Septa schemas/fixtures only when Cap exposes a real mismatch in the contract
- **Non-goals:** no Cap UI changes and no Annulus producer rewrite
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cap/verify-cross-tool-consumer-contracts.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** `server/lib/canopy-validators.ts`, `server/annulus.ts`, `server/canopy.ts`, `src/lib/types/canopy.ts`
- **Reference seams:** `septa/evidence-ref-v1.schema.json`, `septa/annulus-statusline-v1.schema.json`, `annulus/src/statusline.rs`
- **Spawn gate:** do not launch an implementer until the parent agent chooses whether Cap should consume `annulus status --json` or `annulus statusline --json` for this surface

## Problem

Cap has consumer-side contract drift in two narrow places. It rejects the valid `evidence-ref-v1` source kind `script_verification`, and it is listed around the `annulus-statusline-v1` surface while the current server code consumes `annulus status --json` instead of the statusline contract.

## What needs doing

1. Add `script_verification` to Cap evidence-ref types and validators.
2. Add tests proving Cap accepts all Septa evidence source kinds and rejects unknown kinds.
3. Decide whether the Annulus server route should consume statusline JSON or whether the Septa registry/docs should point to the actual status JSON contract.
4. Add a fixture-backed test for the Annulus JSON shape Cap consumes.

## Scope

- **Primary seam:** Cap server contract adapters
- **Allowed files:** Cap server adapters, Cap shared types, Cap server tests, matching Septa metadata only
- **Explicit non-goals:** no React dashboard layout, no Annulus statusline producer changes

## Verification

```bash
cd cap && npx vitest run server/__tests__/canopy-validators.test.ts
cd cap && npx vitest run server/__tests__/annulus.test.ts
bash .handoffs/cap/verify-cross-tool-consumer-contracts.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Cap accepts `script_verification` evidence refs
- [ ] Cap tests cover all Septa evidence source kinds
- [ ] Cap's Annulus consumer contract is named and fixture-backed
- [ ] Septa producer/consumer metadata matches the real Cap route
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the Phase 1 contract round-trip audit in the sequential audit hardening campaign. Severity: medium.
