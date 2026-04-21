# Cap Analytics Chart Sizing

<!-- Save as: .handoffs/cap/analytics-chart-sizing.md -->
<!-- Create verify script: .handoffs/cap/verify-analytics-chart-sizing.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

Analytics charts render, but the browser console warns about containers measuring
`width(-1)` or `height(-1)`. The charts are working now, but the responsive sizing path
is brittle and can break on layout changes.

## What exists (state)

- **Chart wrapper:** `cap/src/pages/analytics/ChartBox.tsx`
- **Observed warning path:** `ChartBox.tsx` and `UsageCostTab.tsx`
- **Current behavior:** charts still render despite the warnings

## What needs doing (intent)

Stabilize chart container sizing so Recharts no longer measures negative dimensions.

---

### Step 1: Tighten Chart Container Layout

**Project:** `cap/`
**Effort:** 45 min
**Depends on:** nothing

Inspect the chart wrapper and parent layout constraints, then ensure the chart only
mounts once it has a valid non-negative width and height.

#### Files to modify

**`cap/src/pages/analytics/ChartBox.tsx`** — guard or normalize the responsive
container sizing path.

**`cap/src/pages/analytics/UsageCostTab.tsx`** and other affected chart tabs — adjust
layout assumptions if needed.

#### Verification

```bash
cd cap && npm run build && npm run test:frontend
```

**Output:**
<!-- PASTE START -->

Build passed.
Test Files  26 passed (26)
Tests       94 passed (94)
Duration    73.43s

<!-- PASTE END -->

**Checklist:**
- [x] Analytics charts no longer warn about negative dimensions
- [x] Chart containers still render after the sizing change
- [x] Frontend verification still passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Verification output is pasted above
2. The verification script passes: `bash .handoffs/cap/verify-analytics-chart-sizing.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cap/verify-analytics-chart-sizing.sh
```

**Output:**
<!-- PASTE START -->

Build passed.
Test Files  26 passed (26)
Tests       94 passed (94)
Duration    73.43s

<!-- PASTE END -->

## Status

Complete. `UsageCostTab` now uses explicit non-negative Recharts initial dimensions,
`ChartBox` now fills the available width, and the Cap build/test verifier passes.

## Context

Created from the completed Cap deep audit on 2026-04-05 after live Analytics route
inspection showed repeated Recharts sizing warnings.
