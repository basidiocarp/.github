# Volva: Execution Session Instance Records

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `volva`
- **Allowed write scope:** `volva/...`
- **Cross-repo edits:** none unless this handoff explicitly names a shared contract change
- **Non-goals:** changing Hymenium workflow authority, broad Cap UI work, or inventing a second task ledger
- **Verification contract:** run the repo-local commands below and `bash .handoffs/volva/verify-execution-session-instance-records.sh`
- **Completion update:** once review is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** session store, execution runtime, worktree or backend status modules, and any existing doctor or status command surfaces
- **Reference seams:** current runtime session lifecycle plus [Workspace-Session Route Models](workspace-session-routes.md)
- **Spawn gate:** do not launch an implementer until the parent agent can name the exact file set and exact repo-local verification commands

## Problem

Volva runs execution sessions, but the durable record of a session is still too thin. If a runtime restarts or the operator needs to resume, inspect, or clean up work, too much state must be reconstructed from ad hoc logs or ambient filesystem state. The `claude-squad` audit points to a cleaner seam: persist an execution-session instance record that captures task linkage, branch or worktree state, session lifecycle, and restore or cleanup status directly.

## What exists (state)

- **Volva runtime:** can start and end execution sessions, but restore and cleanup facts are not yet a first-class persisted model
- **Workspace-session work:** [Workspace-Session Route Models](workspace-session-routes.md) covers route identity, but not full persisted instance state
- **External reference:** `claude-squad` persists session instance state deliberately and exposes pause, resume, restore, checkout, and cleanup as explicit operator actions

## What needs doing (intent)

Add a durable execution-session instance record that can explain:

- which task or workflow the session belongs to
- which workspace or worktree it is bound to
- which branch or backend context it is using
- whether it is active, paused, resumable, finished, failed, or cleaned up
- whether restore or cleanup is pending

## Scope

- **Primary seam:** session persistence and restore-state visibility
- **Allowed files:** `volva/src/...`, `volva/tests/...`, `volva/docs/...`
- **Explicit non-goals:**
  - Do not move task authority out of Canopy or Hymenium
  - Do not add a new global coordination database
  - Do not build Cap UI in this handoff

---

### Step 1: Define the execution-session instance record

**Project:** `volva/`
**Effort:** 2-4 hours
**Depends on:** [Volva: Workspace-Session Route Models](workspace-session-routes.md)

Define the persisted instance shape and the minimum lifecycle states it must cover.

#### Verification

```bash
cd volva && cargo check 2>&1
```

**Checklist:**
- [ ] Instance record shape is documented in code or repo docs
- [ ] Record includes task or workflow linkage plus workspace or worktree identity
- [ ] Record includes explicit lifecycle states such as active, paused, resumable, finished, failed, and cleaned_up

---

### Step 2: Persist and update instance state through the runtime lifecycle

**Project:** `volva/`
**Effort:** 0.5-1 day
**Depends on:** Step 1

Write the instance record when a session starts and keep it updated as the session is paused, resumed, completed, or cleaned up.

#### Verification

```bash
cd volva && cargo test session 2>&1
```

**Checklist:**
- [ ] Start, pause, resume, complete, and cleanup paths all update the instance record
- [ ] Restart or resume flows can find the prior instance directly
- [ ] Failure paths preserve enough state to explain what must be recovered

---

### Step 3: Surface restore and cleanup state in status or doctor output

**Project:** `volva/`
**Effort:** 2-4 hours
**Depends on:** Step 2

Expose the instance record through a narrow status or doctor surface so the operator can tell whether a session is active, resumable, or waiting for cleanup.

#### Verification

```bash
cd volva && cargo test 2>&1
cd volva && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Status or doctor output can show active and resumable sessions
- [ ] Worktree or workspace linkage is visible in that output
- [ ] Cleanup-pending state is visible and actionable
- [ ] Tests and clippy pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Volva persists execution-session instance records with explicit lifecycle state
2. `bash .handoffs/volva/verify-execution-session-instance-records.sh` passes
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion

### Final Verification

```bash
bash .handoffs/volva/verify-execution-session-instance-records.sh
```

**Output:**
<!-- PASTE START -->
PASS: Volva source references execution-session instance records or restore state
PASS: Volva session-focused tests pass
PASS: Volva full tests pass
PASS: Volva clippy passes
Results: 4 passed, 0 failed
<!-- PASTE END -->

## Context

Source: `claude-squad` ecosystem borrow audit, especially the persisted session-state and task-oriented operator flow findings. This is a follow-on hardening seam, not a change to the orchestration reset authority model.
