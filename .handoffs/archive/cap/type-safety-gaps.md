# Cap: Type Safety Gaps

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/src/...`
- **Cross-repo edits:** none
- **Non-goals:** adding Zod or a schema-validation library, changing API shapes
- **Verification contract:** run the commands below and the paired verify script
- **Priority:** Medium

## Problem

Despite TypeScript strict mode being enabled, several type safety holes exist where typed interfaces are erased to `Record<string, unknown>` or `unknown`. These gaps defeat the compile-time safety that the well-typed `lib/types/` layer was designed to provide.

## What exists

### 1. Gain type erasure in DashboardPage

**File:** `cap/src/pages/dashboard/DashboardPage.tsx` (~line 32)

```typescript
const gain = gainQuery.data as Record<string, unknown> | undefined
```

`myceliumApi.gain()` returns `GainResult` (defined in `cap/src/lib/types/mycelium.ts`), a properly typed interface with `avg_savings_pct`, `summary`, etc. The cast to `Record<string, unknown>` forces `DashboardKpis` to do runtime type probing.

### 2. DashboardKpis defensive runtime checks

**File:** `cap/src/pages/dashboard/DashboardKpis.tsx` (~lines 7–13)

```typescript
const nestedSummary = gain?.summary && typeof gain.summary === 'object' ? (gain.summary as Record<string, unknown>) : null
const avgSavingsPct = typeof gain?.avg_savings_pct === 'number' ? ...
```

This entire block collapses to simple optional chaining once `gain` is typed as `GainResult | undefined`.

### 3. Other type erasure instances

`grep -rn "as Record<string, unknown>" cap/src/` — 3 non-test instances exist; each should be reviewed.

## What needs doing

### Step 1: Fix GainResult type flow in DashboardPage

**Files:** `cap/src/pages/dashboard/DashboardPage.tsx`, `cap/src/pages/dashboard/DashboardKpis.tsx`

1. Change `DashboardPage.tsx` to use `GainResult` type directly instead of the `as Record<string, unknown>` cast
2. Update `DashboardKpis` props from `gain: Record<string, unknown> | undefined` to `gain: GainResult | undefined`
3. Replace runtime type probing with direct optional chaining on typed fields

### Step 2: Audit and resolve remaining type erasure

**Files:** Search with `grep -rn "as Record<string, unknown>" cap/src/`

Review each non-test instance. Replace with the real type where it already exists; add a typed interface where it does not.

## Verification

```bash
bash .handoffs/cap/verify-type-safety-gaps.sh
```

Manual checks:
- `grep -n "as Record<string, unknown>" cap/src/pages/dashboard/` returns no results
- `grep "GainResult" cap/src/pages/dashboard/DashboardKpis.tsx` matches
- `npm run build && npm test` pass

## Checklist

- [ ] `GainResult` type flows from `DashboardPage` through to `DashboardKpis` without erasure
- [ ] `DashboardKpis` uses typed field access instead of runtime type probing
- [ ] Other non-test `as Record<string, unknown>` instances reviewed and resolved or documented
- [ ] Build succeeds
- [ ] Tests pass
