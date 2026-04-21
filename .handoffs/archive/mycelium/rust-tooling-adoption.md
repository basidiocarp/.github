# Mycelium: Rust Tooling Adoption

## Problem

The umbrella handoff [`.handoffs/archive/cross-project/rust-tooling-adoption.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/cross-project/rust-tooling-adoption.md) needed a repo-owned follow-up for `mycelium/`.

## What exists (state)

- `mycelium` already has a `cargo nextest` command path, but the repo docs were
  too terse about how it behaves
- `mycelium` is one of the repos explicitly in scope for meaningful Criterion
  benchmarks, and the command-routing path is a good fit
- there was no repo-local guidance for choosing whole-command investigation vs
  benchmarking

## What needs doing (intent)

- document the repo-local `cargo-nextest` command surface clearly
- add at least one real Criterion benchmark for a known hot path
- document when end-to-end timing is preferred over Criterion for `mycelium`

## Status

- Added a Criterion benchmark for `discover::registry::{classify_command, rewrite_command}`
- Expanded the `mycelium cargo nextest` docs to explain pass-through behavior
- Added repo-local guidance on when to use Criterion versus whole-command timing

## Verification Notes

- `cargo nextest --version` -> installed locally (`cargo-nextest 0.9.132`)
- `cd mycelium && cargo bench --no-run --bench tooling_hot_paths` -> passed

## Verification targets

- `cargo nextest --version`
- `cd mycelium && cargo bench --no-run --bench tooling_hot_paths`
