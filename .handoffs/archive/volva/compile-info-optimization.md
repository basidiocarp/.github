# Volva: Compile-Info Optimization

## Problem

The audit in [`.audit/workspace/compile-info/volva.md`](/Users/williamnewton/projects/basidiocarp/.audit/workspace/compile-info/volva.md) found one especially high-value optimization lane around profiles and release configuration.

## What exists (state)

- `[profile.release]` is now set in `volva/Cargo.toml` with `opt-level = 3`, `lto = true`, `codegen-units = 1`, `panic = "abort"`, and `strip = true`
- `[profile.dev]` is now set in `volva/Cargo.toml` with `opt-level = 1` and `debug = "line-tables-only"`
- `profile.dev.package."*"` now uses `opt-level = 3` so dependencies stay reasonably optimized in dev builds
- async `reqwest` remains the intentional HTTP stack for Volva's auth and API clients because Volva is a networked host layer

## What needs doing (intent)

- document the chosen profile policy in the repo README
- keep the async HTTP stack decision explicit rather than treating it like an accidental dependency

## Verification targets

- `cd volva && cargo build --release`
- `cd volva && cargo test`
- `cd volva && cargo check`

## Status

Complete. The repo now carries the intended release/dev profile policy, the README documents the tradeoff, and the remaining async HTTP cost is intentional for this networked host layer.

## Verification output

- `cd volva && cargo build --release` -> `Finished \`release\` profile [optimized] target(s) in 8.73s`
- `cd volva && cargo test` -> `Finished \`test\` profile [optimized + debuginfo] target(s) in 1m 00s`
- `cd volva && cargo test` -> `23 passed, 0 failed` for `volva-runtime`
- `cd volva && cargo check` -> `Finished \`dev\` profile [optimized + debuginfo] target(s) in 10.81s`
