# Retrieval Benchmark Runners

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Hyphae has `hyphae evaluate` but no reproducible benchmark runners with expected outputs and documented miss-pattern fixes. Mempalace ships LongMemEval, LoCoMo, and ConvoMem runners in-tree. Retrieval quality is not a measurable product surface in the basidiocarp ecosystem today — you cannot improve ranking if you cannot measure it.

## What exists (state)

- **`hyphae evaluate`**: exists but not a reproducible benchmark suite; no fixture format, no regression tracking
- **`hyphae-core/`**: search and ranking logic with no associated quality baselines
- **`mycelium/`**: reporting surfaces under development (handoff #59), no benchmark integration yet

## What needs doing (intent)

Create a `benchmarks/` directory in hyphae with a fixture-driven benchmark runner, regression tracking between runs, and documented miss-pattern fixes. This is the foundation for handoff #63 (Recall Effectiveness Scoring) — scoring requires a measurement baseline first.

---

### Step 1: Design benchmark framework

**Project:** `hyphae/`
**Effort:** 1 day
**Depends on:** nothing

Create `hyphae/benchmarks/` with a runner that loads fixture data into a temporary hyphae database, runs queries, and compares results against expected outputs.

Fixture format — JSON files with two top-level keys:
- `memories`: array of objects to seed (`topic`, `content`, `importance`, `created_at_offset_days`)
- `queries`: array of objects with `query`, `expected_memory_ids` or `expected_content_contains`, and optional `description`

Results format: pass/fail per query, recall@k metrics (k=1, k=3, k=5), latency per query.

Start with hand-crafted fixtures covering the scenarios hyphae actually encounters:
1. **Recent error recall** — store an error, query by description; expect it surfaces at rank 1
2. **Decision recall** — store an architectural decision, query by topic; expect it in top 3
3. **Temporal ordering** — store memories at different ages, verify recency ranking
4. **Cross-topic retrieval** — store across topics, verify relevance beats topic boundary
5. **Noise resistance** — store many low-relevance memories, verify high-relevance ones surface above them

#### Files to create

**`hyphae/benchmarks/fixtures/recent-error-recall.json`** — fixture for scenario 1
**`hyphae/benchmarks/fixtures/decision-recall.json`** — fixture for scenario 2
**`hyphae/benchmarks/fixtures/temporal-ordering.json`** — fixture for scenario 3
**`hyphae/benchmarks/fixtures/cross-topic-retrieval.json`** — fixture for scenario 4
**`hyphae/benchmarks/fixtures/noise-resistance.json`** — fixture for scenario 5

**`hyphae/benchmarks/runner.rs`** (or `tests/benchmarks.rs`) — loads fixtures, seeds temp database, runs queries, compares results, prints report.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd hyphae && cargo test --workspace 2>&1 | tail -15
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `benchmarks/` directory exists with fixture format documented
- [ ] At least 5 fixture files covering the scenarios above
- [ ] Runner loads fixtures, seeds database, runs queries, compares results
- [ ] Results report pass/fail and recall@k metrics
- [ ] `cargo test --test benchmarks` runs the suite (or equivalent)

---

### Step 2: Add regression tracking

**Project:** `hyphae/`
**Effort:** 4-8 hours
**Depends on:** Step 1

Store benchmark results over time so retrieval regressions are visible:
- After each benchmark run, write results to `hyphae/benchmarks/results/benchmark_results.json` (or a dedicated SQLite table in the hyphae store)
- `hyphae benchmark --compare` shows current vs previous run delta
- Failed benchmarks that were previously passing are flagged as regressions with a clear label

When a benchmark first fails, document the miss pattern and its fix alongside the fixture — creating a record of what went wrong and how the ranking was corrected. This is the failure-driven tuning loop from mempalace.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd hyphae && cargo test --workspace 2>&1 | tail -15
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Benchmark results are persisted between runs
- [ ] `hyphae benchmark --compare` shows regressions
- [ ] At least one benchmark documents a known miss pattern and its fix

---

### Step 3: Wire into mycelium reporting (optional, deferred)

**Project:** `mycelium/`
**Effort:** 2-4 hours
**Depends on:** Step 1, and handoff #59 (Mycelium: Deterministic Telemetry Summary Surfaces)

If mycelium gains a reporting surface for ecosystem health (handoff #59), benchmark results from hyphae could be surfaced there. This step is optional and should only be implemented if #59 is in progress.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd mycelium && cargo build --release 2>&1 | tail -5
cargo test 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Decision recorded: wired into mycelium OR explicitly deferred with justification

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/hyphae/verify-retrieval-benchmarks.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/hyphae/verify-retrieval-benchmarks.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete with failures.

## Context

From mempalace borrow audit. Mempalace ships LongMemEval/LoCoMo/ConvoMem runners in-tree. The basidiocarp ecosystem currently cannot measure retrieval quality reproducibly.

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsThis handoff is the prerequisite for handoff #63 (Recall Effectiveness Scoring) — scoring requires a measurement baseline first. Step 3 is intentionally deferred until handoff #59 advances.
