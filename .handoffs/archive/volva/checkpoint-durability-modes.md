# Volva: Checkpoint Durability Modes

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `volva`
- **Allowed write scope:** `volva/src/checkpoint/` (new checkpoint module), `volva/src/config.rs` (durability mode config)
- **Cross-repo edits:** `canopy/src/graph/` (declare required durability mode per graph), `septa/` (checkpoint-v1 schema — follow-on)
- **Non-goals:** does not implement full state-graph semantics in volva (that is canopy's job); does not add LangChain integration; does not add distributed checkpoint backends (SQLite default only)
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Extracted from the langgraph ecosystem borrow audit (`.audit/external/audits/langgraph-ecosystem-borrow-audit.md`):

> "LangGraph persists graph state to a checkpointer, with three durability modes: sync (persist before next step), async (persist in background), and exit (persist only on termination). Checkpoints store channel values, versions, and metadata."

> "Best fit: `volva` (persistence strategy), `septa` (contract)."

## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:**
  - `src/checkpoint/mod.rs` (new) — `CheckpointDurability` enum, `Checkpoint` struct, `CheckpointSaver` trait
  - `src/checkpoint/sqlite.rs` (new) — SQLite implementation of `CheckpointSaver`
  - `src/config.rs` — add `durability_mode` field
- **Reference seams:**
  - `volva/src/` — read existing execution host structure before adding
  - `canopy/src/` — understand how canopy declares graph execution needs
- **Spawn gate:** read volva's existing persistence and config structure before spawning

## Problem

Volva has no concept of checkpoint durability — when a long-running agent workflow is interrupted, state is lost. There is no contract for how frequently to persist graph state or what to do with it. This means:
1. Agent workflows are not resumable after crashes or SSH logouts
2. There is no cost-optimized persistence mode (sync on every step is expensive; exit-only is fragile)
3. Canopy graphs cannot express their durability requirements

LangGraph's three-mode model solves this cleanly: sync for critical workflows, async for background persistence, exit for lightweight jobs.

## What needs doing (intent)

1. Define `CheckpointDurability` enum with three modes
2. Define `Checkpoint` struct with state snapshot + version + metadata
3. Define `CheckpointSaver` trait (save + load operations)
4. Implement `SqliteCheckpointSaver` as the default backend
5. Wire durability mode through volva config so canopy can declare requirements

## Checkpoint model

```rust
/// When to persist graph state.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CheckpointDurability {
    /// Persist before advancing to the next node. Safest; highest overhead.
    Sync,
    /// Persist in the background while execution continues. Balanced.
    Async,
    /// Persist only when the graph terminates. Lowest overhead; least resilient.
    Exit,
}

impl Default for CheckpointDurability {
    fn default() -> Self {
        CheckpointDurability::Async
    }
}

pub struct Checkpoint {
    /// Unique ID for this checkpoint (ULID).
    pub checkpoint_id: String,
    /// Thread/graph ID this checkpoint belongs to.
    pub thread_id: String,
    /// Monotonic version counter. Increases with each step.
    pub version: u64,
    /// Serialized graph state at this point.
    pub state: serde_json::Value,
    /// Tool-specific metadata (step name, agent_id, etc.).
    pub metadata: std::collections::HashMap<String, serde_json::Value>,
    pub created_at: i64,
}
```

## CheckpointSaver trait

```rust
use async_trait::async_trait;

#[async_trait]
pub trait CheckpointSaver: Send + Sync {
    /// Persist a checkpoint. Called according to the durability mode.
    async fn save(&self, checkpoint: &Checkpoint) -> Result<(), CheckpointError>;

    /// Load the latest checkpoint for a thread.
    async fn load(&self, thread_id: &str) -> Result<Option<Checkpoint>, CheckpointError>;

    /// Load a specific checkpoint by ID.
    async fn load_by_id(&self, checkpoint_id: &str) -> Result<Option<Checkpoint>, CheckpointError>;

    /// List all checkpoints for a thread, newest first.
    async fn list(&self, thread_id: &str) -> Result<Vec<Checkpoint>, CheckpointError>;

    /// Delete all checkpoints for a thread.
    async fn delete_thread(&self, thread_id: &str) -> Result<(), CheckpointError>;
}
```

## SQLite schema

```sql
CREATE TABLE IF NOT EXISTS checkpoints (
    checkpoint_id TEXT PRIMARY KEY,
    thread_id     TEXT NOT NULL,
    version       INTEGER NOT NULL,
    state         TEXT NOT NULL,     -- JSON
    metadata      TEXT NOT NULL,     -- JSON
    created_at    INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_checkpoints_thread ON checkpoints(thread_id, version DESC);
```

## Scope

- **Allowed files:** `volva/src/checkpoint/mod.rs` (new), `volva/src/checkpoint/sqlite.rs` (new), `volva/src/config.rs` (add durability_mode)
- **Explicit non-goals:**
  - No distributed checkpoint backends (PostgreSQL, S3) in this handoff
  - No state-graph semantics in volva (canopy owns the graph)
  - No LangChain Runnable pattern

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Before writing code, read:
1. `volva/src/` — does volva already have any persistence or state snapshot mechanism?
2. `volva/src/config.rs` — what does the config struct look like today?
3. Is there an existing SQLite connection pool in volva? (reuse it if so)

---

### Step 1: Define checkpoint types

**Project:** `volva/`
**Effort:** small
**Depends on:** Step 0

Create `src/checkpoint/mod.rs` with `CheckpointDurability`, `Checkpoint`, `CheckpointSaver`, and `CheckpointError`.

#### Verification

```bash
cd volva && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `CheckpointDurability` compiles with all 3 variants
- [ ] `Checkpoint` struct compiles with serde derives
- [ ] `CheckpointSaver` trait compiles and is object-safe

---

### Step 2: Implement SqliteCheckpointSaver

**Project:** `volva/`
**Effort:** small
**Depends on:** Step 1

Create `src/checkpoint/sqlite.rs` with `SqliteCheckpointSaver` implementing `CheckpointSaver`. Create the `checkpoints` table on init. JSON-encode `state` and `metadata` when persisting.

#### Verification

```bash
cd volva && cargo build 2>&1 | tail -5
cd volva && cargo test checkpoint 2>&1
```

**Checklist:**
- [ ] `SqliteCheckpointSaver` implements `CheckpointSaver`
- [ ] save + load roundtrip works on in-memory SQLite
- [ ] `list()` returns checkpoints newest-first

---

### Step 3: Wire durability mode through config

**Project:** `volva/`
**Effort:** tiny
**Depends on:** Step 2

Add `durability_mode: CheckpointDurability` to the volva config struct (default: `Async`). Read from `VOLVA_CHECKPOINT_DURABILITY` env or config file.

#### Verification

```bash
cd volva && VOLVA_CHECKPOINT_DURABILITY=sync cargo test 2>&1 | tail -10
cd volva && VOLVA_CHECKPOINT_DURABILITY=exit cargo test 2>&1 | tail -10
```

**Checklist:**
- [ ] Config reads durability mode from env
- [ ] Default is `async`
- [ ] Unknown value logs warning and falls back to `async`

---

### Step 4: Full suite

```bash
cd volva && cargo build --release 2>&1 | tail -5
cd volva && cargo test 2>&1 | tail -20
cd volva && cargo clippy --all-targets -- -D warnings 2>&1 | tail -20
cd volva && cargo fmt --check 2>&1
```

**Checklist:**
- [ ] Release build succeeds
- [ ] All tests pass
- [ ] Clippy clean
- [ ] Fmt clean

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output
2. Full test suite passes
3. All checklist items checked
4. `.handoffs/HANDOFFS.md` updated

## Follow-on work (not in scope here)

- `septa/checkpoint-v1.schema.json` — if checkpoints need to cross tool boundaries
- PostgreSQL checkpoint backend for multi-host durability
- Canopy integration: graph execution declares required `CheckpointDurability`; volva enforces it
- `hymenium`: use checkpoints to implement phase-gate resume (restart at last completed phase)

## Context

Spawned from Wave 2 audit program (2026-04-23). LangGraph's three durability tiers (sync/async/exit) solve a real production problem: making agent workflows resumable after crashes without paying for sync persistence on every step. The default `async` mode gives the best balance — state is eventually persisted in the background while execution continues. Sync is for critical paths where losing a step is unacceptable. Exit is for short-lived jobs where overhead matters more than resilience.
