# Resumability and Idempotency (Deferred)

This note records an architectural gap, not a planned project. Resumability means crash recovery,
checkpoint/restore for in-flight tasks, and idempotent re-execution of interrupted workflows. The
decision today is to not build it.

## What Resumability Means Here

The capabilities that are absent from the current ecosystem:

| Capability | What it means |
|---|---|
| Crash recovery | Detect that a run failed mid-stream and restore enough state to continue |
| Checkpoint/restore | Snapshot in-flight task state and reload it after failure |
| Sequence replay | Re-execute a failed task sequence from the last known-good point |
| Idempotent re-execution | Run the same workflow again without duplicating side effects |

None of these exist today. If a multi-agent run fails mid-way, the operator restarts manually.

## Why It Is Deferred

- The harness wraps agents that already handle retry at the prompt level. Most failure recovery
  happens inside the model context, not at the infrastructure layer.
- Single-agent workflows — the current primary use case — recover by restarting the session.
  Hyphae memory means the agent does not start from zero; prior decisions and context survive.
- Multi-agent checkpoint/restore requires a stable orchestration kernel. Hymenium is itself
  deferred — see [hymenium-design-note.md](./hymenium-design-note.md). Building crash recovery
  before the coordinator exists would be out of order.
- Volva is at v0.1.3. Defining checkpoint semantics before the execution model stabilizes would
  mean redesigning that checkpoint contract when volva matures.

The gap is real. The preconditions for addressing it are not met.

## What Exists That Partially Addresses It

The ecosystem provides soft resumability — an agent can reconstruct context from a prior crash
without automated checkpoint/restore:

| Component | What it contributes |
|---|---|
| `hyphae` | Memories are stored in SQLite, survive process crashes, and are immediately searchable on restart |
| `canopy` | Task ledger and handoff records persist; an agent can query what was in flight |
| `cortina` | Session events are written as they occur, not batched — state is visible even after an abrupt stop |
| PreCompact capture (handoff #66) | Will snapshot working state before context window loss, giving a structured handoff surface |

These together mean recovery is possible by recall, not by replay. The operator or agent reads
what happened and decides how to continue; no mechanism assembles that into an automatic resume path.

## What Would Trigger Building It

| Trigger | Signal |
|---|---|
| Multi-agent crash recovery becomes operational | Humans restart multi-agent runs frequently enough to drive tooling investment |
| Volva execution model stabilizes | Checkpoint semantics can be defined without anticipating further redesign |
| Hymenium exists | A coordination kernel provides the layer where checkpoint/restore would live |
| Canopy sub-task hierarchy (#73) lands | Structured task graphs give replay a natural unit of work to target |

If the first trigger appears alongside the second or third, revisit the deferral.

## Related

- [hymenium-design-note.md](./hymenium-design-note.md) — deferred orchestration kernel; a prerequisite
- [platform-layer-model.md](./platform-layer-model.md) — ecosystem coverage summary and gap analysis
