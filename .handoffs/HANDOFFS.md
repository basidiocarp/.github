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

### Tier 2: High Priority Infrastructure

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| — | [Stipe: Doctor Expansion](stipe/doctor-expansion.md) | High | — |
| — | [Stipe: Install Completeness Verification](stipe/install-completeness-verification.md) | High | — |
| — | [Cortina: Hook Registry Hardening](cortina/hook-registry-hardening.md) | High | — |
| — | [Cortina: PreCompact / UserPromptSubmit Capture](cortina/precompact-capture.md) | High | — |
| — | [Hymenium: Error Classifier Taxonomy](hymenium/error-classifier-taxonomy.md) | High | — |
| — | [Hymenium: Runtime Sweeper](hymenium/runtime-sweeper.md) | High | — |

### Tier 3: Canopy Core

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| — | [Canopy: Council Session Lifecycle](canopy/council-session-lifecycle.md) | High | — |
| — | [Canopy: Sub-Task Hierarchy](canopy/sub-task-hierarchy.md) | Medium | — |
| — | [Canopy: Task Duplicate Prevention](canopy/task-duplicate-prevention.md) | Medium | — |
| — | [Canopy: Notification Model and Storage](canopy/notification-model-and-storage.md) | Medium | — |
| — | [Canopy: Council Record Artifact Emission](canopy/council-record-artifact-emission.md) | Medium | Canopy Council Session Lifecycle |

### Tier 4: Cortina, Hyphae, Cross-Cutting

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| — | [Cortina: Tool Usage Emission](cortina/tool-usage-emission.md) | Medium | — |
| — | [Cortina: Usage Event Producer Serialization](cortina/usage-event-producer-serialization.md) | Medium | — |
| — | [Cortina: Tool Call Risk Classification](cortina/tool-call-risk-classification.md) | Medium | — |
| — | [Cortina: Compact Summary Artifact Emission](cortina/compact-summary-artifact-emission.md) | Medium | — |
| — | [Cortina: Session-End Tool Usage Advisory](cortina/session-end-tool-advisory.md) | Medium | Cortina Tool Usage Emission |
| — | [Cortina: Session-End Stale Handoff Warning](cortina/session-end-stale-handoff-warning.md) | Medium | handoff-path-extraction (archived) |
| — | [Cortina: Pre-Write Tool Check](cortina/pre-write-tool-check.md) | Medium | — |
| — | [Hyphae: Artifact Model](hyphae/artifact-model.md) | Medium | — |
| — | [Hyphae: Archive Export Command](hyphae/archive-export-command.md) | Medium | — |
| — | [Hyphae: Archive Import Validation](hyphae/archive-import-validation.md) | Medium | — |
| — | [Hyphae: Compact Summary Artifact Query Surface](hyphae/compact-summary-artifact-query-surface.md) | Medium | Hyphae Artifact Model |
| — | [Hyphae: Council Record Artifact Query Surface](hyphae/council-record-artifact-query-surface.md) | Medium | Hyphae Artifact Model |
| — | [Hyphae: Memory Provider Lifecycle Hooks](hyphae/memory-provider-lifecycle.md) | Medium | — |
| — | [Lamella: Skill Authoring Convention](lamella/skill-authoring-convention.md) | Medium | — |
| — | [Septa: Foundation Alignment](septa/foundation-alignment.md) | Medium | — |

### Tier 5: Standalone or Lower Urgency

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 20 | [Hyphae: HTTP Embeddings](hyphae/http-embeddings.md) | Low | — |
| 112 | [Mycelium: Compressed Format Experiments](mycelium/compressed-format-experiments.md) | Low | [Mycelium Structural Parser Hardening](archive/mycelium/structural-parser-hardening.md) |
| — | [Mycelium: Command Output Summary Mode](mycelium/command-output-summary-mode.md) | Medium | — |
| — | [Mycelium: Deterministic Telemetry Summary Surfaces](mycelium/deterministic-telemetry-summary-surfaces.md) | Medium | — |
| — | [Annulus: Per-Provider Usage Scanner](annulus/per-provider-usage-scanner.md) | Medium | — |
| — | [Lamella: Strategic Compact Skill](lamella/strategic-compact-skill.md) | Medium | Lamella Skill Authoring Convention |
| — | [Lamella: Agent Introspection Debugging Skill](lamella/agent-introspection-debugging-skill.md) | Medium | Lamella Skill Authoring Convention |
| — | [Spore: OpenTelemetry Tracing (foundation child)](spore/otel-tracing.md) | Medium | — |

