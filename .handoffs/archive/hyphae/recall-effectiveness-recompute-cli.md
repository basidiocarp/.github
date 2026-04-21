# Recall Effectiveness Recompute CLI

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none
- **Non-goals:** reworking shipped recall-effectiveness scoring internals or hybrid ranking
- **Verification contract:** run the repo-local commands named here and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only

## Problem

`hyphae` already computes `recall_effectiveness`, but it does so implicitly from
session-end and signal flows. There is still no explicit operator CLI to
recompute effectiveness on demand, which leaves the scoring system hard to audit,
repair, or backfill.

## What Needs Doing

Add a narrow CLI surface under `hyphae feedback` that can recompute stored
recall-effectiveness records without reintroducing the older umbrella scope.

Preferred shape:

- `hyphae feedback compute --session-id <id>` for targeted recompute
- optional `hyphae feedback compute --all` for ended sessions

The implementation should reuse the existing store scoring path instead of
duplicating the algorithm.

## Files To Modify

- `hyphae/crates/hyphae-cli/src/commands/feedback.rs`
- `hyphae/crates/hyphae-cli/src/cli.rs`
- `hyphae/crates/hyphae-cli/src/main.rs` if wiring needs adjustment
- `hyphae/crates/hyphae-store/src/store/feedback.rs` only if a public or broader recompute seam is required
- tests as needed

## Verification

```bash
cd hyphae && cargo test --workspace feedback --quiet
cd hyphae && cargo test --workspace recall_effectiveness --quiet
bash .handoffs/hyphae/verify-recall-effectiveness-recompute-cli.sh
```

## Checklist

- [x] `hyphae feedback compute` exists
- [x] the CLI can recompute for a targeted session or another explicit bounded scope
- [x] the implementation reuses existing scoring logic instead of duplicating it
- [x] tests cover the new CLI path
- [x] verify script passes with `Results: N passed, 0 failed`

## Verification Status

- `cd hyphae && cargo test --workspace feedback --quiet` passed
- `cd hyphae && cargo test --workspace recall_effectiveness --quiet` passed
- `bash .handoffs/hyphae/verify-recall-effectiveness-recompute-cli.sh` passed with `Results: 4 passed, 0 failed`
