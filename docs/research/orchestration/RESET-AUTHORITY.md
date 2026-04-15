# Orchestration Authority and Runtime Roles

**Status:** Accepted, 2026-04-15

---

## Context

The orchestration design is richer in the research literature than in the current implementation. The research docs describe a nuanced system of roles and responsibilities, but there is no single canonical document that pins down which tool owns which capability at runtime, which workflow states are real, or which cleaner role names should replace the research shorthand. Without this clarity, drift between design intent and implementation is inevitable before code changes even begin.

---

## Decision

This note establishes the authoritative ownership model for the orchestration ecosystem:

1. **`.handoffs/`** — Authored work contracts and decomposition artifacts. Humans and orchestration tooling create and refine handoffs here.

2. **Hymenium (single orchestration authority)** — Owns the workflow lifecycle: phase transitions, dispatch decisions, handoff decomposition, progress monitoring, retry logic, and escalation. Hymenium is the authoritative source for what phase a workflow is in and whether a phase transition is allowed.

3. **Canopy (coordination ledger and operator surface)** — Owns task state, assignment history, evidence references, and read models for operator attention. Canopy is the coordination ledger where all coordination facts live and the operator surface where task state and evidence are visible. Canopy does not orchestrate workflows or manage dispatch decisions; it stores and reports on work that Hymenium coordinates.

4. **Septa** — The concrete orchestration contract layer. Payload schemas and test fixtures that connect Hymenium, Canopy, and other tools live here.

This authority model replaces earlier interim language where Canopy appeared to own workflow state or where orchestration responsibilities were ambiguous. Hymenium is the single orchestration authority for the ecosystem.

---

## Runtime Role Language

The research uses short labels (`A`, `B1`, `B2`, `V1`, `C1`, `C2`, `V2`, `R`, `V3`) for analytical clarity, but these labels are poor runtime names. The following table maps research labels to cleaner runtime role names used in handoffs, documentation, and implementation:

| Research Label | Runtime Role Name |
|---|---|
| `A` | `Spec Author` |
| `B1` | `Workflow Planner` |
| `B2` | `Packet Compiler` |
| `V1` | `Decomposition Checker` |
| `C1` | `Workflow Coordinator` |
| `C2` | `Worker` |
| `V2` | `Output Verifier` |
| `R` | `Repair Worker` |
| `V3` | `Final Verifier` |

Guidelines:
- Use human-facing names in active handoffs, agent assignments, and documentation.
- Keep the old labels only when explicitly cross-referencing the research docs.
- Do not add all research labels as first-class Canopy agent roles; only create agent types when there is real coordination work to do.

---

## Non-Goals and Guardrails

- **Backward compatibility is not a design constraint** — This is an internal reset for a tool that is not yet widely deployed. Weak interim contracts should be deleted, not preserved.
- **Canopy does not become a second workflow engine** — Canopy reads and reports task state; Hymenium coordinates workflows. No cross-tool workflow logic.
- **Schemas are not aspirational** — Septa contracts must match what Hymenium and Canopy actually enforce.

---

## References

- [Orchestration Reset Campaign](../../.handoffs/campaigns/orchestration-reset/README.md) — Campaign sequencing and detailed authority model
- [Umbrella Handoff: Orchestration Reset](../../.handoffs/cross-project/orchestration-reset.md) — Top-level work structure
- [Multi-Agent Orchestration System (Research)](./README.md) — Analytical foundation
