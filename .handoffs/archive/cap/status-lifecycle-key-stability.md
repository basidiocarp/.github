# Cap Status Lifecycle Key Stability

<!-- Save as: .handoffs/cap/status-lifecycle-key-stability.md -->
<!-- Create verify script: .handoffs/cap/verify-status-lifecycle-key-stability.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

The Status page renders lifecycle adapter badges with `key={hook.event}`. When the
live lifecycle list contains repeated event names, React emits duplicate-key warnings
and can mis-reconcile the badge list.

## What exists (state)

- **Component:** `cap/src/pages/status/LifecycleAdaptersCard.tsx`
- **Current key:** `` `${hook.event}-${index}` ``
- **Observed behavior:** duplicate React key warning during live inspection; regression test now guards against it

## What needs doing (intent)

Use a stable unique key for lifecycle badges so repeated events do not collide.

---

### Step 1: Replace The Duplicate Key

**Project:** `cap/`
**Effort:** 20 min
**Depends on:** nothing

Update the badge list key to use a stable unique identifier derived from more than
just the event name, such as event plus adapter path or list index as a last resort.

#### Files to modify

**`cap/src/pages/status/LifecycleAdaptersCard.tsx`** — replace `key={hook.event}`.

**`cap/src/pages/status/StatusHeader.test.tsx`** or a new focused test — add coverage
for repeated lifecycle events.

#### Verification

```bash
cd cap && npm run test:frontend
```

**Output:**
<!-- PASTE START -->
Test Files  1 passed (1)
Tests       1 passed (1)
<!-- PASTE END -->

**Checklist:**
- [x] Lifecycle badges no longer key only on event name
- [x] Repeated lifecycle events are covered by a frontend test
- [x] React duplicate-key warning is eliminated

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Verification output is pasted above
2. The verification script passes: `bash .handoffs/cap/verify-status-lifecycle-key-stability.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cap/verify-status-lifecycle-key-stability.sh
```

**Output:**
<!-- PASTE START -->
Test Files  1 passed (1)
Tests       1 passed (1)
<!-- PASTE END -->

## Context

Created from the completed Cap deep audit on 2026-04-05 after live Status page
inspection exposed a duplicate React key warning.
