# Stipe: Control Plane Quality

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/src/backup.rs`, `stipe/src/commands/backup.rs`, `stipe/src/commands/install/runner.rs`, `stipe/src/commands/init.rs`, `stipe/src/commands/*/tests.rs`, `stipe/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no install UX redesign and no package registry changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/stipe/verify-control-plane-quality.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** Hyphae backup command, install runner options, init command options
- **Reference seams:** existing doctor/init/install tests; current backup command output
- **Spawn gate:** do not launch an implementer until the parent agent inspects the dirty Stipe worktree and confirms no user changes would be overwritten

## Problem

Stipe can report Hyphae backup success after file-copy failures because failures are warnings while the command still returns a backup directory. The audit also found boolean-heavy control-plane APIs with clippy suppressions, making dry-run/json/force/repair behavior easy to mix up.

## What needs doing

1. Replace `Option<PathBuf>` style backup success with a structured outcome that records copied, missing, and failed artifacts.
2. Make manual `stipe backup hyphae` fail or clearly report partial backup when DB/binary copies fail.
3. Preserve fail-open behavior where update flows intentionally continue after backup warnings, but make that explicit in the outcome.
4. Replace excessive boolean function parameters in install/init paths with option structs.
5. Split command planning from mutation where that reduces boolean coupling.

## Verification

```bash
cd stipe && cargo test backup
cd stipe && cargo test install
cd stipe && cargo test init
bash .handoffs/stipe/verify-control-plane-quality.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] backup outcome reports partial failure accurately
- [ ] manual backup command does not print unconditional success after copy failures
- [ ] update flow behavior remains deliberate and tested
- [ ] install/init entry points use option structs instead of excessive bool parameters
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 Rust ecosystem audit. Severity: medium. Stipe had a dirty worktree during audit; inspect current state first.
