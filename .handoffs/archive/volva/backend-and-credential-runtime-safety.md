# Volva: Backend And Credential Runtime Safety

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `volva`
- **Allowed write scope:** `volva/crates/volva-runtime/src/backend/official_cli.rs`, `volva/crates/volva-runtime/src/hooks.rs`, `volva/crates/volva-config/src/lib.rs`, `volva/crates/volva-auth/src/`, `volva/crates/volva-cli/src/run.rs`, `volva/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no backend provider rewrite and no Septa hook DTO redesign
- **Verification contract:** run the repo-local commands below and `bash .handoffs/volva/verify-backend-and-credential-runtime-safety.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** official CLI backend, hook adapter subprocess env handling, config validation, auth storage
- **Reference seams:** hook adapter timeout implementation, `volva-auth` save permissions, runtime backend tests
- **Spawn gate:** do not launch an implementer until the parent agent chooses the default trust model for project-local `volva.json` hook adapters

## Problem

Volva's official CLI backend runs the model command with no bounded wait or cleanup policy. Project-local `volva.json` can configure a hook adapter command that executes with the inherited environment, exposing API keys or other secrets to repo-controlled commands. Saved auth credentials are written with restrictive permissions but loaded without checking existing file permissions. The data integrity audit also found corrupted checkpoint JSON is silently converted to empty state during load, which can make resume proceed from the wrong state.

The security audit added that hook adapter diagnostics can re-emit sensitive adapter output. Hook payloads include prompt text and backend stdout/stderr; if an adapter echoes stdin or inherited environment and fails or times out, Volva can print secret-bearing diagnostics to stderr.

## What needs doing

1. Add configurable backend subprocess deadlines and kill/wait cleanup for official CLI runs.
2. Minimize or allowlist environment variables passed to hook adapter commands.
3. Warn, refuse, or require explicit trust for project-local hook adapter commands outside the approved Cortina adapter.
4. Reject or warn on overly permissive saved credential file modes.
5. Reject corrupted checkpoint JSON on load and consider DB `CHECK(json_valid(...))` constraints for checkpoint state/metadata.
6. Redact prompt/backend output and secret-like values from hook adapter diagnostics before they are printed or persisted.
7. Add tests for backend timeout cleanup, hook adapter env exposure, diagnostic redaction, auth storage permissions, and corrupt checkpoint rejection.

## Verification

```bash
cd volva && cargo test -p volva-runtime official_cli hook_adapter
cd volva && cargo test -p volva-runtime checkpoint
cd volva && cargo test -p volva-auth storage
bash .handoffs/volva/verify-backend-and-credential-runtime-safety.sh
```

**Output:**
<!-- PASTE START -->
PASS: official_cli tests pass
PASS: checkpoint tests pass
PASS: auth storage tests pass
PASS: env_clear applied to hook adapter subprocess
PASS: trusted field in HookAdapterConfig
PASS: corrupted checkpoint fails loudly
PASS: credential file permission check on load
PASS: backend subprocess has timeout
Results: 8 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] official CLI backend cannot hang indefinitely
- [x] killed backend children are reaped
- [x] hook adapters receive only intentional environment data
- [x] project-local hook adapter trust is explicit
- [x] hook adapter diagnostics redact prompt/backend output and secret-like values
- [x] permissive credential files produce a warning or error
- [x] corrupted checkpoint JSON fails loudly instead of becoming empty state
- [x] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 2 runtime safety audit. Severity: medium/high.
