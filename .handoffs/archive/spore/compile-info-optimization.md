# Spore: Compile-Info Optimization

## Status

Done. `spore` now keeps the logging and self-update surfaces available by default, but exposes both behind optional Cargo features so slimmer consumers can disable them when they do not need those APIs. The crate also now has an explicit `profile.dev` policy and `panic = "abort"` in release.

## What changed

- Added `logging` and `http` features in [`spore/Cargo.toml`](/Users/williamnewton/projects/basidiocarp/spore/Cargo.toml).
- Marked `tracing-subscriber` and `ureq` optional while keeping both enabled by default for compatibility.
- Gated [`spore::logging`](/Users/williamnewton/projects/basidiocarp/spore/src/logging.rs) and [`spore::self_update`](/Users/williamnewton/projects/basidiocarp/spore/src/self_update.rs) behind those features in [`spore/src/lib.rs`](/Users/williamnewton/projects/basidiocarp/spore/src/lib.rs).
- Added [`[profile.dev]`](/Users/williamnewton/projects/basidiocarp/spore/Cargo.toml) tuning and `panic = "abort"` in release.
- Documented the default-on feature split in [`spore/README.md`](/Users/williamnewton/projects/basidiocarp/spore/README.md).

## Verification

- `cd spore && cargo build` -> passed
- `cd spore && cargo test` -> passed
- `cd spore && cargo build --no-default-features` -> passed
- `cd spore && cargo test --no-default-features` -> passed
- `cd spore && cargo tree -e features` -> passed; default build shows `tracing-subscriber` and `ureq` in the feature graph
- `cd spore && cargo tree --no-default-features -e features | rg 'tracing-subscriber|ureq'` -> passed by returning no matches
- `bash .handoffs/archive/spore/verify-compile-info-optimization.sh` -> `Results: 13 passed, 0 failed`

## Notes

The current design keeps `logging` and `http` enabled by default so existing consumers do not need to change. Consumers that want a slimmer embed can disable default features and opt back into only the surfaces they need.
