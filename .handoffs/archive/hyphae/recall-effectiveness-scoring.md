# Hyphae Recall Effectiveness Scoring Job

## Problem

The recall effectiveness infrastructure is fully wired: `recall_events`,
`outcome_signals`, and `recall_effectiveness` tables all exist. The hybrid search
ranking applies a `0.12 * learned_score` boost at query time (`memory_store.rs:891`).
But nothing populates `recall_effectiveness` — no scoring job runs. The boost factor
is live but always multiplies zero. The complete algorithm is specified in
`docs/FEEDBACK-LOOP-DESIGN.md`.

## What exists (state)

- **Tables:** `recall_events`, `outcome_signals`, `recall_effectiveness` — all created in `schema.rs`
- **Boost:** `0.3 * fts_score + 0.7 * vec_score + static_weight_bias + 0.12 * learned_score` (`memory_store.rs:891`)
- **Design doc:** `hyphae/docs/FEEDBACK-LOOP-DESIGN.md` — complete algorithm with SQL
- **Missing:** the scoring job that reads `recall_events` + `outcome_signals` and writes `recall_effectiveness`

## What needs doing (intent)

Implement the session-end scoring job that populates `recall_effectiveness` so the
0.12 boost actually does something.

---

### Step 1: Implement per-recall effectiveness scoring

**Project:** `hyphae/`
**Effort:** 2-3 hours

Add `score_recall_effectiveness(session_id: &str)` to the store, called from
`session_end`. The algorithm from `FEEDBACK-LOOP-DESIGN.md` §3.1:

```
For each recall_event R in session:
  window = R.recalled_at .. min(session.ended_at, R.recalled_at + 60min)
  signals = outcome_signals WHERE session_id = R.session_id AND occurred_at IN window
  positive_sum = sum(signal_value > 0)
  negative_sum = sum(signal_value < 0)
  raw_score = (positive_sum + negative_sum) / max(|pos| + |neg|, 1)  -- [-1, 1]

  For each memory_id at position i in R.memory_ids (JSON array):
    position_factor = 1.0 / (1.0 + 0.3 * i)
    UPSERT recall_effectiveness (memory_id, recall_event_id, effectiveness, signal_count, computed_at)
```

#### Files to modify

**`crates/hyphae-store/src/store/feedback.rs`** (or `memory_store.rs`) — add scoring function.

**`crates/hyphae-store/src/store/mod.rs`** — call `score_recall_effectiveness` at the end of `session_end`.

#### Verification

```bash
cd hyphae && cargo test recall_effectiveness 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `score_recall_effectiveness` called on `session_end`
- [ ] `recall_effectiveness` rows written for sessions with recall events
- [ ] Test: session with test-pass signal → positive effectiveness score
- [ ] Test: session with correction signal → negative contribution
- [ ] Test: session with no outcome signals → zero effectiveness (not an error)

---

### Step 2: Add aggregate effectiveness lookup

**Project:** `hyphae/`
**Effort:** 1 hour
**Depends on:** Step 1

The hybrid search calls `recall_effectiveness_for_memory_ids` at query time
(`memory_store.rs:873`). Verify this aggregates across multiple recall events with
recency weighting as specified in `FEEDBACK-LOOP-DESIGN.md` §3.2:

```
For memory M, aggregate with exponential recency weighting:
  recency_half_life = 14 days
  aggregate += effectiveness * exp(-age_days / (recency_half_life / ln(2)))
```

If the current implementation returns raw single-event scores, update it.

#### Verification

```bash
cd hyphae && cargo test hybrid_search 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `recall_effectiveness_for_memory_ids` applies recency weighting across multiple events
- [ ] A memory recalled 3 months ago with positive score ranks lower than same memory recalled last week
- [ ] Hybrid search test passes

---

## Completion Protocol

1. Every step has verification output pasted
2. All checklist items checked
3. `cd hyphae && cargo test --all` passes

## Context

`hyphae/docs/FEEDBACK-LOOP-DESIGN.md` contains the complete algorithm. The boost
factor (0.12) is already in hybrid search at `memory_store.rs:891`. This handoff
wires the data supply that makes the boost non-zero. Priority: High — the entire
feedback loop depends on this.
