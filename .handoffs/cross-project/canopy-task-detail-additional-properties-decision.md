# Cross-Project: canopy-task-detail additionalProperties Decision (F2.14 + F2.15)

⚠ **Decision Required before starting** — design call between schema-relax vs producer-split.

## Handoff Metadata

- **Dispatch:** `direct` (after decision)
- **Owning repo:** `septa` and/or `canopy` (depending on decision)
- **Allowed write scope:** depends on direction — see below
- **Cross-repo edits:** depends on direction
- **Non-goals:** does not modify the cap consumer (already validates correctly via C3/F2.6 + F2.7)
- **Verification contract:** TBD after decision

## Problem (F2.14 + F2.15, blockers)

`septa/canopy-task-detail-v1.schema.json` declares `additionalProperties: false` on both the root object and the `attention` subobject. The canopy producer's `TaskDetail` and `TaskAttention` structs emit roughly **24 extra fields** between them that the schema doesn't list.

The drift is invisible today because:
- The canonical fixture in `septa/fixtures/canopy-task-detail-v1.example.json` is minimal and doesn't exercise the extras.
- Cap's consumer doesn't validate `additionalProperties` — it just reads the fields it cares about.
- `septa/validate-all.sh` checks the fixture against the schema and stays green.

But any strict consumer (or a future migration to a strict validator) would reject every payload canopy emits.

## ⚠ Decision needed

Two directions:

### Option A — Relax the schema

Change `additionalProperties: false` to `additionalProperties: true` (or unset it) on the root and `attention` subobject. This matches reality. **Cost**: loses the schema's ability to detect drift in the other direction (producer adds new field, consumer doesn't notice).

### Option B — Split the producer struct

Define a dedicated `TaskDetailWire` (or similar) struct that contains only the schema-declared fields. The canopy producer keeps its rich internal `TaskDetail` for in-memory work, and serializes via `TaskDetailWire` at the API boundary. Same shape applies to `TaskAttention`. **Cost**: maintenance — every new schema field requires updating the wire type and the producer's mapping.

### Hybrid — Option C

Add the legitimately-shared fields to the schema; keep producer-only fields out. Requires going through each of the ~24 fields and classifying.

## Operator decision capture

Before dispatch, record:
1. Chosen direction (A / B / C).
2. If C: the field-by-field classification (which fields belong in the schema, which stay producer-only).
3. Whether `cap` should also tighten its consumer to validate `additionalProperties: false` (currently it doesn't).

## Scope (depends on direction)

- **Option A**: edit `septa/canopy-task-detail-v1.schema.json` to relax `additionalProperties`. Update fixture if needed. No producer change.
- **Option B**: edit `canopy/src/api.rs` (or wherever `TaskDetail` is serialized) to introduce `TaskDetailWire`. No schema change.
- **Option C**: edit both — extend the schema with newly-schema-promoted fields, and split the producer for fields that stay internal.

## Context

Closes lane 2 blockers F2.14 and F2.15 from the 2026-04-30 audit. Design-bound — operator must pick the direction before implementer can proceed.
