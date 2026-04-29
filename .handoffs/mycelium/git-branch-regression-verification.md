# Mycelium: Git Branch Regression Verification

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** `mycelium/src/vcs/git/status.rs`, `mycelium/tests/`, `mycelium/AGENTS.md`
- **Cross-repo edits:** none
- **Non-goals:** no git command feature redesign and no output filter rewrite
- **Verification contract:** run the repo-local commands below and `bash .handoffs/mycelium/verify-git-branch-regression-verification.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** git status command classification tests and temp-repo branch integration tests
- **Reference seams:** ignored branch creation regression tests in `src/vcs/git/status.rs`
- **Spawn gate:** do not launch an implementer until the parent agent chooses which branch-mode classification can be pure unit tests

## Problem

Mycelium has regression tests for branch write behavior, but the exact temp-repo tests are ignored. Default `cargo test` can pass while command preservation around branch creation/write paths is untested.

## What needs doing

1. Extract list-versus-write branch classification into non-ignored pure unit tests.
2. Keep temp-repo git execution coverage as integration tests and document when to run ignored tests.
3. Update validation docs so default tests cover the classification regression.

## Verification

```bash
cd mycelium && cargo test branch_creation
cd mycelium && cargo test --ignored test_branch_creation
bash .handoffs/mycelium/verify-git-branch-regression-verification.sh
```

**Output:**
<!-- PASTE START -->
PASS: branch classification tests run by default
PASS: ignored branch integration tests are documented
Results: 2 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] branch list/write classification has non-ignored tests
- [x] temp-repo branch creation tests remain available and documented
- [x] default validation catches command-preservation regressions
- [x] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 3 verification quality audit. Severity: medium.
