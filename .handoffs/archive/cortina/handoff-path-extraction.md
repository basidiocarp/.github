# Cortina Handoff Path Extraction

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** cortina/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

`stale-handoff-detection` stalls because the first unit of work is still too broad.
Cortina needs one small, testable parser seam before any stop-hook or audit logic
can be built on top.

## What needs doing

Add a focused parser that reads a handoff markdown file and extracts:

- referenced file paths
- checklist items
- checked vs unchecked status

Keep this handoff limited to parsing and unit tests. Do not add hook logic or CLI
commands here.

## Files to modify

- `cortina/src/handoff_paths.rs`
- `cortina/src/main.rs` or module wiring as needed
- `cortina/src/...` tests for the parser

## Verification

```bash
cd cortina && cargo test handoff_paths --quiet
bash .handoffs/cortina/verify-handoff-path-extraction.sh
```

## Checklist

- [x] parser extracts paths from `Files to modify` sections
- [x] parser extracts inline backtick paths from checklist items
- [x] parser preserves checklist checked/unchecked state
- [x] at least 3 unit tests cover representative handoff markdown
- [x] verify script passes with `Results: N passed, 0 failed`

## Verification Status

- `cd cortina && cargo test handoff_paths --quiet` passed
- `bash .handoffs/cortina/verify-handoff-path-extraction.sh` passed with `Results: 3 passed, 0 failed`
