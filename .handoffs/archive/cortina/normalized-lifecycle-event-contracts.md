# Cortina Normalized Lifecycle Event Contracts

## Problem

The audit set repeatedly pointed to the same need in `cortina`: it already owns lifecycle capture and host normalization, but the ecosystem still lacks a clearer shared event vocabulary for host, tool, compaction, and council-like lifecycle signals. Without that, downstream consumers keep re-deriving similar meanings from host-specific payloads.

## What exists (state)

- **`cortina`:** already captures hook and session lifecycle events
- **`adapters/`:** already own host-specific parsing
- **`septa`:** already owns explicit shared contracts, but does not yet cover this event family
- **Examples:** `rtk`, `1code`, `context-keeper`, `claurst`, and `council` all reinforced the value of richer normalized lifecycle semantics

## What needs doing (intent)

Expand `cortina`’s normalized event model and push the shared parts into explicit contracts. Start with:

- normalized host/tool event fields
- broader lifecycle vocabulary
- compaction lifecycle capture
- council lifecycle capture
- fail-open invariants documented and enforced

---

### Step 1: Define the normalized event vocabulary

**Project:** `cortina/`
**Effort:** 2-3 hours
**Depends on:** nothing

Define the shared internal vocabulary for normalized lifecycle events and make the boundaries explicit:

- host
- tool event
- session lifecycle
- compaction lifecycle
- council lifecycle

#### Files to modify

**`cortina/`** — add or refine internal event models and documentation.

**`cortina/docs/`** — document the normalized lifecycle vocabulary.

#### Verification

```bash
cd cortina && cargo build
cd cortina && cargo test
```

**Output:**
<!-- PASTE START -->
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 1.38s
    Finished `test` profile [unoptimized + debuginfo] target(s) in 2.04s
    test result: ok. 160 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 93.48s
<!-- PASTE END -->

**Checklist:**
- [x] cortina has an explicit normalized lifecycle vocabulary
- [x] host-specific parsing remains inside adapters
- [x] build and tests pass

---

### Step 2: Add shared contract surface for transferable event fields

**Project:** `cortina/` plus `septa/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Move the transferable part of the event shape into an explicit contract so downstream repos do not invent their own normalization. Keep the contract narrow and host-agnostic.

#### Files to modify

**`septa/`** — add a new contract family for normalized lifecycle or tool events.

**`cortina/`** — emit or validate against that shared shape where appropriate.

#### Verification

```bash
cd cortina && cargo build
cd cortina && cargo test
```

**Output:**
<!-- PASTE START -->
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 1.38s
    Finished `test` profile [unoptimized + debuginfo] target(s) in 2.04s
    test result: ok. 160 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 93.48s
<!-- PASTE END -->

**Checklist:**
- [x] shared contract exists in septa
- [x] cortina aligns with the shared contract
- [x] build and tests pass

---

### Step 3: Add compaction and council lifecycle capture with fail-open policy

**Project:** `cortina/`
**Effort:** 3-4 hours
**Depends on:** Steps 1-2

Add explicit capture for:

- compaction lifecycle
- council lifecycle

Keep fail-open behavior as a cross-host invariant.

#### Files to modify

**`cortina/src/hooks/`** — extend lifecycle capture paths.

**`cortina/src/policy.rs`** — keep degradation and fail-open behavior explicit.

#### Verification

```bash
cd cortina && cargo build
cd cortina && cargo test
bash .handoffs/archive/cortina/verify-normalized-lifecycle-event-contracts.sh
```

**Output:**
<!-- PASTE START -->
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 1.38s
    Finished `test` profile [unoptimized + debuginfo] target(s) in 2.04s
    test result: ok. 160 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 93.48s
PASS: Cortina defines a normalized lifecycle vocabulary module
PASS: Cortina docs explain the normalized lifecycle vocabulary
PASS: Septa owns a shared cortina lifecycle schema
PASS: Septa includes a cortina lifecycle fixture
PASS: Cortina compaction capture includes a normalized lifecycle envelope
PASS: Cortina council lifecycle capture exists
PASS: Fail-open lifecycle invariant is explicit in policy
PASS: Volva adapter preserves fail-open behavior
PASS: Cortina handoff checklist is marked complete
Results: 9 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] compaction lifecycle capture exists
- [x] council lifecycle capture exists
- [x] fail-open policy is explicit and preserved
- [x] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/cortina/verify-normalized-lifecycle-event-contracts.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/cortina/verify-normalized-lifecycle-event-contracts.sh
```

**Output:**
<!-- PASTE START -->
PASS: Cortina defines a normalized lifecycle vocabulary module
PASS: Cortina docs explain the normalized lifecycle vocabulary
PASS: Septa owns a shared cortina lifecycle schema
PASS: Septa includes a cortina lifecycle fixture
PASS: Cortina compaction capture includes a normalized lifecycle envelope
PASS: Cortina council lifecycle capture exists
PASS: Fail-open lifecycle invariant is explicit in policy
PASS: Volva adapter preserves fail-open behavior
PASS: Cortina handoff checklist is marked complete
Results: 9 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Derived from:

- `.audit/external/audits/rtk/ecosystem-borrow-audit.md`
- `.audit/external/audits/1code/ecosystem-borrow-audit.md`
- `.audit/external/audits/context-keeper/ecosystem-borrow-audit.md`
- `.audit/external/audits/claurst/ecosystem-borrow-audit.md`
- `.audit/external/audits/council/ecosystem-borrow-audit.md`
- `.audit/external/synthesis/project-examples-ecosystem-synthesis.md`
