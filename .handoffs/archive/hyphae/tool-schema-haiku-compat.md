# Hyphae Tool Schema Haiku Compatibility

## Problem

Three hyphae MCP tools use `allOf` at the top level of their `inputSchema` for conditional field validation (`worktree_id` ↔ `project_root` co-dependency). Haiku and other strict MCP clients reject `oneOf`/`allOf`/`anyOf` at the top level of `input_schema` outright, refusing to initialize entirely. This breaks any orchestration pattern that uses Haiku as a subagent — it fails with 0 token usage before doing any work.

```
tools.58.custom.input_schema: input_schema does not support oneOf, allOf, or anyOf at the top level
```

Sonnet tolerates the non-conforming schema; Haiku does not.

## What exists (state)

Three tools in `hyphae/crates/hyphae-mcp/src/tools/schema.rs` have top-level `allOf`:

- **`hyphae_memory_recall`** (line ~101) — enforces that `project_root` and `worktree_id` must appear together
- **`hyphae_gather_context`** (line ~650) — same pattern
- **`hyphae_search_all`** (line ~770) — same pattern

The `allOf` blocks encode the rule "if one of `project_root`/`worktree_id` is supplied, the other must be too." This is valid JSON Schema draft 2019+ but is not supported at the top level of MCP `input_schema`.

## What needs doing (intent)

Remove the `allOf` blocks from all three tool schemas. Move the co-dependency constraint into the field descriptions instead. The runtime handlers already validate this at call time — the schema constraint is documentation, not enforcement.

---

### Step 1: Remove top-level `allOf` from the three schemas

**Project:** `hyphae/`
**Effort:** 30 min
**Depends on:** nothing

In `crates/hyphae-mcp/src/tools/schema.rs`, for each of the three tools:
1. Delete the `"allOf": [...]` block
2. Update the `worktree_id` and `project_root` field descriptions to note the co-dependency, e.g.: `"When supplied, project_root must also be provided (and vice versa)."`

The `required` array stays unchanged — only `allOf` is removed.

#### Verification

```bash
cd hyphae && cargo build --workspace --no-default-features 2>&1 | tail -5
cargo test --workspace --no-default-features 2>&1 | tail -10
grep -n "allOf\|oneOf\|anyOf" crates/hyphae-mcp/src/tools/schema.rs
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `allOf` removed from `hyphae_memory_recall` schema
- [ ] `allOf` removed from `hyphae_gather_context` schema
- [ ] `allOf` removed from `hyphae_search_all` schema
- [ ] Field descriptions updated to document the co-dependency
- [ ] `grep` for `allOf`/`oneOf`/`anyOf` in schema.rs returns only test assertions (lines ~1015-1058), not tool definitions
- [ ] Build and tests pass

---

## Completion Protocol

1. Verification output pasted above
2. `cargo build --no-default-features` passes
3. `grep` confirms no `allOf`/`oneOf`/`anyOf` in tool definitions (only in test assertions)

## Context

Discovered when Sonnet spun up a Haiku subagent (implementer) and it failed immediately with 0 token usage. Haiku is stricter than Sonnet about MCP tool schema validation. The fix is purely cosmetic — the runtime handlers already enforce the co-dependency at call time. This should be in **Tier 1** since it blocks all Haiku subagent usage across the ecosystem.
