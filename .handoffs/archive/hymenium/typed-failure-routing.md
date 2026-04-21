# Hymenium: Typed Failure Routing

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/...`
- **Cross-repo edits:** `septa/...` only if a named failure or outcome contract must be consumed in the same change
- **Non-goals:** repair automation, provider-specific credential pools, or Cap analytics work
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-typed-failure-routing.sh`
- **Completion update:** once review is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** new `src/failure.rs` or similar; `src/retry.rs`; `src/monitor/`; `src/dispatch/`
- **Reference seams:** current monitor and retry modules and the existing error-classifier direction
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

The current recovery path mostly knows that work stalled or failed. It does not reliably know whether the root cause was ambiguity, scope violation, missing dependency, contract mismatch, or incomplete execution. That makes retries blunt and prevents the system from learning.

## What exists (state)

- **Retry policy:** exists, but mostly routes from coarse progress signals
- **Monitor:** can detect some stall reasons
- **Research baseline:** already defines the failure taxonomy and escalation logic to target

## What needs doing (intent)

Add a typed failure layer that:

- classifies workflow failures into a small stable taxonomy
- records workflow outcomes in a machine-readable form
- routes retry, escalation, and future repair decisions from those typed failures

## Scope

- **Primary seam:** workflow failure typing and recovery routing
- **Allowed files:** `hymenium/src/...`, `hymenium/tests/...`
- **Explicit non-goals:**
  - Do not implement repair automation in this handoff
  - Do not hide failure type in only freeform strings
  - Do not widen the failure taxonomy before the canonical categories are wired

---

### Step 1: Define the canonical workflow failure taxonomy

**Project:** `hymenium/`
**Effort:** 2-4 hours
**Depends on:** [Septa: Orchestration Contract Reset](../septa/orchestration-contract-reset.md)

Introduce stable failure kinds aligned to the research baseline:

- `SpecAmbiguity`
- `TaskTooLarge`
- `MissingDependency`
- `ExecutionIncomplete`
- `ScopeViolation`
- `ContractMismatch`
- `MinorDefect`

#### Verification

```bash
cd hymenium && cargo test failure 2>&1
```

**Checklist:**
- [ ] Failure taxonomy exists in code as a typed enum
- [ ] Tests cover each canonical failure kind
- [ ] The taxonomy is small and intentionally named

---

### Step 2: Route recovery from typed failures

**Project:** `hymenium/`
**Effort:** 0.5 day
**Depends on:** Step 1

Replace or augment the generic retry path so escalation, retry, or no-op decisions are driven by typed failures rather than only coarse stall categories.

#### Verification

```bash
cd hymenium && cargo test retry 2>&1
```

**Checklist:**
- [ ] Retry policy can branch on typed failure kinds
- [ ] Ambiguity and contract mismatch escalate instead of blindly retrying
- [ ] Incomplete execution can retry only when it is actually safe to do so

---

### Step 3: Record workflow outcomes for later learning

**Project:** `hymenium/`
**Effort:** 0.5 day
**Depends on:** Step 2

Emit outcome records that preserve failure type, attempt count, route taken, confidence, and root-cause layer so later analytics are not forced to reverse-engineer them.

#### Verification

```bash
cd hymenium && cargo check 2>&1
cd hymenium && cargo test 2>&1
cd hymenium && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Outcome records preserve typed failure information
- [ ] Retry and escalation paths record route decisions explicitly
- [ ] Tests and clippy pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Failure routing is typed instead of mostly string- or stall-driven
2. `bash .handoffs/hymenium/verify-typed-failure-routing.sh` passes
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion

### Final Verification

```bash
bash .handoffs/hymenium/verify-typed-failure-routing.sh
```

## Context

This handoff deliberately stops before repair automation. The system should first become truthful about why work failed before it tries to automate more recovery.
