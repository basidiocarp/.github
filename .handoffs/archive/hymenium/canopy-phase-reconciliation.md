# Hymenium: Canopy Phase Reconciliation

<!-- Save as: .handoffs/hymenium/canopy-phase-reconciliation.md -->
<!-- Create verify script: .handoffs/hymenium/verify-canopy-phase-reconciliation.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/src/workflow/`, `hymenium/src/dispatch/`, `hymenium/src/commands/status.rs`, `hymenium/tests/`
- **Cross-repo edits:** none unless Canopy lacks a stable read surface for task status
- **Non-goals:** no Cap dashboard integration and no new scheduler backend
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-canopy-phase-reconciliation.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** workflow phase state, Canopy task status client, dispatch/status commands, phase advancement logic
- **Reference seams:** workflow engine phase gating tests, Canopy `task show`, existing status command
- **Spawn gate:** do not launch an implementer until task identity persistence from `task-packet-runtime-identity.md` is available or mocked in tests

## Problem

After the CentralCommand implement task was verified and completed in Canopy, `hymenium status` still reported the workflow as `dispatched`, current phase `implement`, and both phases pending. This breaks the core value of orchestration: the coordinator cannot see that the implement phase is done or advance to the auditor phase.

## What exists (state)

- **Canopy:** task verification and completion work for the task id
- **Hymenium:** workflow status stores planned phases and Canopy task ids but does not reconcile external task completion
- **Operator flow:** manual `task verify` and `task complete` can close the task, but manual commands do not update Hymenium

## What needs doing (intent)

Add a reconciliation path that reads Canopy task state for phase task ids, updates Hymenium phase status and timestamps, and advances the workflow to the next eligible phase when gates are satisfied.

## Scope

- **Primary seam:** Hymenium workflow phase state reconciliation
- **Allowed files:** workflow state store, dispatch/status commands, Canopy CLI adapter, tests
- **Explicit non-goals:** no automatic agent spawning, no review policy redesign, no CentralCommand audit logic

## Verification

```bash
cd hymenium && cargo test phase_reconciliation
cd hymenium && cargo test workflow status dispatch
bash .handoffs/hymenium/verify-canopy-phase-reconciliation.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] completed Canopy implement task marks the matching Hymenium phase completed
- [ ] failed or unverified Canopy task does not advance the phase
- [ ] audit phase becomes current only after implement completion and gates pass
- [ ] reconciliation is idempotent across repeated status/reconcile calls
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 CentralCommand dogfood run. This is the main hardening item before the next dogfood run.

