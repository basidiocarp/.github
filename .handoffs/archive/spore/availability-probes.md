# Spore Availability Probes

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `spore`
- **Allowed write scope:** spore/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

The runtime seam in `graceful-degradation-classification` belongs in `spore`:
one probe surface that returns availability, tier, and degraded capabilities.

## What needs doing

Add `spore` availability probing:

- `AvailabilityReport`
- `DegradationTier`
- `probe_tool(...)`
- non-blocking checks with bounded timeout

Keep this handoff limited to `spore`. Do not add Annulus CLI output or Cap UI here.

## Files to modify

- `spore/src/...`
- `spore/src/...` tests for availability and timeout behavior

## Verification

```bash
cd spore && cargo test availability --quiet
bash .handoffs/spore/verify-availability-probes.sh
```

## Checklist

- [x] all registered tools can be probed
- [x] the compiled-in tier table matches the taxonomy
- [x] unavailable tools include a meaningful reason
- [x] probe time is bounded
- [x] verify script passes with `Results: N passed, 0 failed`

## Verification Output

### `cargo build` (tail -5)

```
   Compiling spore v0.4.10 (/Users/williamnewton/projects/basidiocarp/spore)
    Finished `dev` profile [optimized + debuginfo] target(s) in 2.69s
```

### `cargo test availability` (tail -20)

```
    Finished `test` profile [optimized + debuginfo] target(s) in 2.43s
     Running unittests src/lib.rs (target/debug/deps/spore-8b9828fac8f72aa4)

running 13 tests
test availability::tests::all_tools_have_at_least_one_degraded_capability ... ok
test availability::tests::degradation_tier_display ... ok
test availability::tests::single_probe_completes_within_budget ... ok
test availability::tests::tier1_tools_have_degraded_capabilities ... ok
test availability::tests::probe_tool_report_carries_degraded_capabilities ... ok
test availability::tests::tier_assignments_match_taxonomy ... ok
test availability::tests::unknown_tool_returns_tier3_report ... ok
test availability::tests::unavailable_tool_reason_mentions_path ... ok
test availability::tests::unavailable_tool_has_non_empty_reason ... ok
test availability::tests::all_registered_tools_are_probeable ... ok
test availability::tests::probe_all_covers_every_registered_tool ... ok
test availability::tests::probe_all_completes_within_reasonable_time ... ok
test availability::tests::probe_all_completes_within_budget ... ok

test result: ok. 13 passed; 0 failed; 0 ignored; 0 measured; 90 filtered out; finished in 0.00s
```

### `cargo clippy --all-targets -- -D warnings` (availability.rs errors)

```
(none — zero errors in src/availability.rs)
```

All 15 clippy errors are pre-existing in src/datetime.rs and src/logging.rs.

### `verify-availability-probes.sh`

```
PASS: availability report exists
PASS: availability tests exist
PASS: cargo availability tests pass
Results: 3 passed, 0 failed
```
