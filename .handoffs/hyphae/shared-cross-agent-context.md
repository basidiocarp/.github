# Hyphae: Shared Cross-Agent Context

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/crates/hyphae-core/src/` (new `shared_context.rs`), `hyphae/crates/hyphae-store/src/schema.rs`, `hyphae/crates/hyphae-store/src/store/` (new impl file), `hyphae/crates/hyphae-mcp/src/tools/context.rs`
- **Cross-repo edits:** none (septa contract for the context payload is follow-on)
- **Non-goals:** does not implement cross-session sharing; does not add locking or conflict resolution for concurrent writes; does not implement a pub/sub or event fan-out mechanism; does not replace session-scoped memory (use `hyphae_memory_store` for durable memory; this is ephemeral shared state for a live session)
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Inspired by headroom's shared context model (audit: `.audit/external/audits/headroom-ecosystem-borrow-audit.md`) and wave2-ecosystem-synthesis Theme 3 (typed shared context for multi-agent sessions):

> "SharedContext is stored under a well-known key (session_id + key) and any agent in that session can read or append to it. Context entries record which agent wrote them, what key they used, and what JSON value they stored."

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:**
  - `crates/hyphae-core/src/shared_context.rs` (new) — `SharedContextEntry` struct and `SharedContextStore` trait
  - `crates/hyphae-store/src/schema.rs` — add `shared_context` table DDL
  - `crates/hyphae-store/src/store/shared_context.rs` (new) — SQLite implementation
  - `crates/hyphae-mcp/src/tools/context.rs` — add `hyphae_context_put` and `hyphae_context_get` tool handlers (file already exists — read it first to understand the existing surface)
- **Reference seams:**
  - `crates/hyphae-store/src/store/session.rs` — read how `session_id` is established; the shared context is keyed on this
  - `crates/hyphae-mcp/src/tools/session.rs` — read how `session_id` flows through MCP tool calls to understand how to thread it into the new tools

## Problem

Agents in the same session have no typed shared space to exchange intermediate results without going through full memory storage. When one agent finishes a sub-task and wants to hand a typed result to a sibling agent, it must either write to the memory store (durable, but not scoped to the session) or emit unstructured text that the sibling must parse. Neither is reliable.

The headroom insight: a `SharedContext` table scoped to `session_id` gives agents a lightweight key-value store for the duration of a session. Any agent in the session can write a value under a key; any other agent in the same session can read it back. Values are JSON-typed and carry an `agent_id` attribution. The table is session-scoped and does not outlive the session.

## What needs doing (intent)

1. Define `SharedContextEntry` struct in a new `shared_context.rs` in hyphae-core
2. Define `SharedContextStore` trait with `put_context`, `get_context`, and `list_context_keys`
3. Add `shared_context` table to `hyphae-store/src/schema.rs`
4. Implement `SharedContextStore` in a new `hyphae-store/src/store/shared_context.rs`
5. Add `hyphae_context_put(key, value)` and `hyphae_context_get(key)` MCP tool handlers to `hyphae-mcp/src/tools/context.rs`, operating on the current session's shared space

## Data Model

```rust
// In hyphae-core/src/shared_context.rs

#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct SharedContextEntry {
    /// UUID v4 — unique per write.
    pub entry_id: String,
    /// The session this entry belongs to.
    pub session_id: String,
    /// The agent that wrote this entry.
    pub agent_id: String,
    /// Namespaced key (e.g. "plan/phase", "result/file-list").
    pub key: String,
    /// Arbitrary JSON value — stored as TEXT in SQLite.
    pub value: serde_json::Value,
    pub written_at: chrono::DateTime<chrono::Utc>,
}

pub trait SharedContextStore {
    /// Write or overwrite a key for this session.
    /// A new entry_id is assigned on each write, even if the key already exists.
    fn put_context(
        &self,
        session_id: &str,
        agent_id: &str,
        key: &str,
        value: serde_json::Value,
    ) -> HyphaeResult<String>; // returns entry_id

    /// Read the most recent value for a key in this session.
    /// Returns None if the key has never been written.
    fn get_context(
        &self,
        session_id: &str,
        key: &str,
    ) -> HyphaeResult<Option<SharedContextEntry>>;

