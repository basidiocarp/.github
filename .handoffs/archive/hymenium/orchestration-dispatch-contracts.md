# Hymenium: Orchestration Dispatch Contracts

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/src/dispatch/`, `hymenium/src/commands/`, `hymenium/src/workflow/`, `hymenium/src/monitor/`, `hymenium/tests/`, `hymenium/README.md`, `hymenium/AGENTS.md`, `hymenium/CLAUDE.md`
- **Cross-repo edits:** no source edits outside `hymenium`; read `canopy/src/cli.rs`, `septa/dispatch-request-v1.schema.json`, and `septa/canopy-task-detail-v1.schema.json` as references only
- **Non-goals:** no Canopy CLI redesign and no new orchestration template system
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-orchestration-dispatch-contracts.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** `src/dispatch/cli.rs`, `src/dispatch/mod.rs`, `src/dispatch/orchestrate.rs`, `src/commands/dispatch.rs`, `src/workflow/engine.rs`, `src/monitor/progress.rs`, `src/main.rs`, dispatch/workflow/monitor tests
- **Reference seams:** `canopy/src/cli.rs` for actual task CLI args; `septa/dispatch-request-v1.schema.json` for intake shape; `septa/canopy-task-detail-v1.schema.json` for task-detail consumption
- **Spawn gate:** do not launch an implementer until the parent agent has confirmed the Canopy task create/assign flags and the exact Hymenium dispatch tests to update

## Problem

The audit found that Hymenium's Canopy CLI adapter does not match Canopy's actual CLI, dispatched workflows do not activate their first phase, and future gated phase tasks are created before gates pass. Hymenium docs also describe stale command surfaces and missing MCP/config behavior.

The contract round-trip audit also found that Hymenium's Canopy task-detail consumer uses a narrow local DTO and does not enforce `canopy-task-detail-v1` or its `schema_version`.

## What exists

- **Canopy adapter:** `hymenium/src/dispatch/cli.rs` builds `task create` and `task assign` args manually.
- **Canopy CLI:** `canopy/src/cli.rs` requires `--requested-by` on create and `--task-id`, `--assigned-to`, `--assigned-by` on assign.
- **Workflow lifecycle:** dispatch creates tasks, but monitor expects active phases.
- **Docs:** README/AGENTS/CLAUDE still mention commands or seams not present in the current CLI.

## What needs doing

1. Align `CliCanopyClient` with Canopy's real CLI flags.
2. Add contract tests for task create and assign argument builders.
3. Activate and persist the first phase after successful first assignment.
4. Stop creating gated future phase tasks before gate conditions pass, or create them in an explicitly blocked state that cannot be claimed.
5. Add or adapt `DispatchRequest` handling so CLI path dispatch maps into the Septa intake shape.
6. Make Hymenium's Canopy task-detail consumer either deserialize the Septa shape or use an explicit adapter with contract tests.
7. Update Hymenium README/AGENTS/CLAUDE to the implemented CLI and module layout.

## Scope

- **Primary seam:** Hymenium dispatch into Canopy and workflow phase lifecycle
- **Allowed files:** listed in metadata
- **Explicit non-goals:** no Cap UI work, no Canopy schema work, no implementation agents before seam confirmation

## Verification

```bash
cd hymenium && cargo test dispatch
cd hymenium && cargo test workflow
cd hymenium && cargo test monitor
bash .handoffs/hymenium/verify-orchestration-dispatch-contracts.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `task create` includes `--requested-by` and omits unsupported `--required-tier`
- [ ] `task assign` uses Canopy's `--task-id`, `--assigned-to`, and `--assigned-by` flags
- [ ] first dispatched phase becomes active before monitoring starts
- [ ] future gated phase tasks are not claimable before gates pass
- [ ] dispatch input is represented by or adapted into `dispatch-request-v1`
- [ ] Canopy task-detail consumption is covered by a fixture or adapter test
- [ ] Hymenium docs match current command and module surfaces
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 Rust ecosystem audit. Severity: critical/high/medium. This handoff covers Hymenium findings so one implementer can stay inside the orchestration repo.
