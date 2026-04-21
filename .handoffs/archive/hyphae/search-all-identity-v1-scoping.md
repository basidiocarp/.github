# Hyphae Search-All Identity-v1 Scoping

## Problem

`hyphae_memory_recall` and `hyphae_gather_context` now honor identity-v1 when the
caller supplies `project_root` + `worktree_id`. `hyphae_search_all` does not.

That leaves a live read-path asymmetry: an agent in worktree A can still call the
unified search surface and get memory hits from worktree B of the same project.
Because `hyphae_search_all` is the cross-store convenience tool, this is easy to
miss during normal usage even after recall was fixed.

The gap is narrower than the original read-asymmetry bug, but it is still a real
correctness issue. It also leaves the contract unclear for the document side of
the tool: command-output and other project-scoped chunks may need identity-aware
filtering or an explicit decision that they remain project-scoped.

## What exists (state)

- **Fixed already:** `hyphae_memory_recall` and `hyphae_gather_context` now scope
  memory reads to the active worktree when a full identity pair is supplied
- **Still legacy:** `hyphae_search_all` does not accept or enforce identity-v1
  inputs today
- **Current implementation:** `crates/hyphae-mcp/src/tools/ingest.rs` calls
  `store.search_all(query, emb_ref, limit, offset, include_docs, project, None)`
  with no worktree context
- **Store layer:** `crates/hyphae-store/src/store/search.rs` uses project-scoped
  memory search helpers, not the new scoped variants
- **Contract risk:** `_shared` memories must stay visible even when worktree
  scoping is active, matching `hyphae_memory_recall`
- **Input risk:** partial identity must not silently fall back to cross-worktree
  recall behavior

## What needs doing (intent)

Make `hyphae_search_all` identity-v1 aware for the memory half of unified search,
preserve `_shared` memory results, and define the document-side contract clearly.

If command-output or other chunks are intended to be worktree-scoped under
identity-v1, implement that. If they are intentionally project-scoped, document
that explicitly and keep tests honest about the difference.

---

### Step 1: Add identity-v1 inputs to hyphae_search_all

**Project:** `hyphae/`
**Effort:** 30-45 min

#### Files to modify

- `crates/hyphae-mcp/src/tools/schema.rs`
- `crates/hyphae-mcp/src/tools/ingest.rs`

Add `project_root` and `worktree_id` to the `hyphae_search_all` MCP schema.
Require them as a pair. Do not silently normalize one-sided identity input.

Parse the new fields in `tool_search_all` and either:
- reject partial identity with a clear error, or
- document an intentional normalization rule and test it

The preferred behavior is the same as the fixed recall path:

```rust
let raw_project_root = get_str(args, "project_root");
let raw_worktree_id = get_str(args, "worktree_id");
if raw_project_root.is_some() ^ raw_worktree_id.is_some() {
    return ToolResult::error(
        "project_root and worktree_id must be provided together".to_string(),
    );
}
```

#### Verification

```bash
cd hyphae && cargo test test_tool_search_all_rejects_partial_identity_pair 2>&1 | tail -10
```

**Checklist:**
- [ ] `hyphae_search_all` schema accepts `project_root` and `worktree_id`
- [ ] Partial identity input is not silently accepted
- [ ] Tool behavior matches the documented contract

---

### Step 2: Scope memory results inside unified search

**Project:** `hyphae/`
**Effort:** 1-2 hours
**Depends on:** Step 1

#### Files to modify

- `crates/hyphae-mcp/src/tools/ingest.rs`
- `crates/hyphae-store/src/store/search.rs`
- any helper needed in `crates/hyphae-store/src/store/memory_store.rs`

When a full identity pair is present, the memory side of `hyphae_search_all`
must use the same worktree-aware filtering as `hyphae_memory_recall`.

That means:
- worktree A memory hits do not surface in worktree B
- `_shared` memories still surface alongside project-scoped results
- no-identity fallback still works as today

If `search_all` keeps using RRF, make sure the scoped memory path preserves the
same ranking behavior instead of downgrading to a simpler search mode.

#### Verification

```bash
cd hyphae && cargo test search_all 2>&1 | tail -20
```

**Checklist:**
- [ ] Full identity pair scopes memory results to the active worktree
- [ ] `_shared` memory hits still appear with identity-v1 enabled
- [ ] No-identity fallback still returns project-scoped results
- [ ] Existing `search_all` tests still pass

---

### Step 3: Decide and enforce the document-side contract

**Project:** `hyphae/`
**Effort:** 1-2 hours
**Depends on:** Step 2

#### Files to modify

- `crates/hyphae-mcp/src/tools/ingest.rs`
- `crates/hyphae-store/src/store/search.rs`
- `crates/hyphae-store/src/store/chunk_store.rs` or document/query layer as needed
- `docs/MCP-TOOLS.md`
- `docs/FEATURES.md`

`hyphae_search_all` returns both memories and chunks. The handoff is not complete
until the chunk side has an explicit identity-v1 story.

Choose one:

1. **Identity-aware chunks**
   Command-output and other identity-v1 namespaced chunk sources do not surface
   across worktrees when a full pair is supplied.

2. **Project-scoped chunks by design**
   Keep chunk search project-scoped, but document that only memory results are
   narrowed by identity-v1 today.

Either choice is acceptable if it is explicit, tested, and reflected in docs.
Failing to decide is not acceptable.

#### Verification

```bash
cd hyphae && cargo test test_tool_search_all_identity_contract 2>&1 | tail -20
```

**Checklist:**
- [ ] Chunk-side identity behavior is explicit
- [ ] Tests cover the chosen chunk-side contract
- [ ] MCP docs describe the actual behavior, not an implied one

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. `hyphae_search_all` no longer leaks worktree-scoped memories across identity-v1 boundaries
2. `_shared` memories still surface under identity-v1 search
3. Partial identity input cannot silently fall back to cross-worktree results
4. The chunk-side identity contract is implemented or explicitly documented
5. Verification output is pasted between the markers for each step

## Context

This is the remaining follow-up from `identity-v1-read-asymmetry.md`.
`hyphae_memory_recall` and `hyphae_gather_context` were fixed first because they
were the highest-value correctness surfaces. `hyphae_search_all` still needs its
own pass so the unified search entry point matches the same identity-v1 rules.
