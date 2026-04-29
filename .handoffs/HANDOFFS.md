# Active Handoffs

This file is the live dashboard for active work only. Archive history lives under [archive/README.md](archive/README.md), session notes live under [sessions/README.md](sessions/README.md), and reusable scaffolding now lives under [../templates/handoffs/README.md](../templates/handoffs/README.md).

Delegated execution note: if a task is run with the implementer/auditor pattern, use the strict workflow from [AGENTS.md](../AGENTS.md). The implementer goes first on one concrete handoff, the auditor starts only after there is a real diff and verification output, findings get fixed before signoff, the dashboard is updated when the work is complete, and both agents are closed when done. Parallel workflows are allowed when they target different concrete handoffs with disjoint write scopes. Name agents as `<role>/<repo>/<handoff-slug>/<run>`, with any human nickname shown secondarily. Keep orchestration with the parent agent, keep implementers code-only, require the implementer to inspect repo state and target files before editing, and treat meta-status replies without a repo diff as failure. Triage lanes early and close empty or off-scope lanes instead of carrying them forward.

## Layout

```text
.handoffs/
├── HANDOFFS.md            # Active dashboard
├── README.md              # Layout and operating rules
├── <project>/             # Active repo-owned handoffs + verify scripts
├── cross-project/         # Active handoffs spanning multiple repos
├── campaigns/             # Multi-step audit or rollout programs
├── sessions/              # Short-lived resume notes
├── archive/               # Completed handoffs and old verify scripts
├── state/                 # Local runner state
└── scripts/               # Local maintenance helpers
```

- Active work stays in `.handoffs/<project>/` or `.handoffs/cross-project/`.
- Each active handoff keeps a paired `verify-*.sh` script in the same directory.
- Run verification with `bash .handoffs/<project>/verify-<topic>.sh`.
- New handoffs should start from [WORK-ITEM-TEMPLATE.md](../templates/handoffs/WORK-ITEM-TEMPLATE.md).

## Supporting Folders

- [README.md](README.md): folder rules and naming guidance
- [campaigns/README.md](campaigns/README.md): long-running multi-repo efforts
- [sessions/README.md](sessions/README.md): session-note conventions
- [archive/README.md](archive/README.md): completed work and historical notes

## Active Campaigns

| Campaign | Status | Phase |
|----------|--------|-------|
| [Ecosystem Health Audit](campaigns/ecosystem-health-audit/README.md) | All Phases Complete | 16 issues tracked — fix phase ready |
| [Sequential Audit Hardening Campaign](campaigns/sequential-audit-hardening-2026-04-26/README.md) | All Phases Complete | 53 issues tracked — fix phase ready |
| [Capability Ecosystem Control Plane](cross-project/capability-ecosystem-control-plane.md) | Ready | C5-C8 pending — typed local service APIs and CLI-coupling audit (C0-C4 done) |
| [Scope Freeze And Operator Console Reset](cross-project/core-hardening-freeze-roadmap.md) | Ready | F1-F2 tracked — freeze roadmap and Cap operator-console scope reset |

---

## Completed Batches

All Foundation, Tier 1, Tier 2, selected Tier 3, and the full audit hardening campaign are done. Files are in [archive/](archive/).

| Batch | Items |
|-------|-------|
| Foundation (A1–A5, S1–S3, C1–C5, U1–U4, U4b) | Audit fixes, structural improvements, cohesion, uncharted — all done 2026-04-23 |
| Tier 1 (W3a, W2g, W1c, W2a, W2f, W1a) | GateGuard, hook governance, context envelope, lifecycle stages, DAG task graph, permission memory — all done 2026-04-24 |
| Tier 2 (W2e, W2h, W3d, W3b, W1b, W2j, W2k, W2d, W2c, U4a, St1) | Credential abstraction, dependency types, stop hooks, context metrics, declarative filters, task output, session cost, memory eviction, pluggable backends, server exposure warning, install mode — all done 2026-04-24 |
| Tier 3 partial (W2c-b, W2i, W2o, W2r) | MemoryStore trait extension, checkpoint durability, content-aware routing, watcher framework — all done 2026-04-24 |
| Audit hardening (A1–A54, C0–C4, H0–H7) | Cross-ecosystem drift audit, interconnectivity hardening, dogfood campaign — all done 2026-04-28 |

---

## Active Handoffs

### Cap

Consumer contracts, stale cache, supply chain, and docs drift.

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| A12 | [Cap: Cross-Tool Consumer Contracts](cap/cross-tool-consumer-contracts.md) | Medium | Evidence source kind and Annulus status/statusline consumer drift |
| A37 | [Cap: Canopy Stale Cache Integrity](cap/canopy-stale-cache-integrity.md) | Medium | Stale snapshot fallback is global instead of project/filter keyed |
| A46 | [Cap: Node Supply Chain Script Policy](cap/node-supply-chain-script-policy.md) | Medium | `npx` scripts, release checks, install lifecycle policy |
| A50 | [Cap: Dashboard And API Docs Drift](cap/dashboard-api-docs-drift.md) | Medium | API docs, route inventory, internals docs, and UI behavior claims are stale |

---

### Stipe

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| A9 | [Stipe: Control Plane Quality](stipe/control-plane-quality.md) | Medium | Backup partial-success semantics and boolean-heavy APIs |

---

### Lamella

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| A40 | [Lamella: Manifest Sync Maintenance](lamella/manifest-sync-maintenance.md) | Medium | Manifest sync maintenance script points at obsolete paths |

---

### Cross-Project & Workspace

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| A52 | [Cross-Project: Workspace Docs Link Drift](cross-project/workspace-docs-link-drift.md) | Medium | Broken docs links, archived handoff references, command rendering, unavailable skill refs |
