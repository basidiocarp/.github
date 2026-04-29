# Cortina: Capture Policy Boundary

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/src/hooks/pre_tool_use.rs`, `cortina/src/hooks/gate_guard.rs`, `cortina/src/adapters/`, `cortina/tests/`, `cortina/README.md`, `cortina/AGENTS.md`
- **Cross-repo edits:** none; Lamella/Stipe policy ownership changes require a separate handoff
- **Non-goals:** no new hook envelope schema and no Volva hook DTO changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cortina/verify-capture-policy-boundary.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** `src/hooks/pre_tool_use.rs`, `src/hooks/gate_guard.rs`, `src/adapters/mod.rs`, Claude adapter response builders, docs
- **Reference seams:** `septa/hook-execution-v1.schema.json`, existing adapter fail-open tests
- **Spawn gate:** do not launch an implementer until the parent agent decides whether GateGuard should be opt-in blocking or advisory-only by default

## Problem

Cortina is documented as lifecycle capture, but `PreToolUse` can emit blocking permission decisions. That turns capture into policy enforcement and risks violating fail-open expectations. Cortina README also points one Septa seam at a nonexistent `src/statusline.rs`.

The docs drift audit confirmed the stale file-reference side: Cortina README still routes `usage-event-v1` work to `src/statusline.rs`, which does not exist in the repo.

The runtime safety audit confirmed the process-boundary risk: GateGuard state is process-local, while real hook invocations can start a fresh Cortina process for each call. A blocking gate can therefore fail to advance on retry even after investigation evidence exists.

## What needs doing

1. Make GateGuard blocking opt-in or advisory-only by default.
2. Move policy ownership out of Cortina default capture path, or make the policy boundary explicit in docs and config.
3. Remove inconsistent `thread_local` assumptions if hook invocations are process-per-call.
4. Update README/AGENTS to describe the actual capture/policy boundary and correct Septa-related file references.
5. Preserve adapter fail-open behavior.
6. Add a process-boundary regression that invokes the adapter twice as separate processes and proves the gate can advance or is advisory-only.

## Verification

```bash
cd cortina && cargo test adapter
cd cortina && cargo test pre_tool_use
cd cortina && cargo test gate_guard
bash .handoffs/cortina/verify-capture-policy-boundary.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] default lifecycle capture path does not block host operations
- [ ] any blocking GateGuard behavior is opt-in and documented
- [ ] GateGuard behavior does not depend on same-process `thread_local` retries
- [ ] docs do not route `usage-event-v1` work to nonexistent `src/statusline.rs`
- [ ] adapter and pre-tool-use tests pass
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 Rust ecosystem audit. Severity: high plus docs drift.
