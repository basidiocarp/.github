# Cortina: Hook Executor Verification

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/src/hooks/executor.rs`, `cortina/tests/`, `cortina/README.md`
- **Cross-repo edits:** none
- **Non-goals:** no GateGuard policy changes and no Volva hook DTO changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cortina/verify-hook-executor-verification.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** hook executor implementation/tests and README claims
- **Reference seams:** existing fail-open adapter tests and executor stub tests
- **Spawn gate:** do not launch an implementer until the parent agent decides whether hook executor behavior is intended to remain a no-op stub or become real execution

## Problem

Cortina docs describe hook execution, timeout, and output aggregation behavior, but the current executor is a no-op stub and its tests only prove the stub. Verification should either test real execution behavior or update docs to stop claiming it.

## What needs doing

1. Decide whether the hook executor is intentionally stubbed.
2. If real, add temp-executable tests for success aggregation, nonzero fail-open diagnostics, timeout handling, and context modification limits.
3. If stubbed, update docs and validation expectations so tests do not imply runtime execution exists.

## Verification

```bash
cd cortina && cargo test hooks::executor
bash .handoffs/cortina/verify-hook-executor-verification.sh
```

**Output:**
<!-- PASTE START -->
PASS: hook executor tests run
PASS: executor behavior is documented or tested beyond constructor
Results: 2 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] executor docs match implemented behavior
- [x] success/nonzero/timeout behavior is tested if execution is real
- [x] fail-open diagnostics are tested if execution is real
- [x] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 3 verification quality audit. Severity: medium.
