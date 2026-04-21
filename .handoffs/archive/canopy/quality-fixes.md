# Canopy: Quality fixes (MCP error, schema, TOCTOU, tests)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** canopy/...
- **Cross-repo edits:** none
- **Non-goals:** completion guard recursion fix (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — MCP error path doesn't name blocking children
`src/store/tasks.rs:292-297`

`update_task_status` returns a generic `"tasks cannot complete while child tasks remain open"` error. CLI callers enumerate blocking children by name and status, but MCP callers receive the opaque message. Include child task IDs and titles in the error returned from `update_task_status` so all callers benefit.

### 2 — ON DELETE SET NULL can diverge from task_relationships
`src/store/schema.rs:27`

`tasks.parent_task_id` has `ON DELETE SET NULL`. When a parent is deleted, the child's `parent_task_id` becomes NULL, but the `task_relationships` row (`kind = 'parent'`) is independently cascade-deleted. Both changes happen but the order and atomicity aren't guaranteed to keep the two sources of truth consistent. Audit the delete path and either remove the `task_relationships` redundancy or add a trigger/transaction to keep them in sync.

### 3 — TOCTOU in create_subtask_with_options
`src/store/tasks.rs:159-177`

`ensure_task_exists` is called outside the transaction, then the parent is re-fetched inside it. A concurrent deletion between the check and the transaction open produces a confusing `NotFound` error path. Move the parent existence check inside the transaction.

### 4 — Zero tests for parent/child feature
No tests exist for: completion guard, auto-complete propagation, cycle detection, orphan handling, or tree traversal. Add integration tests in `tests/` covering at minimum:
- completing a parent with open children is rejected
- completing a parent with all children completed succeeds and auto-completes
- completing a parent with a cancelled child succeeds
- deleting a parent orphans children cleanly

## Implementation Seam

- `src/store/tasks.rs:292` — richer error message
- `src/store/schema.rs` — delete path audit
- `src/store/tasks.rs:159` — move existence check into transaction
- `tests/` — new integration test file for task tree behavior

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/canopy
cargo test --all 2>&1 | tail -5
```

## Checklist

- [ ] MCP error names blocking children
- [ ] Parent delete path keeps `tasks.parent_task_id` and `task_relationships` consistent
- [ ] `create_subtask_with_options` parent check is inside the transaction
- [ ] Integration tests for tree behavior added to `tests/`
- [ ] All tests pass