    /// List all keys written in this session (distinct, most-recently-written first).
    fn list_context_keys(&self, session_id: &str) -> HyphaeResult<Vec<String>>;
}
```

SQL schema addition:

```sql
CREATE TABLE IF NOT EXISTS shared_context (
    entry_id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    agent_id TEXT NOT NULL DEFAULT '',
    key TEXT NOT NULL,
    value TEXT NOT NULL,          -- JSON
    written_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_shared_context_session_key
    ON shared_context(session_id, key, written_at DESC);
```

`get_context` returns the row with the maximum `written_at` for the given `(session_id, key)` pair — last-writer-wins, no conflict resolution.

## Scope

- **Allowed files:** `hyphae-core/src/shared_context.rs` (new), `hyphae-core/src/lib.rs` (re-export), `hyphae-store/src/schema.rs`, `hyphae-store/src/store/shared_context.rs` (new), `hyphae-store/src/store/mod.rs` (add module), `hyphae-mcp/src/tools/context.rs`
- **Explicit non-goals:**
  - No cross-session sharing — context is always isolated to one `session_id`
  - No locking or CAS — last write wins; no atomicity guarantees beyond SQLite row writes
  - No TTL or eviction — shared context lives until the session record is cleaned up

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Before writing code, read:
1. `hyphae/crates/hyphae-store/src/store/session.rs` — understand how `session_id` (the `id` field on `Session`) is generated and stored; confirm it is a plain `String`
2. `hyphae/crates/hyphae-mcp/src/tools/context.rs` — read the existing surface; understand what is already there and where to add the two new tool handlers
3. `hyphae/crates/hyphae-mcp/src/tools/session.rs` — see how the current session_id is threaded into MCP tool call contexts
4. `hyphae/crates/hyphae-store/src/schema.rs` — read the full current DDL to pick the right place to append the `shared_context` table

---

### Step 1: Add SharedContextEntry struct and SharedContextStore trait

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 0

Create `crates/hyphae-core/src/shared_context.rs` with:
- `SharedContextEntry` struct as shown in the data model
- `SharedContextStore` trait with `put_context`, `get_context`, and `list_context_keys`

Export from `crates/hyphae-core/src/lib.rs`.

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `SharedContextEntry` compiles with correct field types
- [ ] `SharedContextStore` trait compiles and is object-safe
- [ ] Exported from hyphae-core lib.rs

---

### Step 2: Add shared_context table to schema

**Project:** `hyphae/`
**Effort:** tiny
**Depends on:** Step 1

In `crates/hyphae-store/src/schema.rs`, append the `shared_context` DDL to the `init_db_with_dims` batch. Keep it after the existing memoir tables so that the migration order is clear.

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
cd hyphae && cargo test -p hyphae-store 2>&1 | tail -20
```

**Checklist:**
- [ ] Schema batch still compiles and runs without error
- [ ] `shared_context` table is created on a fresh database
- [ ] Index `idx_shared_context_session_key` is created

---

### Step 3: Implement SharedContextStore in SQLite

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 2

Create `crates/hyphae-store/src/store/shared_context.rs`. Implement `SharedContextStore` for `SqliteStore`:

- `put_context` — INSERT a new row with a fresh UUID `entry_id` and the current UTC timestamp
- `get_context` — SELECT the row with `MAX(written_at)` for the given `(session_id, key)` pair; deserialize `value` as `serde_json::Value`
- `list_context_keys` — SELECT DISTINCT `key` WHERE `session_id = ?` ORDER BY `MAX(written_at) DESC`

Register the module in `crates/hyphae-store/src/store/mod.rs`.

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
cd hyphae && cargo test context 2>&1 | tail -20
```

**Checklist:**
- [ ] `put_context` inserts a row and returns an `entry_id`
- [ ] `get_context` returns the most-recently-written value for the key
- [ ] `get_context` returns `None` for a key that has never been written
- [ ] `list_context_keys` returns keys in most-recently-written order

---

### Step 4: Add hyphae_context_put and hyphae_context_get MCP tools

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 3

In `crates/hyphae-mcp/src/tools/context.rs`, add two tool handlers following the existing context tool patterns:

**hyphae_context_put:**
- Input: `key: String`, `value: serde_json::Value`
- Resolves the current `session_id` from the MCP call context (see how other session tools do this)
- Resolves `agent_id` from the session context (use the session's `scope` or a passed-in identity; default to empty string if unavailable)
- Calls `store.put_context(session_id, agent_id, key, value)`
- Returns: `{ "entry_id": "...", "session_id": "...", "key": "..." }`

**hyphae_context_get:**
- Input: `key: String`
- Resolves `session_id` from call context
- Calls `store.get_context(session_id, key)`
- Returns the full `SharedContextEntry` as JSON, or `null` if not found

Register both tools in the dispatch layer (see how existing context tools are registered in `server.rs` or `dispatch.rs`).

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
cd hyphae && cargo test context 2>&1 | tail -20
```

**Checklist:**
- [ ] `hyphae_context_put` tool is registered and dispatches correctly
- [ ] `hyphae_context_get` returns the last-written value for a key
- [ ] `hyphae_context_get` returns a clear null/not-found response (not an error) for missing keys
- [ ] Session isolation holds: two sessions with the same key do not share values

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

- `hyphae_context_list(session_id)` MCP tool to enumerate all keys in a session's shared context
- TTL support: shared context entries expire with the session on `session end`
- `septa/shared-context-v1.schema.json` if canopy or cap need to read shared context via CLI or structured contract
- Cap operator view showing live shared context for active multi-agent sessions
- Write history: `hyphae_context_history(key)` returning all writes for a key within the session, not just the latest

## Context

Spawned from Wave 2 audit program (2026-04-23). The seam facts confirmed: sessions already have `project`, `branch`, `worktree_id`, and `runtime_session_id` in `hyphae-store/src/store/session.rs` — no `SharedContext` struct exists yet. The `hyphae-mcp/src/tools/context.rs` file already exists and is the right place to add the two new tool handlers rather than creating a new file. The `agent_id` for attribution is available via the session `scope` field or from MCP call context depending on how the session identity is threaded — the implementer must check step 0 to confirm the exact threading path. Last-writer-wins is the deliberate design choice: conflict resolution is out of scope and would require locking semantics incompatible with SQLite's concurrency model.
