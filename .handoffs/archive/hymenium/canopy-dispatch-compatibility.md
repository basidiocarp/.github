# Hymenium: Canopy Dispatch Compatibility

<!-- Save as: .handoffs/hymenium/canopy-dispatch-compatibility.md -->
<!-- Create verify script: .handoffs/hymenium/verify-canopy-dispatch-compatibility.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/src/dispatch/cli.rs`, `hymenium/src/dispatch/orchestrate.rs`, `hymenium/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no Canopy service endpoint migration and no phase reconciliation
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-canopy-dispatch-compatibility.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** `hymenium/src/dispatch/cli.rs`, dispatch CLI argument builders, Canopy command output parsing
- **Reference seams:** existing dispatch tests and the A1 orchestration dispatch contract fix
- **Spawn gate:** do not launch an implementer until the parent agent confirms whether the local dogfood patch should be kept, reshaped, or replaced

## Problem

The dogfood dispatch failed because Hymenium sent role names that Canopy does not accept and expected a raw task id where Canopy now returns JSON. These are compatibility bugs at the CLI integration boundary and should be locked with tests.

## What exists (state)

- **Role model:** Hymenium workflow roles include names like `Worker` and `Output Verifier`
- **Canopy CLI:** `--required-role` accepts `orchestrator`, `implementer`, and `validator`
- **Dogfood patch:** local source already contains a narrow role-mapping and JSON task-id parser; this handoff formalizes it with review and verification

## What needs doing (intent)

Make `hymenium dispatch` compatible with current Canopy CLI behavior and prove it with tests that would have caught the dogfood failures.

## Scope

- **Primary seam:** Hymenium Canopy CLI adapter
- **Allowed files:** dispatch CLI adapter and tests
- **Explicit non-goals:** no work-queue UX changes, no workflow phase advancement, no capability registry dispatch

## Verification

```bash
cd hymenium && cargo test dispatch
cd hymenium && cargo fmt --check
bash .handoffs/hymenium/verify-canopy-dispatch-compatibility.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Hymenium roles map to Canopy-required role values
- [ ] JSON `canopy task create` output is parsed for `task_id`
- [ ] raw task-id output remains supported as a fallback
- [ ] tests cover implementer and validator role mappings
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 CentralCommand dogfood run. This is the narrowest compatibility fix needed before deeper runtime reconciliation work.

