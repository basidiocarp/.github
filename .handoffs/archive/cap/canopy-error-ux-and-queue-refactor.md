# Cap: Canopy Error UX and Queue Data-Driven Refactor

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/src/pages/canopy/...`
- **Cross-repo edits:** none
- **Non-goals:** performance lazy-loading (covered in `canopy-performance.md`), adding new queue types
- **Verification contract:** run the commands below and the paired verify script
- **Priority:** High

## Problem

The Canopy page has three compounding problems that create the worst UX and code quality surface in Cap:

1. **Error alert flood:** `CanopyPage.tsx` renders 30+ individual `<ErrorAlert>` components, one per queue snapshot. When multiple queues are unavailable (common when Canopy CLI is down), the user sees a wall of identical red alerts before any useful content.

2. **Repetitive variable explosion:** `useCanopyPageState.ts` (476 lines) creates 35+ individual `useCanopySnapshot()` calls with identical structure differing only in the `preset` string. Each is assigned to its own variable.

3. **Prop drilling explosion:** `CanopyPage.tsx` passes each of the 35 queue snapshot objects as individual props to `CanopyQueuesSection`, resulting in ~35 props just for queue data.

## What exists

- **`cap/src/pages/canopy/useCanopyPageState.ts`** — 476 lines, 35 `useCanopySnapshot()` calls
- **`cap/src/pages/canopy/CanopyPage.tsx`** — 378 lines, ~30 `<ErrorAlert>` blocks (lines 95–261)
- **`cap/src/pages/canopy/CanopyQueuesSection.tsx`** — receives all queue snapshots as individual props
- **`cap/src/lib/types/canopy.ts`** — defines `CanopySnapshotPreset` as a 35-member union type
- **Related handoff:** `canopy-performance.md` covers lazy-loading queues and splitting `TaskOperatorActionsSection` — coordinate to avoid conflicts

## What needs doing

### Step 1: Define a queue registry data structure

**New file:** `cap/src/pages/canopy/canopy-queues.ts`

Create a typed array of queue definitions that drives both the state hook and the render:

```typescript
interface QueueDefinition {
  preset: CanopySnapshotPreset
  label: string
  errorTitle: string
}

const CANOPY_QUEUES: QueueDefinition[] = [
  { preset: 'critical', label: 'Critical', errorTitle: 'Critical queue unavailable' },
  // ... all presets derived from the CanopySnapshotPreset union
]
```

### Step 2: Replace the 35 individual snapshot calls with a mapped hook

**New or refactored file:** `cap/src/pages/canopy/useCanopyQueueSnapshots.ts`

Replace the 35 individual `useCanopySnapshot()` calls with a single hook that maps over `CANOPY_QUEUES` and returns a typed array:

```typescript
// Returns { data, error, isLoading, definition }[] — one entry per queue
```

### Step 3: Replace the error alert flood with an aggregated error summary

**New component:** `cap/src/pages/canopy/CanopyQueueErrors.tsx`
**Modified:** `cap/src/pages/canopy/CanopyPage.tsx`

Replace the 30 individual `<ErrorAlert>` blocks with a single component that:
- Shows nothing if all queues succeeded
- Shows a single alert "N queue(s) unavailable" with an expand button
- Lists the individual queue names only on expand

### Step 4: Refactor CanopyQueuesSection to accept the queue array

**File:** `cap/src/pages/canopy/CanopyQueuesSection.tsx`

Change from ~35 individual queue-snapshot props to accepting the queue array from the mapped hook and iterating over it.

### Step 5: Slim useCanopyPageState

**File:** `cap/src/pages/canopy/useCanopyPageState.ts`

Extract the queue snapshot logic into `useCanopyQueueSnapshots` and reduce `useCanopyPageState` to composing it with filter/search/detail state. Target: under 200 lines.

## Verification

```bash
bash .handoffs/cap/verify-canopy-error-ux-and-queue-refactor.sh
```

Manual checks:
- `useCanopyPageState.ts` is under 200 lines
- `CanopyPage.tsx` has at most 3 `<ErrorAlert>` components (one for main snapshot, one for detail, one aggregated queue error)
- `npm run build && npm test && npm run lint:check` all pass

## Checklist

- [ ] Queue registry data structure created in `canopy-queues.ts`
- [ ] `useCanopyQueueSnapshots` hook eliminates the 35 repetitive calls
- [ ] Error alerts replaced with aggregated `CanopyQueueErrors` component
- [ ] `CanopyQueuesSection` accepts queue array instead of 35 individual props
- [ ] `useCanopyPageState.ts` is under 200 lines
- [ ] Build succeeds
- [ ] Tests pass
- [ ] Lint passes
