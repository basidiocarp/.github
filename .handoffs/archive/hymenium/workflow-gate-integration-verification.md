# Hymenium: Workflow Gate Integration Verification

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/src/workflow/`, `hymenium/src/dispatch/`, `hymenium/tests/`, `hymenium/README.md`
- **Cross-repo edits:** none
- **Non-goals:** no workflow engine redesign and no Canopy source changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-workflow-gate-integration-verification.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** workflow gate evaluator tests, dispatch orchestration integration tests, README validation section
- **Reference seams:** existing `MockGateEvaluator`, workflow engine phase gating tests, Canopy client test doubles
- **Spawn gate:** do not launch an implementer until the parent agent identifies the smallest fake/in-memory Canopy-backed evaluator needed for the test

## Spawn Gate Decision

- **Evaluator approach:** extend `MockCanopyClient` (in `dispatch/mock.rs`) to return `TaskDetail` records with variance — some with evidence fields populated, some without. Wire the gate evaluator to inspect those `TaskDetail` evidence fields to determine `code_diff_exists` and `verification_passed` condition outcomes.
- **Test requirement:** prove both directions — auditor phase blocked when `TaskDetail` lacks evidence, auditor phase advances when both evidence types are present.
- **Chaos coverage:** test with partial evidence (diff present, verification absent) to confirm the gate is field-checking, not just returning true.
- **If wiring evaluator to TaskDetail is out of scope:** explicitly document in README that current gates are structural only (phase state machine), not evidence-backed, and add a follow-up handoff for the evidence integration. Do not leave this ambiguous.

## Problem

Hymenium claims the auditor phase cannot start until a real code diff and verification evidence exist, but current tests satisfy the gate with mocks. That proves wiring, not the implemented evidence/diff integration that protects the strict implementer/auditor workflow.

## What needs doing

1. Add a non-ignored integration test proving audit is blocked without both diff and verification evidence.
2. Use a fake or in-memory Canopy-backed evaluator rather than a mock that simply returns success.
3. Update docs if the current implementation only guarantees structural gates, not evidence-backed gates.

## Verification

```bash
cd hymenium && cargo test workflow_gate_blocks_audit_without_real_diff_and_verification
cd hymenium && cargo test workflow
bash .handoffs/hymenium/verify-workflow-gate-integration-verification.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] auditor phase remains blocked without diff evidence
- [ ] auditor phase remains blocked without verification evidence
- [ ] auditor phase advances after both evidence types are recorded
- [ ] test is not `#[ignore]`
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 3 verification quality audit. Severity: high.
