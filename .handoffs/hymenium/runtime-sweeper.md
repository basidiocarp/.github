# Runtime Sweeper

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** runtime registration, heartbeat emission (volva side), or cap UI surfaces for runtime status
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-runtime-sweeper.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** new `src/sweeper.rs` or within existing dispatch/recovery modules
- **Reference seams:** multica `server/cmd/server/runtime_sweeper.go` for the complete sweeper cycle; existing hymenium retry/recovery logic for integration points
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Hymenium dispatches work to runtimes but has no explicit watchdog cycle that detects stale runtimes, fails orphaned tasks, reconciles agent status, or garbage-collects offline entries. If a runtime disappears mid-task, the task may remain in a running state indefinitely. Multica's runtime sweeper is the most mature external reference for this pattern: a 30-second background cycle with heartbeat timeout at 45 seconds, orphan failure, reconciliation, and 7-day GC.

## What exists (state)

- **`hymenium`:** has retry/recovery logic but no named sweeper cycle with explicit constants
- **`volva`:** emits heartbeats from the runtime side but hymenium does not consume them for liveness detection
- **multica reference:** a complete production-grade sweeper with named constants and four responsibilities

## What needs doing (intent)

Add an explicit named sweeper module to hymenium with four responsibilities:
1. **Heartbeat timeout** — mark runtimes as offline after a configurable missed-heartbeat threshold
2. **Orphan failure** — transition tasks owned by offline runtimes to a failed state with a clear reason
3. **Status reconciliation** — ensure runtime and task states are consistent after the sweep
4. **GC cadence** — remove long-offline runtime entries after a configurable retention period

## Scope

- **Primary seam:** runtime liveness detection and orphan recovery
- **Allowed files:** `hymenium/src/` sweeper and dispatch modules
- **Explicit non-goals:**
  - Do not implement heartbeat emission (that is volva's responsibility)
  - Do not build cap UI for runtime status (separate handoff)
  - Do not change the task state machine beyond adding a sweep-triggered failure transition

---

### Step 1: Define sweeper configuration and runtime liveness model

**Project:** `hymenium/`
**Effort:** 0.5 day
**Depends on:** nothing

Define named constants (configurable) for:
- `SWEEP_INTERVAL` — how often the sweeper runs (default 30s)
- `HEARTBEAT_TIMEOUT` — how long before a runtime is marked offline (default 45s)
- `GC_RETENTION` — how long to keep offline runtime records (default 7 days)

Define a `RuntimeStatus` type if one does not exist: `Online`, `Offline`, `GarbageCollected`.

#### Verification

```bash
cd hymenium && cargo check 2>&1
```

**Checklist:**
- [ ] Named constants are defined and configurable
- [ ] RuntimeStatus type exists with documented variants

---

### Step 2: Implement sweep cycle

**Project:** `hymenium/`
**Effort:** 1 day
**Depends on:** Step 1

Implement the four-phase sweep:
1. Check each runtime's last heartbeat against `HEARTBEAT_TIMEOUT`; mark stale runtimes as `Offline`
2. Find tasks owned by newly-offline runtimes; transition them to failed with reason "runtime went offline"
3. Reconcile: ensure no task claims an online runtime that is actually offline, and vice versa
4. Remove runtime records that have been offline longer than `GC_RETENTION`

The sweep should be non-blocking and log each phase's outcome at trace level.

#### Verification

```bash
cd hymenium && cargo test sweeper 2>&1
```

**Checklist:**
- [ ] Each sweep phase has at least one test case
- [ ] Orphaned tasks are transitioned to failed with a descriptive reason
- [ ] GC only removes entries past the retention threshold
- [ ] Sweep does not panic on empty state

---

### Step 3: Wire sweeper into hymenium runtime

**Project:** `hymenium/`
**Effort:** 0.5 day
**Depends on:** Step 2

Start the sweeper as a background task when hymenium initializes. It should run at `SWEEP_INTERVAL` and be cancellable on shutdown.

#### Verification

```bash
cd hymenium && cargo test 2>&1
cd hymenium && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Sweeper starts on init and stops on shutdown
- [ ] Existing tests pass without regression
- [ ] No new clippy warnings

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/hymenium/verify-runtime-sweeper.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/hymenium/verify-runtime-sweeper.sh
```

## Context

Source: multica ecosystem borrow audit (2026-04-14). The runtime sweeper is described as multica's "most mature watchdog pattern." See `.audit/external/audits/multica-ecosystem-borrow-audit.md` section "Server-side runtime sweeper" for the full reference design.

Related handoffs: pairs with volva heartbeat emission (not yet a handoff). Error classifier taxonomy (#121) handles what happens when the failure is API-level; this handoff handles what happens when the runtime itself disappears.
