# Structural Fallback Handoff

## Task

Implement a narrow structural fallback for code-context expansion in `hyphae`.

The current code-term extraction fix made context expansion deterministic and
cheap, but it is still heavily dependent on exact concept-name matches and
per-term concept FTS. This slice should improve graceful degradation when a
query contains code-shaped terms but exact or direct FTS lookup is too sparse.

The fallback should stay structural, not semantic:

- no embeddings
- no fuzzy ranking subsystem
- no broad search redesign

## Ownership

Write scope:

- `hyphae/crates/hyphae-store/src/store/context.rs`

Optional tests in:

- `hyphae/crates/hyphae-store/src/store/context.rs`

Read-only context:

- `hyphae/crates/hyphae-store/src/store/memoir_store.rs`
- `hyphae/crates/hyphae-store/src/store/search.rs`
- `hyphae/docs/handoffs/completed/CODE-CONTEXT-TERM-EXPANSION-IMPLEMENTER.md`

You are not alone in the codebase. Do not revert others' edits. Keep the change
inside the store-side context helper surface so it does not overlap the MCP-side
recall follow-up work.

## Goal

When extracted code terms do not produce enough useful concept names through the
current exact/FTS path, add one narrow structural fallback that can still return
relevant concept names from the `code:{project}` memoir.

Examples of acceptable structural fallback behavior:

- derive additional lookup candidates from path/file-stem fragments
- split CamelCase or snake_case terms into stable structural pieces
- try concept-name containment/prefix matching in memoir-local concept rows

Examples of unacceptable behavior:

- semantic similarity
- heuristic scoring across unrelated concept attributes
- large new search API surface

## Constraints

- keep the fallback deterministic and bounded
- preserve the current hard cap on returned concept names
- dedupe results
- degrade gracefully when no code memoir exists
- do not change MCP output shape or recall ranking in this slice

## Acceptance Criteria

- structural fallback is implemented in the store-side code-context helper path
- existing code-term expansion behavior still passes
- at least one new focused test proves the fallback helps when direct term
  lookup alone is insufficient
- no drift into broader search redesign

## Validation

Run:

```bash
cd /Users/williamnewton/projects/basidiocarp/hyphae
cargo test -p hyphae-store
cargo fmt --all --check
```

## Deliverable

Return:

- what changed
- files changed
- tests run
- any remaining limitation in the structural fallback
