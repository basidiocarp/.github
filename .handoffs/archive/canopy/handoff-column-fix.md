# Canopy: Fix list_handoffs_for_task column mismatch (runtime panic)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** canopy/...
- **Cross-repo edits:** none
- **Non-goals:** other canopy fixes
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problem

`src/store/helpers/status.rs:216-232`

`list_handoffs_for_task_in_connection` selects 13 columns but `map_handoff` expects 16. When `goal`, `next_steps`, and `stop_reason` were added to the schema, this SELECT was not updated. Every call to `has_unresolved_review_handoffs_in_connection` panics with a column index out-of-range error.

Fix: add the three missing columns (`goal`, `next_steps`, `stop_reason`) to the SELECT in `list_handoffs_for_task_in_connection` at the positions `map_handoff` expects them (indices 7, 8, 9).

Check `map_handoff` to confirm the exact expected column order and add any other callers of `list_handoffs_for_task_in_connection` that may be affected.

## Implementation Seam

- `src/store/helpers/status.rs:216` — update SELECT column list
- Verify `map_handoff` expected column order

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/canopy
cargo test --all 2>&1 | tail -5
# Specifically exercise has_unresolved_review_handoffs_in_connection if a test exists
```

## Checklist

- [ ] SELECT includes `goal`, `next_steps`, `stop_reason` in the correct positions
- [ ] `map_handoff` column indices match the SELECT
- [ ] All other callers of `list_handoffs_for_task_in_connection` verified
- [ ] All tests pass
