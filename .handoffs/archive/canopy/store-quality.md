# Canopy: Store quality fixes (round 2)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** canopy/...
- **Cross-repo edits:** none
- **Non-goals:** column mismatch, Blocks write, council atomicity (separate handoffs)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — ensure_column SQL injection surface (MEDIUM)
`src/store/schema.rs:500-512`

`PRAGMA table_info({table})` and `ALTER TABLE {table} ADD COLUMN {column} {definition}` built via Rust string formatting. All call sites are internal constants today, but the function provides no structural defence. Quote the identifier in the `ALTER TABLE` statement (`ALTER TABLE "{table}" ADD COLUMN ...`). The PRAGMA cannot use bound parameters; keep as-is but add a comment explaining why.

### 2 — Dynamic SQL bind index arithmetic (MEDIUM)
`src/store/tasks.rs:843-915`

`list_tasks_filtered` computes `status_placeholder_start` and `limit_placeholder` from runtime offsets. A third filter would silently produce wrong bind positions. Refactor to a query builder pattern or add a compile-time assertion that the offset arithmetic matches the parameter count.

### 3 — build_session always returns non-None summary (MEDIUM)
`src/store/council.rs:130-134`

`session_summary` is synthesised to a hard-coded default string if absent, so `Option<String>` always returns `Some`. Callers cannot distinguish "no summary yet" from an actual decision. Either make the default explicit (`DEFAULT_SUMMARY` constant) or use an inner type that separates the two states.

### 4 — Low severity items
- `tasks.rs:1263` — `list_open_child_tasks` issues two DB round-trips via `get_children`; query open children directly
- `status.rs:59` — `has_passing_script_verification_in_connection` uses free-text substring match on `summary`; use a structured boolean or enum field
- `status.rs:62` — ancestor-chain walk queries one hop at a time; use a recursive CTE

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/canopy
cargo test --all 2>&1 | tail -5
cargo clippy 2>&1 | tail -10
```

## Checklist

- [ ] `ensure_column` SQL identifiers are quoted
- [ ] `list_tasks_filtered` bind offset arithmetic is validated or refactored
- [ ] `build_session` summary absence is clearly distinguishable from a real summary
- [ ] Low severity items addressed
- [ ] All tests pass, clippy clean
