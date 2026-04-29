# Phase 1 Summary: Contract Round-Trip Audit

**Status:** consolidated into active handoffs

## Covered By Existing Handoffs

- `dispatch-request-v1` Hymenium intake drift: `hymenium/orchestration-dispatch-contracts.md`
- Canopy task detail, snapshot, handoff, and workflow outcome drift: `canopy/septa-read-model-contracts.md`
- Rhizome/Hyphae `code-graph-v1` producer/import drift: `rhizome/code-graph-contract-and-install-boundary.md` and `hyphae/code-graph-import-and-core-boundary.md`
- Volva hook/runtime identity/timeout drift: `volva/hook-runtime-contracts.md`
- Annulus statusline producer drift: `annulus/operator-boundary-statusline-contracts.md`
- Mycelium optional Hyphae fallback output warning: `mycelium/output-cleanliness.md`

## Folded Into Existing Handoffs

- Hymenium Canopy task-detail consumer does not enforce `canopy-task-detail-v1`; folded into `hymenium/orchestration-dispatch-contracts.md`.
- Canopy has no real `workflow-status-v1` ingest/read model despite being listed as a consumer; folded into `canopy/septa-read-model-contracts.md`.

## New Handoffs

- `canopy/canopy-notification-contract-alignment.md`: notification schema/code/Cap/Annulus mismatch.
- `cap/cross-tool-consumer-contracts.md`: `script_verification` evidence kind and Annulus status/statusline consumer mismatch.
- `cortina/session-usage-event-contracts.md`: session and usage event payloads do not round-trip through Septa.
- `hyphae/read-model-and-archive-contracts.md`: Hyphae read-model schemas drift from CLI output and Cap consumers; archive export includes forbidden `filter.until`.
- `mycelium/gain-summary-contracts.md`: gain JSON emits `telemetry_summary` outside schema; summary contract is advertised without a real JSON round-trip.
- `septa/validation-tooling-and-inventory.md`: raw validation docs are network-sensitive, registries lag schemas, and variant fixtures are outside default validation.

## Validation Notes

The audit used `septa/validate-all.sh`, which passed with `52 passed, 0 failed, 0 skipped`. Direct raw `check-jsonschema --schemafile` commands for cross-ref schemas can fail without DNS because `$id` rebases local refs to `https://basidiocarp.dev`; that is now tracked in the Septa validation handoff.
