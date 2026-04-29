# Phase 4: Data Integrity Audit

**Status:** Complete

## Scope

Audit whether persisted state remains correct across migrations, retries, concurrent writers, partial failures, imports/exports, and derived read models. This phase should avoid re-reporting Phase 2 runtime safety findings unless the data correctness impact is distinct.

## Planned Lanes

| Lane | Scope | Status | Findings |
|------|-------|--------|----------|
| 1 | SQLite schema migrations, WAL/sidecars, and restore/import correctness | Complete | summary.md |
| 2 | task/workflow state machines and derived read models | Complete | summary.md |
| 3 | memory/artifact identity, dedupe, and merge semantics | Complete | summary.md |
| 4 | config/version ledgers and shared dependency pins | Complete | summary.md |
| 5 | event/log append semantics, idempotency, and replay safety | Complete | summary.md |

## Consolidation Rules

- Fold backup/restore mechanics into Phase 2 handoffs when the finding is purely runtime safety.
- Create data-integrity handoffs only when persisted state can become wrong, duplicated, stale, or unrecoverable.
- Prefer repo-owned handoffs with concrete corruption/replay/idempotency regression tests.

## Consolidated Result

New handoffs created:

- `hyphae/memory-document-integrity.md`
- `rhizome/incremental-export-prune-integrity.md`
- `cortina/volva-event-replay-identity.md`
- `canopy/task-event-and-state-idempotency.md`
- `hymenium/terminal-workflow-idempotency.md`
- `cap/canopy-stale-cache-integrity.md`
- `cortina/compact-summary-artifact-integrity.md`
- `cross-project/version-ledger-authority.md`
- `lamella/manifest-sync-maintenance.md`

Existing handoffs updated:

- `hyphae/read-model-and-archive-contracts.md`
- `canopy/mcp-handoff-runtime-boundaries.md`
- `septa/validation-tooling-and-inventory.md`
- `volva/backend-and-credential-runtime-safety.md`

Existing handoffs already cover Hyphae archive atomicity and WAL-safe backup/restore; this phase added archive graph/provenance preservation and memory/document identity integrity.
