# Cortina: Volva Event Replay Identity

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/src/adapters/volva.rs`, `cortina/src/events/adapter_events.rs`, `cortina/src/events/normalized_lifecycle.rs`, `cortina/tests/`, and matching Volva/Cortina event fixtures if present
- **Cross-repo edits:** `volva/crates/volva-runtime/src/hooks.rs` tests/DTO identity only if Cortina cannot preserve identity from current payloads
- **Non-goals:** no hook execution policy redesign and no Volva backend rewrite
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cortina/verify-volva-event-replay-identity.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** Volva adapter event model, normalized lifecycle mapping, duplicate delivery handling
- **Reference seams:** Volva hook payload `execution_session`, Cortina normalized lifecycle events, existing Volva adapter tests
- **Spawn gate:** do not launch an implementer until the parent agent chooses the replay identity tuple: event id/sequence if available, otherwise `(session_id, phase, timestamp/payload hash)`

## Problem

Volva hook events carry execution-session identity, but Cortina's consumer model drops it and normalized lifecycle events leave `session_id` unset. Retries or overlapping Volva runs in the same cwd can therefore create duplicate or ambiguous lifecycle events that cannot be replayed or deduped by session.

## What needs doing

1. Preserve Volva execution-session identity through Cortina adapter parsing and normalized lifecycle events.
2. Add stable event identity or sequence handling for replay/dedupe.
3. Add duplicate-delivery tests for repeated Volva adapter events.
4. Coordinate with Volva only if current hook payloads lack enough stable identity.

## Verification

```bash
cd cortina && cargo test volva
cd volva && cargo test -p volva-runtime hooks
bash .handoffs/cortina/verify-volva-event-replay-identity.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Volva `execution_session.session_id` survives into Cortina normalized lifecycle events
- [ ] duplicate Volva event delivery does not create ambiguous replay state
- [ ] two Volva runs in the same cwd remain distinguishable
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 4 data integrity audit. Severity: high.
