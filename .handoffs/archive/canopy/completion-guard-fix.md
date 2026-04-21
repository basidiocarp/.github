# Canopy: Fix completion guard and auto-complete logic

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** canopy/...
- **Cross-repo edits:** none
- **Non-goals:** MCP error message, schema divergence, TOCTOU (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — Completion guard only checks direct children
`src/store/helpers/status.rs:5-24`

`has_open_child_tasks_in_connection` queries `WHERE tasks.parent_task_id = ?1` — a single-level check. A grandparent can complete while grandchildren are open because only direct children are inspected. Fix with a recursive CTE:

```sql
WITH RECURSIVE descendants(task_id) AS (
    SELECT task_id FROM tasks WHERE parent_task_id = ?1
    UNION ALL
    SELECT t.task_id FROM tasks t
    INNER JOIN descendants d ON t.parent_task_id = d.task_id
)
SELECT 1 FROM descendants
INNER JOIN tasks ON tasks.task_id = descendants.task_id
WHERE tasks.status IN ('open', ...)
LIMIT 1
```

Use the same open-status set that `is_open_task_status` uses elsewhere.

### 2 — Auto-complete dead for verification_required = false
`src/store/helpers/status.rs:113-121`

`maybe_auto_complete_task_in_connection` returns early when `task.verification_required` is false. This is the common case. The auto-complete cascade is therefore never triggered for most tasks: a parent whose children all complete will not cascade to Completed. Remove or invert the early-return guard so auto-complete runs for all tasks, not only those with `verification_required = true`.

### 3 — Cancelled children treated as blockers
`src/store/helpers/status.rs:104-106`

The child-completeness check uses `status != TaskStatus::Completed` to identify incomplete children. This treats `Cancelled` and `Closed` as open/blocking. A parent with children `[Completed, Cancelled]` will never auto-complete. Use the same terminal-status set as `is_open_task_status` (which correctly excludes `Completed`, `Closed`, and `Cancelled`).

## Implementation Seam

- **Likely file:** `src/store/helpers/status.rs`
  - `has_open_child_tasks_in_connection` — recursive CTE
  - `maybe_auto_complete_task_in_connection:113` — remove early return on `!verification_required`
  - `maybe_auto_complete_task_in_connection:104` — fix terminal-status check

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/canopy
cargo test --all 2>&1 | tail -5
cargo clippy 2>&1 | tail -10
```

## Checklist

- [x] `has_open_child_tasks_in_connection` uses recursive CTE to check full subtree
- [x] `maybe_auto_complete_task_in_connection` runs for tasks regardless of `verification_required`
- [x] Cancelled and Closed children do not block parent auto-complete
- [x] All tests pass
