# Context-Aware Recall Follow-Up Handoff

## Task

Implement the next narrow follow-up to `hyphae`'s context-aware recall path.

The core context-aware recall slice landed, and the code-term expansion plumbing
has already been repaired. This follow-up should improve the MCP-side recall
behavior without touching the store-side code-context helper logic.

Keep this slice focused on recall behavior and test clarity.

## Ownership

Write scope:

- `hyphae/crates/hyphae-mcp/src/tools/memory.rs`
- `hyphae/crates/hyphae-mcp/src/tools/schema.rs` only if help text needs a
  precise update
- `hyphae/docs/MCP-TOOLS.md` only if the user-facing recall description needs a
  narrow wording update
- `hyphae/docs/FEATURES.md` only if the user-facing recall description needs a
  narrow wording update

Read-only context:

- `hyphae/crates/hyphae-store/src/store/context.rs`
- `hyphae/crates/hyphae-mcp/src/tools/context.rs`
- `hyphae/docs/handoffs/completed/CONTEXT-AWARE-RECALL.md`
- `hyphae/docs/handoffs/completed/CODE-CONTEXT-TERM-EXPANSION-VALIDATOR.md`

You are not alone in the codebase. Do not revert others' edits. Do not edit the
store-side context helper path; that write scope is reserved for the separate
structural fallback worker.

## Goal

Tighten the recall-side behavior around context-aware queries while keeping the
logic explicit and testable.

Good target directions:

- make the recall expansion/merge stages clearer and more obviously bounded
- improve result merging or ordering for context-aware branches
- add missing regression coverage around session-shaped or code-shaped recall
  behavior

## Constraints

- do not redesign `hyphae_memory_recall`
- do not add new store APIs unless absolutely necessary
- do not edit `hyphae-store/src/store/context.rs`
- preserve current output shape
- keep this as a recall-path follow-up, not a generic search overhaul

## Acceptance Criteria

- context-aware recall behavior is improved or clarified in a concrete way
- tests make the intended behavior more obvious
- the change stays in the MCP recall layer
- no overlap with the structural fallback write scope

## Validation

Run:

```bash
cd /Users/williamnewton/projects/basidiocarp/hyphae
cargo test -p hyphae-mcp -p hyphae-cli -p hyphae-store
cargo fmt --all --check
```

## Deliverable

Return:

- what changed
- files changed
- tests run
- any remaining limitation in the context-aware recall behavior
