# Stipe: Rollback Self-Invocation → Library Call

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/src/commands/rollback.rs` only
- **Cross-repo edits:** none
- **Non-goals:** no behavior change to what doctor checks; no changes to `commands/doctor.rs`
- **Verification contract:** `cd stipe && cargo test && cargo clippy`
- **Completion update:** update `.handoffs/HANDOFFS.md` when done

## Problem

After restoring a backup, `stipe/src/commands/rollback.rs` verifies the restored state by spawning itself:

```rust
// rollback.rs:83-97
let status = std::process::Command::new("stipe").arg("doctor").status();

match status {
    Ok(s) if s.success() => {
        println!("Doctor: all checks passed.");
        Ok(())
    }
    Ok(s) => Err(anyhow::anyhow!(
        "Rollback complete but 'stipe doctor' reported issues (exit {s}). \
         Run 'stipe doctor' for details."
    )),
    Err(e) => Err(anyhow::anyhow!(
        "Rollback complete but could not run 'stipe doctor': {e}"
    )),
}
```

This is a setup-time self-invocation classified in C7 as acceptable for now, but flagged for replacement with a direct library call. Problems:
- Spawning `stipe` relies on `$PATH` after rollback, when PATH may be in an inconsistent state — the exact moment when you most want a reliable check
- Spawning is slower than a function call and introduces an extra failure mode (binary not found on PATH)
- `commands/doctor::run()` is already public with a stable signature

## Current State

**File:** `stipe/src/commands/rollback.rs:83-97`

Calls `std::process::Command::new("stipe").arg("doctor").status()` and maps the `ExitStatus` to `Ok(())` or `Err(...)`.

**Doctor API:** `stipe/src/commands/doctor.rs:1438`

```rust
pub fn run(json: bool, developer: bool, deep: bool) -> Result<()>
```

The rollback needs a plain health check: `run(false, false, false)` — no JSON output, no developer mode, no deep scan. The function returns `Ok(())` on success or `Err(...)` on failure, which maps directly to what rollback currently derives from the exit status.

## Migration

Replace the subprocess call with a direct call to `crate::commands::doctor::run`.

**New code:**

```rust
println!("Running stipe doctor to verify restored state...");

match crate::commands::doctor::run(false, false, false) {
    Ok(()) => {
        println!("Doctor: all checks passed.");
        Ok(())
    }
    Err(e) => Err(anyhow::anyhow!(
        "Rollback complete but 'stipe doctor' reported issues: {e}. \
         Run 'stipe doctor' for details."
    )),
}
```

**Remove the unused import**: if `std::process::Command` is only used for the doctor check, remove it from rollback.rs. If it is used elsewhere in the file, leave it.

## Why This Is Better

- Calls the doctor logic directly — no PATH dependency, no subprocess overhead
- Reliable even when the installed stipe binary is temporarily unavailable (which can happen mid-rollback)
- The error message is richer: it includes the actual Err detail rather than just an exit code
- Removes a self-referential subprocess that can confuse process tree inspection

## Verification

```bash
cd stipe && cargo test
cd stipe && cargo clippy
```

Behavior must be identical: rollback succeeds if doctor returns `Ok(())`, fails with an informative message if doctor returns `Err(...)`.

If stipe has integration tests that exercise the full rollback flow, run those too:

```bash
cd stipe && cargo test --ignored
```

## Context

- C7: `stipe → stipe (self)` classified as "setup-time self-invocation" in `septa/integration-patterns.md`, with the note: "Prefer library call (`run_doctor()`) in a future pass"
- C8: `docs/foundations/inter-app-communication.md` tier 1 (library/crate dependency) is preferred
- This is a contained, low-risk change — same crate, same binary, no new dependencies
