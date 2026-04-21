# Cap: Data Loading and UX State Consistency

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/src/...`
- **Cross-repo edits:** none
- **Non-goals:** adding new page components, changing the routing structure
- **Verification contract:** run the commands below and the paired verify script
- **Priority:** Low

## Problem

Cap pages handle loading, error, and empty states inconsistently. Some pages (Status, Sessions) use early-return patterns with rich empty states and retry guidance. Others (Dashboard) load all queries in parallel but show a generic "Failed to load" on any single failure, losing all data for the user. The Canopy page has no empty state for when no tasks exist.

## What exists

### Current per-page patterns

| Page | Loading | Error | Empty |
|------|---------|-------|-------|
| Status | `PageLoader` → `ToolingUnavailableState` with retry | Rich error with guidance | Rich empty state |
| Sessions | `PageLoader` → `ErrorAlert` | Descriptive | Rich empty state with explanation |
| Dashboard | `PageLoader` for all 4 queries | Generic "Failed to load" loses everything | None for missing stats |
| Canopy | `PageLoader` for main snapshot only | 30+ individual alerts | None for zero tasks |
| Memories | Inline spinner | None | `MemoryBrowseView` as no-query state |

The `ToolingUnavailableState` and rich empty-state pattern from the Status page is the best pattern in Cap — standardize on it.

## What needs doing

### Step 1: Fix DashboardPage error and empty handling

**File:** `cap/src/pages/dashboard/DashboardPage.tsx`

- Replace the generic "Failed to load" string with the specific failing query name (stats vs gain vs sessions vs status)
- Consider partial rendering: if `stats` loaded but `gain` failed, show stats KPIs with a badge indicating gain data is unavailable rather than losing everything
- Add empty state for when `stats` is null after loading completes

### Step 2: Add CanopyPage empty state

**File:** `cap/src/pages/canopy/CanopyPage.tsx`

After the snapshot loads, if `filteredTasks` is empty and no search filters are active, show an `EmptyState` or `ToolingUnavailableState` explaining that no tasks exist yet. Reference the Status page pattern.

### Step 3: Audit remaining pages for consistency

**Files:** All files in `cap/src/pages/`

Walk through each page and ensure the loading → error → empty → data pattern is consistent. Document any intentional deviations as comments.

## Verification

```bash
bash .handoffs/cap/verify-data-loading-ux-consistency.sh
```

Manual checks:
- `grep "Failed to load" cap/src/pages/dashboard/DashboardPage.tsx` returns no results
- CanopyPage renders an empty state when tasks are empty and no filters are active
- `npm run build && npm test` pass

## Checklist

- [ ] DashboardPage shows specific error messages per failing query (not generic "Failed to load")
- [ ] DashboardPage handles partial data (some queries succeed, some fail)
- [ ] DashboardPage has an empty state when stats are absent after load
- [ ] CanopyPage has an empty state for zero tasks with no filters
- [ ] All pages audited for loading/error/empty consistency
- [ ] Build succeeds
- [ ] Tests pass
