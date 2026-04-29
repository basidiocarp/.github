# Canopy: Assigned Work Operator Surface

<!-- Save as: .handoffs/canopy/assigned-work-operator-surface.md -->
<!-- Create verify script: .handoffs/canopy/verify-assigned-work-operator-surface.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/src/tools/queue.rs`, `canopy/src/tools/task.rs`, `canopy/src/api/`, `canopy/src/app.rs`, `canopy/src/cli.rs`, `canopy/tests/`
- **Cross-repo edits:** docs only if CLI help changes require it
- **Non-goals:** no Hymenium phase reconciliation and no Cap UI work
- **Verification contract:** run the repo-local commands below and `bash .handoffs/canopy/verify-assigned-work-operator-surface.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** work queue tool, task list/show surfaces, assigned-task filters, CLI/API operator views
- **Reference seams:** `tool_work_queue`, `tool_task_list`, `list_tasks_assigned_to_agent`, operator attention views
- **Spawn gate:** do not launch an implementer until the parent agent decides whether to add a new surface or extend existing `work-queue` output

## Problem

During dogfood, `canopy work-queue --agent-id ...` returned `[]` after the task was assigned. That is defensible if the command means "claimable work", but it is confusing for a worker trying to find their current assigned task.

The operator surface should make assigned-but-not-claimable work visible without requiring manual task id tracking.

## What exists (state)

- **Work queue:** returns available work, not necessarily the current assigned task
- **Task show:** works when the operator already knows the task id
- **Store:** has assigned-task queries that can be reused

## What needs doing (intent)

Add or clarify a worker-facing command/tool/API path that answers: "what am I assigned to right now, and what command verifies or completes it?"

## Scope

- **Primary seam:** Canopy task discovery surfaces for assigned work
- **Allowed files:** queue tools, task tools, CLI/app command handling, API view helpers, tests
- **Explicit non-goals:** no scheduler changes, no Hymenium status changes, no dashboard UI

## Verification

```bash
cd canopy && cargo test work_queue assigned task_list
cd canopy && cargo test cli_task
bash .handoffs/canopy/verify-assigned-work-operator-surface.sh
```

**Output:**
<!-- PASTE START -->
PASS: work_queue tests pass
PASS: assigned task not visible in default work-queue
PASS: include-assigned flag exists in CLI
PASS: list_tasks_for_agent used in work_queue path
Results: 4 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] worker can list their assigned tasks without knowing task ids
- [x] claimable work and assigned work are named distinctly or documented clearly
- [x] output includes enough task identity to run verify/complete commands
- [x] tests cover assigned work not appearing as claimable work
- [x] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 CentralCommand dogfood run. This hardens the human/operator loop around Canopy assignments.

