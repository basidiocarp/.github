# Spore OTel Foundation

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `spore`
- **Allowed write scope:** spore/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

The original OTel handoff was too broad. The real critical path is a single,
repo-scoped foundation in `spore`.

## What needs doing

Add optional OTel support to `spore` behind an `otel` feature flag:

- optional dependencies
- `spore::telemetry` module
- `init_tracer(service_name: &str)`
- serializable trace context propagation helper
- no-op behavior when OTel endpoint is not configured

Do not instrument downstream tools in this handoff.

## Files to modify

- `spore/Cargo.toml`
- `spore/src/telemetry.rs`
- `spore/src/lib.rs` or module wiring
- tests as needed

## Verification

```bash
cd spore && cargo build
cd spore && cargo build --features otel
cd spore && cargo test
cd spore && cargo test --features otel
bash .handoffs/spore/verify-otel-foundation.sh
```

## Checklist

- [x] `spore::telemetry` exists behind `otel`
- [x] tracer init is configured when endpoint is set
- [x] tracer init is a no-op when endpoint is absent
- [x] trace context serializes and deserializes cleanly
- [x] build without `otel` still works
- [x] verify script passes with `Results: N passed, 0 failed`

## Verification Output

### `cargo build`

<!-- PASTE START -->
    Finished `dev` profile [optimized + debuginfo] target(s) in 1.41s
<!-- PASTE END -->

### `cargo build --features otel`

<!-- PASTE START -->
    Finished `dev` profile [optimized + debuginfo] target(s) in 1.18s
<!-- PASTE END -->

### `cargo test`

<!-- PASTE START -->
test result: ok. 90 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.20s

running 7 tests
test result: ok. 5 passed; 0 failed; 2 ignored; 0 measured; 0 filtered out; finished in 0.00s

all doctests ran in 0.53s; merged doctests compilation took 0.33s
<!-- PASTE END -->

### `cargo test --features otel`

<!-- PASTE START -->
test result: ok. 94 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.21s

running 7 tests
test result: ok. 5 passed; 0 failed; 2 ignored; 0 measured; 0 filtered out; finished in 0.01s

all doctests ran in 0.59s; merged doctests compilation took 0.39s
<!-- PASTE END -->

### `bash .handoffs/spore/verify-otel-foundation.sh`

<!-- PASTE START -->
PASS: spore telemetry module exists
PASS: spore otel feature exists
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
    Finished `dev` profile [optimized + debuginfo] target(s) in 0.11s
PASS: spore otel build passes
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
    Finished `test` profile [optimized + debuginfo] target(s) in 0.16s
     Running unittests src/lib.rs (target/debug/deps/spore-beae36297a921118)
   Doc-tests spore
PASS: spore otel tests pass
Results: 4 passed, 0 failed
<!-- PASTE END -->
