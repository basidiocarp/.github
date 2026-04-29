# Hymenium: Terminal Workflow Idempotency

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/src/commands/complete.rs`, `hymenium/src/workflow/engine.rs`, `hymenium/src/store.rs`, `hymenium/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no Canopy CLI adapter work and no workflow template redesign
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-terminal-workflow-idempotency.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** complete command, workflow engine terminal state checks, workflow transition/outcome persistence
- **Reference seams:** existing workflow complete/cancel/fail tests, outcome insert behavior
- **Spawn gate:** do not launch an implementer until the parent agent decides whether already-completed workflows are idempotent success or explicit no-op rejection

## Spawn Gate Decision

- **Behavior for all terminal states:** informative no-op — exit 0, output a message with the existing outcome, its timestamp, and the workflow ID. Never overwrite a terminal outcome.
- **Completed → complete again:** `"Workflow <id> already completed at <timestamp>. No change."`
- **Cancelled → complete:** `"Workflow <id> was cancelled at <timestamp>. Outcome preserved."`
- **Failed → complete:** `"Workflow <id> failed at <timestamp>. Outcome preserved."`
- **Rationale:** consistent behavior across all terminal states; scripts can safely retry `complete` without error handling for the already-done case; original outcome is always preserved in the record.
- **No duplicate transitions:** the guard must fire before any state write — do not record a transition event and then return the informative message.

## Problem

`hymenium complete` can operate on already terminal workflows and record another transition/outcome. A cancelled workflow with a completed final phase can be converted to `completed`, corrupting terminal outcome history; retries can also duplicate transitions.

## What needs doing

1. Add an `AlreadyTerminal` guard before completing a workflow.
2. Preserve cancelled/failed outcomes on later complete attempts.
3. Make already-completed retry behavior idempotent or reject without duplicate transitions.
4. Add tests for cancelled, failed, and completed retry cases.

## Verification

```bash
cd hymenium && cargo test complete
cd hymenium && cargo test record_transition insert_outcome
bash .handoffs/hymenium/verify-terminal-workflow-idempotency.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] completing cancelled workflow preserves cancelled outcome
- [ ] completing failed workflow preserves failed outcome
- [ ] retrying complete does not duplicate terminal transitions
- [ ] outcome replacement is intentional and tested
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 4 data integrity audit. Severity: high.
