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

## Active Handoffs

### Tier 4: Cross-Project Contract

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 136 | [Cortina: Resolve Boundary Expansion (handoff audit, rules, mycelium DB)](cortina/boundary-expansion.md) | Medium | — |
| 137 | [Canopy: Resolve Orchestration Logic Boundary with Hymenium](canopy/orchestration-boundary.md) | Medium | — |
| 122 | [Lamella: Resolve Homunculus Observation System Boundary](lamella/homunculus-boundary.md) | Medium | — |

### Tier 5: Standalone or Lower Urgency

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 20 | [Hyphae: HTTP Embeddings](hyphae/http-embeddings.md) | Low | — |
| 23 | [Cortina: Deduplicate Helpers](cortina/deduplicate-helpers.md) | Low | — |
| 89 | [Hyphae: Scoped Agent Journals](hyphae/scoped-agent-journals.md) | Low | — |
| 112 | [Mycelium: Compressed Format Experiments](mycelium/compressed-format-experiments.md) | Low | [Mycelium Structural Parser Hardening](archive/mycelium/structural-parser-hardening.md) |

### Tier 6: Cap

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 24 | [Cap: Live Operator Views And Browser Review Surfaces](cap/live-operator-views-and-browser-review-surfaces.md) | Medium | Volva Execution-Host Session Workspace Contract; Canopy Queue Worktree Review Orchestration; Hyphae Scoped Memory Identity And Export Contract |
| 60 | [Cap: Status Preview And Customization Surface](cap/status-preview-and-customization-surface.md) | Medium | Septa Resolved Status And Customization Contract; Cap Live Operator Views And Browser Review Surfaces |
| 30 | [Cap: Canopy Performance](cap/canopy-performance.md) | Medium | Deep Audit |
| 32 | [Cap: Operational Modes](cap/operational-modes.md) | Low | — |
| 90 | [Cap: Replay and Eval Surfaces](cap/replay-eval-surfaces.md) | Medium | — |
| — | [Cap: Data Loading UX Consistency](cap/data-loading-ux-consistency.md) | Low | — |

### Tier 7: Later Phases

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 77 | [Canopy: Capability Routing + Multi-Model Orchestration](canopy/capability-routing.md) | Lower | [Canopy Sub-Task Hierarchy](archive/canopy/sub-task-hierarchy.md) (#73) |
| 78 | [Canopy: Drift Detection Pipeline](canopy/drift-detection.md) | Lower | — |
| 79 | [Canopy: File-Scope Conflict Resolution Strategies](canopy/conflict-resolution-strategies.md) | Lower | — |
| 80 | [Hyphae: Composite Recall Resources](hyphae/composite-recall-resources.md) | Lower | — |
| 81 | [Volva: Auth and Native API Backend](volva/auth-native-api.md) | Lower | — |
| 82 | [Cortina: Codex / Gemini Adapters](cortina/codex-gemini-adapters.md) | Lower | — |
| 105 | [Volva: Workspace-Session Route Models](volva/workspace-session-routes.md) | Lower | Volva Hyphae Recall Injection (#71) |
| 106 | [Cap: Inline Diff-Comment Review Loops](cap/inline-diff-review.md) | Lower | Cap Live Operator Views (#24) |
| 107 | [Rhizome: Analyzer Plugin Extensibility](rhizome/analyzer-plugin-extensibility.md) | Lower | Shipped prerequisite: Rhizome Structural Fallback (v0.7.11) |
