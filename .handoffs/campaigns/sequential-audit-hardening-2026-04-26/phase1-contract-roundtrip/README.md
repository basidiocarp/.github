# Phase 1: Contract Round-Trip Audit

**Status:** Complete

## Lanes

| Lane | Scope | Status | Findings |
|------|-------|--------|----------|
| 1 | Canopy, Cap, Annulus | Complete | summary.md |
| 2 | Hyphae, Rhizome, Mycelium | Complete | summary.md |
| 3 | Volva, Cortina | Complete | summary.md |
| 4 | Hymenium, Canopy workflow | Complete | summary.md |
| 5 | Septa validation tooling | Complete | summary.md |

## Consolidation Rules

- Fold duplicate findings into existing handoffs when possible.
- Create new handoffs only for findings not already covered.
- Prefer contract-family handoffs over one handoff per schema when write scopes
  overlap.

## Consolidated Result

New handoffs created:

- `canopy/canopy-notification-contract-alignment.md`
- `cap/cross-tool-consumer-contracts.md`
- `cortina/session-usage-event-contracts.md`
- `hyphae/read-model-and-archive-contracts.md`
- `mycelium/gain-summary-contracts.md`
- `septa/validation-tooling-and-inventory.md`

Existing handoffs updated:

- `canopy/septa-read-model-contracts.md`
- `hymenium/orchestration-dispatch-contracts.md`

Existing handoffs already covered the known code graph, Volva hook/runtime, Annulus statusline, Mycelium output cleanliness, and Canopy outcome drift findings.
