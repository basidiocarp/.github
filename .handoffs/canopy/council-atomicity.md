# Canopy: Fix council session non-atomic operations

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** canopy/...
- **Cross-repo edits:** none
- **Non-goals:** other canopy fixes
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — close_council_session is not transactional
`src/store/council.rs:314-358`

Performs read (state check) → write (UPDATE) → read (fetch task_id) as three separate non-atomic operations on `self.conn`. A concurrent close can bypass the state guard or produce a torn final read. All other multi-step writes in this file use `in_transaction`.

Fix: wrap the entire sequence in `in_transaction` (or `self.conn.in_transaction(|conn| { ... })`).

### 2 — join_council_session has a read-modify-write race
`src/store/council.rs:368-410`

Reads `participants_json`, deserialises in Rust, appends the new participant, writes back — with no transaction wrapping. Two concurrent `join_council_session` calls for different agents on the same session will race; one agent's join will be silently lost.

Fix: wrap in `in_transaction` so the read and write are atomic. The idempotency check inside should remain but must operate on the locked row.

## Implementation Seam

- `src/store/council.rs:314` — add `in_transaction` wrapper to `close_council_session`
- `src/store/council.rs:368` — add `in_transaction` wrapper to `join_council_session`

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/canopy
cargo test --all 2>&1 | tail -5
cargo clippy 2>&1 | tail -10
```

## Checklist

- [ ] `close_council_session` state check, UPDATE, and task_id fetch are inside one transaction
- [ ] `join_council_session` read-modify-write is inside one transaction
- [ ] All tests pass, clippy clean
