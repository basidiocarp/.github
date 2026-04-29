# Hymenium/Canopy Dogfood Hardening

<!-- Save as: .handoffs/cross-project/hymenium-canopy-dogfood-hardening.md -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `umbrella`
- **Owning repo:** `cross-project`
- **Allowed write scope:** none for this umbrella; child handoffs own implementation scopes
- **Cross-repo edits:** `hymenium`, `canopy`, `stipe`, and workspace docs only through child handoffs
- **Non-goals:** no redesign of the full orchestration product and no CentralCommand source edits
- **Verification contract:** all child handoffs complete with repo-local verification and paired verify scripts passing
- **Completion update:** archive this umbrella after all child handoffs are complete and the dashboard is updated

## Problem

The first CentralCommand dogfood run proved the basic path can dispatch a handoff into Canopy, assign work, enforce script verification, and produce a useful audit artifact. It also exposed integration gaps that make the system too brittle for routine use: strict handoff parsing, CLI compatibility drift, missing runtime identity, stale installed binaries, confusing queue surfaces, and no Hymenium reconciliation after Canopy task completion.

This umbrella turns those findings into implementation work. The goal is not to add more orchestration theory; the goal is to make the next dogfood run require fewer manual repair commands and produce trustworthy phase state.

## Dogfood Evidence

- **External repo:** `/Users/williamnewton/projects/ccoCentralCommand`
- **Handoff:** `.handoffs/centralcommnd/audit-drop-shipping.md`
- **Workflow:** `01KQ44QFTH252379KX3ZR9RNNK`
- **Implement task:** `01KQ44QFTYPC49SGA0T25RZ3BD`
- **Observed result:** Canopy task verification passed and task was completed, but Hymenium status still showed the implement phase as pending.

## Findings

1. Handoff parser rejected semantically equivalent headings because section matching is exact and case-sensitive.
2. The handoff format had no first-class way to distinguish read-only source scope from allowed artifact writes.
3. The installed `hymenium` binary was stale relative to source, so the user had to run via `cargo run --manifest-path`.
4. Hymenium emitted Canopy role names such as `Worker`, while Canopy accepts `orchestrator`, `implementer`, and `validator`.
5. Hymenium assumed `canopy task create` returned a raw id, while current Canopy returns JSON.
6. Agent registration and runtime environment were manual, including `CANOPY_DB_PATH`, agent id, task id, and project root.
7. Canopy task rows had nullable `workflow_id` and `phase_id` even though the task packet contained those values.
8. Hymenium status displayed the handoff path as the repo name rather than the actual handoff path.
9. `canopy work-queue` returned `[]` after assignment, which is technically consistent with "claimable work" but confusing for an assigned worker.
10. Canopy correctly blocked task completion until verification passed.
11. Hymenium did not reconcile the completed Canopy task or advance to the audit phase.
12. Task packet quality was too generic: titles were uninformative, comma splitting damaged non-goals, and read-only audits still requested broad write capability.

## Child Handoffs

| # | Handoff | Owner | Priority | Purpose |
|---|---------|-------|----------|---------|
| H1 | [Hymenium: Dogfood Handoff Intake Lint](../hymenium/dogfood-handoff-intake-lint.md) | `hymenium` | High | Make parser errors actionable and support audit/artifact scope semantics |
| H2 | [Hymenium: Canopy Dispatch Compatibility](../hymenium/canopy-dispatch-compatibility.md) | `hymenium` | Critical | Formalize role mapping and JSON task-id parsing with tests |
| H3 | [Hymenium: Task Packet Runtime Identity](../hymenium/task-packet-runtime-identity.md) | `hymenium` | Critical | Carry absolute handoff/project/task identity into dispatch and status |
| H4 | [Hymenium: Canopy Phase Reconciliation](../hymenium/canopy-phase-reconciliation.md) | `hymenium` | Critical | Reconcile Canopy completion back into Hymenium workflow phase state |
| H5 | [Hymenium: Read-Only Audit Packet Quality](../hymenium/read-only-audit-packet-quality.md) | `hymenium` | High | Improve task packets for read-only audit workflows |
| H6 | [Canopy: Assigned Work Operator Surface](../canopy/assigned-work-operator-surface.md) | `canopy` | Medium | Make assigned-but-not-claimable tasks visible to workers and operators |
| H7 | [Stipe: Installed Binary Freshness](../stipe/installed-binary-freshness.md) | `stipe` | Medium | Detect stale installed ecosystem binaries before dogfood runs |

## Sequencing

Start with H2 because the dispatch compatibility bug is already well understood and has a narrow source seam. H3 and H4 should follow together: runtime identity without reconciliation still leaves Hymenium blind, and reconciliation without reliable identity is fragile. H1 and H5 improve the input and packet quality around that core path. H6 and H7 are operator hardening once the dispatch loop is stable.

## Completion Protocol

This umbrella is complete only when:

1. H1-H7 are complete or explicitly retired with a replacement handoff.
2. A new CentralCommand dogfood run reaches the audit phase without manual DB/task reconciliation.
3. The active dashboard is updated and this umbrella is archived.

