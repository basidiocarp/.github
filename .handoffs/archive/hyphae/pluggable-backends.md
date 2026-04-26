# Hyphae: Pluggable Backend Adapters

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/src/store/` (backend trait + SQLite adapter refactor), `hyphae/Cargo.toml`
- **Cross-repo edits:** none (septa contract for backend interface is follow-on)
- **Non-goals:** does not add Elasticsearch or MongoDB backends (this handoff only defines the SPI and ensures SQLite implements it); does not change hyphae's public MCP tool API; does not change memory schema
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Inspired by cognee's pluggable multi-backend architecture (audit: `.audit/external/audits/cognee-ecosystem-borrow-audit.md`) and corroborated by letta and strands:

> "Cognee abstracts graph, vector, and relational databases behind interface-based adapters. Users configure via environment variables and get isolated backends. This eliminates vendor lock-in and enables multi-cloud deployments with no code changes."

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:**
  - `src/store/` — existing storage layer; read it first to understand current structure
  - `src/store/backend.rs` (new) — `MemoryBackend` trait definition
  - `src/store/sqlite.rs` — refactor existing SQLite code to implement the trait
  - `src/lib.rs` or `src/config.rs` — backend selection via config/env
- **Reference seams:**
  - cognee's `GraphDBInterface` / `VectorDBInterface` pattern as external reference
  - `hyphae/src/store/` — read all existing store code before writing
- **Spawn gate:** read hyphae's store module first — identify the current interface between store and callers, then spawn

## Problem

Hyphae's SQLite storage is hardcoded — no abstraction layer between the memory operations and the SQLite implementation. This means:

1. Testing requires a real SQLite database (no in-memory mock that speaks a different interface)
2. Future backends (Elasticsearch for semantic search at scale, a remote sync backend) require invasive rewrites
3. The backend selection can't be changed at deployment time without code changes

Cognee, letta, and strands all solved this by defining a backend trait/interface and making the default implementation (SQLite) just one backend that satisfies it.

## What needs doing (intent)

Define a `MemoryBackend` trait that captures all the operations hyphae currently does against SQLite. Refactor the existing SQLite code to implement this trait. Add a factory that selects the backend from config (defaulting to SQLite). No behavior changes — just a clean interface extraction.

## Scope

- **Allowed files:** `hyphae/src/store/backend.rs` (new), `hyphae/src/store/` (refactor), `hyphae/src/config.rs` (backend selection)
- **Explicit non-goals:**
  - No new backends added in this handoff — SQLite remains the only implementation
  - No changes to hyphae's MCP tool signatures or memory schema
  - No septa contract yet — trait stays internal for now

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Read `hyphae/src/store/` before writing any code. Answer:
1. What are all the operations the store currently exposes to callers? (list them)
2. Is there already a trait or interface, or is it direct struct methods?
3. What types do the store operations use? (memory entry shape, search result shape, etc.)
4. What async runtime is in scope (tokio)? Are store operations sync or async?

Document findings as a comment at the top of `src/store/backend.rs`.

---

### Step 1: Define the MemoryBackend trait

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 0

Create `src/store/backend.rs`. Define `MemoryBackend` with all operations identified in Step 0. Rough shape (adjust to match actual hyphae types):

```rust
use async_trait::async_trait;

/// The storage SPI for hyphae memory operations.
/// All backends must implement this trait.
/// The default backend is SQLite.
#[async_trait]
pub trait MemoryBackend: Send + Sync {
    /// Store a memory entry. Returns the generated ID.
    async fn store(&self, entry: MemoryEntry) -> StoreResult<String>;

    /// Retrieve a memory entry by ID.
    async fn get(&self, id: &str) -> StoreResult<Option<MemoryEntry>>;

    /// Delete a memory entry by ID.
    async fn delete(&self, id: &str) -> StoreResult<()>;

    /// Full-text search across stored memories.
    async fn search(&self, query: &str, limit: usize) -> StoreResult<Vec<MemoryEntry>>;

    /// List memories by topic.
    async fn list_by_topic(&self, topic: &str) -> StoreResult<Vec<MemoryEntry>>;

    /// Update an existing memory entry.
    async fn update(&self, id: &str, entry: MemoryEntry) -> StoreResult<()>;

