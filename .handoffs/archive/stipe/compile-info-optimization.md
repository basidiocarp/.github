# Stipe: Compile-Info Optimization

## Result

The compile-info pass is complete for `stipe`.

- blocking `reqwest` was replaced with `ureq`
- `dialoguer` was updated to `0.12.0`
- the `spore` pin was confirmed aligned with the ecosystem policy at `v0.4.9`
- there is no `modern_sqlite` feature split in `stipe`, and no `rusqlite` cleanup was needed here

## Verification targets

- `cd stipe && cargo build`
- `cd stipe && cargo test`
- `cd stipe && cargo tree | rg 'reqwest|ureq|spore|thiserror'`

## Verification output

- `cargo build` passed
- `cargo test` passed
- `cargo tree | rg 'reqwest|ureq|spore|dialoguer|thiserror'` showed `dialoguer v0.12.0`, `spore v0.4.9 -> thiserror v2.0.18 -> ureq v3.3.0`, and direct `ureq v3.3.0`; `reqwest` no longer appears in the graph
