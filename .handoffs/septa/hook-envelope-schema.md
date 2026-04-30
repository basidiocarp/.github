# Septa: Hook Envelope Schema (hook-execution-v1)

## Handoff Metadata

- **Dispatch:** direct
- **Owning repo:** `septa` (new schema); `cortina` (validate against schema in adapter)
- **Allowed write scope:** `septa/hook-execution-v1.schema.json`, `septa/fixtures/hook-execution-v1.example.json`, `septa/validate-all.sh`, `cortina/src/adapters/` (add schema version check)
- **Non-goals:** does not change cortina's hook parsing behavior; does not change lamella hooks.json; does not modify Claude Code hook format
- **Priority:** Low — practical risk only when Claude Code changes its hook envelope format
- **Verification contract:** `cd septa && bash validate-all.sh`; `cd cortina && cargo build && cargo test`
- **Completion update:** Stage 1 + Stage 2 review pass → commit → mark handoff done

## Problem

Claude Code sends a JSON envelope to cortina when hooks fire. Cortina parses this envelope in `cortina/src/adapters/` but there is no septa schema documenting the expected shape. If Claude Code changes its hook envelope format, cortina silently breaks with no contract-level detection.

This is the "lamella hook envelope not schema-backed" finding (#13) from the Ecosystem Health Audit, Phase 5 Pass 2. Downgraded from Medium to Low because:
- Claude Code's format is stable and changes are announced
- Cortina's adapter already logs parse failures and exits cleanly
- The risk window is narrow: a schema break would surface immediately in testing

## Step 1 — Identify the envelope shape

Read `cortina/src/adapters/` to find the struct(s) that parse the incoming hook JSON. The relevant adapter is likely `cortina/src/adapters/claude_code.rs` or similar. Identify all fields and their types.

Look for:
- `hook_event_name` or `event_type` — which hook fired
- `tool_name` / `tool_input` / `tool_response` — for post-tool-use events
- `session_id` / `transcript_path` — session identity
- Any timestamp fields

Confirm the actual field names by reading the adapter struct definitions, not by guessing. The source of truth is the Rust struct(s) that `serde_json::from_str` deserializes the stdin payload into.

## Step 2 — Write the schema

Create `septa/hook-execution-v1.schema.json`. Use `oneOf` or a discriminated union pattern if the shape varies by hook type, or document the common superset with all fields optional where they only appear for certain hook types.

Follow the septa conventions: JSON Schema Draft 2020-12, `additionalProperties: false`, const `schema_version`.

**Note:** The hook envelope is written by Claude Code, not by the ecosystem. Cortina does not add `schema_version` to the incoming envelope (it's the consumer, not the producer). The schema documents what cortina expects to receive, not what it emits. Do not add a `schema_version` constant validation to the adapter unless the Claude Code envelope already sends one.

## Step 3 — Write the fixture

Create `septa/fixtures/hook-execution-v1.example.json` representing a realistic `post-tool-use` event (the most common case). Use realistic but non-sensitive values.

## Step 4 — Register in validate-all.sh

Add `hook-execution-v1` to `septa/validate-all.sh`.

## Verification

```bash
cd septa && bash validate-all.sh
cd cortina && cargo build && cargo test
```

## Context

Ecosystem Health Audit issue #13 (Low priority). The practical risk is bounded: Claude Code announces breaking changes to hook formats, and cortina's adapter already handles parse failures gracefully. This handoff captures the contract for documentation purposes and gives a future early-warning signal if Claude Code's format changes.

**Start by reading the adapter source before writing any schema.** The shape must match what cortina actually parses, not what you'd expect the shape to be.
