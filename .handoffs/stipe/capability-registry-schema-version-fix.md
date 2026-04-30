# Stipe: Capability-Registry Schema-Version Fix (F2.19)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/src/commands/tool_registry/capability_registry.rs` and any tests that build `CapabilityRegistry` instances
- **Cross-repo edits:** none — septa schema is correct
- **Non-goals:** does not modify the schema; does not change the registry consumer in `spore/src/capability.rs`
- **Verification contract:** `bash .handoffs/stipe/verify-capability-registry-schema-version-fix.sh`
- **Completion update:** Stage 1 + Stage 2 review pass → commit → dashboard

## Problem (F2.19, blocker)

`stipe/src/commands/tool_registry/capability_registry.rs:64` emits `"schema_version": "capability-registry-v1"` instead of the schema-required const `"1.0"`.

`septa/capability-registry-v1.schema.json` declares `schema_version` as `const: "1.0"`. Every registry file written today is invalid against septa.

## Step 1 — Apply fix

Change the literal at line 64 (or wherever `schema_version` is assigned) from `"capability-registry-v1"` to `"1.0"`.

If a constant is defined elsewhere (e.g. `CAPABILITY_REGISTRY_SCHEMA_VERSION`), update that single source of truth.

## Step 2 — Tests

Add or update a test that:
- Constructs a `CapabilityRegistry`, serializes to JSON, asserts `.schema_version == "1.0"`.
- (If feasible) validates the serialized output against `septa/capability-registry-v1.schema.json`.

## Step 3 — Build + test

```bash
cd /Users/williamnewton/projects/personal/basidiocarp/stipe && cargo test --release
```

## Verify Script

`bash .handoffs/stipe/verify-capability-registry-schema-version-fix.sh` confirms:
- The literal `"capability-registry-v1"` no longer appears as a `schema_version` value
- `"1.0"` is set as the schema_version
- Tests pass

## Context

Closes lane 2 blocker F2.19 from the 2026-04-30 audit.
