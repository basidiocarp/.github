# Annulus: Quality fixes (TTL overflow, model match, cast_sign_loss, wildcard pattern)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** annulus/...
- **Cross-repo edits:** none
- **Non-goals:** new segment features
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — Integer overflow in TTL staleness check (HIGH)
`src/bridge.rs:65` (approx)

The TTL staleness check computes `last_update + ttl_ms` using plain integer addition.
If `last_update` is close to `u64::MAX` or `ttl_ms` is large enough to overflow, the
sum wraps around and the check silently passes. Use `saturating_add` (or `checked_add`
with an explicit fallback) to prevent the overflow.

### 2 — Model name substring match incorrect for `gpt-5` (MEDIUM)
The model-tier classification uses a substring match that incorrectly classifies
`gpt-5` variants. The match pattern should use prefix or exact matching rather than
a loose substring to avoid false positives when new model versions are released.

### 3 — `cast_sign_loss` in statusline rendering (MEDIUM)
A signed-to-unsigned cast in the statusline rendering path can silently lose the sign
bit on negative values, producing a very large unsigned number and corrupted output.
Add an explicit check (`if value < 0 { 0 } else { value as u64 }`) or use `try_from`
with an error fallback.

### 4 — `DegradationTier` wildcard match suppresses exhaustiveness (MEDIUM)
A wildcard `_` arm on a `DegradationTier` match suppresses the compiler's exhaustiveness
check. When a new tier variant is added, the wildcard silently matches it rather than
forcing the developer to handle it explicitly. Replace the wildcard with explicit arms
for all current variants.

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/annulus
cargo build 2>&1 | tail -3
cargo test 2>&1 | tail -5
cargo clippy 2>&1 | tail -10
```

Expected: build and tests pass (3 tests from prior audit); clippy clean.

## Checklist

- [ ] TTL staleness check uses `saturating_add`
- [ ] Model name match uses prefix or exact matching, not loose substring
- [ ] `cast_sign_loss` addressed with explicit guard or `try_from`
- [ ] `DegradationTier` wildcard replaced with explicit variant arms
- [ ] All tests pass, clippy clean
