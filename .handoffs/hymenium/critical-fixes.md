# Hymenium: Fix critical bugs (retry loop, SQL injection, stale runtime detection)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** hymenium/...
- **Cross-repo edits:** none
- **Non-goals:** dispatch template routing, CanopyClient API extension
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — `retry_count` never incremented → infinite retry loop (CRITICAL)
`src/retry.rs:85-169`, `src/workflow/engine.rs`

`decide_recovery` and `decide_recovery_typed` accept `retry_count: u32` from callers.
`PhaseState` holds `retry_count: u32` in the store (`engine.rs:101`, `store.rs:142`),
but no code path anywhere in the repository increments `phase_state.retry_count`
before re-dispatching. Searching for `retry_count +=` yields zero results.

Every retry call arrives with `retry_count == 0`, so `decide_progressive_recovery`
always executes the "first retry" branch and never escalates. A permanently stalled
phase will loop forever. Fix: increment `retry_count` in the engine when re-dispatching
a phase, and persist the updated value.

### 2 — SQL injection surface in `ensure_column` (CRITICAL)
`src/store.rs:191-203`

`ensure_column` interpolates caller-supplied `table`, `column`, and `declaration`
strings directly into SQL:
```rust
"SELECT COUNT(*) > 0 FROM pragma_table_info('{table}') WHERE name = '{column}'"
"ALTER TABLE {table} ADD COLUMN {column} {declaration};"
```
Currently only called with string literals, but the function signature accepts
arbitrary `&str`. A future caller passing externally-derived strings (config file,
env var) would introduce SQL injection. Replace the `ALTER TABLE` statement with
a hardcoded format that only interpolates vetted identifiers, or make `ensure_column`
private with compile-time-checked callers only.

### 3 — Corrupted timestamps silently become `Utc::now()` (CRITICAL)
`src/sweeper.rs:210-214`

```rust
let last_heartbeat = parse_dt(&hb_str).unwrap_or_else(|_| Utc::now());
```

A corrupt `last_heartbeat` in the `runtimes` table is silently replaced with the
current time, making a stale runtime appear healthy (freshly heartbeated). The runtime
never gets marked offline, orphan detection never fires, and active phases remain
unchecked. Replace the silent fallback with an error that is logged and surfaced in
`SweepReport.errors`.

### 4 — `Ordering::Relaxed` on stop flag insufficient on ARM (HIGH)
`src/sweeper.rs:527,546,568,577`

The `stop_flag` `AtomicBool` is read and written with `Ordering::Relaxed`. On
weakly-ordered architectures (ARM / Apple Silicon), relaxed loads are not guaranteed
to observe relaxed stores in bounded time. The sweeper thread may spin indefinitely
after `stop()` is called. Use `Ordering::Release` on the write and `Ordering::Acquire`
on the read.

### 5 — Partial dispatch permanently orphans Canopy tasks (HIGH)
`src/dispatch/orchestrate.rs:104-152`

If any `create_subtask` call fails mid-loop, previously-created Canopy tasks are
permanently orphaned: `CanopyClient` exposes no cancel method, and the `WorkflowInstance`
is never persisted in the failure path. Add at minimum: (a) a comment in the handoff
making this limitation explicit for operators, and (b) a `TODO` for a future
reconciliation scan. If `CanopyClient` gains a cancel method, implement cleanup here.

### 6 — `advance()` reuses `StateError` for "already at final phase" (HIGH)
`src/workflow/engine.rs:313-400`

The "already at final phase" condition returns a `StateError` identical in type to
invalid-transition errors. Callers must inspect the error message string to decide
whether to call `complete_workflow()` — fragile and error-prone. Add a dedicated
`AlreadyAtFinalPhase` variant so callers can match on it.

### 7 — Unbounded IN clause in orphan detection (HIGH)
`src/sweeper.rs:260-294`

The dynamically-constructed `IN (?, ?, ...)` clause for `offline_ids` has no length
bound. SQLite's default variable limit is 999. With 1000+ offline runtimes,
`rusqlite::params_from_iter` fails with `SQLITE_RANGE`, silently skipping orphan
detection for the entire batch. Chunk `offline_ids` into batches of ≤ 999.

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/hymenium
cargo build 2>&1 | tail -3
cargo test 2>&1 | tail -5
```

Expected: build clean, 3+ tests pass.

## Checklist

- [ ] `retry_count` incremented before re-dispatching a phase, persisted to store
- [ ] `ensure_column` SQL uses compile-time-checked identifiers only
- [ ] Corrupted timestamps log an error instead of silently substituting `Utc::now()`
- [ ] Stop flag uses `Release`/`Acquire` ordering
- [ ] Partial dispatch failure documents the orphan risk (comment + TODO)
- [ ] `AlreadyAtFinalPhase` error variant added to `WorkflowError`
- [ ] `offline_ids` batched in ≤ 999 chunks for the orphan detection IN clause
- [ ] All tests pass, build clean
