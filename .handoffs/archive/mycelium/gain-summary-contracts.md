# Mycelium: Gain And Summary Contracts

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** `mycelium/src/gain/`, `mycelium/src/summary_cmd.rs`, `mycelium/src/summarizer.rs`, `mycelium/src/tracking/`, `mycelium/tests/`, and matching Mycelium Septa schemas/fixtures
- **Cross-repo edits:** `cap/server/mycelium/` and `hyphae/` only if consumer contract tests must move with the chosen DTO shape
- **Non-goals:** no scoring algorithm redesign and no output-cleanliness fallback work
- **Verification contract:** run the repo-local commands below and `bash .handoffs/mycelium/verify-gain-summary-contracts.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** `src/gain/export.rs`, `src/summary_cmd.rs`, `src/summarizer.rs`, tracking summary storage, Cap Mycelium gain API
- **Reference seams:** `septa/mycelium-gain-v1.schema.json`, `septa/mycelium-summary-v1.schema.json`, `cap/server/mycelium/gain.ts`
- **Spawn gate:** do not launch an implementer until the parent agent chooses whether `telemetry_summary` is part of `mycelium-gain-v1` or an internal/debug-only field

## Problem

`mycelium-gain-v1` rejects real Mycelium `gain --format json` output because the producer emits `telemetry_summary` and the schema forbids extra top-level properties. `mycelium-summary-v1` is advertised as a JSON contract, but the current summary command prints plain text and tracking stores summaries directly without a schema-shaped DTO.

## What needs doing

1. Align `gain --format json` with `mycelium-gain-v1` or add `telemetry_summary` to the schema and fixture.
2. Make Cap's Mycelium gain API validate the full canonical shape rather than only selected fields.
3. Decide whether `mycelium-summary-v1` is a real public contract; either implement a JSON summary DTO or remove/mark the advertised contract as not currently produced.
4. Add CLI output contract tests for gain and summary surfaces.

## Scope

- **Primary seam:** Mycelium public JSON output contracts
- **Allowed files:** Mycelium gain/summary/tracking code and tests, matching Septa schemas/fixtures, narrow Cap gain consumer tests
- **Explicit non-goals:** no scoring changes, no Hyphae fallback warning changes

## Verification

```bash
cd mycelium && cargo test gain
cd mycelium && cargo test summary
cd septa && check-jsonschema --schemafile mycelium-gain-v1.schema.json fixtures/mycelium-gain-v1.example.json
cd septa && check-jsonschema --schemafile mycelium-summary-v1.schema.json fixtures/mycelium-summary-v1.example.json
bash .handoffs/mycelium/verify-gain-summary-contracts.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] real gain JSON output validates against `mycelium-gain-v1`
- [ ] Cap validates the canonical gain contract
- [ ] `mycelium-summary-v1` is produced by real code or removed from active contract claims
- [ ] summary command behavior is documented by tests
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the Phase 1 contract round-trip audit in the sequential audit hardening campaign. Severity: high/medium.
