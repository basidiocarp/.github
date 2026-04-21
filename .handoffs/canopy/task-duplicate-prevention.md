# Task Duplicate Prevention

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** task state machine changes (hymenium), runtime sweeper (hymenium), or notification model (separate handoff #101a)
- **Verification contract:** run the repo-local commands below and `bash .handoffs/canopy/verify-task-duplicate-prevention.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** task storage layer — wherever tasks are enqueued and persisted (likely SQLite with rusqlite)
- **Reference seams:** multica `server/migrations/022_task_lifecycle_guards.up.sql` for the partial unique index; `server/internal/service/task.go:L33` for the enqueue guard
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Canopy does not prevent duplicate queued tasks for the same scope. If two enqueue requests arrive concurrently for the same task scope (e.g., same issue, same agent), both can be created, leading to double execution. Multica solves this with a partial unique index: one queued task per agent per scope, enforced at the database level. This is a small schema change that eliminates a class of race conditions.

## What exists (state)

- **`canopy`:** has task enqueue and lifecycle management but no uniqueness constraint on queued tasks
- **multica reference:** a partial unique index on `(agent_id, scope)` WHERE `status = 'queued'`, preventing concurrent duplicate queued tasks; atomic claim with concurrency cap enforcement

## What needs doing (intent)

1. Add a partial unique index (or equivalent constraint) to canopy's task storage that prevents duplicate queued tasks for the same scope.
2. Add atomic claim with concurrency enforcement: a claim operation that atomically transitions a task from queued to claimed while checking the agent's concurrency cap.
3. Ensure the constraint is enforced at the database level, not just application-level checks, so it survives concurrent access.

## Scope

- **Primary seam:** task enqueue and claim at the storage layer
- **Allowed files:** `canopy/` storage and task modules
- **Explicit non-goals:**
  - Do not change the task state machine beyond adding the constraint
  - Do not implement a runtime sweeper (hymenium concern, see #122)
  - Do not add notification emission for task events (separate handoff #101c)

---

### Step 1: Add partial unique index for queued tasks

**Project:** `canopy/`
**Effort:** 0.5 day
**Depends on:** nothing

Add a database migration (or schema change) that creates a partial unique index preventing duplicate queued tasks for the same scope. The index should only apply to tasks in `queued` status so that completed/failed tasks for the same scope are not affected.

#### Verification

```bash
cd canopy && cargo check 2>&1
cd canopy && cargo test task 2>&1
```

**Checklist:**
- [ ] Partial unique index exists in the schema
- [ ] Attempting to enqueue a duplicate returns a clear error, not a crash
- [ ] Completed/failed tasks for the same scope are not affected by the constraint

---

### Step 2: Add atomic claim with concurrency enforcement

**Project:** `canopy/`
**Effort:** 0.5 day
**Depends on:** Step 1

Add a claim operation that atomically transitions a queued task to claimed status while checking the agent's concurrency cap. If the agent already has N claimed tasks (where N is the cap), the claim fails gracefully.

#### Verification

```bash
cd canopy && cargo test claim 2>&1
```

**Checklist:**
- [ ] Claim is atomic (single transaction)
- [ ] Concurrency cap is enforced
- [ ] Exceeding the cap returns a clear error, not a crash

---

### Step 3: Add integration tests for concurrent enqueue and claim

**Project:** `canopy/`
**Effort:** 0.5 day
**Depends on:** Step 2

Add tests that verify the constraint under concurrent access: two simultaneous enqueue requests for the same scope should result in exactly one queued task. Two simultaneous claims for the same task should result in exactly one claim.

#### Verification

```bash
cd canopy && cargo test duplicate 2>&1
cd canopy && cargo test 2>&1
cd canopy && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Concurrent enqueue test passes
- [ ] Concurrent claim test passes
- [ ] All existing tests pass without regression
- [ ] No new clippy warnings

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/canopy/verify-task-duplicate-prevention.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/canopy/verify-task-duplicate-prevention.sh
```

## Context

Source: multica ecosystem borrow audit (2026-04-14) sections "Task lifecycle with duplicate-prevention and atomic claim" and "Harden task enqueue with a duplicate-prevention constraint." See `.audit/external/audits/multica-ecosystem-borrow-audit.md`.

Related handoffs: #101a Canopy Notification Model and Storage, #73 Canopy Sub-Task Hierarchy, #72 Canopy Verification Completion Gate. This handoff hardens the task foundation that those features build on.
