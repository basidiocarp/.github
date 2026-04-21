# Canopy: Compile-Info Optimization

## Problem

The audit in [`.audit/workspace/compile-info/canopy.md`](/Users/williamnewton/projects/basidiocarp/.audit/workspace/compile-info/canopy.md) flagged a `modern_sqlite` dead-weight risk and a separate `spore` logging cost. After inspecting the current repo state, `canopy` does not actually carry a `modern_sqlite` feature today, so the repo-local work here is documenting the existing bundled-SQLite-only design and confirming the remaining logging cost is cross-repo.

## What changed

- confirmed `modern_sqlite` is not present in `canopy/Cargo.toml`
- documented the bundled-SQLite-only design in `canopy/docs/architecture.md`
- left the `spore` logging / `tracing-subscriber` cost as a deferred cross-repo concern

## What remains intentionally open

- if a future deployment target can rely on system SQLite, revisit `bundled`
- if `spore` gains optional logging, Canopy should inherit that win automatically

## Verification

- `cd canopy && cargo build`
- `cd canopy && cargo test`
- `cd canopy && cargo tree | rg 'rusqlite|tracing-subscriber|modern_sqlite'`

Status: complete under current scope.

## Verification Notes

- `cd canopy && cargo build` passes.
- `cd canopy && cargo test` passes.
- `cd canopy && cargo tree | rg 'rusqlite|tracing-subscriber|modern_sqlite'` shows `rusqlite v0.39.0` and `spore v0.4.9 -> tracing-subscriber v0.3.23`; there is no `modern_sqlite` feature in the manifest.
