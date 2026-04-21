# Replay and Eval Surfaces

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

## Problem

Cap provides read-only views of ecosystem state but no way to replay sessions, run evaluations, or intervene in active workflows. Operators can see what happened but can't re-run, compare, or evaluate outcomes. The platform layer model flags this as a gap in the Authoring / Operator Surface.

## What exists (state)

- **cap**: memory browser, token analytics, multi-host status. All read-only.
- **hyphae evaluate**: CLI command that measures agent improvement over a time window. Not surfaced in cap.
- **hyphae retrieval benchmarks**: planned (#86) but not surfaced in cap.
- **cortina**: captures session outcomes but cap doesn't render a session timeline.
- **No replay harness, no A/B comparison, no eval dashboard.**

## What needs doing (intent)

Add evaluation, session timeline, and comparison surfaces to cap — giving operators temporal and evaluative views that reveal whether the ecosystem is making agents better over time.

---

### Step 1: Surface hyphae evaluate in cap

**Project:** `cap/`
**Effort:** 1-2 days
**Depends on:** nothing

Add an evaluation panel to cap that runs `hyphae evaluate --days <N> --format json` and renders the results:
- Agent improvement metrics over time.
- Memory effectiveness breakdown.
- Retrieval quality indicators (when benchmark runners from #86 are available).
- Trend chart showing improvement over multiple evaluation periods.

#### Verification

```bash
cd cap && npm run build && npm test
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Evaluation panel renders hyphae evaluate output
- [ ] Time period selector (7/14/30 days)
- [ ] Graceful handling when hyphae is not available

---

### Step 2: Add session timeline view

**Project:** `cap/`
**Effort:** 2-3 days
**Depends on:** Step 1

Render a chronological timeline of session events from hyphae and cortina:
- Recalls, errors, corrections, fixes, session summaries in time order.
- Filter by project, date range, agent (when #89 scoped journals land).
- Click-through to memory details.

This is the session replay surface — not re-execution, but reviewing what happened in sequence.

#### Verification

```bash
cd cap && npm run build && npm test
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Timeline renders session events chronologically
- [ ] Filtering by project and date range works
- [ ] Events link to underlying memory/signal details

---

### Step 3: Add evaluation comparison view

**Project:** `cap/`
**Effort:** 1 day
**Depends on:** Step 1

Allow operators to compare two evaluation periods side-by-side:
- "Last 7 days" vs "Previous 7 days".
- Highlight improvements and regressions.
- Surface which memories contributed to improvements (when #63 recall scoring is available).

#### Verification

```bash
cd cap && npm run build && npm test
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Side-by-side comparison renders
- [ ] Improvements and regressions are visually highlighted

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cap/verify-replay-eval-surfaces.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cap/verify-replay-eval-surfaces.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete with failures.

## Context

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom platform-layer-model.md Layer 6 gaps. Cap currently provides static read views. This handoff adds the temporal and evaluative surfaces that operators need to understand whether the ecosystem is actually making agents better over time.
