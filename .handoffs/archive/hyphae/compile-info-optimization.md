# Hyphae: Compile-Info Optimization

## Problem

The audit in [`.audit/workspace/compile-info/hyphae.md`](/Users/williamnewton/projects/basidiocarp/.audit/workspace/compile-info/hyphae.md) found real compile-time and dependency-weight issues that should be resolved deliberately.

## What exists (state)

- repo-local `[profile.dev]` tuning is now in `hyphae/Cargo.toml`
- `fastembed` and `hf-hub` dominate default build cost
- `ureq` v2 and v3 are both present through different dependency paths
- `modern_sqlite` is no longer enabled in the workspace `rusqlite` feature set

## What needs doing (intent)

- evaluate and land a tuned dev profile if it improves iteration time without hurting debugging
- document and tighten the default embeddings feature story, including release
  binaries and install guidance
- investigate whether the `hf-hub`/`ureq` duplication can be reduced without
  forcing unsafe churn; if not, document the reason it remains

## Verification targets

- `cd hyphae && cargo build --workspace`
- `cd hyphae && cargo test --workspace`
- `cd hyphae && cargo build --workspace --no-default-features`

## Status

- Landed repo-local dev profile tuning in `hyphae/Cargo.toml`
- Removed the unneeded `modern_sqlite` feature from workspace `rusqlite`
- Release assets now expose both slim and embeddings-enabled prebuilt binaries
  so the install story matches the feature split
- Left the `hf-hub`/`ureq` duplication in place for now because resolving it
  would require dependency updates outside the low-risk compile-info scope

## Upstream dependency note

The remaining `hf-hub` / `ureq` v2+v3 duplication is documented and deferred on
purpose.

- `hyphae` still uses `ureq v3` directly in its HTTP embedder path
- `spore` also uses `ureq v3` for self-update downloads
- `fastembed` still depends on `hf-hub 0.4.x`, which keeps the older `ureq v2`
  chain alive
- `hf-hub 0.5.x` has moved to `ureq v3`, but current `fastembed` releases have
  not adopted it yet

In other words, the remaining fix depends on upstream fastembed moving to
hf-hub 0.5.x or on a separate maintained fork or cross-repo migration.

That means this duplication is no longer a `hyphae`-only cleanup. Finishing it
would require one of:

- upstream `fastembed` moving to `hf-hub 0.5.x`
- a maintained local fork of `fastembed`
- a coordinated cross-repo HTTP client migration involving both `hyphae` and
  `spore`

That work is intentionally out of scope for this handoff.

## Completion

This handoff is complete under the current scope.

- low-risk local compile-info fixes are landed
- the release/install surface now reflects the real feature split
- the remaining `hf-hub` / `ureq` duplication is documented as an upstream or
  cross-repo follow-up instead of being left ambiguous

## Verification Notes

- `cd hyphae && cargo build --workspace`
- `cd hyphae && cargo test --workspace`
- `cd hyphae && cargo build --workspace --no-default-features`

## Output

```text
<!-- PASTE START -->
    Finished `dev` profile [optimized + debuginfo] target(s) in 1m 52s
<!-- PASTE END -->
```

```text
<!-- PASTE START -->
test result: ok. 240 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.98s
<!-- PASTE END -->
```

```text
<!-- PASTE START -->
    Finished `dev` profile [optimized + debuginfo] target(s) in 28.30s
<!-- PASTE END -->
```
