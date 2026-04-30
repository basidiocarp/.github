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

## Decision (recorded 2026-04-30)

**Option C chosen — Hybrid.** Audit each of the ~24 extra fields. Promote fields that are useful to consumers (cap dashboard, future operator-facing surfaces) to the schema; demote producer-only fields to internal struct state via a `TaskDetailWire`/`TaskAttentionWire` split (or `#[serde(skip_serializing)]` if a wire struct is overkill).

**Outcome (after first pass + Stage 1 review + scope expansion)**: 22 fields promoted to the schema (every field that had at least one observable consumer signal — named in cap consumer code OR asserted by canopy's CLI integration tests in `tests/api_snapshot.rs` / `tests/cli.rs`). 6 fields stayed pure-internal and are dropped at the wire boundary: `agent_attention`, `deadline_summary`, `execution_summary`, `messages`, `council_session`, `tool_adoption_score`. The promotion bar was higher than the initial 5–10 estimate because canopy's CLI integration tests use 18+ task-detail fields, which counts as a real consumer signal under the heuristic.

**Implementer judgment**: classify each field per the heuristic below. Bias toward "promote" when the field has clear operator/consumer value; bias toward "internal" when it's a serde artifact of an in-memory bookkeeping type that nobody outside canopy needs to see.

| Field characteristic | Disposition |
|----------------------|-------------|
| Already referenced by cap or another sibling consumer | Promote |
| Documented in canopy's public API surface (api.rs return type that flows out) | Promote |
| Internal cache, lookup, or runtime-only state (e.g. last-touch timestamps, in-flight flags) | Internal |
| Bookkeeping for canopy's own future code (no current consumer) | Internal |
| Ambiguous | Internal — promote later if a consumer materialises |

Cap consumer **does not** need additional tightening in this handoff. C3/F2.6+F2.7 already added `attention` and `sla_summary` presence checks. Whether cap should also enforce `additionalProperties: false` against the schema is a separate concern (Low priority); not in scope here.

## Scope (depends on direction)

- **Option A**: edit `septa/canopy-task-detail-v1.schema.json` to relax `additionalProperties`. Update fixture if needed. No producer change.
- **Option B**: edit `canopy/src/api.rs` (or wherever `TaskDetail` is serialized) to introduce `TaskDetailWire`. No schema change.
- **Option C**: edit both — extend the schema with newly-schema-promoted fields, and split the producer for fields that stay internal.

## Context

Closes lane 2 blockers F2.14 and F2.15 from the 2026-04-30 audit. Design-bound — operator must pick the direction before implementer can proceed.