### Tier 6: Cap

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 24 | [Cap: Live Operator Views And Browser Review Surfaces](cap/live-operator-views-and-browser-review-surfaces.md) | Medium | Volva Execution-Host Session Workspace Contract; Canopy Queue Worktree Review Orchestration; Hyphae Scoped Memory Identity And Export Contract |
| 60 | [Cap: Status Preview And Customization Surface](cap/status-preview-and-customization-surface.md) | Medium | Septa Resolved Status And Customization Contract; Cap Live Operator Views And Browser Review Surfaces |
| 30 | [Cap: Canopy Performance](cap/canopy-performance.md) | Medium | Deep Audit |
| 32 | [Cap: Operational Modes](cap/operational-modes.md) | Low | — |
| 90 | [Cap: Replay and Eval Surfaces](cap/replay-eval-surfaces.md) | Medium | — |
| — | [Cap: Data Loading UX Consistency](cap/data-loading-ux-consistency.md) | Low | — |
| — | [Cap: Service Health Panel](cap/service-health-panel.md) | Medium | Spore graceful-degradation-classification |

### Tier 7: Later Phases

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 77 | [Canopy: Capability Routing + Multi-Model Orchestration](canopy/capability-routing.md) | Lower | [Canopy Sub-Task Hierarchy](canopy/sub-task-hierarchy.md) |
| 78 | [Canopy: Drift Detection Pipeline](canopy/drift-detection.md) | Lower | — |
| 79 | [Canopy: File-Scope Conflict Resolution Strategies](canopy/conflict-resolution-strategies.md) | Lower | — |
| 80 | [Hyphae: Composite Recall Resources](hyphae/composite-recall-resources.md) | Lower | — |
| 81 | [Volva: Auth and Native API Backend](volva/auth-native-api.md) | Lower | — |
| 82 | [Cortina: Codex / Gemini Adapters](cortina/codex-gemini-adapters.md) | Lower | — |
| 105 | [Volva: Workspace-Session Route Models](volva/workspace-session-routes.md) | Lower | Volva Hyphae Recall Injection (#71) |
| 106 | [Cap: Inline Diff-Comment Review Loops](cap/inline-diff-review.md) | Lower | Cap Live Operator Views (#24) |
| 107 | [Rhizome: Analyzer Plugin Extensibility](rhizome/analyzer-plugin-extensibility.md) | Lower | Shipped prerequisite: Rhizome Structural Fallback (v0.7.11) |
| — | [Stipe: Annulus Statusline Auto-Config](stipe/annulus-statusline-auto-config.md) | Medium | Stipe Doctor Expansion |
| — | [Stipe: Hyphae Pre-Upgrade Backup](stipe/hyphae-pre-upgrade-backup.md) | Medium | Hyphae Archive Export Command |
| — | [Stipe: Permission Memory and Provider UX](stipe/permission-memory-provider-ux.md) | Medium | — |
| — | [Volva: Execution Environment Isolation](volva/execution-environment-isolation.md) | Medium | — |
| — | [Cortina: Cache-Friendly Context Ordering](cortina/cache-friendly-context-ordering.md) | Low | — |
| — | [Lamella: Cache-Friendly Context Ordering](lamella/cache-friendly-context-ordering.md) | Low | — |
| — | [Lamella: Session-End Direct Hook Cutover](lamella/session-end-direct-hook-cutover.md) | Low | Lamella-Cortina Boundary Phase 2 |
