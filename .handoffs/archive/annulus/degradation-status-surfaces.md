# Annulus Degradation Status Surfaces

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** annulus/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

Once `spore` can report degraded state, Annulus needs its own bounded operator
surface: a compact indicator in the statusline and a fuller JSON or CLI status
view.

## What needs doing

Add Annulus degradation surfaces:

- statusline degraded indicator
- `annulus status --json`
- mapping from `spore` availability reports into operator-facing status

Keep this handoff limited to Annulus. Do not build the Cap panel here.

## Files to modify

- `annulus/src/...`
- `annulus/src/...` tests

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/annulus && cargo build 2>&1 | tail -5
Finished `dev` profile [unoptimized + debuginfo] target(s) in 1.36s

cd /Users/williamnewton/projects/basidiocarp/annulus && cargo test 2>&1 | tail -10
test result: ok. 53 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out

cd /Users/williamnewton/projects/basidiocarp/annulus && cargo clippy --all-targets -- -D warnings 2>&1 | tail -10
Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.33s

bash /Users/williamnewton/projects/basidiocarp/.handoffs/annulus/verify-degradation-status-surfaces.sh
PASS: annulus status command exists
PASS: spore availability is consumed
PASS: cargo status tests pass
Results: 3 passed, 0 failed
```

## Checklist

- [ ] `annulus status --json` emits availability reports
- [ ] statusline can show a degraded indicator
- [ ] Tier 1 and Tier 2 absence is surfaced more prominently than Tier 3
- [ ] unavailable probes do not crash status rendering
- [ ] verify script passes with `Results: N passed, 0 failed`
