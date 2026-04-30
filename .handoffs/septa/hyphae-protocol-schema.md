# Septa: Hyphae Protocol Schema (hyphae-protocol-v1)

## Handoff Metadata

- **Dispatch:** direct
- **Owning repo:** `septa` (new schema file); `hyphae` and `volva` (add schema_version validation)
- **Allowed write scope:** `septa/hyphae-protocol-v1.schema.json`, `septa/fixtures/hyphae-protocol-v1.example.json`, `septa/validate-all.sh`, and optionally `hyphae/crates/hyphae-mcp/src/memory_protocol.rs` (add schema_version constant to output) and `volva/crates/volva-runtime/src/context.rs` (validate schema_version on deserialization)
- **Cross-repo edits:** septa, hyphae, volva
- **Non-goals:** does not change the memory protocol behavior; does not change hyphae MCP tools; does not change volva runtime logic
- **Verification contract:** `cd septa && bash validate-all.sh` must pass; `cd hyphae && cargo build && cargo test`; `cd volva && cargo check && cargo test`
- **Completion update:** Stage 1 + Stage 2 review pass → commit per repo → mark handoff done

## Problem

The `MemoryProtocolSurface` struct in `hyphae/crates/hyphae-mcp/src/memory_protocol.rs` is a cross-tool contract: hyphae emits it as JSON, and volva consumes it at `volva/crates/volva-runtime/src/context.rs:123-151`. This is a system-to-system boundary with no septa schema backing it.

**Risk:** If hyphae renames a field or adds a required field, volva's deserialization silently fails (returns `None` → context injection skipped). There is no `validate-all.sh` check to catch the drift. This risk increases if the tools are ever versioned independently.

Ecosystem Health Audit finding #11 (Phase 5 Pass 2): "CONFIRMED unseamed. Low urgency but real gap."

## Current shape (hyphae emits, volva consumes)

From `hyphae/crates/hyphae-mcp/src/memory_protocol.rs`:

```json
{
  "schema_version": "1.0",
  "artifact_type": "memory_protocol",
  "scoped_identity": { ... },
  "project": "canopy",
  "summary": "...",
  "recall": {
    "when": ["...", "..."],
    "tools": ["hyphae_gather_context", "hyphae_memory_recall"],
    "passive_resource_uri": "hyphae://context/current"
  },
  "store": {
    "when": ["...", "..."],
    "tool": "hyphae_memory_store",
    "project_topics": ["context/canopy", "decisions/canopy"],
    "shared_topics": ["errors/resolved", "preferences"]
  },
  "resources": [
    { "uri": "hyphae://protocol/current", "purpose": "..." },
    { "uri": "hyphae://context/current", "purpose": "..." },
    { "uri": "hyphae://artifacts/project-understanding/current", "purpose": "..." }
  ]
}
```

The `scoped_identity` shape comes from `hyphae_core::ScopedIdentity`. Read `hyphae/crates/hyphae-core/src/lib.rs` or wherever `ScopedIdentity` is defined to get its fields before writing the schema.

## Step 1 — Write the schema

Create `septa/hyphae-protocol-v1.schema.json` following the septa schema conventions (JSON Schema Draft 2020-12, `"$schema": "https://json-schema.org/draft/2020-12/schema"`, `additionalProperties: false` at all levels, required arrays listing every mandatory field).

Key fields:
- `schema_version`: const `"1.0"`
- `artifact_type`: const `"memory_protocol"`
- `scoped_identity`: object with fields from `ScopedIdentity`
- `project`: optional string
- `summary`: string
- `recall`: object with `when` (string array), `tools` (string array), `passive_resource_uri` (string)
- `store`: object with `when` (string array), `tool` (string), `project_topics` (string array), `shared_topics` (string array)
- `resources`: array of `{ uri: string, purpose: string }`

## Step 2 — Write the fixture

Create `septa/fixtures/hyphae-protocol-v1.example.json` using a realistic project value (e.g., `"canopy"`) and the actual URIs and tool names from the production code. The fixture must pass schema validation.

## Step 3 — Register in validate-all.sh

Add `hyphae-protocol-v1` to `septa/validate-all.sh` following the existing pattern (check how other schemas are registered — typically one line per schema).

Verify: `cd septa && bash validate-all.sh` — count should increase by 1 and all pass.

## Step 4 (optional but recommended) — Add schema_version check in volva

In `volva/crates/volva-runtime/src/context.rs`, after deserializing the protocol surface from hyphae stdout, add a schema_version check:

```rust
const HYPHAE_PROTOCOL_SCHEMA_VERSION: &str = "1.0";

// After deserialization:
if surface.schema_version != HYPHAE_PROTOCOL_SCHEMA_VERSION {
    tracing::warn!(
        got = surface.schema_version,
        expected = HYPHAE_PROTOCOL_SCHEMA_VERSION,
        "volva: hyphae protocol schema version mismatch — context injection skipped"
    );
    return None;
}
```

This turns a silent drift failure into an observable warning. Only add if the struct already has `schema_version: String` on the volva-side mirror struct; if it does not, add it.

## Verification

```bash
cd septa && bash validate-all.sh
cd hyphae && cargo build && cargo test
cd volva && cargo check && cargo test
```

## Context

Ecosystem Health Audit issue #11. Phase 5 Pass 2 confirmed: no septa schemas for `MemoryProtocolSurface` or session-context recall response. Both tools evolve in the same monorepo today, but the risk grows if they are versioned independently or if a third consumer is added.
