# Hyphae: Memoir Git Versioning

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/crates/hyphae-core/src/memoir.rs`, `hyphae/crates/hyphae-core/src/memoir_store.rs`, `hyphae/crates/hyphae-mcp/src/tools/memoir.rs`
- **Cross-repo edits:** none
- **Non-goals:** does not diff actual memoir content; does not commit to user's git repo on their behalf; does not implement conflict resolution or merge; does not change how existing memoir reads or writes behave
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Inspired by letta's versioned memory blocks (audit: `.audit/external/audits/letta-ecosystem-borrow-audit.md`) and wave2-ecosystem-synthesis Theme 3 (versioned, auditable memory):

> "Each memoir edit records the git commit hash at time of edit, the agent_id that made the change, and a parent_version_id forming a lineage chain. The memoir_store knows its own edit history."

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:**
  - `crates/hyphae-core/src/memoir.rs` — extend `Memoir` struct; add `MemoirVersion` struct
  - `crates/hyphae-core/src/memoir_store.rs` — extend `MemoirStore` trait with `store_version` and `get_memoir_history`
  - `crates/hyphae-mcp/src/tools/memoir.rs` — add `hyphae_memoir_history` MCP tool handler
- **Reference seams:**
  - `crates/hyphae-core/src/git_context.rs` — already has `detect_git_context_from`; read HEAD from here at save time
  - `crates/hyphae-store/src/schema.rs` — read current schema before adding the versions table
  - `crates/hyphae-store/src/store/memoir_store.rs` — SQLite implementation to extend with version persistence

## Problem

Memoir edits are currently silent overwrites. When an agent refines a concept or updates a memoir's description, the previous state is lost. There is no audit trail showing which agent made which change, at what point in the project's git history, or how the memoir's lineage evolved over time.

This matters for multi-agent coordination: if two agents edit the same memoir in sequence, the orchestrator cannot tell which edit came from which agent or whether any context from the first edit was preserved in the second.

## What needs doing (intent)

1. Add `author: String` (agent_id at save time), `git_hash: Option<String>` (HEAD at save time), and `parent_version_id: Option<String>` to the `Memoir` struct
2. Add a `MemoirVersion` struct capturing a full snapshot per edit: `version_id`, `memoir_id`, `version_seq`, `author`, `git_hash`, `diff_summary` (name/description diff as plain text), `created_at`
3. Add a `memoir_versions` table to the store schema; add `store_version()` and `get_memoir_history()` methods to the `MemoirStore` trait
4. Add `hyphae_memoir_history(memoir_id)` MCP tool that retrieves the version list for a memoir
5. Wire git hash capture at memoir save time using `detect_git_context_from` from `git_context.rs` — read `git rev-parse HEAD` and store the result as `git_hash`

## Data Model

```rust
// In memoir.rs — extend Memoir struct
pub struct Memoir {
    pub id: MemoirId,
    pub name: String,
    pub description: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub consolidation_threshold: u32,
    // New fields:
    /// Agent that last modified this memoir. Empty string if unknown.
    pub author: String,
    /// Git HEAD hash at the time of the last write. None outside git repos.
    pub git_hash: Option<String>,
    /// Version ID of the immediately preceding write, forming a lineage chain.
    pub parent_version_id: Option<String>,
}

