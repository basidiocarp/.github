# Mycelium: Compile-Info Optimization

## Problem

The audit in [`.audit/workspace/compile-info/mycelium.md`](/Users/williamnewton/projects/basidiocarp/.audit/workspace/compile-info/mycelium.md) found repo-local binary-size and compile-time costs that deserve a dedicated follow-up.

## What exists (state)

- bundled `rusqlite` is retained intentionally for portable local storage
- `[profile.dev]` tuning is present in `mycelium/Cargo.toml`
- the direct `ureq` dependency has been removed from `mycelium/Cargo.toml`

## What needs doing (intent)

- keep bundled SQLite and document the portability tradeoff rather than switching to system SQLite
- keep the tuned `[profile.dev]` block with rationale
- leave HTTP ownership with `spore` instead of carrying a direct `ureq` dependency here

## Completion

- bundled SQLite stays on purpose
- direct `ureq` is removed from `mycelium/Cargo.toml`
- dev builds use the tuned profile in `mycelium/Cargo.toml`
- `mycelium` still inherits `ureq` transitively through `spore`

## Validation

- `cd mycelium && cargo build` -> `Finished 'dev' profile [optimized + debuginfo] target(s) in 1m 07s`
- `cd mycelium && cargo test` -> `test result: ok. 1069 passed; 0 failed; 2 ignored; 0 measured; 0 filtered out`
- `cd mycelium && cargo tree | rg 'rusqlite|ureq'` -> `rusqlite v0.39.0` and transitive `ureq v3.3.0`
- `cd mycelium && cargo tree -i ureq` -> `ureq v3.3.0` is owned by `spore`, not `mycelium` directly
- `bash .handoffs/archive/mycelium/verify-compile-info-optimization.sh` -> `Results: 7 passed, 0 failed`

## Verification targets

- `cd mycelium && cargo build`
- `cd mycelium && cargo test`
- `cd mycelium && cargo tree | rg 'rusqlite|ureq'`
