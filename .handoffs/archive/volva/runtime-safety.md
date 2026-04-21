# Volva: Fix runtime safety (double-wait, AuthTarget unreachable, zombie child)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `volva`
- **Allowed write scope:** volva/...
- **Cross-repo edits:** none
- **Non-goals:** auth backend (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — Double-wait on child process (HIGH)
`src/context.rs:177` (approx)

A child process is waited on twice: once inline and once in a background thread or
drop path. The second `wait()` call returns an error because the PID was already
reaped by the first. The process state is then misinterpreted as a crash. Fix: ensure
exactly one wait per child process, using a flag or ownership transfer to prevent
double-reaping.

### 2 — `unreachable!` on `#[non_exhaustive]` `AuthTarget` enum at six sites (MEDIUM)
Six sites in the codebase use `_ => unreachable!()` or equivalent on `AuthTarget`,
a `#[non_exhaustive]` enum. When a new variant is added to `AuthTarget`, these sites
panic at runtime rather than producing a compile-time exhaustiveness error.

Fix: replace wildcard arms with explicit match arms that return an appropriate error
or a handled fallback. Do not use `unreachable!` on a `#[non_exhaustive]` type.

### 3 — Zombie child process on kill + wait discard (MEDIUM)
After killing a child process, the `wait()` result is discarded. If the OS has not yet
delivered SIGCHLD when `wait()` is called, it may block or return `ECHILD`. On some
platforms the child becomes a zombie until the parent is reaped. Fix: use `waitpid`
with `WNOHANG` in a retry loop, or use a proper `Child::wait()` with timeout.

### 4 — Silent OS error in `try_wait` (MEDIUM)
`try_wait()` errors are swallowed without logging. If `try_wait` fails for any reason
other than "not done yet" (e.g. EINVAL, ECHILD), the caller proceeds as if the child
is still running. Log OS errors at `warn` level before returning the "still running"
state.

### 5 — Auth callback unbounded header read (MEDIUM)
The auth callback handler reads request headers without a size bound. A crafted HTTP
request with oversized headers can cause unbounded memory allocation. Add a header
size limit (e.g. 8 KB total).

### 6 — `home_dir()` fallback writes auth tokens to CWD (LOW)
When `home_dir()` returns `None`, auth token files fall back to the current working
directory. If the CWD is a project repo, auth tokens may be committed accidentally.
Fix: return an error rather than falling back to CWD.

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/volva
cargo build 2>&1 | tail -3
cargo test 2>&1 | tail -5
```

Expected: build clean, tests pass (106 tests from prior audit).

## Checklist

- [x] Double-wait eliminated; exactly one `wait()` per child
- [x] `AuthTarget` match arms are explicit (no wildcard `unreachable!`)
- [x] Zombie child: discard-then-zombie pattern replaced with WNOHANG retry or proper wait
- [x] `try_wait` OS errors logged before treating as "still running"
- [x] Auth callback header read bounded to ≤ 8 KB
- [x] `home_dir()` failure returns an error instead of falling back to CWD
- [x] All tests pass, build clean
