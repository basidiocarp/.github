# Cap Canopy Performance And Decomposition

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** cap/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

<!-- Save as: .handoffs/cap/canopy-performance.md -->
<!-- Create verify script: .handoffs/cap/verify-canopy-performance.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

The Canopy route is the main frontend hotspot in `cap/`. `useCanopyPageState` eagerly
creates dozens of snapshot queries, and `TaskOperatorActionsSection` has grown into an
800-line component that mixes action routing, form state, and reset logic.

## What exists (state)

- **State hook:** `cap/src/pages/canopy/useCanopyPageState.ts` creates 37 snapshot queries
- **Page bundle:** `Canopy` is the heaviest route-local chunk in the build output
- **Large component:** `TaskOperatorActionsSection.tsx` is 800 lines

## What needs doing (intent)

Reduce up-front query fan-out on the Canopy page and split the action operator logic
into smaller, testable units.

---

### Step 1: Reduce Snapshot Fan-Out

**Project:** `cap/`
**Effort:** 90 min
**Depends on:** nothing

Refactor Canopy page loading so it does not eagerly create every preset query on first
render. Prefer one of these concrete end states:

- lazy-load preset queries when the related section becomes visible or selected
- or batch related preset snapshots through one server call and one hook

Choose one path and remove the current “37 hooks on first render” pattern.

### Step 2: Split Operator Actions

**Project:** `cap/`
**Effort:** 90 min
**Depends on:** Step 1

Split `TaskOperatorActionsSection.tsx` into smaller hooks/components so action
selection, form state, and mutation wiring are not all in one file.

#### Files to modify

**`cap/src/pages/canopy/useCanopyPageState.ts`** — remove eager snapshot fan-out.

**`cap/src/pages/canopy/TaskOperatorActionsSection.tsx`** — split into smaller units.

**`cap/src/pages/Canopy.test.tsx`** — extend route-level tests for the new loading and
action behavior.

#### Verification

```bash
cd cap && npm run test:frontend && npm run build
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Canopy no longer creates every preset snapshot query on first render
- [ ] Operator actions logic is split into smaller units
- [ ] Frontend tests cover the refactored behavior

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Verification output is pasted above
2. The verification script passes: `bash .handoffs/cap/verify-canopy-performance.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cap/verify-canopy-performance.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

## Context

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsCreated from the completed Cap deep audit on 2026-04-05. This handoff captures the
main structural/performance hotspot from the frontend audit slice.