    /// Health check — returns true if the backend is reachable and functional.
    async fn health_check(&self) -> bool;
}
```

Adjust method signatures to match hyphae's actual types. The goal is to extract the interface from the implementation, not to redesign it.

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] Trait compiles
- [ ] All existing store operations are captured in the trait

---

### Step 2: Implement MemoryBackend for the existing SQLite store

**Project:** `hyphae/`
**Effort:** medium
**Depends on:** Step 1

Refactor `src/store/sqlite.rs` (or equivalent) so that `SqliteBackend` implements `MemoryBackend`. This is a mechanical refactor — the logic stays identical, just organized behind the trait.

```rust
pub struct SqliteBackend {
    conn: /* existing connection type */,
}

#[async_trait]
impl MemoryBackend for SqliteBackend {
    async fn store(&self, entry: MemoryEntry) -> StoreResult<String> {
        // existing SQLite insert logic
    }
    // ... all other methods
}
```

After this step, all callers of the store should go through `Box<dyn MemoryBackend>` or `Arc<dyn MemoryBackend>` rather than the concrete type.

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
cd hyphae && cargo test 2>&1 | tail -20
```

**Checklist:**
- [ ] `SqliteBackend` implements `MemoryBackend`
- [ ] All callers updated to use the trait (no direct SQLite struct references)
- [ ] All existing tests still pass

---

### Step 3: Add backend factory and config selection

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 2

Add a `create_backend(config: &Config) -> Box<dyn MemoryBackend>` factory. Read `HYPHAE_BACKEND` (or equivalent) from config/env. Default to `sqlite`. Unknown values should log a warning and fall back to SQLite.

```rust
pub fn create_backend(config: &Config) -> Box<dyn MemoryBackend> {
    match config.backend.as_deref().unwrap_or("sqlite") {
        "sqlite" => Box::new(SqliteBackend::new(&config.db_path)?),
        other => {
            tracing::warn!(backend = other, "unknown backend, falling back to sqlite");
            Box::new(SqliteBackend::new(&config.db_path)?)
        }
    }
}
```

#### Verification

```bash
cd hyphae && HYPHAE_BACKEND=sqlite cargo test 2>&1 | tail -10
cd hyphae && HYPHAE_BACKEND=unknown cargo test 2>&1 | grep "unknown backend"
```

**Checklist:**
- [ ] Factory selects SQLite by default
- [ ] Unknown backend logs warning and falls back gracefully

---

### Step 4: Add an in-memory backend for tests

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 3

Create `src/store/memory_backend.rs` — a simple `HashMap`-backed in-memory implementation of `MemoryBackend` for use in tests. This is the immediate payoff of the abstraction: tests no longer need SQLite.

```rust
#[cfg(test)]
pub struct InMemoryBackend {
    entries: std::sync::Mutex<std::collections::HashMap<String, MemoryEntry>>,
}

#[cfg(test)]
#[async_trait]
impl MemoryBackend for InMemoryBackend {
    // ... simple HashMap operations
}
```

Update one or more existing tests to use `InMemoryBackend` instead of a SQLite file to prove the abstraction works.

#### Verification

```bash
cd hyphae && cargo test 2>&1 | tail -20
```

**Checklist:**
- [ ] `InMemoryBackend` compiles and implements `MemoryBackend`
- [ ] At least one test uses `InMemoryBackend`
- [ ] All tests pass

---

### Step 5: Full suite

```bash
cd hyphae && cargo build --release 2>&1 | tail -5
cd hyphae && cargo test 2>&1 | tail -20
cd hyphae && cargo clippy --all-targets -- -D warnings 2>&1 | tail -20
cd hyphae && cargo fmt --check 2>&1
```

**Checklist:**
- [ ] Release build succeeds
- [ ] All tests pass
- [ ] Clippy clean
- [ ] Fmt clean

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The full test suite passes
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` updated to reflect completion

## Follow-on work (not in scope here)

- `septa/memory-backend-v1.schema.json` — if other tools need to target the backend interface
- Elasticsearch backend for semantic search at scale
- Remote sync backend for cross-machine hyphae state

## Context

Spawned from Wave 2 audit program (2026-04-23). Cognee, letta, and strands all show that a pluggable backend trait is table stakes for a production memory system. The key insight: this handoff is a pure refactor — no behavior changes, no new features. The payoff is faster tests (InMemoryBackend), easier future backends, and a cleaner seam for septa contracts.
