# Hyphae: Rust Tooling Adoption

## Problem

The umbrella handoff [`.handoffs/archive/cross-project/rust-tooling-adoption.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/cross-project/rust-tooling-adoption.md) needed a repo-owned follow-up for `hyphae/`.

## What exists (state)

- `hyphae` still uses plain `cargo test`
- there is no documented `cargo-nextest` workflow here
- `hyphae` is valid `criterion` scope on named retrieval hot paths, with the
  follow-up now tracked in
  [`.handoffs/archive/hyphae/criterion-hotpaths.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/hyphae/criterion-hotpaths.md)
- there is no repo-local whole-command investigation guidance

## What needs doing (intent)

- document the repo-local `cargo-nextest` command surface
- route any `criterion` work into the named retrieval-hot-path follow-up instead
  of leaving the scope open-ended
- document when whole-command timing is preferred over Criterion for `hyphae`

## Status

- Added repo-local README guidance for `cargo nextest run`
- Added whole-command timing guidance for end-to-end investigation
- Named the first-wave `criterion` scope and moved implementation into
  [`.handoffs/archive/hyphae/criterion-hotpaths.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/hyphae/criterion-hotpaths.md)

## Verification Notes

- `cargo nextest --version` -> installed locally (`cargo-nextest 0.9.132`)
- `hyphae/README.md` now documents `cargo nextest run` and whole-command timing guidance
- This repo-owned tooling handoff stays docs-only; the benchmark implementation
  is now a separate executable follow-up

## Verification targets

- `cargo nextest --version`
- route benchmark work through [`.handoffs/archive/hyphae/criterion-hotpaths.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/hyphae/criterion-hotpaths.md)
