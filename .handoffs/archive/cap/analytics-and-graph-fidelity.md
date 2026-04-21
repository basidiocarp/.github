# Cap Analytics And Graph Fidelity

<!-- Save as: .handoffs/cap/analytics-and-graph-fidelity.md -->
<!-- Create verify script: .handoffs/cap/verify-analytics-and-graph-fidelity.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

Cap’s graphs and charts are functional, but several of them are either misleading or
underutilized. The biggest issues are a synthetic host-coverage signal in Usage,
lossy backend/tool-call visualization in Code Intelligence, weak test coverage for
analytics correctness, and graph/chart choices that leave important dimensions of the
data unused.

## What exists (state)

- **Usage tab:** `UsageCostTab.tsx` builds a fake ecosystem status object from session
  presence and feeds it into `getHostCoverageView`
- **Code Intelligence tab:** `CodeIntelligenceTab.tsx` collapses mixed backend state
  into a single KPI label and ignores `avg_duration_ms` from `tool_calls`
- **Memory Health tab:** uses a single stacked bar for importance distribution
- **Graphs:** `ConceptGraph.tsx` and `CallGraph.tsx` render, but only use a subset of
  the available semantics
- **Tests:** `Analytics.test.tsx` only checks top-level links and does not protect
  chart/graph fidelity

## What needs doing (intent)

Audit and improve analytics correctness first, then strengthen the visuals so charts
and graphs reflect the actual data model instead of a reduced or inferred version.

---

### Step 1: Fix Usage Host Coverage Fidelity

**Project:** `cap/`
**Effort:** 60 min
**Depends on:** nothing

Stop deriving host-coverage status in the Usage tab from `sessions`. Instead:

- source host-coverage messaging from real ecosystem status data, or
- clearly downgrade the copy to “runtime presence in usage history” if real host
  status is not available in this tab

The end state must not present inferred session presence as if it were verified host
configuration state.

#### Files to modify

**`cap/src/pages/analytics/UsageCostTab.tsx`** — remove the synthetic host-status
construction path or replace it with a real one.

**`cap/src/pages/Analytics.test.tsx`** or a new focused analytics test — add coverage
for the corrected host-coverage behavior.

#### Verification

```bash
cd cap && npm run test:frontend
```

**Output:**
<!-- PASTE START -->
`npm run test:frontend` passed after the Usage tab change.
Relevant coverage: `src/pages/analytics/UsageCostTab.test.tsx` now verifies the tab is explicitly history-only and no longer implies host configuration state.
<!-- PASTE END -->

**Checklist:**
- [x] Usage tab no longer fabricates host configuration state from session presence
- [x] Copy and badges reflect real status or explicitly scoped history-only coverage
- [x] Frontend tests cover the corrected behavior

---

### Step 2: Improve Code Intelligence Chart Fidelity

**Project:** `cap/`
**Effort:** 75 min
**Depends on:** Step 1

Improve the Rhizome analytics surface so it uses more of the available data:

- show mixed backend state honestly instead of collapsing it to one label
- use `avg_duration_ms` from `tool_calls` somewhere meaningful
- prefer a visualization that supports comparison better than the current pie-only
  view when the tool count grows

Do not remove the current data dimensions from the UI unless they are replaced with a
clearer equivalent.

#### Files to modify

**`cap/src/pages/analytics/CodeIntelligenceTab.tsx`** — improve backend and tool-call
visualization fidelity.

**`cap/src/pages/Analytics.test.tsx`** or a new focused test file — cover the new
rendering logic.

#### Verification

```bash
cd cap && npm run test:frontend && npm run build
```

**Output:**
<!-- PASTE START -->
`npm run test:frontend && npm run build` passed after the Code Intelligence changes.
Rhizome analytics now shows mixed backend state directly, uses `avg_duration_ms`, and compares tool calls with a count-sorted bar chart plus duration table.
<!-- PASTE END -->

**Checklist:**
- [x] Mixed backend state is represented honestly
- [x] Tool-call duration data is surfaced
- [x] Tool-call chart choice remains readable as tool count grows

---

### Step 3: Strengthen Weak Visuals And Graph Utilization

**Project:** `cap/`
**Effort:** 90 min
**Depends on:** Step 2

Review the lowest-signal visuals and upgrade them where the current rendering leaves
useful data on the floor:

- replace or improve the Memory Health importance-distribution chart
- evaluate whether `ConceptGraph` should expose more semantic cues, such as stronger
  edge differentiation or filtering
- evaluate whether `CallGraph` needs a better layout or grouping strategy than the
  current fixed grid

Prefer targeted improvements over broad redesigns.

#### Files to modify

**`cap/src/pages/analytics/MemoryHealthTab.tsx`** — improve the importance
distribution visualization.

**`cap/src/components/ConceptGraph.tsx`** and/or
**`cap/src/components/CallGraph.tsx`** — improve graph fidelity where justified by the
existing data model.

#### Verification

```bash
cd cap && npm run test:frontend && npm run build
```

**Output:**
<!-- PASTE START -->
`npm run test:frontend && npm run build` passed after the memory-health and graph layout updates.
Memory Health now breaks importance into separate comparable buckets, and CallGraph now lays out callers, hubs, callees, and external nodes in distinct columns.
<!-- PASTE END -->

**Checklist:**
- [x] Importance distribution is more informative than a single stacked bar
- [x] Graph improvements use real data semantics, not arbitrary decoration
- [x] Build and frontend tests still pass

---

### Step 4: Add Analytics-Specific Test Coverage

**Project:** `cap/`
**Effort:** 45 min
**Depends on:** Step 3

Add focused tests that protect analytics fidelity:

- usage host-coverage rendering
- code intelligence mixed backend/tool-call rendering
- memory-health chart/summary behavior
- graph empty-state and at least one populated-state contract where practical

The goal is to catch wrong bindings, missing series, and misleading fallbacks.

#### Files to modify

**`cap/src/pages/Analytics.test.tsx`** and/or new focused `analytics/*.test.tsx`
files.

**`cap/src/pages/memoirs/MemoirInspectPanel.test.tsx`** or a new graph-focused test if
ConceptGraph behavior is changed.

**`cap/src/pages/code-explorer/CodeExplorerSymbolBrowser.test.tsx`** or a new
CallGraph-focused test if CallGraph behavior is changed.

#### Verification

```bash
cd cap && npm run test:frontend
```

**Output:**
<!-- PASTE START -->
`npm run test:frontend` passed with focused coverage in `UsageCostTab.test.tsx`, `CodeIntelligenceTab.test.tsx`, `MemoryHealthTab.test.tsx`, and `CallGraph.test.tsx`.
<!-- PASTE END -->

**Checklist:**
- [x] Analytics correctness has direct frontend test coverage
- [x] Graph changes are protected by focused tests where behavior changed
- [x] The test suite checks more than top-level analytics navigation

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cap/verify-analytics-and-graph-fidelity.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cap/verify-analytics-and-graph-fidelity.sh
```

**Output:**
<!-- PASTE START -->
`bash .handoffs/cap/verify-analytics-and-graph-fidelity.sh` passed.
The verifier confirmed the Usage tab no longer synthesizes host status, the Code Intelligence tab exposes richer fidelity, and analytics tests cover behavior beyond top-level links.
<!-- PASTE END -->

## Context

Created from the post-audit Cap review on 2026-04-05 after a final pass over the
analytics and graph surfaces found fidelity issues beyond the existing
`analytics-chart-sizing.md` handoff. Keep this separate from chart sizing: this handoff
is about correctness and utilization, not just rendering warnings.
