# Hyphae: Tiered Memory with Context-Window Eviction

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/src/` (tier classification, eviction policies, recall API additions)
- **Cross-repo edits:** none (septa contract for tier schema is follow-on)
- **Non-goals:** does not change the memory schema (entries stay the same); does not add summarization LLM calls (that's a policy, not infrastructure); does not replace the current store; does not touch the pluggable backend work (do that first or in parallel)
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Inspired by letta's tiered memory (audit: `.audit/external/audits/letta-ecosystem-borrow-audit.md`) and graphrag's community-ranked retrieval (audit: `.audit/external/audits/graphrag-ecosystem-borrow-audit.md`):

> "Letta separates core memory (editable blocks, fixed in context), archival memory (full-text searchable passage store), and recall memory (message history with summarization). Context window fit is monitored and excess messages are summarized and evicted to archival."

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:**
  - `src/memory/tier.rs` (new) — `MemoryTier` enum and classification logic
  - `src/memory/eviction.rs` (new) — eviction policy trait and default policies
  - `src/store/` — add tier field to memory entry schema and filter by tier in recall
  - `src/tools/` or `src/mcp/` — expose `tier` as a parameter in hyphae MCP tools
- **Reference seams:**
  - `hyphae/src/store/` — read the current memory entry shape before adding fields
  - letta `letta/schemas/memory.py` and `letta/services/summarizer/summarizer.py` as external reference (do not copy; understand the model)
- **Spawn gate:** do the pluggable-backends handoff first (or verify the store layer is stable); then spawn this

## Problem

Hyphae stores all memories in a flat pool — there is no concept of "this memory is always needed" vs "this memory is rarely accessed" vs "this memory is just session context". When the context window fills, there is no principled way to decide what to evict or compress.

Letta's insight: classify memories into three tiers at storage time:
- **Core** — always in context; high-importance persistent facts; small volume
- **Recall** — recent session context; medium importance; subject to eviction as sessions age
- **Archival** — long-term searchable store; low recency; never actively pushed into context unless searched

This classification is metadata, not a behavioral change. It enables eviction policies that know what to compress first.

## What needs doing (intent)

1. Add a `tier` field to the memory entry schema (default: `recall` for backward compatibility)
2. Add `MemoryTier` classification logic (operators can set tier at store time; hyphae can promote/demote)
3. Add an `EvictionPolicy` trait with a `DefaultEvictionPolicy` that evicts `archival` first, then oldest `recall`, and never touches `core`
4. Expose tier as an optional parameter in `hyphae_memory_store` and `hyphae_memory_recall`
5. Add a `token_budget` parameter to recall: return entries ranked by tier + recency, stopping at budget

## Tier semantics

| Tier | Meaning | Eviction priority |
|------|---------|-----------------|
| `core` | Always-needed facts, user preferences, system invariants | Never evict |
| `recall` | Session context, recent decisions, working memory | Evict oldest first |
| `archival` | Long-term store, historical context, searchable archive | Evict first; never pushed to context unless searched |

## Scope

- **Allowed files:** `hyphae/src/memory/tier.rs` (new), `hyphae/src/memory/eviction.rs` (new), `hyphae/src/store/` (schema + query additions), `hyphae/src/tools/` or `src/mcp/` (API additions)
- **Explicit non-goals:**
  - No LLM summarization — eviction means "don't return in context" not "compress with LLM"
  - No automatic promotion/demotion — tier is set at store time; promotion is a future tool call
  - No changes to memoir system (memoirs are already higher-level than tier classification)

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Before writing code, read `hyphae/src/store/` and the MCP tool definitions:
1. What does a memory entry struct look like today? (fields, types)
2. What does `hyphae_memory_store` accept as parameters?
3. What does `hyphae_memory_recall` return?
4. Is there already an `importance` or `decay` field? (check for overlap)

---

### Step 1: Add MemoryTier enum and schema migration

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 0

Create `src/memory/tier.rs`:

```rust
/// Memory tier classification for eviction and recall prioritization.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MemoryTier {
    /// Always in context. Never evicted. High-importance persistent facts.
    Core,
    /// Recent session context. Evicted oldest-first as sessions age.
    Recall,
    /// Long-term archive. Evicted first. Only retrieved when searched.
    Archival,
}

