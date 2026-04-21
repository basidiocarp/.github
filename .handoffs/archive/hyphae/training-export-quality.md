# Hyphae Training Export Quality Flags

## Problem

`hyphae export-training` exports SFT/DPO pairs without quality filtering. A memory
stored once, never recalled, with weight 0.31 exports identically to a memory recalled
10 times that resolved real errors. The custom SQL example in the docs manually adds
`AND weight > 0.3`, acknowledging the need but leaving it off the CLI. Additionally,
recall effectiveness scores (which indicate memories that demonstrably helped before
successful outcomes) are not used as an export quality signal at all.

Training on degraded data is worse than training on less data.

## What exists (state)

- **CLI:** `hyphae export-training --topic <t> --output <file> --format sft|dpo|alpaca`
- **No quality flags:** no `--min-weight`, no `--min-recalls`, no `--min-effectiveness`
- **Effectiveness data:** `recall_effectiveness` scores exist in the store (Phase 3 shipped)
- **Docs example:** manually adds `AND weight > 0.3` in custom SQL — acknowledges the gap

## What needs doing (intent)

Add quality filtering flags to `hyphae export-training` and default to reasonable
minimums so the default export produces useful training data.

---

### Step 1: Add --min-weight and --min-recalls flags

**Project:** `hyphae/`
**Effort:** 1 hour

Add to `hyphae export-training`:
- `--min-weight <f>`: only export memories with weight ≥ f (default: 0.5)
- `--min-recalls <n>`: only export memories recalled ≥ n times (default: 1)
- `--min-effectiveness <f>`: only export memories with effectiveness score ≥ f (default: no filter)

The defaults should be conservative enough to filter out noise without being too
aggressive. Existing behavior (no filtering) accessible via `--min-weight 0 --min-recalls 0`.

#### Verification

```bash
cd hyphae && cargo test export_training 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `--min-weight` filters by weight threshold
- [ ] `--min-recalls` filters by recall count
- [ ] `--min-effectiveness` filters by effectiveness score
- [ ] Default export uses `--min-weight 0.5 --min-recalls 1`
- [ ] Explicit `--min-weight 0 --min-recalls 0` restores old behavior

---

### Step 2: Prefer high-effectiveness memories for DPO pairs

**Project:** `hyphae/`
**Effort:** 1 hour
**Depends on:** Step 1

For DPO format, the "chosen" example should prefer memories with positive
effectiveness scores (recalled before successful outcomes). Add logic so DPO
export ranks candidate pairs by effectiveness score descending when selecting
the "chosen" side of a training pair.

**Checklist:**
- [ ] DPO export uses effectiveness score to prefer high-signal chosen examples
- [ ] Test: DPO export with effectiveness data ranks positive examples correctly

---

## Completion Protocol

1. Every step has verification output pasted
2. All checklist items checked
3. `cd hyphae && cargo test --all` passes

## Context

`IMPROVEMENTS-OBSERVATION-V3.md`. The recall effectiveness data is already being
captured (Phase 1) and reportedly influencing rankings with a small bias (Phase 3
per changelog). Using it as an export quality signal requires no new data collection.
