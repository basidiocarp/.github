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

### Tier 1: Critical — Broken Connections

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 146 | [Mycelium: Fix Critical Bugs (no-op migration, binary exec, git failure, GLOB injection)](mycelium/critical-fixes.md) | Critical | — |
| 143 | [Hymenium: Fix Critical Bugs (retry loop, SQL injection, stale runtime detection)](hymenium/critical-fixes.md) | Critical | — |
| 140 | [Rhizome: Fix Code Graph Data Integrity (node collision, edge corruption, pub label)](rhizome/graph-data-integrity.md) | Critical | — |
| 132 | [Canopy: Fix tool_task_decompose Missing Blocks Write](canopy/blocks-relationship-fix.md) | High | — |
| 133 | [Canopy: Fix Council Session Non-Atomic Operations](canopy/council-atomicity.md) | High | — |
| 117 | [Canopy: Fix Completion Guard and Auto-Complete Logic](canopy/completion-guard-fix.md) | High | — |
| 127 | [Hyphae: Fix Cross-Project Memory Data Loss](hyphae/cross-project-safety.md) | High | — |
| 118 | [Hyphae: Fix content_hash TOCTOU and CLI Ingest Path](hyphae/content-hash-fix.md) | High | — |

### Tier 2: Core Feature Work

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 129 | [Stipe: Fix Tar Extraction Path Traversal Risk](stipe/install-security.md) | High | — |
| 119 | [Stipe: Fix Backup Correctness Bugs](stipe/backup-correctness.md) | High | — |
| 144 | [Volva: Fix Runtime Safety (double-wait, AuthTarget unreachable, zombie child)](volva/runtime-safety.md) | High | — |
| 147 | [Spore: Quality Fixes (DoS allocation, JSON panic, TOCTOU, tilde, non-atomic backup)](spore/quality-fixes.md) | High | — |
| 135 | [Lamella: Fix Hook Correctness Issues](lamella/hook-correctness.md) | High | — |
| 120 | [Lamella: Fix Eval Harness Placeholder Snapshots and Delta Convention](lamella/eval-harness-fix.md) | Medium | — |
| 139 | [Cortina: Quality Fixes (byte slicing, DefaultHasher, budget_memories, transcript)](cortina/quality-fixes.md) | Medium | — |
| 141 | [Rhizome: Quality Fixes (hover stub, ref injection, path traversal, DefaultHasher)](rhizome/quality-fixes.md) | Medium | — |
| 142 | [Cap: Fix Analytics Correctness (type contract, most_active_project, since semantics)](cap/analytics-correctness.md) | Medium | — |
| 145 | [Annulus: Quality Fixes (TTL overflow, model match, cast_sign_loss)](annulus/quality-fixes.md) | Medium | — |

### Tier 3: Integration

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 138 | [Septa: Fix Schema Drift (stipe-doctor, stipe-init-plan, canopy-notification)](septa/schema-drift-fix.md) | Medium | — |
| 121 | [Cortina: Move inject_recall to Hyphae](cortina/recall-boundary.md) | Medium | #118 |

### Tier 4: Cross-Project Contract

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 136 | [Cortina: Resolve Boundary Expansion (handoff audit, rules, mycelium DB)](cortina/boundary-expansion.md) | Medium | — |
| 137 | [Canopy: Resolve Orchestration Logic Boundary with Hymenium](canopy/orchestration-boundary.md) | Medium | — |
| 122 | [Lamella: Resolve Homunculus Observation System Boundary](lamella/homunculus-boundary.md) | Medium | — |

### Tier 5: Standalone or Lower Urgency

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 123 | [Hyphae: Quality Fixes (project scoping, bench, fixture)](hyphae/quality-fixes.md) | Medium | — |
| 128 | [Hyphae: Round 2 Quality Fixes (purge, audit log, memoir, chunker)](hyphae/round2-quality.md) | Medium | — |
| 124 | [Stipe: Quality Fixes (TTY guard, tilde, file_name, low items)](stipe/quality-fixes.md) | Low | — |
| 130 | [Stipe: Install Quality Fixes (rollback, codesign, busy-poll, version)](stipe/install-quality.md) | Medium | — |
| 125 | [Canopy: Quality Fixes (MCP error, schema, TOCTOU, tests)](canopy/quality-fixes.md) | Medium | #117 |
| 134 | [Canopy: Store Quality Fixes (SQL injection, bind indices, summary model)](canopy/store-quality.md) | Medium | — |
| 126 | [Lamella: Fix SessionEnd Hook Timeout and Async](lamella/hook-fixes.md) | Low | — |
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
