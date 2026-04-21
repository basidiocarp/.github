# Cap: Charting Library Consolidation and Remaining Unused Dependencies

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/...`
- **Cross-repo edits:** none
- **Non-goals:** restructuring the analytics tab layout or adding new chart types
- **Verification contract:** run the commands below and the paired verify script
- **Priority:** Medium

## Problem

Cap ships two charting libraries: `@mantine/charts` (used in 4 analytics tab files) and `recharts` (used in exactly 1 file: `UsageCostTab.tsx`). This adds unnecessary bundle weight and forces developers to know two APIs. Additionally, `@mantine/dates`, `@mantine/nprogress`, and `@mantine/modals` have zero imports in the codebase but remain in `package.json`. The existing `dependency-cleanup.md` handoff covers Tiptap and spotlight removal but does not cover these items.

## What exists

- `recharts` is imported only in `cap/src/pages/analytics/UsageCostTab.tsx`
- `@mantine/charts` is imported in `CodeIntelligenceTab.tsx`, `MemoryHealthTab.tsx`, `TelemetryTab.tsx`, `TokenSavingsTab.tsx` — these are the reference for the correct pattern
- `@mantine/dates`, `@mantine/nprogress`, `@mantine/modals` — zero imports anywhere in `src/` or `server/`
- `react-force-graph-2d` is imported only in `ConceptGraph.tsx` — legitimate use, keep it

## What needs doing

### Step 1: Migrate UsageCostTab from recharts to @mantine/charts

**File:** `cap/src/pages/analytics/UsageCostTab.tsx`

Replace `Bar`, `BarChart`, `CartesianGrid`, `Line`, `LineChart`, `ResponsiveContainer`, `Tooltip`, `XAxis`, `YAxis` from recharts with the equivalent `BarChart` and `LineChart` components from `@mantine/charts`. The other 4 analytics tab files already demonstrate the correct @mantine/charts usage pattern.

### Step 2: Remove recharts and unused Mantine packages

```bash
cd cap
npm uninstall recharts @mantine/dates @mantine/nprogress @mantine/modals
```

### Step 3: Verify

```bash
cd cap && npm run build && npm test && npm run lint:check
```

## Verification

```bash
bash .handoffs/cap/verify-charting-and-unused-deps-consolidation.sh
```

Manual checks:
- `grep -r "from 'recharts'" cap/src/` returns no results
- `npm run build` succeeds
- `npm test` passes

## Checklist

- [ ] `UsageCostTab.tsx` migrated from recharts to @mantine/charts
- [ ] `recharts` removed from package.json and node_modules
- [ ] `@mantine/dates` removed from package.json
- [ ] `@mantine/nprogress` removed from package.json
- [ ] `@mantine/modals` removed from package.json
- [ ] Build succeeds
- [ ] Tests pass
- [ ] Lint passes
