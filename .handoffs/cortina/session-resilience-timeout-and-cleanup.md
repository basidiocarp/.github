# Cortina: Session Resilience — Subprocess Timeout and State File Cleanup

## Handoff Metadata

- **Dispatch:** direct
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/src/utils/session_scope.rs` and its tests
- **Cross-repo edits:** none
- **Non-goals:** does not change session SQLite schema; does not change hyphae protocol; does not modify hook integration
- **Verification contract:** `cd cortina && cargo build --release && cargo test --release && cargo clippy`
- **Completion update:** Stage 1 + Stage 2 review pass → commit → mark handoff done in campaign README

## Problem

Two related gaps in `cortina/src/utils/session_scope.rs` (from Ecosystem Health Audit issues #9 and #15):

### Gap 1 — State file not removed on hyphae failure (issue #9)

`end_hyphae_session_with` correctly marks the session as orphaned in SQLite when `run_command` fails or exits non-zero (lines 309–337), but it does NOT remove the state file at `session_state_path(hash)`. The stale file persists on disk until the next session in the same worktree overwrites it.

**Failure sequence:**
1. Session 1 ends: `hyphae session end` fails → SQLite `end_orphaned` called → file stays on disk.
2. Hyphae recovers; session 2 starts in the same worktree.
3. `ensure_hyphae_session_with_hash` loads the stale file → calls `match_active_session` → hyphae says the old session is dead → creates new session → writes over the file.

The stale file being picked up each time adds a redundant liveness round-trip to hyphae on every session start following a failed end. In multi-worktree setups each stale path is different, so stale files accumulate.

**Fix:** In both failure return paths (command failure, non-zero exit), delete the state file inside a `with_file_lock` guard, identical to the success path at lines 350–358, before returning `Ok(None)`.

### Gap 2 — No internal subprocess timeout on hyphae write (issue #15)

`end_hyphae_session_with` calls `run_command(&mut cmd)` where production callers pass `Command::output` directly. `Command::output` blocks indefinitely if the hyphae subprocess hangs. Cortina relies entirely on the lamella hook-level timeout (which kills the entire cortina process) to escape a hanging hyphae write. When the hook timeout fires and kills cortina, the state file is NOT cleaned (the exit is abrupt), worsening issue #9.

**Fix:** Add an internal timeout of `HYPHAE_WRITE_TIMEOUT` (5 seconds is enough — hyphae writes are fast under normal load). Implement using a thread-based approach consistent with how other parts of the codebase handle subprocess timeouts: spawn a background killer thread that fires after the deadline, with a cancellation channel to signal it when the process exits normally.

Pattern to follow: `hymenium/src/dispatch/capability_client.rs` `send_dispatch_request` (the timeout/killer/cancel_tx/cancel_rx pattern).

## Step 1 — Add cleanup to failure paths

In `end_hyphae_session_with`, find the two `return Ok(None)` paths that skip file cleanup:

**Path 1** (run_command fails, lines ~309–320): After calling `store.end_orphaned`, also remove the file:
```rust
with_file_lock(&path, || {
    if load_json_file::<SessionState>(&path)
        .as_ref()
        .is_some_and(|current| current.session_id == state.session_id)
    {
        let _ = fs::remove_file(&path);
    }
    Ok(())
})?;
return Ok(None);
```

**Path 2** (non-zero exit, lines ~323–337): Same pattern.

Both paths already use `with_file_lock` on the success path (line 350). Apply the same guard to the failure paths so cleanup is always consistent.

## Step 2 — Add internal subprocess timeout

Define a constant near the top of the file (or alongside the other timeout constants if any exist):
```rust
const HYPHAE_WRITE_TIMEOUT: Duration = std::time::Duration::from_secs(5);
```

Wrap the `run_command(&mut cmd)` call with a timeout mechanism. Since `session_scope.rs` already uses `std::thread` (verify), a background killer thread is the right approach:

```rust
let mut child = cmd.spawn().map_err(|e| anyhow::anyhow!("spawn hyphae session end: {e}"))?;
let child_id = child.id();
let (cancel_tx, cancel_rx) = std::sync::mpsc::channel::<()>();
let killer = std::thread::spawn(move || {
    if cancel_rx.recv_timeout(HYPHAE_WRITE_TIMEOUT).is_err() {
        // Timeout — kill the child
        #[cfg(unix)]
        unsafe { libc::kill(child_id as libc::pid_t, libc::SIGKILL); }
    }
});
let output = child.wait_with_output();
let _ = cancel_tx.send(());
let _ = killer.join();
```

**Important:** This changes `run_command` from being called as a function pointer to using `cmd.spawn()` directly. Since tests inject `run_command` via a closure, you need to handle this: either keep the `run_command` injection for tests and add a separate `end_hyphae_session_with_timeout` that uses `spawn`, or add a separate timeout wrapper only at the production call sites (`end_hyphae_session` which passes `Command::output`).

The simplest approach: add the timeout only in `end_hyphae_session` (the public entry point that uses `Command::output`) by wrapping `Command::output` with a timeout closure before passing it to `end_hyphae_session_with`. Tests continue to inject the mock `run_command` directly.

If cortina already depends on `libc`, use it. Check `Cargo.toml` — if not present, add `libc = "0.2"`.

## Step 3 — Tests

Verify:
1. **File cleanup test**: The existing test for `end_hyphae_session_with` that exercises the failure path should assert the state file is gone after failure. Add this assertion if it's not already there.
2. **Existing tests still pass**: The mock `run_command` injection pattern must continue to work unchanged.

## Verification

```bash
cd /Users/williamnewton/projects/personal/basidiocarp/cortina
cargo build --release
cargo test --release
cargo clippy
```

## Context

Ecosystem Health Audit issues #9 and #15. Phase 5 Pass 2 findings confirmed:
- State file orphaning: `session_scope.rs:309-337` — failure paths skip `fs::remove_file`
- No subprocess timeout: `Command::output` used directly with no deadline
- SQLite `end_orphaned` is called correctly; the fix is additive (also clean the file)
