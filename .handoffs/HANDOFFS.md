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

---

## Completed Batches

All Foundation, Tier 1, Tier 2, and selected Tier 3 items are done. Files are in [archive/](archive/).

| Batch | Items |
|-------|-------|
| Foundation (A1–A5, S1–S3, C1–C5, U1–U4, U4b) | Audit fixes, structural improvements, cohesion, uncharted — all done 2026-04-23 |
| Tier 1 (W3a, W2g, W1c, W2a, W2f, W1a) | GateGuard, hook governance, context envelope, lifecycle stages, DAG task graph, permission memory — all done 2026-04-24 |
| Tier 2 (W2e, W2h, W3d, W3b, W1b, W2j, W2k, W2d, W2c, U4a, St1) | Credential abstraction, dependency types, stop hooks, context metrics, declarative filters, task output, session cost, memory eviction, pluggable backends, server exposure warning, install mode — all done 2026-04-24 |
| Tier 3 partial (W2c-b, W2i, W2o, W2r) | MemoryStore trait extension, checkpoint durability, content-aware routing, watcher framework — all done 2026-04-24 |

---

## Active Handoffs

### Tier 3: Do Later

Organized by cluster with internal ordering. Items within each cluster have dependencies on each other; clusters are largely independent.

#### Cluster A — Lamella/Stipe authoring ecosystem

SPI definition before authoring conventions; install pack last (depends on packaged skill shape being settled).

| # | Handoff | Notes |
|---|---------|-------|
| W2p | [Lamella: Validator Plugin Architecture](lamella/validator-plugin-architecture.md) | Define the ValidatorProvider SPI first — other authoring work keys off this |
| W2b | [Lamella: Skill Progressive Disclosure](lamella/skill-progressive-disclosure.md) | Authoring conventions and scaffold tooling; builds on W2p |
| W3f | [Lamella: Council Role Bundles](lamella/council-role-bundles.md) | Packaged role bundles; depends on authoring conventions being stable |
| W2q | [Lamella: Evolution Feedback Loop](lamella/evolution-feedback-loop.md) | Closes the authoring loop; needs W2b and W3f to exist |
| W3e | [Stipe: Skill Install Pack](stipe/skill-install-pack.md) | Install side; depends on packaged skill shape settled by W2p/W2b |

#### Cluster B — Hyphae depth

Formalize the search surface before adding behavior on top of it.

| # | Handoff | Notes |
|---|---------|-------|
| W2m | [Hyphae: Search Type Registry](hyphae/search-type-registry.md) | Formalizes the search surface first — subsequent items build on a stable retrieval API |
| W2l | [Hyphae: Memoir Git Versioning](hyphae/memoir-git-versioning.md) | Adds traceability to memoirs; needs stable memoir shape |
| W2n | [Hyphae: Shared Cross-Agent Context](hyphae/shared-cross-agent-context.md) | Multi-agent memory sharing; needs retrieval working well (W2m) |

#### Cluster C — Tooling and execution

Largely independent; order within cluster is advisory.

| # | Handoff | Notes |
|---|---------|-------|
| W1d | [Rhizome: Incremental Fingerprinting](rhizome/incremental-fingerprinting.md) | Performance improvement to rhizome indexing; self-contained |
| W3c | [Rhizome: Blast-Radius Simulation](rhizome/blast-radius-simulation.md) | Change impact analysis tool; depends on stable rhizome symbol graph |

---

### Background: Deferred or Larger Features

Larger operator surfaces and lower-signal work. Not blocked on Tier 1–3; just lower return per effort at this stage.

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 24 | [Cap: Live Operator Views And Browser Review Surfaces](cap/live-operator-views-and-browser-review-surfaces.md) | Medium | Volva Execution-Host Session Workspace Contract; Canopy Queue Worktree Review Orchestration; Hyphae Scoped Memory Identity And Export Contract |
| 60 | [Cap: Status Preview And Customization Surface](cap/status-preview-and-customization-surface.md) | Medium | Septa Resolved Status And Customization Contract; Cap Live Operator Views (#24) |
| 30 | [Cap: Canopy Performance](cap/canopy-performance.md) | Medium | Deep Audit |
| — | [Cap: Service Health Panel](cap/service-health-panel.md) | Medium | Spore graceful-degradation-classification |
| 112 | [Mycelium: Compressed Format Experiments](mycelium/compressed-format-experiments.md) | Low | Mycelium Structural Parser Hardening (archived) |
| 81 | [Volva: Auth and Native API Backend](volva/auth-native-api.md) | Lower | — |
| 82 | [Cortina: Codex / Gemini Adapters](cortina/codex-gemini-adapters.md) | Lower | — |
| 105 | [Volva: Workspace-Session Route Models](volva/workspace-session-routes.md) | Lower | Volva Hyphae Recall Injection (#71) |
| 106 | [Cap: Inline Diff-Comment Review Loops](cap/inline-diff-review.md) | Lower | Cap Live Operator Views (#24) |
| 107 | [Rhizome: Analyzer Plugin Extensibility](rhizome/analyzer-plugin-extensibility.md) | Lower | Shipped prerequisite: Rhizome Structural Fallback (v0.7.11) |
| — | [Lamella: Session-End Direct Hook Cutover](lamella/session-end-direct-hook-cutover.md) | Low | Lamella-Cortina Boundary Phase 2 |
