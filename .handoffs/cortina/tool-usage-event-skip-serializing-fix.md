# Cortina: tool-usage-event Skip-Serializing Fix (F2.17)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/src/hooks/stop/tool_usage_emit.rs` (and any helper module that defines the serializable struct)
- **Cross-repo edits:** none — schema is correct
- **Non-goals:** does not modify the schema; does not change the consumer in hyphae
- **Verification contract:** `bash .handoffs/cortina/verify-tool-usage-event-skip-serializing-fix.sh`
- **Completion update:** Stage 1 + Stage 2 review pass → commit → dashboard

## Problem (F2.17, blocker)

The producer at `cortina/src/hooks/stop/tool_usage_emit.rs` uses `#[serde(skip_serializing_if = "Vec::is_empty")]` on `tools_available` and `tools_relevant_unused` — both of which are **required** by `septa/tool-usage-event-v1.schema.json`. Today both vectors are always empty, so both fields are always omitted from emitted JSON, producing an invalid payload on every emission.

## Step 1 — Remove the `skip_serializing_if` attributes

In the struct definition that builds `tool-usage-event-v1` payloads, remove `#[serde(skip_serializing_if = "Vec::is_empty")]` from `tools_available` and `tools_relevant_unused`. Empty arrays serialize as `[]`, which the schema accepts.

If those fields should never have been required by the schema (i.e. they're aspirational), surface that as a separate finding rather than fixing it here — but the default move is to let the producer emit empty arrays, matching the schema's "required, but possibly empty" intent.

## Step 2 — Tests

Add or update a test that:
- Builds a `ToolUsageEvent` with empty vecs.
- Serializes to JSON.
- Asserts `tools_available` is present in the output as `[]`, same for `tools_relevant_unused`.

## Step 3 — Build + test

```bash
cd /Users/williamnewton/projects/personal/basidiocarp/cortina && cargo test --release
cd /Users/williamnewton/projects/personal/basidiocarp/cortina && cargo clippy
```

## Verify Script

`bash .handoffs/cortina/verify-tool-usage-event-skip-serializing-fix.sh` confirms:
- The skip_serializing_if attributes are gone from `tools_available`/`tools_relevant_unused`
- Tests pass

## Context

Closes lane 2 blocker F2.17 from the 2026-04-30 audit.
