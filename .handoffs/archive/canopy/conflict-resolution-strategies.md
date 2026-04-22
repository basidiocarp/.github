# Canopy File-Scope Conflict Resolution Strategies

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** canopy/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Canopy v0.3.1 shipped scope field and conflict detection for multi-agent file
coordination. When two agents try to claim overlapping file scopes, the conflict
is detected and the second claim is rejected. But the three resolution strategies —
`--after <task-id>` (sequential), `--worktree` (isolated), and `--force`
(advisory-only) — are designed but not fully implemented. Agents with a detected
conflict have no automated path forward.

## What exists (state)

- **File-scope conflict detection (v0.3.1)**: `scope` field on tasks; conflict
  check on claim — rejects overlapping claims
- **Resolution strategies**: `--after`, `--worktree`, `--force` are documented
  in the roadmap but not implemented in the CLI
- **Task relationships**: parent/child via `task_relationships` table (gaps #12
  adds enforcement); sequential dependency (`--after`) would use this table

## What needs doing (intent)

Implement the three conflict resolution strategies as explicit flags on
`canopy task claim`. Each strategy resolves the conflict differently: sequential
waits for the blocking task, worktree isolation creates a fork, and advisory-only
lets both agents proceed with a logged warning.

---

### Step 1: Implement `--after <task-id>` sequential conflict resolution

**Project:** `canopy/`
**Effort:** 1 day
**Depends on:** nothing

When `canopy task claim <id> --after <blocking-task-id>`:

1. Verify that `<blocking-task-id>` is the task that caused the conflict
2. Create a `task_relationships` entry: `<id>` depends on `<blocking-task-id>`
3. Set `<id>` status to `waiting` (new status or use `blocked`)
4. Register a watcher: when `<blocking-task-id>` completes, auto-transition
   `<id>` from `waiting` → `open` and notify (emit a council `status` message)

```bash
canopy task claim 42 --after 37
# Task 42 now waits for task 37 to complete before becoming claimable.
# Current status: waiting (blocked by #37)
```

#### Files to modify

**`canopy-core/src/task/claim.rs`** — add `--after` resolution:

```rust
pub enum ClaimResolution {
    Force,
    After(TaskId),
    Worktree(String),
}
```

**`canopy-core/src/task/watcher.rs`** — new: task completion watchers

#### Verification

```bash
cd canopy && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `canopy task claim --after <id>` creates dependency relationship
- [ ] Dependent task set to `waiting` status
- [ ] When blocking task completes, dependent task transitions to `open`
- [ ] Council `status` message emitted on auto-transition
- [ ] Build and tests pass

---

### Step 2: Implement `--worktree` isolated conflict resolution

**Project:** `canopy/`
**Effort:** 1 day
**Depends on:** nothing (can parallel with Step 1)

When `canopy task claim <id> --worktree`:

1. Record that the agent intends to work in a git worktree (isolated branch)
2. Store the intended worktree path in the task scope metadata
3. Allow the claim to proceed — worktree isolation means the conflict is resolved
   by file system separation, not scheduling
4. Emit a council `status` message noting the worktree isolation intent

This is primarily a metadata and logging concern — canopy does not manage git
worktrees. The implementation records the intent and removes the conflict block.

```bash
canopy task claim 42 --worktree
# Claim allowed: agent commits to working in an isolated git worktree.
# Scope conflict with task 37 logged but not blocking.
```

#### Verification

```bash
cd canopy && cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `canopy task claim --worktree` allows claim despite scope conflict
- [ ] Worktree intent recorded in task scope metadata
- [ ] Council `status` message records the worktree resolution
- [ ] Conflict is logged (not silently suppressed)

---

### Step 3: Implement `--force` advisory-only conflict resolution

**Project:** `canopy/`
**Effort:** 2–4 hours
**Depends on:** nothing (simplest of the three)

When `canopy task claim <id> --force`:

1. Allow the claim to proceed regardless of scope conflict
2. Log the conflict and the force override as a council `evidence` message
3. Show a warning: "force claim — scope conflict with task <id> not resolved"

This is the escape hatch for cases where the operator knows the conflict is not
real (false positive in scope matching) or has accepted the coordination risk.

```bash
canopy task claim 42 --force
# WARNING: scope conflict with task 37 not resolved.
# Proceeding with advisory-only mode. Conflict logged to task council.
```

#### Verification

```bash
cd canopy && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `canopy task claim --force` proceeds despite conflict
- [ ] Conflict override logged as council evidence message
- [ ] Warning printed to stderr
- [ ] Build and tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build --workspace` and `cargo test --workspace` pass in `canopy/`
3. All three resolution strategies (`--after`, `--worktree`, `--force`) work
4. Each resolution produces an appropriate council message on the task
5. All checklist items are checked

### Final Verification

```bash
cd canopy && cargo test --workspace 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** all tests pass, no failures.

## Context

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsGap #19 in `docs/workspace/ECOSYSTEM-REVIEW.md`. Conflict detection shipped in
v0.3.1 but without resolution paths, detected conflicts are dead ends — the second
agent is simply rejected with no automated path forward. The three resolution
strategies cover the main coordination scenarios: sequential work, isolated work,
and accepted risk. All three are designed already; this is implementation work
against an existing design.
