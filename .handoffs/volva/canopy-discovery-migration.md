# Volva: Canopy CLI Availability Check → Spore Discovery

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `volva`
- **Allowed write scope:** `volva/crates/volva-cli/src/run.rs` only
- **Cross-repo edits:** none
- **Non-goals:** no changes to canopy itself; no orchestration mode behavior changes beyond swapping the check mechanism
- **Verification contract:** `cd volva && cargo check && cargo test && cargo clippy`
- **Completion update:** update `.handoffs/HANDOFFS.md` when done

## Problem

`volva/crates/volva-cli/src/run.rs` checks whether canopy is available by running:

```rust
// run.rs:39-44
let canopy_ok = std::process::Command::new("canopy")
    .arg("--version")
    .output()
    .map(|o| o.status.success())
    .unwrap_or(false);
```

This is a CLI availability check used as a system-to-system probe. Problems:
- Spawning a subprocess for a binary check that spore already knows how to do is wasteful
- `Command::new("canopy")` relies on `$PATH` rather than spore's ecosystem-aware discovery (which also handles non-`$PATH` install locations)
- C8 rule: use `spore::discover` for tool availability; CLI fallback is for human/operator surfaces only

## Current State

**File:** `volva/crates/volva-cli/src/run.rs:39-56`

```rust
OperationMode::Orchestration => {
    let canopy_ok = std::process::Command::new("canopy")
        .arg("--version")
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false);
    if !canopy_ok {
        bail!(
            "orchestration mode requires canopy — start canopy first or use --mode baseline"
        );
    }
    context::Capabilities {
        mode: OperationMode::Orchestration,
        canopy_available: true,
    }
}
```

## Migration

Replace the `Command::new("canopy")` availability check with `spore::discover(Tool::Canopy)`.

**Check spore dependency**: Confirm `spore` is already a dependency of `volva-cli`. If not, add it to `volva/crates/volva-cli/Cargo.toml` — it is already pinned in `ecosystem-versions.toml`.

**New code:**

```rust
use spore::{Tool, discover};

// ... in handle_run, Orchestration match arm:
OperationMode::Orchestration => {
    let canopy_ok = discover(Tool::Canopy).is_some();
    if !canopy_ok {
        bail!(
            "orchestration mode requires canopy — start canopy first or use --mode baseline"
        );
    }
    context::Capabilities {
        mode: OperationMode::Orchestration,
        canopy_available: true,
    }
}
```

Remove the now-unused `std::process::Command` import if it is no longer used elsewhere in the file.

## Why This Is Better

- `spore::discover(Tool::Canopy)` searches the same locations stipe installs to — not just `$PATH`
- Zero subprocess overhead for the check
- Consistent with how every other tool availability check in the ecosystem works
- Removes an unclassified CLI coupling path

## Verification

```bash
cd volva && cargo check
cd volva && cargo test
cd volva && cargo clippy
```

Behavior must be identical: orchestration mode proceeds if canopy is discoverable, bails with the same message if it is not.

## Context

- C7: `volva → canopy` classified as "temporary compatibility" in `septa/integration-patterns.md`
- C8: `docs/foundations/inter-app-communication.md` — discovery via `spore::discover` is the correct pattern for availability checks
- This is the smallest migration in the C7/C8 set — a one-function change with no new dependencies
