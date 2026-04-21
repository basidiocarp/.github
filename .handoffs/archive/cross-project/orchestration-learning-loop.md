# Cross-Project: Orchestration Learning Loop

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cross-project`
- **Allowed write scope:** `septa/...`, `hymenium/...`, `canopy/...`
- **Cross-repo edits:** only the named repos above
- **Non-goals:** model training, Cap dashboards, or speculative policy tuning before truthful outcome data exists
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-orchestration-learning-loop.sh`
- **Completion update:** once review is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `septa` for the outcome shape, then `hymenium` and `canopy` for emission and storage
- **Likely files/modules:** outcome schemas and fixtures in `septa/`; workflow outcome emission in `hymenium/`; ledger or query surfaces in `canopy/`
- **Reference seams:** existing evidence and task event surfaces in Canopy and the reset outcome contract in Septa
- **Spawn gate:** do not launch an implementer until the parent agent can name the exact schema, emitter, and storage surfaces

## Problem

The orchestration baseline wants the system to improve from outcome data, but the current surfaces do not yet preserve enough truthful structure to support safe tuning. If the learning loop is added too early, it will optimize on noisy or fake success.

## What exists (state)

- **Research baseline:** already defines the desired metrics and feedback fields
- **Canopy:** can store rich task and evidence history but not yet the full orchestration outcome record
- **Hymenium:** will emit richer typed outcomes after the reset work ahead of this handoff

## What needs doing (intent)

Create a minimal but truthful learning loop that records:

- task or workflow class
- assigned tier or capability path
- failure type
- attempt count
- route taken
- confidence
- root-cause layer
- runtime, session, or workspace identity when those facts explain the route that was taken

Then make those outcomes queryable without immediately turning them into automatic global policy changes.

## Scope

- **Primary seam:** truthful orchestration outcome collection and summary
- **Allowed files:** `septa/...`, `hymenium/...`, `canopy/...`
- **Explicit non-goals:**
  - Do not auto-tune routing globally in this handoff
  - Do not learn from silent repairs
  - Do not build a large analytics UI first

---

### Step 1: Finalize the outcome record shape

**Project:** `septa/`
**Effort:** 2-4 hours
**Depends on:** [Hymenium: Typed Failure Routing](../hymenium/typed-failure-routing.md)

Make sure the workflow outcome contract captures the fields needed for the first truthful feedback loop.

#### Verification

```bash
cd septa && bash validate-all.sh
```

**Checklist:**
- [ ] Outcome schema captures failure type, route taken, attempt count, confidence, and root-cause layer
- [ ] Outcome schema captures runtime or session-threading identity needed to explain a route retrospectively
- [ ] Fixture validates
- [ ] Field names are stable and intentionally small

---

### Step 2: Emit outcomes from Hymenium and store them visibly

**Project:** `hymenium/`, `canopy/`
**Effort:** 0.5 day
**Depends on:** Step 1

Emit the outcome record from Hymenium and store or surface it in Canopy so operator and future policy work can query it directly.

#### Verification

```bash
cd hymenium && cargo test 2>&1
cd canopy && cargo test 2>&1
```

**Checklist:**
- [ ] Hymenium emits typed outcomes
- [ ] Canopy can query or display the stored outcomes
- [ ] Test coverage exists on both sides

---

### Step 3: Add a narrow summary surface for policy review

**Project:** `canopy/` or `hymenium/`
**Effort:** 2-4 hours
**Depends on:** Step 2

Expose a narrow summary or CLI view for outcome counts by task class, failure type, and route taken so future policy tuning has an observable baseline.

#### Verification

```bash
rg -n "failure_type|attempt_count|root_cause_layer|route_taken" septa hymenium canopy
```

**Checklist:**
- [ ] A narrow summary surface exists
- [ ] It is derived from truthful stored outcome records
- [ ] It can group outcomes by runtime or session route when that is materially relevant
- [ ] It does not auto-modify routing policy yet

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. The reset path produces truthful outcome records
2. `bash .handoffs/cross-project/verify-orchestration-learning-loop.sh` passes
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion

### Final Verification

```bash
bash .handoffs/cross-project/verify-orchestration-learning-loop.sh
```

## Context

This is the last major child handoff in the reset sequence. It should land after the contracts, runtime authority, ledger alignment, typed failures, and capability routing are already truthful.
