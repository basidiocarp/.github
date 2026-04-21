# Operator Contract Drift

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa` (primary) with coordinated update to `hymenium` (serialization skip)
- **Allowed write scope:** `septa/canopy-task-detail-v1.schema.json`, `septa/canopy-snapshot-v1.schema.json`, `septa/workflow-status-v1.schema.json`, their corresponding `septa/fixtures/*.example.json`, and `hymenium/src/workflow/engine.rs` (`PhaseState` serde attributes only)
- **Cross-repo edits:** hymenium serde attributes only — do not change Rust struct shape or engine logic
- **Non-goals:** role vocabulary redesign (see `septa/workflow-template-role-vocabulary.md`), new fields, new contracts
- **Verification contract:** `bash .handoffs/septa/verify-operator-contract-drift.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive

## Implementation Seam

- **Likely repos:** `septa`, `hymenium`, minor read-only cross-check against `canopy` and `cap`
- **Likely files:**
  - `septa/canopy-task-detail-v1.schema.json`
  - `septa/fixtures/canopy-task-detail-v1.example.json` (re-validate)
  - `septa/workflow-status-v1.schema.json`
  - `septa/fixtures/workflow-status-v1.example.json` (re-validate)
  - `hymenium/src/workflow/engine.rs` (`PhaseState` struct)
- **Reference seams:**
  - Canopy producer: `canopy/src/models.rs` around `AttentionLevel` (~L473) and `BreachSeverity` (~L492)
  - Cap consumer: `cap/src/lib/types/canopy.ts` (`CanopyAttentionLevel`, `CanopyBreachSeverity`)
- **Spawn gate:** parent must confirm the exact current enum values in both Rust and TS before launching

## Problem

The cross-repo contract-drift audit identified five schema-vs-code mismatches in operator-surface contracts. The code (producer + consumer) is consistent with itself, but the schemas are stale. A strict schema validator rejects payloads that real systems emit. Additionally, one Rust struct leaks internal fields (`failure_reason`, `retry_count`) that the schema does not declare.

## What exists (state)

1. **`septa/canopy-task-detail-v1.schema.json` `attention.level` enum is stale.**
   - Schema: `["normal", "warning", "critical"]`
   - Canopy `AttentionLevel` Rust enum serializes as: `"normal"`, `"needs_attention"`, `"critical"` (see `canopy/src/models.rs:470-476`)
   - Cap TypeScript: `'normal' | 'needs_attention' | 'critical'` (see `cap/src/lib/types/canopy.ts:5`)
   - Producer and consumer agree; schema is stuck on an older label (`"warning"`).

2. **`septa/canopy-task-detail-v1.schema.json` `sla_summary.breach_severity` enum is stale.**
   - Schema: `["none", "warning", "critical"]`
   - Canopy `BreachSeverity` Rust enum: `none`, `low`, `medium`, `high`, `critical` (5 values, `canopy/src/models.rs:489-497`)
   - Cap TypeScript: matches producer — 5 values (`cap/src/lib/types/canopy.ts:171`)
   - Producer and consumer agree; schema has only 3 values and includes a non-existent `"warning"`.

3. **`septa/canopy-snapshot-v1.schema.json` `sla_summary.breach_severity` enum is stale (same drift as #2).**
   - Schema (line 33): `["none", "warning", "critical"]`
   - Same Rust `BreachSeverity` producer, same TypeScript consumer.
   - Identical fix; paired with #2 since the enum is a shared value type across both schemas.

4. **`septa/canopy-snapshot-v1.schema.json` `agents[].status` enum is inconsistent with `AgentStatus`.**
   - Schema (line 65): `["active", "idle", "stopped", "error"]`
   - Canopy Rust `AgentStatus` (`canopy/src/models.rs:29-35`) serializes: `"idle"`, `"assigned"`, `"in_progress"`, `"blocked"`, `"review_required"` (`#[serde(rename_all = "snake_case")]`).
   - Only `"idle"` overlaps. `"active"`, `"stopped"`, `"error"` do not exist in the producer; `"assigned"`, `"in_progress"`, `"blocked"`, `"review_required"` are missing from the schema.
   - This is a substantial operator-surface mismatch: the snapshot dashboard's agents panel cannot honestly validate against the schema without a real shape update.

5. **`septa/workflow-status-v1.schema.json` phase items have `additionalProperties: false` but Rust `PhaseState` serializes extra fields.**
   - Rust `PhaseState` (`hymenium/src/workflow/engine.rs:100-101`) has `failure_reason: Option<String>` and `retry_count: u32`.
   - Schema does not declare these two fields and has `additionalProperties: false` on phase items.
   - A strict validator rejects the serialized `PhaseState`. Whether this is a leak (internal fields shouldn't be wire-visible) or a schema gap (wire should declare them) is the design question.

## What needs doing (intent)

For 1 and 2: update the schema enums to match the code. Producer and consumer are the ground truth.

For 3: choose one — either add the two fields to the schema (declare the wire contract includes them) or mark the Rust fields `#[serde(skip)]` for the status wire format (treat them as internal). Default recommendation: add to schema. `failure_reason` is genuinely useful to operators; `retry_count` is operator-visible at the task level already. Hiding them in the status contract is a strictly worse UX.

## Scope

- **Primary seam:** schema enum values and phase-item property list
- **Allowed files:** the two schemas, the two fixtures (re-validate), and `hymenium/src/workflow/engine.rs` (only if choosing the `#[serde(skip)]` path)
- **Explicit non-goals:**
  - Do not introduce new enum values beyond what producer+consumer already emit
  - Do not renumber schema versions — these are backward-compatible relaxations (adding enum values, adding optional fields)
  - Do not change the Rust or TS code beyond the optional `#[serde(skip)]` path
  - Do not touch the workflow-template role enum (separate handoff)

---

### Step 1: Fix `canopy-task-detail-v1` `attention.level` enum

**Project:** `septa/`
**Effort:** 0.25 day
**Depends on:** nothing

In `septa/canopy-task-detail-v1.schema.json`, locate the `attention.level` enum. Replace `"warning"` with `"needs_attention"`. Do NOT remove `"warning"` silently — verify first that no consumer reads it. Grep in `canopy/src`, `cap/src`, `cap/server/src`, and any other reader for `'warning'` or `"warning"` in an attention context.

If no reader uses `"warning"`: drop it, add `"needs_attention"`.
If any reader still accepts `"warning"` (defensive): add `"needs_attention"` alongside and file a follow-up to remove `"warning"` later.

Update `septa/fixtures/canopy-task-detail-v1.example.json` if it uses `attention.level` — prefer an example value that exercises `needs_attention` so the contract is under test.

### Step 2: Fix `canopy-task-detail-v1` `sla_summary.breach_severity` enum

**Project:** `septa/`
**Effort:** 0.25 day
**Depends on:** Step 1 (same file; bundle)

Replace the enum with `["none", "low", "medium", "high", "critical"]`. `"warning"` in the old schema was never emitted; drop it (same defensive grep as Step 1 applies).

Update the fixture to use one of the intermediate values (`low`, `medium`, or `high`) so the additions are exercised by validation.

### Step 2b: Fix the same `breach_severity` drift in `canopy-snapshot-v1`

**Project:** `septa/`
**Effort:** 0.1 day
**Depends on:** Step 2 (same enum, different schema)

In `septa/canopy-snapshot-v1.schema.json` line 33, replace the identical stale enum `["none", "warning", "critical"]` with `["none", "low", "medium", "high", "critical"]`. Update `septa/fixtures/canopy-snapshot-v1.example.json` to exercise one of the added values.

This is the same producer/consumer vocabulary; treat Step 2 and Step 2b as one logical fix executed across two schemas.

### Step 2c: Fix `canopy-snapshot-v1` `agents[].status` enum

**Project:** `septa/`
**Effort:** 0.25 day
**Depends on:** nothing

In `septa/canopy-snapshot-v1.schema.json` line 65, replace the stale enum `["active", "idle", "stopped", "error"]` with the actual `AgentStatus` vocabulary from `canopy/src/models.rs:29-35`: `["idle", "assigned", "in_progress", "blocked", "review_required"]`.

Before changing: grep `cap/src`, `cap/server/src`, and any other reader for string literals `"active"`, `"stopped"`, `"error"` in an agent-status context. If any consumer still accepts the old values defensively, add a follow-up note to remove them later — but do NOT leave the schema endorsing strings the producer cannot emit.

Update `septa/fixtures/canopy-snapshot-v1.example.json` so at least one agent has a non-`idle` status (e.g., `assigned` or `in_progress`) to exercise the added values.

### Step 3: Reconcile `workflow-status-v1` phase fields with `PhaseState`

**Project:** `septa/` primary, `hymenium/` secondary
**Effort:** 0.5 day
**Depends on:** nothing

Decide: add `failure_reason` and `retry_count` to the schema, or skip them in Rust serde.

**Preferred path: add to schema.** In `septa/workflow-status-v1.schema.json`, under phases items, add:

```json
"failure_reason": { "type": ["string", "null"] },
"retry_count": { "type": "integer", "minimum": 0 }
```

Keep `additionalProperties: false`. Update `septa/fixtures/workflow-status-v1.example.json` to include representative values (one phase with `failure_reason: null, retry_count: 0`, another phase with both populated — exercising the schema's full range).

**Alternate path (only if the fields are genuinely internal):** In `hymenium/src/workflow/engine.rs`, add `#[serde(skip_serializing_if = "Option::is_none")]` on `failure_reason` and `#[serde(skip_serializing_if = "u32_is_zero")]` on `retry_count` (or mark both `#[serde(skip)]` entirely). Write a test that serializes a `PhaseState` and asserts the two fields are not present.

Document the decision in the handoff's completion note.

### Step 4: Re-validate

**Project:** `septa/`
**Effort:** 0.1 day
**Depends on:** Steps 1-3

Run the full septa validator and the workspace integration script:

```bash
cd septa && bash validate-all.sh
cd .. && bash scripts/test-integration.sh
```

All schemas must still pass. The integration script will still show 6 pre-existing `$ref`-resolution failures that are out of scope for this handoff (tracked in `cross-project/integration-script-ref-resolution.md`); no regression beyond those.

---

## Verification Contract

```bash
cd septa && bash validate-all.sh
cd .. && bash scripts/test-integration.sh
bash .handoffs/septa/verify-operator-contract-drift.sh
```

## Completion criteria

- [ ] `canopy-task-detail-v1` `attention.level` enum matches producer+consumer
- [ ] `canopy-task-detail-v1` `sla_summary.breach_severity` enum matches producer+consumer
- [ ] `canopy-snapshot-v1` `sla_summary.breach_severity` enum matches producer+consumer
- [ ] `canopy-snapshot-v1` `agents[].status` enum matches `AgentStatus`
- [ ] `PhaseState` serialization and schema agree (decision documented)
- [ ] Fixtures exercise the corrected enum values
- [ ] `validate-all.sh` clean
- [ ] Integration script shows no NEW failures beyond the 6 pre-existing $ref issues
- [ ] HANDOFFS.md updated, handoff archived
