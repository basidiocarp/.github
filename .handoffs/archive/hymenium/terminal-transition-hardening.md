# Terminal Transition Hardening

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/...`
- **Cross-repo edits:** none
- **Non-goals:** septa contract changes, cap surfaces, CLI wiring for fail/complete (still deferred)
- **Verification contract:** `bash .handoffs/hymenium/verify-terminal-transition-hardening.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** `src/store.rs`, `src/monitor/progress.rs`
- **Reference seams:** the four-step persist pattern in `src/commands/{cancel,fail,complete}.rs` is the consumer that benefits from a reliable `current_phase_idx` reload
- **Spawn gate:** parent must confirm that the persisted `current_phase` column exists in the `workflows` table schema before launching an implementer (check `src/store.rs` schema section)

## Problem

The terminal-transition correctness PR (`impl/hymenium/terminal-transition-correctness/1`) resolved the top four data-integrity bugs in the outcome-emission surface, but a cross-audit identified four remaining hardening items. None are blocking today, but each will bite under realistic evolution of the codebase.

## What exists (state)

1. **`current_phase_idx` reconstruction is accidentally correct** (`hymenium/src/store.rs:251-262`). On reload, the loader scans phase states looking for `Active`, then the last `Completed`, then falls back to `0`. The persisted `current_phase` column is read into `_current_phase` and discarded. The math works by coincidence for 2-phase templates; 3+ phase templates or unusual status combinations will produce the wrong `current_phase_idx`.

2. **Silent default path fallback** (`hymenium/src/store.rs:97-98`). When both `XDG_DATA_HOME` and `HOME` are unset, `default_path()` returns `PathBuf::from(".")`, producing `./hymenium/hymenium.db` silently in the current working directory. No warning to stderr.

3. **Silent i64 clamp** (`hymenium/src/store.rs:376`). `i64::try_from(order).unwrap_or(i64::MAX)` clamps an overflow to `i64::MAX` instead of surfacing it. Impossible in practice today; genuinely corrupts position data if the input ever exceeds `i64::MAX`.

4. **Silent `Duration::MAX` fallback** (`hymenium/src/monitor/progress.rs:64-65` and `:86-87`). `chrono::Duration::from_std(...).unwrap_or(chrono::Duration::MAX)` silently disables timeout detection if the `std::Duration` exceeds `chrono::Duration` range. Current defaults (300s, 1800s) don't trip it; a mis-configured 100-year value silently disables stall detection.

## What needs doing (intent)

Persist the `current_phase_idx` and read it on load. Replace the three silent fallbacks with observable error returns or at-minimum stderr warnings.

## Scope

- **Primary seam:** `src/store.rs` load path and `src/monitor/progress.rs` timeout parsing
- **Allowed files:** `hymenium/src/store.rs`, `hymenium/src/monitor/progress.rs`, `hymenium/src/monitor/mod.rs` (if the MonitorError enum lives there)
- **Explicit non-goals:**
  - Do not touch engine state-machine logic
  - Do not redesign the `Monitor` API
  - Do not modify `commands/` files
  - Do not change any septa contract
  - Do not add CLI flags for monitor timeouts (config-file or env handles it)

---

### Step 1: Persist and reload `current_phase_idx`

**Project:** `hymenium/`
**Effort:** 0.5 day
**Depends on:** nothing

Today the `workflows` table's `current_phase` column stores the current phase ID as text but is discarded on load (`_current_phase` at approximately line 219 of `src/store.rs`). The loader then reconstructs `current_phase_idx` by scanning phase states.

Change:
1. On insert/update, persist the numeric `current_phase_idx` to a dedicated integer column. If the existing text column is named `current_phase`, add a new `current_phase_idx INTEGER NOT NULL DEFAULT 0` column via `ensure_column` in `migrate_schema`.
2. On load, read `current_phase_idx` directly into the returned `WorkflowInstance` instead of recomputing it from phase statuses.
3. Remove the scan-for-Active-then-last-Completed heuristic at lines 251-262.
4. Add a regression test: a 3-phase template, complete phase 0, advance to phase 1, fail phase 1, reload, assert `current_phase_idx == 1` on reload (the old heuristic would also return 1 here — but the test proves the new direct-read path).
5. Add a regression test the old heuristic would fail: a hypothetical 3-phase template where two phases somehow show `Completed` but the workflow was advanced past them via a direct insert (this simulates a future bug path). The persisted `current_phase_idx` should trump phase-status scanning.

### Step 2: Replace silent default-path fallback

**Project:** `hymenium/`
**Effort:** 0.25 day
**Depends on:** nothing

In `src/store.rs` `default_path()`:

Today:
```rust
Some(home) => PathBuf::from(home).join(".local/share/hymenium/hymenium.db"),
None => PathBuf::from("./hymenium/hymenium.db"),
```

Change the `None` arm to log a warning via `eprintln!` (or the project's logger if one exists) before returning the fallback, so the user learns their DB landed in the current directory:

```rust
None => {
    eprintln!(
        "warning: neither XDG_DATA_HOME nor HOME is set; writing hymenium.db to {}",
        "./hymenium/hymenium.db"
    );
    PathBuf::from("./hymenium/hymenium.db")
}
```

Do not change the return type — returning `Result` would cascade through too many callers for a defensive nit.

### Step 3: Replace silent i64 clamp

**Project:** `hymenium/`
**Effort:** 0.25 day
**Depends on:** Step 1 (same file, easier to land together)

In `src/store.rs:376` (approximate line):

Today:
```rust
i64::try_from(order).unwrap_or(i64::MAX)
```

Change to return a typed error:
```rust
i64::try_from(order).map_err(|_| StoreError::InvalidValue {
    field: "phase_order".into(),
    reason: format!("value {} exceeds i64::MAX", order),
})?
```

Identify the actual field name from the call site (may be `retry_count`, `phase_order`, or similar — read the context). The surrounding function must return `Result<_, StoreError>`; if it does not, propagate via the natural boundary rather than wrapping in a new `Result`.

### Step 4: Replace silent `Duration::MAX` fallback

**Project:** `hymenium/`
**Effort:** 0.25 day
**Depends on:** nothing

In `src/monitor/progress.rs` at approximately lines 64-65 and 86-87:

Today:
```rust
chrono::Duration::from_std(std_duration).unwrap_or(chrono::Duration::MAX)
```

Change to return a `MonitorError::InvalidConfig` (or equivalent) so misconfiguration surfaces at construction time rather than silently disabling stall detection:

```rust
chrono::Duration::from_std(std_duration).map_err(|e| MonitorError::InvalidConfig {
    field: "stall_timeout".into(),
    reason: format!("{e}"),
})?
```

If `MonitorError` does not yet have an `InvalidConfig` variant, add one as `#[non_exhaustive]`.

---

## Verification Contract

From the workspace root:

```bash
cd hymenium
cargo build
cargo test
cargo clippy -- -D warnings
cargo fmt --check
```

Then:

```bash
bash .handoffs/hymenium/verify-terminal-transition-hardening.sh
```

Expected: all pass, zero clippy warnings, integration script still 61+ pass / 6 fail (pre-existing $ref issues tracked separately in `cross-project/integration-script-ref-resolution.md`).

## Completion criteria

- [ ] `current_phase_idx` persisted and read on load; heuristic scan removed
- [ ] Silent default-path fallback prints a stderr warning
- [ ] Silent i64 clamp returns a typed error
- [ ] Silent `Duration::MAX` fallback returns a typed error
- [ ] Regression tests added for each
- [ ] `cargo test` green, clippy clean, fmt clean
- [ ] HANDOFFS.md updated, handoff archived
