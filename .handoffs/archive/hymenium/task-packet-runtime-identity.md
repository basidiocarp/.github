# Hymenium: Task Packet Runtime Identity

<!-- Save as: .handoffs/hymenium/task-packet-runtime-identity.md -->
<!-- Create verify script: .handoffs/hymenium/verify-task-packet-runtime-identity.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/src/dispatch/`, `hymenium/src/workflow/`, `hymenium/src/commands/status.rs`, `hymenium/tests/`
- **Cross-repo edits:** none; Canopy storage changes only if a missing CLI flag or field is proven
- **Non-goals:** no worker process launcher and no capability registry integration
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-task-packet-runtime-identity.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** dispatch context, task packet builder, Canopy task creation args, workflow instance persistence, status rendering
- **Reference seams:** `hymenium/src/dispatch/orchestrate.rs`, `hymenium/src/dispatch/task_packet.rs`, Canopy `task create --workflow-id --phase-id`
- **Spawn gate:** do not launch an implementer until the parent agent confirms the exact runtime identity fields to persist and display

## Problem

During dogfood, the operator had to manually track the Canopy DB path, agent id, task id, workflow id, and handoff path. Canopy task rows showed `workflow_id: null` and `phase_id: null`, while Hymenium status showed the handoff path as `ccoCentralCommand` instead of the actual file path.

Without durable runtime identity, workers can act on the wrong DB or task and Hymenium cannot reliably reconcile Canopy state.

## What exists (state)

- **Task packet:** includes useful JSON fields, but some are not passed into Canopy task row fields
- **Status:** shows workflow phase records but not enough execution context to resume safely
- **Canopy CLI:** supports workflow and phase ids on task creation

## What needs doing (intent)

Persist and surface the runtime identity needed to resume a workflow without reconstructing state from shell history.

## Scope

- **Primary seam:** Hymenium dispatch context and workflow status model
- **Allowed files:** dispatch context, task packet builder, workflow instance store, status output, tests
- **Explicit non-goals:** no automatic worker launch, no Canopy schema migration unless the current CLI cannot store required fields, no UI/dashboard work

## Verification

```bash
cd hymenium && cargo test runtime_identity
cd hymenium && cargo test dispatch status
bash .handoffs/hymenium/verify-task-packet-runtime-identity.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Canopy task creation receives `workflow_id` and `phase_id`
- [ ] Hymenium status shows the actual handoff path, not only the owning repo name
- [ ] status or task packet surfaces the Canopy task id and assigned agent id per phase
- [ ] project root is absolute or clearly resolvable from the workflow record
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 CentralCommand dogfood run. This is a prerequisite for reliable phase reconciliation.

