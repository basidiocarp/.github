# Hymenium Design Note

## Decision

Create Hymenium as a separate Rust binary for workflow orchestration. Canopy remains the passive coordination ledger. Hymenium is the active orchestrator that reads canopy state, drives workflows, and manages agent lifecycle.

## Why a Separate Service

Canopy is a passive ledger — it stores coordination state, answers queries, and enforces local invariants. Adding scheduling, routing, retry, and dependency resolution would turn it into two things with different performance characteristics and failure modes:

| Concern | Ledger (Canopy) | Orchestrator (Hymenium) |
|---------|-----------------|------------------------|
| Model | Query-driven, synchronous | Event-driven, asynchronous |
| State | Consistent, durable | Ephemeral workflow state + durable checkpoints |
| Failure | Fail-closed (reject bad state) | Fail-safe (retry, escalate, recover) |
| Scaling | Single-writer SQLite | Multiple concurrent workflows |

Bolting the second onto the first produces a monolith that's bad at both.

## Hymenium Responsibilities

| Concern | What It Means |
|---------|--------------|
| Workflow templates | "Implementer/auditor" as a first-class pattern, not prose instructions |
| Phase gating | Don't spawn auditor until implementer has real diff + verification |
| Dispatch | Read a handoff, decide which agent tier, create canopy tasks, assign |
| Dependency resolution | Handoff A depends on B — don't dispatch A until B is complete |
| Handoff decomposition | Large handoff → split into focused child handoffs automatically |
| Retry/recovery | Agent stalled? Close it, narrow scope, relaunch |
| Progress monitoring | Check canopy state, completeness gates, escalate when stuck |

## What Stays in Canopy

- Task CRUD, lifecycle state machine, agent registry
- File locks, evidence references, council threads
- Completeness checking (hymenium calls this tool)
- Sub-task hierarchy and completion invariants
- Snapshot/detail read models for cap

## What Stays in Other Tools

- **Cortina**: lifecycle signal capture, hook events
- **Volva**: execution host, session management
- **Hyphae**: long-term memory, recall
- **Stipe**: installation, updates, doctor

## Architecture

```text
┌──────────────────────────────────────────────┐
│  Operator / Parent Agent                     │
│  "dispatch handoff #87a with impl/auditor"   │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│  Hymenium (workflow orchestrator)             │
│  ┌────────────┐ ┌──────────┐ ┌────────────┐ │
│  │ Handoff    │ │ Workflow  │ │ Progress   │ │
│  │ Parser     │ │ Engine    │ │ Monitor    │ │
│  └─────┬──────┘ └────┬─────┘ └─────┬──────┘ │
│        │             │              │         │
│  ┌─────┴──────┐ ┌────┴─────┐ ┌─────┴──────┐ │
│  │ Decomposer │ │ Dispatch │ │ Retry/     │ │
│  │            │ │          │ │ Recovery   │ │
│  └────────────┘ └──────────┘ └────────────┘ │
└──────────────┬───────────────────────────────┘
               │
    ┌──────────┼──────────┐
    ▼          ▼          ▼
 Canopy    Cortina    .handoffs/
 (ledger)  (signals)  (documents)
```

## Data Flow

1. Operator or parent agent sends dispatch request to hymenium
2. Hymenium reads the handoff document from `.handoffs/`
3. If handoff is too large, decompose into focused child handoffs
4. Check dependency graph — are prerequisites complete?
5. Select workflow template (e.g., implementer/auditor)
6. Create canopy tasks via MCP/CLI
7. Assign agent tier based on effort/complexity
8. Monitor canopy state for progress signals
9. Gate phase transitions (implementer done → auditor starts)
10. Handle failures (stalled agent → close, narrow, relaunch)
11. On completion: update dashboard, archive handoff, close agents

## Contract Boundary

Hymenium communicates with canopy and cortina through defined septa contracts:

| Contract | Direction | Purpose |
|----------|-----------|---------|
| `workflow-template-v1` | Internal | Defines workflow patterns (phases, gates, roles) |
| `dispatch-request-v1` | Hymenium → Canopy | Handoff dispatch: tasks to create, agents to assign |
| `workflow-status-v1` | Hymenium → Cap/Annulus | Current workflow state for operator visibility |

Hymenium reads canopy state via existing canopy MCP tools. It does NOT share canopy's database.

## Interaction Model

Hymenium exposes its own MCP surface for the parent agent:

- `hymenium_dispatch` — dispatch a handoff with a workflow template
- `hymenium_status` — query running workflow status
- `hymenium_decompose` — split a large handoff into focused pieces
- `hymenium_retry` — relaunch a stalled or failed workflow step
- `hymenium_cancel` — cancel a running workflow

It also exposes a CLI for operator use:

```bash
hymenium dispatch .handoffs/work-items/spore/otel-foundation.md --workflow impl-audit
hymenium status
hymenium decompose .handoffs/large-handoff.md --max-effort 4h
```

## Migration Path

The current instruction-driven approach (SKILL.md, CLAUDE.md, AGENTS.md) continues to work. Hymenium automates the same protocol:

1. **Phase 1 (now)**: Instructions drive the workflow. Parent agent follows skill file.
2. **Phase 2 (hymenium MVP)**: Hymenium automates dispatch, phase gating, and progress monitoring. Parent agent uses `hymenium_dispatch` instead of manually following the skill.
3. **Phase 3 (full orchestration)**: Hymenium handles decomposition, dependency resolution, retry/recovery. Parent agent becomes a thin approval layer.

The skill file remains the specification. Hymenium is the automation of that specification.

## Prerequisites

- **#73 (Sub-Task Hierarchy)**: Canopy must enforce parent/child completion invariants before hymenium can rely on "all implementer subtasks done" signals.
- **Septa contracts**: Workflow-template, dispatch-request, and workflow-status schemas must be defined before hymenium emits or consumes them.

## Related Handoffs

- #73 (Canopy Sub-Task Hierarchy) — prerequisite
- #77 (Canopy Capability Routing) — complementary, can be absorbed into hymenium's dispatch
- #72 (Canopy Verification Completion Gate) — hymenium consumes this
- #114a-d (Tool Usage Observability) — hymenium can incorporate tool adoption into workflow quality signals
- #115a-c (Behavioral Guardrails) — hymenium can check tool usage as a phase gate
