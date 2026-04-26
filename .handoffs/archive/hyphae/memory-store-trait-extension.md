# Hyphae: MemoryStore Trait Extension and CLI Migration

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/crates/hyphae-core/src/store.rs`, `hyphae/crates/hyphae-store/src/store/memory_store.rs`, `hyphae/crates/hyphae-cli/src/commands/memory.rs`
- **Cross-repo edits:** none
- **Non-goals:** does not migrate chunk, document, session, or purge operations (those need separate sub-traits); does not change MCP tool signatures or septa schemas; does not rename or restructure the existing trait
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Context

W2c (Pluggable Backend Adapters, completed 2026-04-24) added `HYPHAE_BACKEND` env var support and migrated `extract.rs` to `&dyn MemoryStore`. However, the 25 CLI command files that still use `&SqliteStore` are blocked because they call "extended-options" methods not present in the `MemoryStore` trait.

This handoff resolves the blocker for the largest group: `memory.rs` commands. It extends `MemoryStore` with the `_with_options` variants already implemented by `SqliteStore`, then migrates `memory.rs` to use `&dyn MemoryStore`.

A companion handoff would handle the remaining files (`purge.rs`, `watch.rs`, `docs.rs`, chunk/doc/session operations) once sub-traits are defined — but that's out of scope here.

## Problem

`hyphae-cli/src/commands/memory.rs` contains ~15 public command functions that take `store: &SqliteStore`. They cannot be switched to `&dyn MemoryStore` because they call methods with extended option parameters (`_with_options` variants) not present in the `MemoryStore` trait. This ties the CLI to the concrete SQLite type and makes the `HYPHAE_BACKEND` factory inert for all memory commands.

## What exists (state)

- **`MemoryStore` trait** (`hyphae-core/src/store.rs`): 20+ methods covering CRUD, basic search, decay, topics, and lifecycle hooks. Does NOT include `_with_options` variants.
- **`SqliteStore`** (`hyphae-store/src/store/memory_store.rs:781`): Implements `MemoryStore` AND defines additional `_with_options` methods as inherent methods — not part of the trait.
- **`memory.rs`** (`hyphae-cli/src/commands/memory.rs`): All public command functions take `store: &SqliteStore`. Calls these inherent methods:
  - `store.get_by_topic_with_options(topic, project, include_invalidated, limit, offset)`
  - `store.search_fts_with_options(query, limit, offset, project, include_invalidated, order)`
  - `store.search_fts_count_with_options(query, project, include_invalidated)`
  - `store.stats_with_options(project, include_invalidated)`
  - `store.list_topics_with_options(project, include_invalidated)`
  - `store.topic_health_with_options(topic, project, include_invalidated)`

## What needs doing (intent)

1. Add the six `_with_options` methods to the `MemoryStore` trait in `hyphae-core/src/store.rs`, using the exact signatures already implemented by `SqliteStore`.
2. Update `StubStore` (in `hyphae-core/src/store.rs` tests) to implement the new methods with minimal stubs.
3. Confirm `SqliteStore` already implements them (it does — just moves them from inherent to trait).
4. Update all function signatures in `memory.rs` from `store: &SqliteStore` to `store: &dyn MemoryStore`.

## Scope

- **Primary seam:** `MemoryStore` trait in `hyphae-core` and its usage in `memory.rs`
- **Allowed files:**
  - `hyphae/crates/hyphae-core/src/store.rs`
  - `hyphae/crates/hyphae-store/src/store/memory_store.rs`
  - `hyphae/crates/hyphae-cli/src/commands/memory.rs`
- **Explicit non-goals:**
  - Do NOT touch `purge.rs`, `watch.rs`, `docs.rs`, `audit.rs`, or any other command file
  - Do NOT change the existing trait methods — only add the six new ones
  - Do NOT rename `MemoryStore`
  - Do NOT create a new sub-trait (that's a future handoff)

---

### Step 0: Read the existing method signatures

**Project:** `hyphae/`
**Effort:** 15 min
**Depends on:** nothing

Before writing any code, read the exact signatures of the six methods as they appear on `SqliteStore` (inherent) and confirm they are not already in the `MemoryStore` trait.

```bash
grep -n "with_options\|_with_opts" hyphae/crates/hyphae-store/src/store/memory_store.rs | head -30
grep -n "with_options\|_with_opts" hyphae/crates/hyphae-core/src/store.rs | head -10
```

**Checklist:**
- [ ] Exact signatures identified for all six methods
- [ ] Confirmed they are NOT in `MemoryStore` yet

---

### Step 1: Add six methods to `MemoryStore` trait

**Project:** `hyphae/crates/hyphae-core/`
**Effort:** 30 min
**Depends on:** Step 0

In `hyphae-core/src/store.rs`, add the six methods to the `MemoryStore` trait. Use the exact types already used by `SqliteStore`. Place them after the existing search methods in the trait body.

Rough shape — adjust types to match the actual signatures found in Step 0:

```rust
// Extended search variants with filter options
fn get_by_topic_with_options(
    &self,
    topic: &str,
    project: Option<&str>,
    include_invalidated: bool,
    limit: usize,
    offset: usize,
) -> HyphaeResult<Vec<Memory>>;

