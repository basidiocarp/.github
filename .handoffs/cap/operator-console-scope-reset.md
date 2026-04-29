# Cap: Operator Console Scope Reset

<!-- Save as: .handoffs/cap/operator-console-scope-reset.md -->
<!-- Create verify script: .handoffs/cap/verify-operator-console-scope-reset.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/docs/operator-console-scope-reset.md`, `cap/docs/`, `.handoffs/cap/`
- **Cross-repo edits:** none
- **Non-goals:** no UI rebuild, no route deletion, no server refactor, and no new dashboard features
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cap/verify-operator-console-scope-reset.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** `cap/src/App.tsx`, `cap/src/components/AppLayout.tsx`, `cap/src/pages/`, `cap/src/lib/api/`, `cap/src/lib/queries/`, `cap/server/index.ts`, `cap/server/routes/`, `cap/docs/`
- **Reference seams:** existing Cap docs drift handoff, cross-tool consumer contracts handoff, server/UI verification hardening handoff, system-to-system communication boundary
- **Spawn gate:** do not launch an implementer until the parent agent confirms this is an audit/report handoff only, not a rewrite

## Problem

Cap has grown into a broad dashboard while the underlying ecosystem contracts are still moving. Some surfaces are useful for dogfood, some are stale, and some may be solving problems that belong in the owning tools. A ground-up rebuild would be premature until Cap's operator role is narrowed.

Cap should be evaluated as an operator console: it should show what the ecosystem is doing, make repair/status actions clear, and avoid owning orchestration, memory, install state, or workflow truth.

## What exists (state)

- **Frontend:** multiple route surfaces across memory, code intelligence, sessions, Canopy, settings, analytics, and status.
- **Server:** local API routes that read from or shell out to sibling tools.
- **Docs:** known drift in route inventory, API inventory, and behavior claims.
- **Contracts:** several Cap-facing Septa contracts exist, but not every route is clearly contract-backed.

## What needs doing (intent)

Produce `cap/docs/operator-console-scope-reset.md` as a decision report that inventories Cap and classifies each surface.

The report must answer:

- Which screens/routes are needed for the next dogfood run?
- Which screens should stay but migrate to typed contracts or local service endpoints?
- Which screens should be cut from active UI?
- Which screens should be rebuilt after contracts settle?
- Which screens should be deferred until there is repeated dogfood demand?
- Which server routes are operator actions versus accidental orchestration?
- Which data sources still depend on sibling-tool CLI or direct database access?

## Scope

- **Primary seam:** Cap role, route inventory, data-source inventory, and rebuild decision
- **Allowed files:** docs/report only unless a small inventory script is explicitly approved during implementation
- **Explicit non-goals:** no redesign implementation, no frontend rewrite, no backend migration, no new contracts

## Required Report Structure

`cap/docs/operator-console-scope-reset.md` must contain:

```markdown
# Cap Operator Console Scope Reset

## Executive Decision
[keep repo / partial rebuild / split / full rebuild recommendation]

## Operator Role
[what Cap owns and explicitly does not own]

## Route Inventory
| Route | Current purpose | Data source | Dogfood value | Classification | Notes |

## API Inventory
| API namespace | Current source | Contract-backed? | CLI/DB dependency | Classification | Notes |

## Screen Classification
Use exactly these classifications:
- keep-for-dogfood
- keep-contract-migrate
- cut
- rebuild-after-contracts
- defer

## Split Assessment
[whether to keep one repo, split server/client internally, or split repos later]

## Rebuild Plan
[if partial rebuild is recommended, name the smallest first slice]

## Freeze Rules
[what Cap feature work is frozen until this report is accepted]
```

## Verification

```bash
cd cap && npm run build
cd cap && npm test
bash .handoffs/cap/verify-operator-console-scope-reset.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] report exists at `cap/docs/operator-console-scope-reset.md`
- [ ] every current frontend route is classified
- [ ] every mounted server API namespace is classified
- [ ] each classification uses the required vocabulary
- [ ] report includes a clear split/rebuild recommendation
- [ ] report identifies CLI and direct-database dependencies
- [ ] build and tests pass, or skipped validation is explicitly justified
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created after the CentralCommand dogfood run. Cap should not be rebuilt until this audit narrows its role and distinguishes useful operator-console surfaces from stale or premature dashboard features.

