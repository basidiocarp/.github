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

## Active Handoffs

### Foundation — Completed (2026-04-23)

All Ecosystem Health Audit fixes and structural improvements are done. St1 and U4a were marked Done prematurely and are now in Tier 2. See the [campaign README](campaigns/ecosystem-health-audit/README.md) for full issue tracking.

| # | Handoff | Status |
|---|---------|--------|
| A1–A5 | Audit fixes: enum drift, snapshot schema, cortina seam, spore version, cap→canopy SPOF | Done |
| S1–S3 | Structural: canopy resilience layer, cortina session store, septa contract governance | Done |
| C1–C5 | Cohesion: tool preference instructions, context injection, smoke test, drift signal, orchestration mode | Done |
| U1–U4 | Uncharted: CI gates, seam test coverage, cross-tool observability, auth audit | Done |
| U4b | [Canopy: Policy Event Log](canopy/policy-event-log.md) | Done |

---

### Tier 1: Do First

Empirically validated, fix live seam gaps, or unblock the most other work.

| # | Handoff | Rationale |
|---|---------|-----------|
| W3a | ~~[Cortina: GateGuard Fact-Force Hook](cortina/gateguard-fact-force.md)~~ | Done 2026-04-24 — 8 tests, 239 pass; lamella skill doc shipped |
| W2g | [Cortina: Hook Governance and Tool Metadata](cortina/hook-governance.md) | Hook metadata contract; W3a and W3d build on it |
| W1c | ~~[Septa: Context Envelope V1 Contract](septa/context-envelope-v1.md)~~ | Done 2026-04-24 — 49/49 septa schemas pass |
| W2a | [Cortina: Lifecycle Pipeline Stages](cortina/lifecycle-pipeline-stages.md) | Cortina is the signal backbone — more stages = better observability across everything |
| W2f | [Canopy: DAG-Based Task Graph](canopy/dag-task-graph.md) | Core coordination primitive; multi-agent work has no dependency ordering without it |
| W1a | [Canopy: Permission Memory Policy](canopy/permission-memory-policy.md) | Governs what agents can retain — security concern that touches every multi-agent session |

---

### Tier 2: Do Next

Clear value, no unresolved prerequisites. Septa contracts run together; St1/U4a were marked Done prematurely.

| # | Handoff | Rationale |
|---|---------|-----------|
| W2e | [Septa: Credential Abstraction V1](septa/credential-abstraction-v1.md) | Contract — multi-tool auth needs a shared shape before implementations proliferate |
| W2h | [Septa: Dependency Types V1 Contract](septa/dependency-types-v1.md) | Contract — completes the septa contract triad (W1c → W2e → W2h) |
| W2j | [Canopy: Task Output Envelope](canopy/task-output-envelope.md) | Contract — structured agent output shape; downstream consumers need a stable target |
| W3d | [Cortina: Stop Hook Extensions](cortina/stop-hook-extensions.md) | Extends the hook system with fact-force and trigger words; builds on W2g |
| W3b | [Annulus: Context Window % and Pace Delta](annulus/context-metrics.md) | Operator-visible in the statusline; low implementation risk; completes a core annulus capability |
| W2k | [Cap: Session Persistence and Cost Tracking](cap/session-cost-tracking.md) | Operators need cost visibility; self-contained cap feature |
| W2d | [Hyphae: Tiered Memory Eviction](hyphae/tiered-memory-eviction.md) | Prevents unbounded growth — operational correctness, not just a feature |
| W2c | [Hyphae: Pluggable Backend Adapters](hyphae/pluggable-backends.md) | Structural flexibility; unlocks non-SQLite backends for production deployments |
| W1b | [Mycelium: Declarative Filter Extensions](mycelium/declarative-filter-extensions.md) | Extends core filtering without touching the parser; contained and valuable |
| U4a | [Cap: Server Exposure Warning](cap/server-exposure-warning.md) | Was marked Done prematurely; straightforward cap UI addition |
| St1 | [Stipe: Install Mode Prompt](stipe/install-mode-prompt.md) | Was marked Done prematurely; stipe UX gap from C5 orchestration mode work |

---

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
| W2i | [Volva: Checkpoint Durability Modes](volva/checkpoint-durability-modes.md) | Execution reliability; self-contained volva change |
| W2o | [Mycelium: Content-Aware Routing](mycelium/content-aware-routing.md) | Content-type based routing; extends mycelium without touching filters |
| W2r | [Cap: Watcher Framework](cap/watcher-framework.md) | Reactive dashboard features; cap-local TypeScript change |
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