// New struct in memoir.rs
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MemoirVersion {
    pub version_id: String,
    pub memoir_id: MemoirId,
    pub version_seq: u32,
    pub author: String,
    pub git_hash: Option<String>,
    /// Human-readable summary of what changed (e.g. "description updated").
    pub diff_summary: String,
    pub created_at: DateTime<Utc>,
}
```

New `MemoirStore` trait methods:

```rust
fn store_version(&self, version: MemoirVersion) -> HyphaeResult<()>;
fn get_memoir_history(&self, memoir_id: &MemoirId, limit: usize) -> HyphaeResult<Vec<MemoirVersion>>;
```

## Scope

- **Allowed files:** `hyphae-core/src/memoir.rs`, `hyphae-core/src/memoir_store.rs`, `hyphae-mcp/src/tools/memoir.rs`, `hyphae-store/src/schema.rs`, `hyphae-store/src/store/memoir_store.rs`
- **Explicit non-goals:**
  - No diff of actual concept content — `diff_summary` is a plain-text description written by the caller, not an automated diff
  - No git commit on behalf of the user — `git_hash` is read-only from HEAD
  - No branching or merge logic

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Before writing code, read:
1. `hyphae/crates/hyphae-core/src/memoir.rs` — current `Memoir` struct fields; confirm no existing `author`, `git_hash`, or `parent_version_id`
2. `hyphae/crates/hyphae-core/src/memoir_store.rs` — current `MemoirStore` trait methods; confirm no version-related methods exist
3. `hyphae/crates/hyphae-store/src/schema.rs` — confirm `memoirs` table shape and decide where to add `memoir_versions` DDL
4. `hyphae/crates/hyphae-core/src/git_context.rs` — confirm `detect_git_context_from` and how to extract just the HEAD hash

---

### Step 1: Extend Memoir struct and add MemoirVersion

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 0

In `crates/hyphae-core/src/memoir.rs`:

- Add `author: String`, `git_hash: Option<String>`, `parent_version_id: Option<String>` to `Memoir`
- Update `Memoir::new` to accept an `author: String` parameter (or default to empty string to keep existing callers working with a two-arg `new`)
- Add `MemoirVersion` struct as specified in the data model above

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `Memoir` compiles with new fields
- [ ] `MemoirVersion` struct compiles
- [ ] `Memoir::new` still works for existing call sites (author defaults to empty string or is added as a parameter without breaking callers)

---

### Step 2: Extend MemoirStore trait and add versions table

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 1

In `crates/hyphae-core/src/memoir_store.rs`:

```rust
fn store_version(&self, version: MemoirVersion) -> HyphaeResult<()>;
fn get_memoir_history(&self, memoir_id: &MemoirId, limit: usize) -> HyphaeResult<Vec<MemoirVersion>>;
```

In `crates/hyphae-store/src/schema.rs`, add to the init batch:

```sql
CREATE TABLE IF NOT EXISTS memoir_versions (
    version_id TEXT PRIMARY KEY,
    memoir_id TEXT NOT NULL REFERENCES memoirs(id) ON DELETE CASCADE,
    version_seq INTEGER NOT NULL,
    author TEXT NOT NULL DEFAULT '',
    git_hash TEXT,
    diff_summary TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_memoir_versions_memoir ON memoir_versions(memoir_id, version_seq);
```

Also add `author TEXT NOT NULL DEFAULT ''`, `git_hash TEXT`, `parent_version_id TEXT` columns to the `memoirs` table DDL (add as ALTER TABLE migration or update the CREATE TABLE IF NOT EXISTS to include the columns, then handle existing databases with a defensive migration).

In `crates/hyphae-store/src/store/memoir_store.rs`: implement `store_version` and `get_memoir_history` using rusqlite.

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] Schema builds with new table and columns
- [ ] `store_version` and `get_memoir_history` compile in the SQLite impl
- [ ] Existing memoir CRUD still builds

---

### Step 3: Wire git hash at save time

**Project:** `hyphae/`
**Effort:** tiny
**Depends on:** Step 2

In the memoir store's `create_memoir` and `update_memoir` implementations (SQLite layer), capture the git HEAD hash using `detect_git_context_from(None)`. Extract the commit hash via `git rev-parse HEAD` — note that `git_context.rs` only returns branch/worktree; add a small helper `current_git_hash(cwd: Option<&Path>) -> Option<String>` in `git_context.rs` that runs `git rev-parse HEAD`.

Store the result as `git_hash` on write.

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `current_git_hash` helper compiles and returns `None` gracefully outside a git repo
- [ ] Memoir creates and updates populate `git_hash` from the helper

---

### Step 4: Add hyphae_memoir_history MCP tool

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 3

In `crates/hyphae-mcp/src/tools/memoir.rs`, add a tool handler for `hyphae_memoir_history`:

- Input: `memoir_id: String`, optional `limit: usize` (default 20)
- Output: JSON array of `MemoirVersion` entries, ordered by `version_seq DESC`
- Resolve memoir by name if the input looks like a name rather than an ID (follow the existing pattern in the memoir tool handlers)

Register the tool in `server.rs` or `dispatch.rs` following the existing memoir tool registration pattern.

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
cd hyphae && cargo test memoir 2>&1 | tail -20
```

**Checklist:**
- [ ] `hyphae_memoir_history` tool is registered and dispatched
- [ ] Tool returns empty list for memoirs with no versions (not an error)
- [ ] Tool returns versions in descending sequence order

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

- `hyphae_memoir_diff(memoir_id, version_id_a, version_id_b)` MCP tool to compare two versions
- Concept-level version tracking (this handoff covers memoir-level only)
- Cap operator view showing memoir edit history per session
- `septa/memoir-version-v1.schema.json` if cross-tool consumers need the version payload

## Context

Spawned from Wave 2 audit program (2026-04-23). The seam facts confirmed: `Memoir` struct already has `created_at`, `updated_at`, and `source_memory_ids` but no `author`, `git_hash`, or lineage fields. `git_context.rs` already runs git subprocess calls and returns branch/worktree — extending it to return HEAD hash is a small, isolated addition. The MemoirStore trait is in `memoir_store.rs` and the SQLite implementation is in `hyphae-store`. The MCP tools follow a dispatch pattern in `server.rs` / `dispatch.rs`; add `hyphae_memoir_history` there alongside the existing memoir tools.
