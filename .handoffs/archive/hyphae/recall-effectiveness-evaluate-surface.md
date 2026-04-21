# Recall Effectiveness Evaluate Surface

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none
- **Non-goals:** changing the scoring algorithm or hybrid ranking implementation
- **Verification contract:** run the repo-local commands named here and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only

## Problem

`hyphae evaluate` still reports general agent-improvement metrics, but it does not
surface whether recall-effectiveness scoring is actually populated or affecting
retrieval. That leaves the learning loop hard to inspect from the CLI.

## What Needs Doing

Extend `hyphae evaluate` with recall-effectiveness reporting, for example:

- fraction of recalled memories with a non-zero effectiveness score
- average learned effectiveness across the evaluation window
- top recalled memories by effectiveness

Keep this handoff limited to the reporting surface and tests.

## Files To Modify

- `hyphae/crates/hyphae-cli/src/commands/evaluate.rs`
- `hyphae/crates/hyphae-store/src/store/evaluation.rs` if more evaluation data needs to be exposed
- tests as needed

## Verification

```bash
cd hyphae && cargo test --workspace evaluate --quiet
cd hyphae && cargo test --workspace recall_effectiveness --quiet
bash .handoffs/archive/hyphae/verify-recall-effectiveness-evaluate-surface.sh
```

## Checklist

- [x] `hyphae evaluate` shows recall-effectiveness metrics
- [x] tests cover the added reporting
- [x] verify script passes with `Results: N passed, 0 failed`

## Verification Evidence

```text
$ cd /Users/williamnewton/projects/basidiocarp/hyphae && cargo test --workspace evaluate --quiet

running 5 tests
.....
test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 151 filtered out; finished in 0.02s
```

```text
$ cd /Users/williamnewton/projects/basidiocarp/hyphae && cargo test --workspace recall_effectiveness --quiet

running 1 test
.
test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 155 filtered out; finished in 0.00s

running 8 tests
........
test result: ok. 8 passed; 0 failed; 0 ignored; 0 measured; 239 filtered out; finished in 0.05s
```

```text
$ bash /Users/williamnewton/projects/basidiocarp/.handoffs/archive/hyphae/verify-recall-effectiveness-evaluate-surface.sh
PASS: evaluate command file exists
PASS: evaluate surface references recall effectiveness
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
PASS: workspace evaluate tests pass
Results: 3 passed, 0 failed
```
