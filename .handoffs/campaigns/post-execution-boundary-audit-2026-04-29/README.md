# Post-Execution Boundary Compliance Audit (2026-04-29)

Read-only audit campaign. Evaluates whether the ecosystem is moving in the
direction set by the [F1 freeze roadmap](/Users/williamnewton/projects/personal/basidiocarp/docs/foundations/core-hardening-freeze-roadmap.md)
after the recent close of A12, A37, A46, A50, F1, F2, C7, C8, and the migration
sweep that cleared 4 CLI couplings.

This campaign does **not** fix anything. Each lane produces a findings file
under `findings/`. The fix phase opens new handoffs in
`.handoffs/HANDOFFS.md` based on those files.

## Lanes

Each lane runs in parallel against a disjoint write surface (`findings/<lane>.md`).

| Lane | Handoff | Findings file |
|------|---------|---------------|
| 1 | [lane1-boundary-compliance.md](lane1-boundary-compliance.md) | `findings/lane1-boundary-compliance.md` |
| 2 | [lane2-septa-contract-accuracy.md](lane2-septa-contract-accuracy.md) | `findings/lane2-septa-contract-accuracy.md` |
| 3 | [lane3-low-item-prioritization.md](lane3-low-item-prioritization.md) | `findings/lane3-low-item-prioritization.md` |

## Evaluation Lens

The F1 exit criteria are the lens for "right direction":

1. Core loop works end-to-end (cortina → hyphae → mycelium → rhizome → cap)
2. `septa/validate-all.sh` is green and stays green
3. CLI coupling table is current; no untracked sibling spawns
4. Cap operator console is stable after F2 cuts
5. No open Medium-priority handoffs

Findings should call out drift from these criteria, not introduce new ones.

## Out of Scope

- Frozen repos (cap UI work, canopy, hymenium, lamella, annulus, volva) — only
  evaluate their integration boundaries, not their internal code quality.
- New feature ideas — the freeze policy explicitly defers them.

## Completion

Each lane handoff is complete when its findings file exists and its verify
script exits 0. The campaign is complete when all three lanes are complete and
the operator has reviewed the combined findings to decide which issues become
new handoffs.
