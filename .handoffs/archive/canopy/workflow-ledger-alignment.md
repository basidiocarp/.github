# Canopy: Workflow Ledger Alignment

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/...`
- **Cross-repo edits:** none unless this handoff explicitly names a Septa-facing payload change
- **Non-goals:** becoming a second workflow engine, implementing Hymenium lifecycle logic, or building Cap UI
- **Verification contract:** run the repo-local commands below and `bash .handoffs/canopy/verify-workflow-ledger-alignment.sh`
- **Completion update:** once review is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** `src/models.rs`; `src/store/schema.rs`; `src/store/orchestration.rs`; `src/store/tasks.rs`; `src/api.rs`
- **Reference seams:** current task workflow context, task relationships, handoff and evidence surfaces
- **Spawn gate:** do not launch an implementer until the parent agent can name the exact file set and exact repo-local verification commands

## Problem

Canopy already has strong ledger and operator surfaces, but its workflow context is still thin and risks being interpreted as workflow ownership. After the reset, Canopy needs to record workflow membership and phase state without becoming the orchestrator.

## What exists (state)

- **Task ledger:** tasks, evidence, relationships, and review cycles are already strong
- **Workflow context:** current task workflow context carries queue, worktree, review, and session references
- **Dependency support:** relationships exist but are not yet the execution-time projection of Hymenium decomposition

## What needs doing (intent)

Align Canopy around the role of coordination ledger by storing:

- explicit workflow instance and phase references on tasks
- dependency edges emitted from Hymenium decomposition
- semantic handoff context in addition to mechanical queue and review state
- workspace, worktree, and session route identity where that context exists
- task-anchored council or review state where it affects operator understanding of the task

## Scope

- **Primary seam:** workflow linkage and operator-facing task context
- **Allowed files:** `canopy/src/...`, `canopy/tests/...`, `canopy/docs/...`
- **Explicit non-goals:**
  - Do not add workflow transition logic that belongs in Hymenium
  - Do not widen Cap contracts first
  - Do not hide dependency state in freeform notes

---

### Step 1: Add explicit workflow and phase linkage to tasks

**Project:** `canopy/`
**Effort:** 0.5 day
**Depends on:** [Hymenium: Authoritative Workflow Runtime](../hymenium/authoritative-workflow-runtime.md)

Add explicit workflow identity and current phase linkage to task storage and task read models.

#### Verification

```bash
cd canopy && cargo test 2>&1
```

**Checklist:**
- [ ] Tasks can point to workflow instance identity explicitly
- [ ] Tasks can point to current workflow phase explicitly
- [ ] Tasks can surface workspace, worktree, or session linkage without inventing a second workflow state machine
- [ ] Task detail and snapshot surfaces expose that linkage

---

### Step 2: Preserve decomposition dependencies as task relationships

**Project:** `canopy/`
**Effort:** 0.5 day
**Depends on:** Step 1

Project Hymenium decomposition edges into Canopy task relationships so the ledger can explain blockers without re-parsing handoff prose.

#### Verification

```bash
cd canopy && cargo test api_snapshot 2>&1
```

**Checklist:**
- [ ] Dependency edges are stored as first-class relationships
- [ ] Task attention surfaces can explain dependency blockers
- [ ] Snapshot and task detail views show dependency-derived context

---

### Step 3: Store semantic handoff context alongside mechanical context

**Project:** `canopy/`
**Effort:** 0.5 day
**Depends on:** Step 2

Add the semantic handoff context needed to explain goal, boundary, and next steps rather than only queue, worktree, and review metadata.

#### Verification

```bash
cd canopy && cargo check 2>&1
cd canopy && cargo test 2>&1
```

**Checklist:**
- [ ] Canopy can store or project semantic handoff context
- [ ] Task detail can explain what workflow a task belongs to and what blocks it
- [ ] Task detail can show operator-relevant session, review, or council context when it is task-linked
- [ ] Tests pass without regressing current read models

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Canopy reflects workflow membership and dependency context without owning transitions
2. `bash .handoffs/canopy/verify-workflow-ledger-alignment.sh` passes
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion

### Final Verification

```bash
bash .handoffs/canopy/verify-workflow-ledger-alignment.sh
```

## Context

This handoff is the Canopy side of the reset. It is deliberately ledger-shaped: record what happened, explain why the task is where it is, and make the operator view legible without taking workflow authority away from Hymenium. The `vibe-kanban`, `council`, and `claude-squad` audits are useful here because they all reinforce the same point: operator-visible route identity, review state, and session state should be explicit ledger facts, not UI inference.
