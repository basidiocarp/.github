# Canopy: Notification Contract Alignment

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/src/models.rs`, `canopy/src/store/schema.rs`, `canopy/src/store/`, `canopy/tests/`, and matching `septa/canopy-notification-v1.schema.json`, `septa/fixtures/canopy-notification-v1.example.json`
- **Cross-repo edits:** `cap/server/canopy.ts`, `annulus/src/notify.rs` only if the chosen wire shape changes consumers
- **Non-goals:** no notification UX redesign and no Annulus write-policy changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/canopy/verify-canopy-notification-contract-alignment.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** `canopy/src/models.rs`, notification store schema/builders, Cap notification API adapter, Annulus notification output
- **Reference seams:** `septa/canopy-notification-v1.schema.json`, `septa/fixtures/canopy-notification-v1.example.json`, `cap/server/canopy.ts`, `annulus/src/notify.rs`
- **Spawn gate:** do not launch an implementer until the parent agent chooses whether the contract field is `id` or `notification_id`, and whether `seen` or `read_at` is authoritative

## Problem

`canopy-notification-v1` does not match the real producer or consumers. Septa requires `id`, `event_type`, `payload`, and `created_at`, while Canopy stores and emits `notification_id` and `seen`; Cap and Annulus consume the code/DB shape rather than the Septa shape.

## What needs doing

1. Pick the canonical notification wire shape.
2. Align Canopy model/store serialization with `canopy-notification-v1`.
3. Update the Septa schema and fixture if the code shape is the intended contract.
4. Update Cap and Annulus consumers only if the canonical shape changes.
5. Add a producer/consumer contract test or fixture validation that would catch `id` versus `notification_id` drift.

## Scope

- **Primary seam:** Canopy notification DTO contract
- **Allowed files:** Canopy notification models/store/tests, one Septa schema/fixture, and narrow Cap/Annulus consumer adapters if required
- **Explicit non-goals:** no notification delivery policy, no statusline contract work

## Verification

```bash
cd septa && check-jsonschema --schemafile canopy-notification-v1.schema.json fixtures/canopy-notification-v1.example.json
cd canopy && cargo test notification
bash .handoffs/canopy/verify-canopy-notification-contract-alignment.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Canopy notification code, schema, and fixture agree on identity fields
- [ ] read/seen state uses one documented field shape
- [ ] Cap and Annulus consumers accept the canonical shape
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the Phase 1 contract round-trip audit in the sequential audit hardening campaign. Severity: high.
