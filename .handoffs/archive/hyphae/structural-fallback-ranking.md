# Priority 2: Structural Fallback Ranking

## Task

Implement the next store-side improvement for structural code-context fallback in
`hyphae`.

The current helper in:

- `hyphae/crates/hyphae-store/src/store/context.rs`

already adds structural fragment fallback, but residual limits remain:

- wrapper words such as `Service`, `Manager`, `Controller`, `Handler`, `Impl`
  can still dominate the fragment set
- acronym/initialism-style names are still weakly handled
- fallback matches are returned in discovery order rather than an explicit
  structural strength order

This slice should improve ranking and normalization while staying deterministic
and bounded.

## Priority

`P2`

Do this after the prioritized-merge slice. It improves symbol recovery but has
less user-visible impact than recall-side branch prioritization.

## Ownership

Write scope:

- `hyphae/crates/hyphae-store/src/store/context.rs`

Read-only context:

- `hyphae/crates/hyphae-store/src/store/memoir_store.rs`
- `hyphae/crates/hyphae-store/src/store/search.rs`
- `hyphae/docs/handoffs/completed/CODE-CONTEXT-TERM-EXPANSION-IMPLEMENTER.md`

You are not alone in the codebase. Do not revert others' edits. Keep this slice
inside the store-side code-context helper path so it does not overlap the
MCP-side prioritized merge work.

## Goal

Make structural fallback better at recovering relevant concept names from code
shapes without turning it into fuzzy or semantic search.

Recommended improvements:

- strip or downweight common wrapper suffixes such as `Service`, `Manager`,
  `Controller`, `Handler`, `Impl`
- improve acronym/initialism splitting if there is a small clean way to do it
- rank fallback matches by structural strength:
  exact fragment > prefix > contains
- preserve hard caps and dedupe

## Constraints

- keep the fallback deterministic and bounded
- do not add embeddings or semantic scoring
- do not change MCP output shape in this slice
- do not redesign memoir search APIs

## Tests

Add or update focused tests proving:

- `FooService` can still recover `Foo`
- wrapper-word stripping does not swamp better fragments
- ranking prefers stronger structural matches over weaker contains-only matches

## Acceptance Criteria

- structural fallback ranking is explicit and bounded
- wrapper-word stripping or equivalent normalization improves practical symbol
  recovery
- tests cover the new ranking behavior
- repo-local validation passes

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
- any remaining limitation in the structural fallback ranking
