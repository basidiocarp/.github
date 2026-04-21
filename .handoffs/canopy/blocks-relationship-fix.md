# Canopy: Fix tool_task_decompose missing Blocks relationship write

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** canopy/...
- **Cross-repo edits:** none
- **Non-goals:** other canopy fixes
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problem

`src/tools/task.rs:128-138`

`tool_task_decompose` populates `blocked_by` in the returned JSON and pushes `SubtaskCreated` events, but never calls `store.add_task_relationship(...)` to persist the `Blocks` relationship. Callers receive a response claiming task A blocks task B while no relationship record exists in the database. Scheduling enforcement is silently absent.

Fix: after creating each subtask, call `store.add_task_relationship(parent_id, subtask_id, RelationshipKind::Blocks)` (or the equivalent) for each `blocked_by` entry declared in the decompose input.

## Implementation Seam

- `src/tools/task.rs:128` — add `store.add_task_relationship` calls after subtask creation
- Confirm `RelationshipKind::Blocks` (or equivalent variant name) exists in the store API

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/canopy
cargo test --all 2>&1 | tail -5
```

## Checklist

- [ ] `Blocks` relationship written to database for each `blocked_by` entry
- [ ] Response JSON and database are consistent
- [ ] All tests pass
