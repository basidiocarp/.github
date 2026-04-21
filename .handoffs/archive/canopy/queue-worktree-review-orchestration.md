# Canopy Queue Worktree Review Orchestration

## Problem

The audits now point to a broader coordination gap than the earlier council handoff covered. `canopy` owns task and operator coordination, but it still lacks a clear first-class model for queue state, worktree-bound execution state, and review-cycle state as one orchestrated workflow. That leaves review, execution, and session identity too fragmented.

## What exists (state)

- **`canopy` store:** already has task, council, event, evidence, and assignment records
- **`canopy` tools:** already exposes queue, council, task, and identity surfaces
- **No unified workflow ledger:** queue state, worktree binding, execution-session refs, and review-cycle state are not yet clearly modeled together
- **Examples:** `1code`, `claurst`, `council`, `vibe-kanban`, `cmux`, and `claude-squad` all reinforced the same need

## What needs doing (intent)

Make `canopy` the coordination ledger for:

- queue state
- worktree-bound execution state
- review-cycle state
- council/session linkage
- operator-visible orchestration views built from typed records

This should stay state-first. Do not start with UI or ad hoc views.

---

### Step 1: Add queue, worktree, and review-cycle records to the store

**Project:** `canopy/`
**Effort:** 4-5 hours
**Depends on:** nothing

Extend the store schema so tasks can be linked to:

- queue position or queue state
- worktree or workspace ref
- execution-session ref
- review-cycle ref or status

Prefer explicit tables or typed records over opaque metadata blobs.

#### Files to modify

**`canopy/src/store/schema.rs`** — add the new record shapes.

**`canopy/src/store/tasks.rs`** — thread queue/worktree/review state through task persistence.

**`canopy/src/store/helpers/review.rs`** — extend review helpers to support typed review-cycle state.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -40
cd canopy && cargo test 2>&1 | tail -60
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] queue, worktree, and review-cycle records are explicit in the store
- [ ] task records can reference those typed records
- [ ] build and tests pass

---

### Step 2: Expose orchestration through API and tool surfaces

**Project:** `canopy/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Expose the new state through existing operator and tool seams rather than inventing a second coordination layer.

At minimum:

- queue views include worktree or session context
- identity views can point to the same execution and review records
- council or task surfaces can expose linked review-cycle state

#### Files to modify

**`canopy/src/api/views.rs`** — add queue/worktree/review read models.

**`canopy/src/api/context.rs`** — expose the new workflow context where relevant.

**`canopy/src/tools/queue.rs`** — include richer orchestration state.

**`canopy/src/tools/identity.rs`** — expose stable refs across task, council, session, and review records.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -40
cd canopy && cargo test 2>&1 | tail -60
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] queue and identity tools expose worktree or review-aware state
- [ ] API read models can represent the same workflow records
- [ ] build and tests pass

---

### Step 3: Link review-cycle and council/session lifecycle cleanly

**Project:** `canopy/`
**Effort:** 2-3 hours
**Depends on:** Step 2

Make the orchestration model coherent across review and council workflows. The goal is not to duplicate `volva` or `cortina`, but to make `canopy` the place where those external lifecycles are linked to task state.

#### Files to modify

**`canopy/src/store/council.rs`** — link council-session state to review or execution records where needed.

**`canopy/src/store/events.rs`** — attach lifecycle transitions to the typed workflow records.

**`canopy/src/api/operator_actions.rs`** — expose narrow operator actions that rely on the linked state.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -40
cd canopy && cargo test 2>&1 | tail -60
bash .handoffs/archive/canopy/verify-queue-worktree-review-orchestration.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] council, queue, worktree, and review records can be linked through task state
- [ ] lifecycle events update typed orchestration records instead of ad hoc metadata
- [ ] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/canopy/verify-queue-worktree-review-orchestration.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/canopy/verify-queue-worktree-review-orchestration.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Derived from:

- `.audit/external/audits/1code/ecosystem-borrow-audit.md`
- `.audit/external/audits/claurst/ecosystem-borrow-audit.md`
- `.audit/external/audits/council/ecosystem-borrow-audit.md`
- `.audit/external/audits/vibe-kanban/ecosystem-borrow-audit.md`
- `.audit/external/audits/cmux/ecosystem-borrow-audit.md`
- `.audit/external/audits/claude-squad/ecosystem-borrow-audit.md`
- `.audit/external/synthesis/project-examples-ecosystem-synthesis.md`
- `.audit/external/synthesis/next-session-context-second-wave-handoffs.md`
