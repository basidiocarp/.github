# Cross-Project: Orchestration Reset

## Handoff Metadata

- **Dispatch:** `umbrella`
- **Owning repo:** `cross-project`
- **Allowed write scope:** `docs/research/orchestration/...`, `septa/...`, `hymenium/...`, `canopy/...`
- **Cross-repo edits:** allowed only through the named child handoffs below
- **Non-goals:** dispatching this umbrella directly, preserving backward compatibility, or widening the workflow template surface beyond one canonical flow
- **Verification contract:** use the paired child handoff verifier, not this umbrella file
- **Completion update:** update `.handoffs/HANDOFFS.md` as child handoffs complete; archive this umbrella only after the child queue is finished

## Implementation Seam

- **Likely repo:** child handoffs own the execution seams for this umbrella
- **Likely files/modules:** none directly; use the child handoffs as the execution source of truth
- **Reference seams:** `docs/research/orchestration/`, `hymenium/src/workflow/`, `hymenium/src/dispatch/`, `canopy/src/store/`, `septa/*.schema.json`
- **Spawn gate:** do not launch an implementer from this umbrella; pick a child handoff and complete seam-finding there first

## Status Audit

This umbrella exists because the current orchestration shape is split across:

- research docs with richer states and failure typing than the live system
- Septa schemas that are partly aspirational
- Hymenium runtime seams that are real but still thin
- Canopy workflow context that currently risks competing with the orchestrator

Dispatching this umbrella directly would encourage broad, cross-repo edits without a stable seam. The safe path is to execute the narrower child handoffs in order.

## Role Language

Use these names in active implementation work:

- `Spec Author`
- `Workflow Planner`
- `Packet Compiler`
- `Decomposition Checker`
- `Workflow Coordinator`
- `Worker`
- `Output Verifier`
- `Repair Worker`
- `Final Verifier`

Do not use `B1`, `C1`, `V1`, and similar labels in new active handoffs unless the note is explicitly cross-referencing the research baseline.

## Child Handoffs

Dispatch these instead:

1. [Cross-Project: Authoritative Orchestration ADR](authoritative-orchestration-adr.md)
2. [Septa: Orchestration Contract Reset](../septa/orchestration-contract-reset.md)
3. [Hymenium: Authoritative Workflow Runtime](../hymenium/authoritative-workflow-runtime.md)
4. [Canopy: Workflow Ledger Alignment](../canopy/workflow-ledger-alignment.md)
5. [Hymenium: Typed Failure Routing](../hymenium/typed-failure-routing.md)
6. [Cross-Project: Capability Routing Alignment](capability-routing-alignment.md)
7. [Cross-Project: Orchestration Learning Loop](orchestration-learning-loop.md)

## Notes

- `.handoffs/` stays the authored specification layer.
- `hymenium` becomes the single workflow authority.
- `canopy` becomes the ledger and operator surface.
- `septa` becomes the concrete boundary layer for orchestration packets, status, and outcomes.
- Valuable refinements from the external audit wave are in scope only where they strengthen these boundaries:
  - `multica`: claim semantics, watchdog sweeper seams, and session-threading fields
  - `vibe-kanban`: workspace or session route identity plus clearer review or preview operator reads
  - `council`: readable role names and task-anchored multi-agent session state
  - `claude-squad`: explicit worktree and restore state on execution records