impl Default for MemoryTier {
    fn default() -> Self {
        MemoryTier::Recall  // backward-compatible default
    }
}
```

Add `tier: MemoryTier` to the memory entry struct. Add a SQLite migration that adds a `tier TEXT NOT NULL DEFAULT 'recall'` column to the memories table.

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `MemoryTier` compiles
- [ ] Memory entry struct has `tier` field with default `Recall`
- [ ] Schema migration adds `tier` column with default value

---

### Step 2: Add EvictionPolicy trait and default implementation

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 1

Create `src/memory/eviction.rs`:

```rust
/// Determines which memories to evict when context budget is exceeded.
pub trait EvictionPolicy: Send + Sync {
    /// Given a list of candidate entries and a token budget, return
    /// the subset that fits within the budget, ordered by priority.
    /// Highest-priority entries are returned first; lower-priority are evicted.
    fn select_for_context<'a>(
        &self,
        candidates: &'a [MemoryEntry],
        token_budget: usize,
    ) -> Vec<&'a MemoryEntry>;
}

/// Default policy: core > recall (recency) > archival (never unless searched).
pub struct DefaultEvictionPolicy;

impl EvictionPolicy for DefaultEvictionPolicy {
    fn select_for_context<'a>(
        &self,
        candidates: &'a [MemoryEntry],
        token_budget: usize,
    ) -> Vec<&'a MemoryEntry> {
        let mut sorted: Vec<_> = candidates.iter().collect();
        sorted.sort_by(|a, b| {
            tier_priority(a.tier).cmp(&tier_priority(b.tier))
                .then(b.created_at.cmp(&a.created_at))  // recency within tier
        });
        // Include entries until token budget exhausted
        let mut used = 0;
        sorted.into_iter()
            .filter(|e| {
                let tokens = estimate_tokens(&e.content);
                if used + tokens <= token_budget {
                    used += tokens;
                    true
                } else {
                    e.tier == MemoryTier::Core  // always include Core even if over budget
                }
            })
            .collect()
    }
}

fn tier_priority(tier: MemoryTier) -> u8 {
    match tier {
        MemoryTier::Core => 0,     // highest priority (lowest sort value)
        MemoryTier::Recall => 1,
        MemoryTier::Archival => 2, // lowest priority (evicted first)
    }
}

fn estimate_tokens(content: &str) -> usize {
    // Rough approximation: 1 token ≈ 4 chars
    content.len() / 4
}
```

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `EvictionPolicy` trait compiles and is object-safe
- [ ] `DefaultEvictionPolicy` correctly orders Core > Recall (recency) > Archival

---

### Step 3: Expose tier in MCP tools

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 2

In `hyphae_memory_store`: add optional `tier` parameter (default `recall`).

In `hyphae_memory_recall`: add optional `token_budget` parameter and optional `tier` filter. When `token_budget` is set, apply `DefaultEvictionPolicy` to return entries within budget.

#### Verification

```bash
cd hyphae && cargo build 2>&1 | tail -5
cd hyphae && cargo test 2>&1 | tail -20
```

**Checklist:**
- [ ] `hyphae_memory_store` accepts optional `tier` parameter
- [ ] `hyphae_memory_recall` accepts optional `token_budget` and `tier` parameters
- [ ] Existing callers that omit `tier` still work (default `recall`)

---

### Step 4: Unit tests

**Project:** `hyphae/`
**Effort:** small
**Depends on:** Step 3

Test the eviction policy:
- Core entries always included even over budget
- Archival entries excluded first
- Recall entries ordered by recency

```bash
cd hyphae && cargo test eviction 2>&1
cd hyphae && cargo test tier 2>&1
```

**Checklist:**
- [ ] Eviction policy tests pass
- [ ] Tier field roundtrips through store correctly

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

- `septa/memory-tier-v1.schema.json` — if other tools need to query or set tiers
- LLM-based summarization policy that compresses `recall` entries to `archival` when session ends
- `hyphae_memory_promote` / `hyphae_memory_demote` MCP tools for manual tier management
- `cap` operator view showing memory tier distribution and eviction candidates

## Context

Spawned from Wave 2 audit program (2026-04-23). Letta and graphrag both show that flat memory pools don't scale — you need tiering to make eviction principled. The key design decision: tier is metadata at store time, not a runtime inference. This keeps the hot path simple and lets eviction policies be swappable. The `DefaultEvictionPolicy` implements the obvious ordering; future policies (importance-weighted, topic-clustered) can implement the same trait.
