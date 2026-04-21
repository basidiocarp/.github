# Canopy CanopyStore Trait Decomposition

## Problem

`CanopyStore` trait in `store/traits.rs` has 60+ methods covering agents, tasks, events,
assignments, relationships, handoffs, file locks, evidence, council messages, and
heartbeats. Every new store method requires updating the trait, the blanket impl, and
any mock. The mock in tests panics for all unimplemented methods, forcing tests to
carefully avoid calling anything outside their narrow scope.

## What exists (state)

- **File:** `canopy/src/store/traits.rs` is now a composed store-trait surface
- **Helpers:** `canopy/src/store/helpers.rs` is now a thin root with domain submodules under `src/store/helpers/`
- **Tests:** task lookup coverage now uses a targeted store double in `tools/task.rs`

## What needs doing (intent)

Split into domain-specific sub-traits and use a supertrait for composition.

---

### Step 1: Split into sub-traits

**Project:** `canopy/`
**Effort:** 2-3 hours

Completed with multiple domain traits (`AgentStore`, `TaskGetStore`, `TaskLookupStore`, `TaskMutationStore`, `TaskEventStore`, `TaskAssignmentStore`, `TaskRelationshipStore`, `HandoffStore`, `FileLockStore`, `EvidenceStore`, `CouncilStore`, `HeartbeatStore`) composed through `CanopyStore`.

Mocks can now implement only the relevant sub-trait for their test scope.

**Checklist:**
- [x] No single public sub-trait exceeds the original monolithic surface
- [x] `CanopyStore` is a supertrait composition
- [x] Mock panics replaced with per-sub-trait test doubles
- [x] `cargo test --quiet` passes in `canopy`
- [x] `store/helpers.rs` (1,894 lines pre-split) is now a 31-line root with domain modules

## Context

Found during global ecosystem audit (2026-04-04), Layer 2 structural review of canopy.
