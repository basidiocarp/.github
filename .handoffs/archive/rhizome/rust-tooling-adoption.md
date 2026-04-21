# Rhizome: Rust Tooling Adoption

## Problem

The umbrella handoff [`.handoffs/archive/cross-project/rust-tooling-adoption.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/cross-project/rust-tooling-adoption.md) needed a repo-owned follow-up for `rhizome/`.

## What exists (state)

- `rhizome` previously used plain `cargo test` as the main documented loop
- repo-local `cargo-nextest` guidance was missing from the docs surface
- `rhizome` is one of the repos explicitly in scope for meaningful `criterion` benchmarks
- repo-local whole-command investigation guidance was missing

## What needs doing (intent)

- document the repo-local `cargo-nextest` command surface
- add at least one real `criterion` benchmark for a known hot path
- document when whole-command timing is preferred over Criterion for `rhizome`

## Verification targets

- `cargo nextest --version`
- `cd rhizome && cargo bench --no-run -p rhizome-treesitter --bench parse_symbols`

## Status

- Repo-local tooling docs are now in `rhizome/docs/tooling.md` and linked from the README/docs index.
- The benchmark target is now `rhizome-treesitter/benches/parse_symbols.rs` and measures the real `TreeSitterBackend::get_symbols` path against a large Rust fixture.
- Verification passed for `cargo nextest --version` and `cd rhizome && cargo bench --no-run -p rhizome-treesitter --bench parse_symbols`.
- `cd rhizome && cargo test -p rhizome-treesitter --tests` also passed.
- Repo-local docs now point to whole-command timing for end-to-end investigation instead of `cargo-flamegraph`.