fn search_fts_with_options(
    &self,
    query: &str,
    limit: usize,
    offset: usize,
    project: Option<&str>,
    include_invalidated: bool,
    order: /* existing order type */,
) -> HyphaeResult<Vec<Memory>>;

fn search_fts_count_with_options(
    &self,
    query: &str,
    project: Option<&str>,
    include_invalidated: bool,
) -> HyphaeResult<usize>;

fn stats_with_options(
    &self,
    project: Option<&str>,
    include_invalidated: bool,
) -> HyphaeResult<StoreStats>;

fn list_topics_with_options(
    &self,
    project: Option<&str>,
    include_invalidated: bool,
) -> HyphaeResult<Vec<(String, usize)>>;

fn topic_health_with_options(
    &self,
    topic: &str,
    project: Option<&str>,
    include_invalidated: bool,
) -> HyphaeResult<TopicHealth>;
```

Also update `StubStore` (in the `#[cfg(test)]` module at the bottom of the same file) to implement the six new methods. Stub implementations should return `Ok(Default::default())` or `Ok(vec![])`.

#### Verification

```bash
cd hyphae && cargo build -p hyphae-core 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Six methods added to `MemoryStore` trait
- [ ] `StubStore` implements all six new methods
- [ ] `hyphae-core` compiles

---

### Step 2: Confirm `SqliteStore` implements the trait

**Project:** `hyphae/crates/hyphae-store/`
**Effort:** 15 min
**Depends on:** Step 1

`SqliteStore` already has these six methods as inherent methods. Adding them to the trait means `SqliteStore` now satisfies the trait without any new code — but the compiler will confirm. Run a build to verify, and fix any signature mismatches.

If the inherent method signatures differ from the trait (e.g., slightly different parameter names or types), reconcile them in `hyphae-store/src/store/memory_store.rs` — not in the trait.

```bash
cd hyphae && cargo build -p hyphae-store 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `hyphae-store` compiles without errors
- [ ] `SqliteStore` satisfies the updated `MemoryStore` trait

---

### Step 3: Migrate `memory.rs` to `&dyn MemoryStore`

**Project:** `hyphae/crates/hyphae-cli/`
**Effort:** 45 min
**Depends on:** Step 2

Read `memory.rs` first, then update every function signature that takes `store: &SqliteStore` to `store: &dyn MemoryStore`. Add `use hyphae_core::MemoryStore;` at the top if not already imported. Remove the `use hyphae_store::SqliteStore;` import from this file once no concrete references remain.

The test helper at the bottom (`fn test_store() -> SqliteStore { ... }`) should stay as `SqliteStore` — it is only used to construct values for tests. Tests that pass the store to a public function will need `&store as &dyn MemoryStore` or can rely on Rust's coercion.

#### Verification

```bash
cd hyphae && cargo build -p hyphae-cli 2>&1 | tail -10
cd hyphae && cargo test -p hyphae-cli 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `hyphae-cli` compiles
- [ ] No `SqliteStore` references remain in `memory.rs` function signatures
- [ ] All `hyphae-cli` tests pass

---

### Step 4: Full suite

```bash
cd hyphae && cargo build 2>&1 | tail -5
cd hyphae && cargo test 2>&1 | tail -10
cd hyphae && cargo clippy -p hyphae-core -p hyphae-store -p hyphae-cli -- -D warnings 2>&1 | tail -10
cd hyphae && cargo fmt --check 2>&1
```

Note: `cargo clippy --all-targets` has a pre-existing error in `benches/retrieval_hot_paths.rs` (missing `content_hash` field). Run clippy scoped to the three changed crates, not `--all-targets`.

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Full build succeeds
- [ ] All tests pass
- [ ] Clippy clean on the three changed crates
- [ ] Fmt clean

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. All checklist items are checked
3. `.handoffs/HANDOFFS.md` updated to reflect completion

### Final Verification

```bash
cd hyphae
cargo build 2>&1 | tail -3
cargo test 2>&1 | grep -E "^test result"
cargo clippy -p hyphae-core -p hyphae-store -p hyphae-cli -- -D warnings 2>&1 | tail -3
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

## Follow-on work (not in scope here)

- Extend `MemoryStore` or define sub-traits for chunk, document, session, and purge operations — then migrate `purge.rs`, `watch.rs`, `docs.rs`, and the remaining ~22 CLI command files
- Consider a `MemoryStoreExt` sealed trait or trait blanket to avoid duplicating default implementations
