# Canopy: Rust Tooling Adoption

## Problem

The umbrella handoff [`.handoffs/archive/cross-project/rust-tooling-adoption.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/cross-project/rust-tooling-adoption.md) needed a repo-owned follow-up for `canopy/`.

## What exists (state)

- `canopy` still uses plain `cargo test`
- there is no documented `cargo-nextest` workflow here
- `criterion` is not yet justified for `canopy` and should stay out of scope until a concrete hot path is named
- there is no repo-local whole-command investigation guidance

## What needs doing (intent)

- document the repo-local `cargo-nextest` command surface
- keep `criterion` explicitly out of scope unless a real benchmark target appears
- document when whole-command timing is useful for `canopy`

## Status

- Added repo-local README guidance for `cargo nextest run`
- Kept `criterion` explicitly out of scope in the repo guidance
- Added whole-command timing guidance for real operator paths like `api snapshot`

## Verification Notes

- `cargo nextest --version` -> installed locally (`cargo-nextest 0.9.132`)
- `canopy/README.md` now documents `cargo nextest run` and whole-command timing guidance
- This was a docs-only pass; no repo build or test command was rerun here

## Verification targets

- `cargo nextest --version`
