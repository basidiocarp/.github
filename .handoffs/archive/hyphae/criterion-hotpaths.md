# Hyphae: Criterion Retrieval Hot Paths

## Problem

The repo-owned tooling handoff for `hyphae/` deliberately deferred `criterion`
until a concrete hot path was named. That decision is no longer open: the
retrieval layer now has clear first-wave benchmark targets.

This follow-up should add only the smallest useful benchmark surface for
`hyphae`, centered on user-visible retrieval latency rather than generic
micro-bench sprawl.

## What exists (state)

- `hyphae` already documents `cargo nextest run` and whole-command timing in
  [README.md](/Users/williamnewton/projects/basidiocarp/hyphae/README.md)
- `hyphae-store` now has a dedicated Criterion bench target for the retrieval
  hot paths
- the strongest first-wave retrieval targets are public APIs:
  - `SqliteStore::search_hybrid_scoped` in
    [memory_store.rs](/Users/williamnewton/projects/basidiocarp/hyphae/crates/hyphae-store/src/store/memory_store.rs#L349)
  - `SqliteStore::search_all` in
    [search.rs](/Users/williamnewton/projects/basidiocarp/hyphae/crates/hyphae-store/src/store/search.rs#L48),
    which exercises the private `search_all_impl` path
- later-wave candidates still exist, but stay out of the first bench file:
  - `apply_decay` in
    [memory_store.rs](/Users/williamnewton/projects/basidiocarp/hyphae/crates/hyphae-store/src/store/memory_store.rs#L1245)
  - `get_neighborhood` in
    [memoir_store.rs](/Users/williamnewton/projects/basidiocarp/hyphae/crates/hyphae-store/src/store/memoir_store.rs#L508)
  - ingest chunking in
    [chunker.rs](/Users/williamnewton/projects/basidiocarp/hyphae/crates/hyphae-ingest/src/chunker.rs#L110)

## What needs doing (intent)

- keep the benchmark surface minimal and deterministic:
  - `search_hybrid_scoped` with in-memory fixtures
  - `search_all` with in-memory fixtures and optional document merge
  - fixed local embedding vectors
  - seeded SQLite state in the bench file itself
  - no network calls or external embedding providers
- leave `apply_decay`, memoir traversal, and ingest chunking out of the first
  wave unless the initial benches or profiling data show they matter next

## Benchmark Scope

### First wave

- `SqliteStore::search_hybrid_scoped`
  - covers the user-visible hybrid ranking path: FTS, vector search, learned
    recall score lookup, static weight bias, and final sort
- `SqliteStore::search_all`
  - covers the higher-level unified retrieval path: memory recall, optional
    shared-memory merge, optional document merge, reciprocal-rank fusion,
    deduplication, and optional code-context expansion

### Not first wave

- `apply_decay`
  - valid later, but it is a batch SQL maintenance operation rather than the
    first user-latency target
- `get_neighborhood`
  - valid later if memoir graph traversal shows up in actual usage or audits
- `chunk_text` / `chunk_by_heading` / `chunk_structured_output`
  - valid later if ingest throughput becomes the active bottleneck

## Verification targets

Run these commands and paste the full output below.

```bash
cd hyphae && cargo bench --no-run -p hyphae-store --bench retrieval_hot_paths
```

**Output:**
<!-- PASTE START -->
    Finished `bench` profile [optimized] target(s) in 28.79s
  Executable benches/retrieval_hot_paths.rs (target/release/deps/retrieval_hot_paths-ad846dd87f33c48d)
<!-- PASTE END -->

```bash
bash .handoffs/archive/hyphae/verify-criterion-hotpaths.sh
```

**Output:**
<!-- PASTE START -->
PASS: file exists - .handoffs/archive/hyphae/criterion-hotpaths.md
PASS: file exists - hyphae/crates/hyphae-store/benches/retrieval_hot_paths.rs
PASS: file exists - hyphae/crates/hyphae-store/Cargo.toml
PASS: pattern 'criterion = "0.5"' found in hyphae/crates/hyphae-store/Cargo.toml
PASS: pattern '\[\[bench\]\]' found in hyphae/crates/hyphae-store/Cargo.toml
PASS: pattern 'retrieval_hot_paths' found in hyphae/crates/hyphae-store/benches/retrieval_hot_paths.rs
PASS: pattern 'search_hybrid_scoped' found in hyphae/crates/hyphae-store/benches/retrieval_hot_paths.rs
PASS: pattern 'search_all' found in hyphae/crates/hyphae-store/benches/retrieval_hot_paths.rs
PASS: pattern 'build_fixture' found in hyphae/crates/hyphae-store/benches/retrieval_hot_paths.rs
PASS: pattern 'SqliteStore::in_memory' found in hyphae/crates/hyphae-store/benches/retrieval_hot_paths.rs
PASS: pattern 'with_ymd_and_hms' found in hyphae/crates/hyphae-store/benches/retrieval_hot_paths.rs
PASS: pattern 'store_document' found in hyphae/crates/hyphae-store/benches/retrieval_hot_paths.rs
PASS: pattern 'store_chunks' found in hyphae/crates/hyphae-store/benches/retrieval_hot_paths.rs
PASS: pattern 'cargo bench --no-run -p hyphae-store --bench retrieval_hot_paths' found in .handoffs/archive/hyphae/criterion-hotpaths.md
PASS: pattern 'search_hybrid_scoped' found in .handoffs/archive/hyphae/criterion-hotpaths.md
PASS: pattern 'search_all' found in .handoffs/archive/hyphae/criterion-hotpaths.md
PASS: pattern 'apply_decay' found in .handoffs/archive/hyphae/criterion-hotpaths.md
PASS: pattern 'get_neighborhood' found in .handoffs/archive/hyphae/criterion-hotpaths.md
PASS: pattern 'chunk_text' found in .handoffs/archive/hyphae/criterion-hotpaths.md
PASS: checked item 'criterion was added only to hyphae-store' found in .handoffs/archive/hyphae/criterion-hotpaths.md
PASS: checked item 'retrieval_hot_paths.rs benchmarks search_hybrid_scoped' found in .handoffs/archive/hyphae/criterion-hotpaths.md
PASS: checked item 'retrieval_hot_paths.rs benchmarks search_all' found in .handoffs/archive/hyphae/criterion-hotpaths.md
PASS: checked item 'the benchmark fixtures are deterministic and network-free' found in .handoffs/archive/hyphae/criterion-hotpaths.md
PASS: checked item 'later-wave candidates are documented but intentionally left out of the first bench target' found in .handoffs/archive/hyphae/criterion-hotpaths.md
PASS: checked item 'the verification output is pasted into this handoff' found in .handoffs/archive/hyphae/criterion-hotpaths.md
PASS: found 2 paste blocks in .handoffs/archive/hyphae/criterion-hotpaths.md
PASS: all 2 paste blocks contain output in .handoffs/archive/hyphae/criterion-hotpaths.md
Results: 27 passed, 0 failed
<!-- PASTE END -->

## Completion checklist

- [x] criterion was added only to hyphae-store
- [x] retrieval_hot_paths.rs benchmarks search_hybrid_scoped
- [x] retrieval_hot_paths.rs benchmarks search_all
- [x] the benchmark fixtures are deterministic and network-free
- [x] later-wave candidates are documented but intentionally left out of the first bench target
- [x] the verification output is pasted into this handoff

## Status

- Added `criterion` only to `hyphae-store`
- Added `benches/retrieval_hot_paths.rs` with deterministic in-memory fixtures
  for `search_hybrid_scoped` and `search_all`
- Verified the benchmark target compiles with `cargo bench --no-run`
- Kept later-wave candidates documented but out of the initial bench scope

## Notes for the implementer

- Do not benchmark the private `search_all_impl` symbol directly from
  `benches/`; benchmark the public `search_all` entry point that exercises it.
- Keep the write scope narrow: this is a `hyphae-store` benchmark task, not a
  repo-wide performance framework project.
- If benchmark setup requires helper constructors or test-only fixture builders,
  keep them local to `hyphae-store` instead of leaking benchmark scaffolding
  into unrelated crates.
