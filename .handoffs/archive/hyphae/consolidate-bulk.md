# Hyphae Consolidate Bulk Path

## Problem

`hyphae consolidate` requires `--topic` and operates on a single topic at a time.
There is no `--all` flag, no `--above-threshold` flag, and no `--dry-run` mode.
Running maintenance across a mature hyphae store with many over-threshold topics
requires running the command once per topic, knowing which topics need it, and doing
so manually. This is a CLI ergonomics gap that compounds at scale.

Additionally, the 15-memory consolidation threshold is hardcoded and applied
uniformly. Topics like `errors/active` should stay granular (individual error/resolution
pairs are training data); topics like `exploration` can consolidate aggressively.
Premature consolidation of `errors/active` loses the signal fidelity that makes
those memories useful for training data export.

## What exists (state)

- **CLI:** `hyphae consolidate --topic <t>` — single topic only
- **MCP hint:** consolidation hint appended on recall when threshold exceeded, requires agent action
- **Threshold:** hardcoded 15 in store code
- **No bulk path:** no `--all`, no `--dry-run`, no per-topic config

## What needs doing (intent)

Add `--dry-run` and `--all` / `--above-threshold` flags to `hyphae consolidate`,
and add per-topic threshold override config.

---

### Step 1: Add --dry-run and --all to consolidate CLI

**Project:** `hyphae/`
**Effort:** 1-2 hours

Add to `hyphae consolidate`:
- `--dry-run`: show which topics are above threshold and their memory counts, make no changes
- `--all`: consolidate all topics currently above threshold (prompts for confirmation unless `--yes`)
- `--above-threshold N`: consolidate all topics with ≥N memories (default: configured threshold)

```
$ hyphae consolidate --dry-run
Topics above threshold (15 memories):
  errors/active      — 23 memories
  context/mycelium   — 18 memories
  decisions/canopy   — 16 memories

Run with --all to consolidate all, or --topic <t> to consolidate one.
```

#### Verification

```bash
cd hyphae && cargo test consolidate 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `--dry-run` shows over-threshold topics with counts
- [ ] `--all` consolidates all over-threshold topics
- [ ] Existing `--topic` behavior unchanged

---

### Step 2: Add per-topic threshold config

**Project:** `hyphae/`
**Effort:** 1 hour
**Depends on:** Step 1

Add a `[consolidation]` section to hyphae config:

```toml
[consolidation]
default_threshold = 15

[consolidation.topics]
"errors/active" = "exempt"       # never consolidate
"errors/resolved" = "exempt"     # preserve error/resolution pairs
"exploration" = 8                # consolidate aggressively
```

**Checklist:**
- [ ] Config section recognized
- [ ] Exempt topics never get consolidation hints or consolidate via --all
- [ ] Per-topic thresholds override default

---

## Completion Protocol

1. Every step has verification output pasted
2. All checklist items checked
3. `cd hyphae && cargo test --all` passes

## Context

`IMPROVEMENTS-OBSERVATION-V2.md` and `IMPROVEMENTS-OBSERVATION-V3.md`. The
consolidation hint mechanism requires agent cooperation; this handoff adds an
operator-driven path that doesn't depend on agent availability.
