# Mycelium: Fix critical bugs (no-op migration, binary exec, git failure, GLOB injection)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** mycelium/...
- **Cross-repo edits:** none
- **Non-goals:** compressed format experiments (separate handoff #112)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — No-op schema migration renames column to itself (CRITICAL)
`src/schema.rs:59`

A migration renames a column to its own name. The operation is a no-op and obscures
the schema history — the rename that was intended may never have landed. Audit whether
the intended rename was applied elsewhere and correct the migration:
- If the rename was already applied: remove the no-op migration (or replace with a
  comment explaining why it is intentionally inert)
- If the rename was never applied: apply it correctly

### 2 — SQL datetime concatenation latent injection (CRITICAL)
`src/queries.rs:541`

A query concatenates a datetime value directly into SQL via string formatting. The
value is currently typed `u32`, which is safe, but the pattern is fragile: if the
call site is ever changed to accept a user-supplied or externally-parsed value, this
becomes SQL injection. Replace with a parameterised query (`?` binding).

### 3 — Arbitrary binary execution in `dispatch_json` (HIGH)
`src/dispatch/exec.rs:256`

`dispatch_json` spawns an arbitrary binary from the command field without allowlisting.
Any caller who can supply a JSON payload with an arbitrary `command` value can execute
any binary on the system. Restrict to an allowlist of known tool binaries or validate
the command field against a known-safe list before spawning.

### 4 — `run_commit` silently returns `Ok` on git failure (HIGH)
`src/mutations.rs:60`

`run_commit` checks the exit status of the git process but returns `Ok(())` even when
the process exits non-zero. Callers receive no signal that the commit failed. Fix:
return `Err(...)` when the git process exits with a non-zero status.

### 5 — Bare `.unwrap()` in production regex compilation (HIGH)
`src/next.rs:51`

A regex is compiled with `.unwrap()` in a non-test, non-const context. If the regex
pattern is ever changed to an invalid pattern (e.g. in a refactor), this panics at
runtime. Use `lazy_static!` or `once_cell::sync::Lazy` with a proper regex that is
validated at startup, or add an explicit `expect` message describing the invariant.

### 6 — GLOB path injection for project paths with special characters (HIGH)
`src/utils.rs:151`

Project paths are interpolated directly into a GLOB pattern without escaping. A
project path containing `[`, `]`, `*`, or `?` characters causes the GLOB to match
unintended paths. Use `glob::Pattern::escape()` on the path component before
interpolation.

### 7 — Medium items
- Path traversal in project filter: user-controlled path fragments are not validated
  to stay within the project root before being used in filesystem queries
- Migration `UPDATE` error suppression: a migration step suppresses `UPDATE` errors
  with `let _ =`, hiding schema inconsistencies silently

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/mycelium
cargo build --release 2>&1 | tail -3
cargo test 2>&1 | tail -5
```

Expected: build clean, 14+ tests pass.

## Checklist

- [ ] No-op migration corrected or removed with explanation
- [ ] SQL datetime concatenation replaced with parameterised query
- [ ] `dispatch_json` binary execution restricted to allowlist
- [ ] `run_commit` returns `Err` on git non-zero exit
- [ ] Bare `.unwrap()` in regex replaced with `lazy_static`/`once_cell` or `expect`
- [ ] GLOB path interpolation uses `glob::Pattern::escape()`
- [ ] Path traversal in project filter validated against project root
- [ ] All tests pass, build clean
