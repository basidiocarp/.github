# Canopy: Task Event And State Idempotency

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/src/store/tasks.rs`, `canopy/src/store/helpers/`, `canopy/src/store/operator_actions.rs`, `canopy/src/tools/evidence.rs`, `canopy/src/tools/task.rs`, `canopy/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no Cap UI changes and no Septa read-model schema redesign
- **Verification contract:** run the repo-local commands below and `bash .handoffs/canopy/verify-task-event-and-state-idempotency.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** task status store, task event ledger, evidence tools, triage queue sync, duplicate scope checks
- **Reference seams:** task lifecycle tests, operator action evidence event path, archived duplicate-prevention and workflow-ledger-alignment work
- **Spawn gate:** do not launch an implementer until the parent agent decides the invariant for scoped work: one queued task only or one non-terminal scoped task

## Spawn Gate Decision

- **Duplicate invariant:** block if any task for the same scope is in a non-terminal state (`open`, `assigned`, `in_progress`, `blocked`, `review_required`). `review_required` counts as in-flight.
- **Terminal reference:** if an existing task is `completed`, `closed`, or `cancelled`, allow the new task but include the terminal task ID in the creation response as `prior_task_id` so callers can trace lineage.
- **Rejection message:** include the blocking task's ID, status, and assigned agent so the caller knows who owns it.
- **No scope-similarity check:** duplicate prevention applies to identical scope strings only, not semantically similar ones.

## Problem

Canopy's persisted task/event state can diverge from intended history. Repeated terminal/status updates append duplicate transition events and can shift metadata; evidence tools add evidence without appending task events; scoped duplicate prevention applies only to `open` tasks; priority triage can leave derived queue state stale.

## What needs doing

1. Make repeated same-status terminal updates no-op or explicitly metadata-only without duplicate replay events.
2. Ensure MCP evidence attach/add paths append exactly one `EvidenceAttached` task event.
3. Extend scoped duplicate prevention or transactional checks to the intended active status set.
4. Resync or derive queue state after priority/severity triage changes.
5. Add idempotency and replay tests for retry scenarios.

## Verification

```bash
cd canopy && cargo test task notification
cd canopy && cargo test evidence task_events store_roundtrip
cd canopy && cargo test duplicate
cd canopy && cargo test workflow_ledger_alignment
bash .handoffs/canopy/verify-task-event-and-state-idempotency.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] retrying completion/block/cancel does not duplicate replay events
- [ ] evidence tools append exactly one task event per successful evidence attachment
- [ ] scoped duplicate invariant covers the chosen non-terminal status set
- [ ] triage updates do not leave stale queue position/read-model state
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 4 data integrity audit. Severity: high/medium.
