# Hyphae: Search Type Registry

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/crates/hyphae-core/src/memory.rs`, `hyphae/crates/hyphae-mcp/src/tools/memory/recall.rs`, `hyphae/crates/hyphae-mcp/src/tools/memory/store.rs`
- **Cross-repo edits:** none
- **Non-goals:** does not add new ML models or external vector databases; does not implement AST-indexed code search (Code search type uses FTS keyword matching only in this handoff); does not change how existing recall callers that omit `search_type` behave
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Inspired by cognee's named retrieval graph types (audit: `.audit/external/audits/cognee-ecosystem-borrow-audit.md`) and wave2-ecosystem-synthesis Theme 3 (pluggable retriever dispatch):

> "Instead of all recall queries going through one FTS+vector path, a SearchType enum selects the retrieval strategy. Callers pass the search type explicitly; the registry dispatches to the right retriever."

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:**
  - `crates/hyphae-core/src/memory.rs` — add `SearchType` enum and `SearchQuery` struct
  - `crates/hyphae-mcp/src/tools/memory/recall.rs` — update `hyphae_memory_recall` handler to accept optional `search_type`
  - `crates/hyphae-store/src/store/search.rs` — dispatch to per-type retrieval paths
- **Reference seams:**
  - `crates/hyphae-core/src/store.rs` — existing `MemoryStore` trait already exposes `search_fts`, `search_by_embedding`, `search_hybrid`; route `SearchType` variants to these
  - `crates/hyphae-mcp/src/tools/memory/recall.rs` — current recall handler; add optional `search_type` parameter here, backward-compatible

## Problem

All memory recall queries currently go through a single FTS + vector hybrid path. There is no way for a caller to say "I only want keyword matches" (for exact topic lookup), "I only want semantic matches" (for conceptual similarity), or "I want to traverse memoir concept links" (for graph-structured retrieval). The unified path is often correct but cannot be tuned per use case.

Cognee's insight: name the retrieval strategy explicitly. A `SearchType` enum lets callers select the strategy; a dispatch layer routes the query to the right retriever. Existing callers that omit the parameter get `Hybrid` — same behavior as today.

## What needs doing (intent)

1. Define `SearchType` enum in `hyphae-core/src/memory.rs`: `Semantic`, `Lexical`, `Graph`, `Summary`, `Code`, `Hybrid`
2. Define `SearchQuery` struct: `query: String`, `search_type: SearchType`, `limit: usize`, `topic: Option<String>`, `project: Option<String>`
3. Update `hyphae_memory_recall` MCP tool to accept an optional `search_type: Option<String>` parameter; parse into `SearchType` at the boundary; default to `Hybrid`
4. Implement per-type retrieval dispatch (see strategy table below)
5. Add `SearchType` to the MCP tool schema comment in `memory_protocol.rs` so operators can see the available strategies

## Data Model

```rust
// In memory.rs
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum SearchType {
    /// Embedding similarity search (existing vector path).
    Semantic,
    /// Full-text keyword search (existing FTS path).
    Lexical,
    /// Memoir concept graph traversal: find memories linked to concepts
    /// matching the query.
    Graph,
    /// Topic-level aggregates: return one representative memory per
    /// matching topic, ordered by recency.
    Summary,
    /// Keyword search biased toward code-related topics and keywords.
    Code,
    /// FTS + semantic rerank (current default behavior).
    Hybrid,
}

impl Default for SearchType {
    fn default() -> Self {
        SearchType::Hybrid
    }
}

impl std::str::FromStr for SearchType {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "semantic" => Ok(Self::Semantic),
            "lexical" | "fts" | "keyword" => Ok(Self::Lexical),
            "graph" => Ok(Self::Graph),
            "summary" => Ok(Self::Summary),
            "code" => Ok(Self::Code),
            "hybrid" => Ok(Self::Hybrid),
            _ => Err(format!("unknown search type: {s}")),
        }
    }
}

