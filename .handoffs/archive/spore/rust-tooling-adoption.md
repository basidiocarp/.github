# Spore: Rust Tooling Adoption

## Problem

The umbrella handoff [`.handoffs/archive/cross-project/rust-tooling-adoption.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/cross-project/rust-tooling-adoption.md) needed a repo-owned follow-up for `spore/`.

## What exists (state)

- `spore` still uses plain `cargo test`
- there is no documented `cargo-nextest` workflow here
- `criterion` is not yet justified for `spore` and should stay out of scope until a concrete hot path is named
- there is no repo-local whole-command investigation guidance

## What needs doing (intent)

- document the repo-local `cargo-nextest` command surface
- keep `criterion` explicitly out of scope unless a real benchmark target appears
- document the fallback investigation path for a shared library crate like `spore`

## Status

- Added repo-local README guidance for `cargo nextest run`
- Kept `criterion` explicitly out of scope in the repo guidance
- Documented targeted test timing and downstream integration timing as the fallback investigation path

## Verification Notes

- `cargo nextest --version` -> installed locally (`cargo-nextest 0.9.132`)
- `spore/README.md` now documents `cargo nextest run` and the library-oriented timing fallback
- This was a docs-only pass; no repo build or test command was rerun here

## Verification targets

- `cargo nextest --version`
