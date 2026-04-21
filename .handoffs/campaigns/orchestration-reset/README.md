# Orchestration Reset

Date: 2026-04-15
Purpose: turn the orchestration reset into a coherent campaign with one authority, one runtime model, and one naming scheme for orchestration roles

Related docs:

- [Active dashboard](../../HANDOFFS.md)
- [Umbrella handoff](../../cross-project/orchestration-reset.md)
- [Research baseline](../../../docs/research/orchestration/README.md)

## One-paragraph read

Canopy is still a single-operator internal system, so this campaign optimizes for coherence instead of compatibility. The target shape is straightforward: `.handoffs/` remains the authored specification layer, `hymenium` becomes the single orchestration authority, `canopy` becomes the coordination ledger and operator surface, and `septa` holds the real contracts that connect them. The campaign is intentionally sequenced so that contracts and state ownership are fixed before routing and learning automation are expanded.

## External refinements folded into this campaign

These external audits sharpen the reset, but they do not change the authority model.

- `multica`: make claim, sweeper, runtime watchdog, and session-threading seams explicit inside the runtime and ledger
- `vibe-kanban`: make workspace or session identity, review flow, and preview flow legible in operator surfaces without making UI authoritative
- `council`: keep runtime role language readable and keep any multi-agent deliberation task-anchored instead of free-floating
- `claude-squad`: preserve worktree, session, and restore semantics as first-class execution facts rather than reconstructing them from logs later

## Authority model

- `.handoffs/`: authored work contracts and decomposition artifacts
- `hymenium`: workflow lifecycle, phase transitions, retries, escalation, and workflow status
- `canopy`: tasks, evidence, dependencies, handoffs, and operator read models
- `septa`: orchestration packet, status, and outcome contracts

## Runtime role language

The research labels are useful analytically, but they are poor runtime names. Use the following names in active handoffs, docs, and implementation notes.

| Research label | Use instead |
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

The short version:

- use human-facing names in active work
- keep the old labels only when cross-referencing the research docs
- do not add all research labels as first-class Canopy agent roles

## Execution order

1. [Cross-Project: Authoritative Orchestration ADR](../../cross-project/authoritative-orchestration-adr.md)
2. [Septa: Orchestration Contract Reset](../../septa/orchestration-contract-reset.md)
3. [Hymenium: Authoritative Workflow Runtime](../../hymenium/authoritative-workflow-runtime.md)
4. [Canopy: Workflow Ledger Alignment](../../canopy/workflow-ledger-alignment.md)
5. [Hymenium: Typed Failure Routing](../../hymenium/typed-failure-routing.md)
6. [Cross-Project: Capability Routing Alignment](../../cross-project/capability-routing-alignment.md)
7. [Cross-Project: Orchestration Learning Loop](../../cross-project/orchestration-learning-loop.md)

## Guardrails

- Do not preserve weak interim contracts just because they exist.
- Do not add repair automation before typed failures and output verification are trustworthy.
- Do not let Canopy become a second workflow engine.
- Do not widen the template surface before `impl-audit` is correct end to end.
- Prefer deleting obsolete workflow state and fields over layering compatibility shims.
- Treat runtime sweepers, duplicate prevention, and session threading as hardening details that support the reset, not as alternative authority models.

## Done means

The campaign is only done when:

- Hymenium can create, advance, retry, escalate, and report workflows directly
- Canopy can explain workflow membership, phase, blockers, evidence, and next operator action
- Septa owns the real orchestration contracts instead of aspirational placeholders
- role names in active work use the cleaner runtime language above

## Completion

**Done 2026-04-15.** All 7 original child handoffs (141a–141g) shipped, plus four correctness follow-ons (141h–141k):

- **141h** — Terminal Transition Hardening: `current_phase_idx` persisted on every transition, `ensure_column` migration, typed error replacements. hymenium v0.2.0.
- **141i** — Operator Contract Drift: 5 septa schema↔code mismatches fixed (`attention.level`, `breach_severity` ×2, `agents[].status`, `workflow-status-v1` phase fields).
- **141j** — Integration Script $ref Resolution: delegation to `septa/validate-all.sh`, integration test 23/0.
- **141k** — Workflow Template Role Vocabulary: `Phase.role` split into `ProcessRole` (4 abstract, user-facing) + optional `AgentRole` (9 concrete, dispatch-specific). `workflow-template-v1.schema.json` at v1.1. Round-trip test added. hymenium v0.3.0.

Campaign audit verdict: APPROVED. All verify scripts green, full integration 23/0, septa 45/0, hymenium 215/215 tests.
