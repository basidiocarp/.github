# Canopy: Septa Read Model Contracts

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/src/models.rs`, `canopy/src/api/`, `canopy/src/store/`, `canopy/tests/`, and matching `septa/*canopy*`, `septa/*handoff*`, `septa/*workflow-outcome*`, `septa/*workflow-status*`, `septa/fixtures/*`
- **Cross-repo edits:** `septa/` only for schemas and fixtures that move with Canopy payload changes
- **Non-goals:** no Cap UI changes unless a schema decision requires a follow-up handoff
- **Verification contract:** run the repo-local commands below and `bash .handoffs/canopy/verify-septa-read-model-contracts.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** `src/models.rs`, `src/store/outcomes.rs`, `src/store/orchestration.rs`, `src/store/schema.rs`, task-detail/snapshot API builders, workflow status read models, Canopy contract tests, Septa schemas and fixtures
- **Reference seams:** `septa/canopy-snapshot-v1.schema.json`, `septa/canopy-task-detail-v1.schema.json`, `septa/handoff-context-v1.schema.json`, `septa/workflow-outcome-v1.schema.json`, `septa/workflow-status-v1.schema.json`
- **Spawn gate:** do not launch an implementer until the parent agent chooses whether `allowed_actions` is a string ID list or rich action-object payload

## Problem

Canopy read models and Septa schemas have drifted. `TaskDetail.allowed_actions` emits rich `OperatorAction` objects while Septa says `string[]`; snapshot attention includes fields not represented in the schema; handoff and workflow outcome paths do not round-trip the structured contracts.

The contract round-trip audit also found that Canopy is listed as a `workflow-status-v1` consumer, but no Canopy ingest/read-model path currently accepts or enforces the schema-shaped status payload emitted by Hymenium.

## What needs doing

1. Decide and implement the `allowed_actions` wire shape.
2. Align `canopy-snapshot-v1` with `SnapshotAttentionSummary`, including `needs_verification_count` or removing it from serialization.
3. Add a structured handoff context projection or storage path that round-trips `handoff-context-v1`.
4. Parse and require `schema_version = "1.0"` for workflow outcomes.
5. Fix Septa validation so local `$ref` resolution does not require live DNS for `basidiocarp.dev`.
6. Add or correct Canopy's `workflow-status-v1` consumer/read-model path, or remove Canopy from the contract registry if it is not a real consumer yet.
7. Add producer/fixture tests that serialize real Canopy payloads and validate them against Septa.
8. Harden the paired verify script so it runs the required Septa schema validations, not only broad string checks.

## Scope

- **Primary seam:** Canopy read-model wire contracts
- **Allowed files:** Canopy payload builders/tests and matching Septa schemas/fixtures
- **Explicit non-goals:** no dashboard rendering, no unrelated task lifecycle behavior

## Verification

```bash
cd canopy && cargo test task
cd canopy && cargo test handoff
cd septa && check-jsonschema --schemafile canopy-snapshot-v1.schema.json fixtures/canopy-snapshot-v1.example.json
cd septa && check-jsonschema --schemafile canopy-task-detail-v1.schema.json fixtures/canopy-task-detail-v1.example.json
cd septa && check-jsonschema --schemafile workflow-status-v1.schema.json fixtures/workflow-status-v1.example.json
bash .handoffs/canopy/verify-septa-read-model-contracts.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `allowed_actions` code, schema, fixture, and consumer-facing docs agree
- [ ] snapshot attention code, schema, and fixture agree
- [ ] handoff context round-trips the Septa shape or is explicitly out of scope in Septa
- [ ] workflow outcome ingest rejects missing or wrong `schema_version`
- [ ] workflow status ingest/read-model behavior matches `workflow-status-v1` or Canopy is removed as a consumer
- [ ] schema validation works without network DNS
- [ ] paired verify script runs schema validation for snapshot, task detail, and workflow status
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 Rust ecosystem audit. Severity: high/medium. Focus is contract fidelity, not a model rewrite.
