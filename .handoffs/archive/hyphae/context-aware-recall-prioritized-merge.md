# Priority 1: Context-Aware Recall Prioritized Merge

## Task

Implement the highest-value remaining recall improvement in `hyphae` by changing
context-aware recall from an eager, branch-by-branch truncation model to a
prioritized candidate merge model.

Today `run_context_aware_recall(...)` in:

- `hyphae/crates/hyphae-mcp/src/tools/memory.rs`

still depends on the order that candidate branches are merged. That means
context-specific hits may not displace lower-value primary project hits once the
limit is already full.

This slice should gather candidates from the relevant branches, apply a small
explicit branch priority, dedupe, and truncate once at the end.

## Priority

`P1`

Do this before the structural fallback ranking slice. This has the larger effect
on actual recall quality for user-visible queries.

## Ownership

Write scope:

- `hyphae/crates/hyphae-mcp/src/tools/memory.rs`
- `hyphae/crates/hyphae-mcp/src/tools/schema.rs` only if user-facing wording
  needs a narrow precision update
- `hyphae/docs/MCP-TOOLS.md` only if the recall description needs a narrow
  wording update
- `hyphae/docs/FEATURES.md` only if the recall description needs a narrow
  wording update

Read-only context:

- `hyphae/crates/hyphae-store/src/store/context.rs`
- `hyphae/docs/handoffs/completed/CONTEXT-AWARE-RECALL.md`
- `hyphae/docs/handoffs/completed/CODE-CONTEXT-TERM-EXPANSION-VALIDATOR.md`

You are not alone in the codebase. Do not revert others' edits. Do not edit the
store-side context helper path; that is outside this handoff.

## Goal

Make context-aware recall merge candidates explicitly instead of implicitly.

Recommended model:

1. collect candidates from:
   - primary project recall
   - session boost branch
   - code-context branch
   - shared fallback branch
2. assign a small fixed branch priority, for example:
   - session/code-context
   - primary
   - shared fallback
3. dedupe by memory ID
4. preserve stable intra-branch order
5. truncate only once at the end

The result should let context-specific hits beat weaker general hits at low
limits without redesigning the overall recall system.

## Constraints

- keep the output shape stable
- do not redesign store search APIs
- keep the change local to the MCP recall layer
- avoid a large scoring system; use explicit branch priority only

## Tests

Add or update tests proving:

- a code-context hit can beat a weaker primary project hit at `limit: 1`
- a session-shaped query still prefers session memories
- shared fallback remains last-priority when more specific branches have hits

## Acceptance Criteria

- context-aware recall uses a prioritized candidate merge
- truncation happens only after dedupe and branch-priority ordering
- tests make the intended ordering obvious
- repo-local validation passes

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
- any remaining limitation in the prioritized merge behavior
