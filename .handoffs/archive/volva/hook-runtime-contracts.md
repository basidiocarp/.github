# Volva: Hook Runtime Contracts

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `volva`
- **Allowed write scope:** `volva/crates/volva-runtime/`, `volva/crates/volva-config/`, `volva/crates/volva-cli/`, `volva/crates/volva-core/`, `volva/docs/hook-adapter-cortina.md`, `volva/tests/`, matching `septa/volva-hook-event-v1.schema.json`, `septa/hook-execution-v1.schema.json`, and fixtures only if the contract is intentionally changed
- **Cross-repo edits:** `septa/` only for deliberate contract changes; no Cortina source changes in this handoff
- **Non-goals:** no backend provider rewrite and no auth-system redesign
- **Verification contract:** run the repo-local commands below and `bash .handoffs/volva/verify-hook-runtime-contracts.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** `volva-runtime/src/hooks.rs`, `volva-config/src/lib.rs`, `volva-cli/src/chat.rs`, `volva-cli/src/session.rs`, `volva-core/src/lib.rs`, `volva-runtime/src/context.rs`
- **Reference seams:** `septa/volva-hook-event-v1.schema.json`, `septa/hook-execution-v1.schema.json`, `septa/workflow-participant-runtime-identity-v1.schema.json`
- **Spawn gate:** do not launch an implementer until the parent agent decides whether `execution_session` belongs in `volva-hook-event-v1` or stays internal

## Problem

Volva emits hook payloads that can include fields outside Septa, accepts hook timeouts beyond fail-open bounds, and has a chat path that bypasses runtime hooks and host-context shaping. The focused validation also found one current failing test in `volva-runtime`.

## What needs doing

1. Introduce a `VolvaHookEventV1` DTO that exactly matches Septa, or update Septa intentionally and update consumers together.
2. Validate or clamp hook adapter `timeout_ms` to `1..=30000` at config load or runtime setup.
3. Update hook adapter docs that suggest higher timeouts.
4. Route `volva chat` through the runtime path or explicitly document and test why it does not emit hooks/context.
5. Add a schema-shaped runtime identity DTO for workflow-linked runs.
6. Resolve the failing `volva-runtime` context test.
7. Align dependency pins or record pending/rationale entries for `rusqlite` and `thiserror`.

## Verification

```bash
cd volva && cargo test -p volva-runtime -p volva-config -p volva-cli
cd septa && check-jsonschema --schemafile volva-hook-event-v1.schema.json fixtures/volva-hook-event-v1.example.json
cd septa && check-jsonschema --schemafile hook-execution-v1.schema.json fixtures/hook-execution-v1.example.json
bash .handoffs/volva/verify-hook-runtime-contracts.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] hook payload DTO matches Septa or Septa is intentionally updated
- [ ] hook timeout bounds enforce `1..=30000`
- [ ] hook docs no longer recommend out-of-contract timeouts
- [ ] chat path shares runtime hook/context behavior or is explicitly tested as separate
- [ ] runtime identity has a schema-shaped DTO for workflow-linked runs
- [ ] `volva-runtime` context test passes
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 Rust ecosystem audit. Severity: high/medium/low plus one current test failure.
