# Canopy api.rs Module Split

## Problem

`canopy/src/api.rs` is 3,737 lines — the largest file in the ecosystem. It contains
snapshot construction, attention derivation, SLA computation, operator actions, allowed
actions, deadline state, freshness utilities, view filtering, sorting, and 80+ free
functions. Functions take 15-25 HashSet parameters. 14 clippy lints are suppressed
(9 `too_many_lines`, 5 `too_many_arguments`).

## What exists (state)

- **File:** `canopy/src/api.rs` (3,737 lines)
- **Key function:** `snapshot()` computes ~20 named HashSets on lines 103-243
- **`matches_view()`:** takes 25 parameters (line 895)
- **`derive_task_attention()`:** takes 16 parameters (line 3220)
- **14 suppressed clippy lints** (all symptoms of real structural debt)

## What needs doing (intent)

Extract a `SnapshotContext` struct to bundle the precomputed HashSets. Split `api.rs`
into submodules by concern.

---

### Step 1: Create SnapshotContext struct

**Project:** `canopy/`
**Effort:** 1-2 hours
**Depends on:** nothing

Create `src/api/context.rs` with a struct that holds all the HashSets and HashMaps
currently computed at the top of `snapshot()`. Pass `&SnapshotContext` to all functions
instead of 15-25 individual parameters.

### Step 2: Split into submodules

**Project:** `canopy/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Split `api.rs` into:
- `api/mod.rs` — public `snapshot()` entry point, re-exports
- `api/context.rs` — `SnapshotContext` struct and construction
- `api/attention.rs` — `derive_task_attention`, attention reasons
- `api/sla.rs` — SLA computation, deadline state
- `api/operator_actions.rs` — `derive_operator_actions`
- `api/allowed_actions.rs` — `derive_allowed_task_actions`
- `api/views.rs` — `matches_view`, view filtering, sorting

### Step 3: Remove suppressed lints

After splitting, verify that the 14 `#[allow(clippy::...)]` annotations are no longer
needed. Remove any that clippy no longer triggers.

**Checklist:**
- [ ] No function takes more than 8 parameters
- [ ] Each submodule is under 800 lines
- [ ] All 103 tests still pass
- [ ] Suppressed lint count reduced from 14

## Context

Found during global ecosystem audit (2026-04-04), Layer 2 structural review of canopy.
See `ECOSYSTEM-AUDIT-2026-04-04.md` structural hotspots.
