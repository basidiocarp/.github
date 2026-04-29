# Cortina: Session And Usage Event Contracts

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/src/utils/session_scope.rs`, `cortina/src/hooks/stop/tool_usage_emit.rs`, `cortina/tests/`, `cortina/README.md`, and matching Septa session/usage schemas and fixtures
- **Cross-repo edits:** `septa/session-event-v1.schema.json`, `septa/usage-event-v1.schema.json`, and fixtures only when the canonical payload changes
- **Non-goals:** no capture policy redesign and no new hook runtime
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cortina/verify-session-usage-event-contracts.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** `src/utils/session_scope.rs`, `src/hooks/stop/tool_usage_emit.rs`, session lifecycle tests, README contract notes
- **Reference seams:** `septa/session-event-v1.schema.json`, `septa/usage-event-v1.schema.json`, `septa/cortina-lifecycle-event-v1.schema.json`
- **Spawn gate:** do not launch an implementer until the parent agent chooses whether `SessionState` is an internal persistence model or the actual `session-event-v1` wire DTO

## Problem

Cortina's real session and usage payloads do not round-trip through Septa. `session-event-v1` requires `schema_version`, `type`, `session_id`, and `project`, but Cortina persists `SessionState` without `schema_version`/`type` and with extra internal fields. `usage-event-v1` describes a normalized usage DTO, while Cortina's Stop hook emits `tool-usage-event` with a different shape.

## What needs doing

1. Separate internal session persistence from the public `session-event-v1` DTO, or update Septa if the internal state is the intended contract.
2. Add `schema_version` and type enforcement at the real producer/consumer boundary.
3. Align Stop hook usage emission with `usage-event-v1`, or rename/register the actual emitted payload as a different contract.
4. Update README contract references after the code and schema decision is made.
5. Add fixture-backed tests for both session and usage event producers.

## Scope

- **Primary seam:** Cortina session/usage event wire contracts
- **Allowed files:** Cortina session scope, Stop hook usage emission, Cortina tests/docs, matching Septa schemas and fixtures
- **Explicit non-goals:** no Lamella packaging changes and no Volva hook execution changes

## Verification

```bash
cd cortina && cargo test session_scope
cd cortina && cargo test tool_usage
cd septa && check-jsonschema --schemafile session-event-v1.schema.json fixtures/session-event-v1.example.json
cd septa && check-jsonschema --schemafile usage-event-v1.schema.json fixtures/usage-event-v1.example.json
bash .handoffs/cortina/verify-session-usage-event-contracts.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] session events have an explicit schema-shaped DTO or Septa is corrected
- [ ] session event code rejects missing or wrong `schema_version`
- [ ] usage events have one canonical contract name and shape
- [ ] README references match the implemented contract
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the Phase 1 contract round-trip audit in the sequential audit hardening campaign. Severity: high/medium.
