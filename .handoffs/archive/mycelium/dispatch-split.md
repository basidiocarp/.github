# Mycelium dispatch.rs Split

## Problem

`mycelium/src/dispatch.rs` was 1,624 lines with a 505-line `dispatch()` function that
is essentially a flat match statement mapping ~50 command variants to handlers.
Adding any new command requires editing this single function. `commands.rs` is 1,602
lines of Clap enum definitions. Together they account for 3,200+ lines.

## What exists (state)

- **`dispatch.rs`:** now 100 lines with the heavy routing moved into `src/dispatch/`
- **`commands.rs`:** now 781 lines with subordinate command enums moved into `src/commands/subcommands.rs`
- **Also split out:** family dispatch helpers, JSON envelope wrapper,
  spawned-command runner, `is_operational_command`, and command tests
- **Nesting:** `dispatch_npx` reaches 5 levels deep

## What needs doing (intent)

Extract helper dispatch functions and utilities out of `dispatch.rs`. Consider
splitting `commands.rs` using Clap's `#[command(flatten)]` for sub-groups.

---

### Step 1: Extract dispatch utilities

**Project:** `mycelium/`
**Effort:** 1 hour

Move from `dispatch.rs` to separate files:
- `dispatch_json.rs` — JSON envelope wrapper
- `dispatch_run.rs` — `run_spawned_command`, process execution helpers
- `dispatch_ops.rs` — `is_operational_command` and operational routing

### Step 2: Group command-family dispatchers

Move `dispatch_git_commands`, `dispatch_gh_commands`, `dispatch_docker_commands`,
`dispatch_npx` etc. closer to their corresponding filter modules. Each command
family module could export its own dispatch function.

**Checklist:**
- [x] `dispatch.rs` under 800 lines
- [x] `dispatch()` main function under 300 lines
- [x] `cargo test --quiet` passes in `mycelium`
- [x] No deep nested routing remains in the root dispatcher

## Context

Found during global ecosystem audit (2026-04-04), Layer 2 structural review of mycelium.