#[derive(Debug, Clone)]
pub struct SearchQuery {
    pub query: String,
    pub search_type: SearchType,
    pub limit: usize,
    pub topic: Option<String>,
    pub project: Option<String>,
}
```

## Retrieval Strategy Table

| SearchType | Dispatch target |
|------------|----------------|
| `Semantic` | `store.search_by_embedding(embedding, ...)` — requires embedder; falls back to Lexical if no embedding available |
| `Lexical` | `store.search_fts(query, ...)` — always available |
| `Graph` | FTS search on memoir concepts matching query, then return source memories for matched concepts via `source_memory_ids` |
| `Summary` | `store.get_by_topic` grouped by topic; return one representative per topic |
| `Code` | `store.search_fts(query, ...)` filtered to topics containing "code", "function", "module", or worktree paths |
| `Hybrid` | `store.search_hybrid(query, embedding, ...)` — current default |

## Scope

- **Allowed files:** `hyphae-core/src/memory.rs`, `hyphae-mcp/src/tools/memory/recall.rs`, `hyphae-mcp/src/memory_protocol.rs`, `hyphae-store/src/store/search.rs`
- **Explicit non-goals:**
  - No new ML embedding models
  - Code search is keyword-biased FTS only — not AST analysis
  - Graph traversal is one hop only (concepts whose source_memory_ids match, not multi-hop BFS)

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Before writing code, read:
1. `hyphae/crates/hyphae-core/src/memory.rs` — confirm no existing `SearchType` or `SearchQuery` types
2. `hyphae/crates/hyphae-core/src/store.rs` — confirm existing search method signatures (`search_fts`, `search_by_embedding`, `search_hybrid`)
3. `hyphae/crates/hyphae-mcp/src/tools/memory/recall.rs` — read the current `hyphae_memory_recall` parameter parsing to see where to insert the new `search_type` parameter
4. `hyphae/crates/hyphae-store/src/store/search.rs` — read current dispatch logic

---

### Step 1: Add SearchType enum and SearchQuery struct

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 0

In `crates/hyphae-core/src/memory.rs`:

- Add `SearchType` enum with all six variants as shown in the data model
- Implement `Default` (returns `Hybrid`) and `FromStr` (case-insensitive, with aliases `fts`/`keyword` for `Lexical`)
- Add `SearchQuery` struct

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `SearchType` compiles with all six variants
- [ ] `Default` returns `Hybrid`
- [ ] `FromStr` accepts `"semantic"`, `"lexical"`, `"fts"`, `"graph"`, `"summary"`, `"code"`, `"hybrid"` (case-insensitive)
- [ ] `SearchQuery` struct compiles

---

### Step 2: Implement per-type retrieval dispatch

**Project:** `hyphae/`
**Effort:** medium
**Depends on:** Step 1

In `crates/hyphae-store/src/store/search.rs` (or a new `dispatch.rs` alongside it if the file is already large), add a `dispatch_search` function:

```rust
pub fn dispatch_search(
    store: &SqliteStore,
    query: &SearchQuery,
    embedder: Option<&dyn Embedder>,
) -> HyphaeResult<Vec<Memory>>
```

Route by `query.search_type`:

- `Semantic` — embed the query then call `store.search_by_embedding`; if no embedder, fall back to `Lexical`
- `Lexical` — call `store.search_fts`
- `Graph` — query memoir concept FTS (`search_all_concepts_fts`), collect `source_memory_ids`, load those memories from the memory store
- `Summary` — call `store.get_by_topic` for matching topics, return one representative per topic (most recent)
- `Code` — call `store.search_fts` with the query joined to common code topic prefixes
- `Hybrid` — call `store.search_hybrid`; if no embedder, fall back to `Lexical`

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `dispatch_search` compiles for all six variants
- [ ] Semantic and Hybrid gracefully fall back when no embedder is available

---

### Step 3: Update hyphae_memory_recall MCP tool

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 2

In `crates/hyphae-mcp/src/tools/memory/recall.rs`:

- Add optional `search_type: Option<String>` to the input struct (or equivalent parameter parsing)
- Parse it at the boundary using `SearchType::from_str`; error with a clear message listing valid values if unknown; default to `Hybrid` when absent
- Route the parsed query through `dispatch_search`

Update the tool description in `memory_protocol.rs` to document the available `search_type` values.

The change must be backward-compatible: existing callers that do not pass `search_type` continue to receive `Hybrid` results.

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
cd hyphae && cargo test search 2>&1 | tail -20
```

**Checklist:**
- [ ] `hyphae_memory_recall` accepts optional `search_type` parameter
- [ ] Unknown values return a helpful error listing valid options
- [ ] Omitting `search_type` produces the same results as `"hybrid"`

---

### Step 4: Full suite

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

- Multi-hop Graph search (BFS across concept links, not just one-hop source_memory_ids)
- `septa/search-query-v1.schema.json` if sibling tools (rhizome, cap) need to construct search queries directly
- Per-type relevance scoring so callers can compare results across strategies
- Cap operator view showing which search types are hitting which paths and result counts

## Context

Spawned from Wave 2 audit program (2026-04-23). The seam facts confirmed: hyphae already has unified FTS + vector search with no `SearchType` enum. The existing `MemoryStore` trait in `store.rs` exposes `search_fts`, `search_by_embedding`, and `search_hybrid` as separate methods — `SearchType` is a routing layer over them, not a replacement. `Graph` retrieval builds on the existing memoir concept FTS surface (`search_all_concepts_fts` in `memoir_store.rs`) plus `source_memory_ids` on `Concept`. The key invariant: omitting `search_type` must produce identical behavior to today.
