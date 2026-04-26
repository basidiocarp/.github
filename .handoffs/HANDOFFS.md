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
| [Sequential Audit Hardening Campaign](campaigns/sequential-audit-hardening-2026-04-26/README.md) | In progress | Phase 5 complete; Phase 6 ready |
| [Capability Ecosystem Control Plane](cross-project/capability-ecosystem-control-plane.md) | Ready | Umbrella for registry, discovery, registration, and typed dispatch integration |

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

### Capability Ecosystem Control Plane — 2026-04-26

Created from the capability ecosystem design discussion: standalone tools remain usable independently, while ecosystem-mode communication moves to Septa contracts, Spore discovery, Stipe-managed registration, and typed Canopy/Hymenium dispatch.

Suggested sequence: C0 defines the contracts, C1 adds shared discovery, C2 makes Stipe write and repair registry entries, C3 exposes Canopy dispatch as a typed service endpoint, and C4 migrates Hymenium to capability resolution with CLI fallback.

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| C0 | [Septa: Capability Registry Contracts](septa/capability-registry-contracts.md) | Critical | Defines installed capability registry and runtime lease payloads |
| C1 | [Spore: Capability Registry Discovery](spore/capability-registry-discovery.md) | Critical | Reads registry and leases, resolves capability ids to endpoint candidates |
| C2 | [Stipe: Capability Registration Manager](stipe/capability-registration-manager.md) | High | Writes and repairs managed capability registry entries during install/update/uninstall/doctor |
| C3 | [Canopy: Dispatch Request Service Endpoint](canopy/dispatch-request-service-endpoint.md) | High | Accepts `dispatch-request-v1` directly so callers stop reconstructing CLI flags |
| C4 | [Hymenium: Capability Dispatch Client](hymenium/capability-dispatch-client.md) | High | Resolves `workflow.dispatch.v1` through Spore and treats CLI as fallback |

### Rust Ecosystem Audit Follow-Ups — 2026-04-26

Generated from the multi-agent Rust ecosystem audit focused on contracts, code quality, architecture, KISS/DRY, code splitting, wrapper overuse, docs drift, and verification gaps.

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~A1~~ | ~~[Hymenium: Orchestration Dispatch Contracts](hymenium/orchestration-dispatch-contracts.md)~~ | Critical | Done 2026-04-25 — fixed --requested-by/--required-tier/assign flags; build_assign_task_args; 6 new tests (4e53d05) |
| A2 | [Canopy: Septa Read Model Contracts](canopy/septa-read-model-contracts.md) | High | Snapshot/task-detail/handoff/outcome contract drift |
| A3 | [Rhizome: Code Graph Contract And Install Boundary](rhizome/code-graph-contract-and-install-boundary.md) | High | Code graph Septa drift and core install-policy boundary |
| A4 | [Hyphae: Code Graph Import And Core Boundary](hyphae/code-graph-import-and-core-boundary.md) | High | Import validation, identity storage, core adapter leakage, UTF-8 path safety |
| ~~A5~~ | ~~[Volva: Hook Runtime Contracts](volva/hook-runtime-contracts.md)~~ | High | Done 2026-04-25 — timeout clamped to [1,30000]; execution_session in septa schema; docs updated (49a2abb/a7971d3) |
| A6 | [Cortina: Capture Policy Boundary](cortina/capture-policy-boundary.md) | High | Capture repo has default blocking policy behavior and docs drift |
| A7 | [Annulus: Operator Boundary And Statusline Contracts](annulus/operator-boundary-statusline-contracts.md) | High | Read-only boundary, Canopy notification write, statusline contract/registry, docs/version drift |
| ~~A8~~ | ~~[Spore: Shared Primitive Quality](spore/shared-primitive-quality.md)~~ | High | Done 2026-04-25 — logging API preserved, wait() after kill() in 3 paths, discovery 5s timeout, README v0.4.11/CI (e4cd04b) |
| A9 | [Stipe: Control Plane Quality](stipe/control-plane-quality.md) | Medium | Backup partial-success semantics and boolean-heavy APIs |
| A10 | [Mycelium: Output Cleanliness](mycelium/output-cleanliness.md) | Medium | Optional Hyphae fallback warning contaminates output |
| A11 | [Canopy: Notification Contract Alignment](canopy/canopy-notification-contract-alignment.md) | High | `canopy-notification-v1` does not match Canopy/Cap/Annulus real fields |
| A12 | [Cap: Cross-Tool Consumer Contracts](cap/cross-tool-consumer-contracts.md) | Medium | Evidence source kind and Annulus status/statusline consumer drift |
| A13 | [Cortina: Session And Usage Event Contracts](cortina/session-usage-event-contracts.md) | High | Session and usage payloads do not round-trip through Septa |
| A14 | [Hyphae: Read Model And Archive Contracts](hyphae/read-model-and-archive-contracts.md) | High | Hyphae CLI/Cap read model drift and archive filter mismatch |
| A15 | [Mycelium: Gain And Summary Contracts](mycelium/gain-summary-contracts.md) | High | Gain JSON emits extra telemetry field; summary contract is not a real round-trip |
| A16 | [Septa: Validation Tooling And Inventory](septa/validation-tooling-and-inventory.md) | High | Offline `$ref` validation docs, registry inventory, variant fixture coverage |
| A17 | [Rhizome: MCP Write Boundary And Runtime Timeouts](rhizome/mcp-write-boundary-and-runtime-timeouts.md) | Critical | MCP root override can expand write authority; package-manager installs lack deadlines |
| A18 | [Canopy: MCP Handoff Runtime Boundaries](canopy/mcp-handoff-runtime-boundaries.md) | Critical | Handoff completeness can execute sibling scripts; import and file locks are too permissive |
| A19 | [Hyphae: Storage And Ingest Runtime Safety](hyphae/storage-and-ingest-runtime-safety.md) | High | WAL-safe backup/restore and bounded ingest/storage input policies |
| A20 | [Stipe: Install Hooks And Secret Safety](stipe/install-hooks-and-secret-safety.md) | High | Atomic lockfile, install deadlines, provider secret writes, generated hook policy |
| A21 | [Cap: API Auth And Webhook Defaults](cap/api-auth-and-webhook-defaults.md) | High | API and webhook routes fail open without configured secrets |
| A22 | [Lamella: Session Logger Secret Redaction](lamella/session-logger-secret-redaction.md) | Medium | Hook session logger persists Bash command snippets without redaction or restrictive mode |
| A23 | [Volva: Backend And Credential Runtime Safety](volva/backend-and-credential-runtime-safety.md) | Medium | Official backend timeout, project hook adapter trust/env, credential file permissions |
| A24 | [Mycelium: Input Size Boundaries](mycelium/input-size-boundaries.md) | Medium | read/diff/json commands read unbounded file/stdin input before safeguards |
| A25 | [Cross-Project: Verification Command And Script Hardening](cross-project/verification-command-and-script-hardening.md) | High | Weak verify scripts, cwd-unsafe command blocks, dashboard/script hygiene, CI parity docs |
| A26 | [Cross-Project: Producer Contract Validation Harness](cross-project/producer-contract-validation-harness.md) | High | Real producer output is not broadly schema-validated against Septa and consumer parsers |
| A27 | [Cap: Server And UI Verification Hardening](cap/server-and-ui-verification-hardening.md) | High | Malformed write bodies, fixture-backed consumer tests, and observable UI behavior coverage |
| A28 | [Hymenium: Workflow Gate Integration Verification](hymenium/workflow-gate-integration-verification.md) | High | Implementer-to-auditor gate is tested with mocks, not evidence-backed integration |
| A29 | [Rhizome: LSP And Export Verification](rhizome/lsp-and-export-verification.md) | High | Live LSP/export behavior is mostly ignored or outside default validation |
| A30 | [Cortina: Hook Executor Verification](cortina/hook-executor-verification.md) | Medium | Hook executor tests prove a no-op stub while docs describe execution behavior |
| A31 | [Mycelium: Git Branch Regression Verification](mycelium/git-branch-regression-verification.md) | Medium | Branch write-regression coverage is ignored by default validation |
| A32 | [Hyphae: Memory And Document Integrity](hyphae/memory-document-integrity.md) | High | Memory/vector writes and project-scoped document identity can corrupt persisted state |
| A33 | [Rhizome: Incremental Export Prune Integrity](rhizome/incremental-export-prune-integrity.md) | High | Partial code graph exports can prune unchanged Hyphae concepts |
| A34 | [Cortina: Volva Event Replay Identity](cortina/volva-event-replay-identity.md) | High | Volva hook events lose session/replay identity at Cortina boundary |
| A35 | [Canopy: Task Event And State Idempotency](canopy/task-event-and-state-idempotency.md) | High | Evidence events, repeated status writes, scoped duplicates, and queue state can drift |
| A36 | [Hymenium: Terminal Workflow Idempotency](hymenium/terminal-workflow-idempotency.md) | High | `complete` can overwrite terminal workflow outcomes and duplicate transitions |
| A37 | [Cap: Canopy Stale Cache Integrity](cap/canopy-stale-cache-integrity.md) | Medium | Stale snapshot fallback is global instead of project/filter keyed |
| A38 | [Cortina: Compact Summary Artifact Integrity](cortina/compact-summary-artifact-integrity.md) | Medium | Compact summaries are stored as memories instead of typed artifacts |
| A39 | [Cross-Project: Version Ledger Authority](cross-project/version-ledger-authority.md) | High | Ecosystem tool version authority is split across ledger, manifests, and Stipe pins |
| A40 | [Lamella: Manifest Sync Maintenance](lamella/manifest-sync-maintenance.md) | Medium | Manifest sync maintenance script points at obsolete paths |
| A41 | [Cortina: Handoff Audit And Hook Secret Boundaries](cortina/handoff-audit-and-hook-secret-boundaries.md) | High | Handoff audit outside-root file oracle and PostToolUse secret redaction |
| A42 | [Lamella: Hook Trust And Manifest Path Security](lamella/hook-trust-and-manifest-path-security.md) | High | Post-edit hook toolchain env trust, manifest traversal, raw hook payload echoing |
| A43 | [Hymenium: Dispatch Command Trust Boundary](hymenium/dispatch-command-trust-boundary.md) | Medium | Dispatch shells out to ambient `canopy` without timeout or trusted path |

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
| ~~W1d~~ | ~~[Rhizome: Incremental Fingerprinting](rhizome/incremental-fingerprinting.md)~~ | Done 2026-04-25 — Fingerprint + ChangeClass in rhizome-core; signature collision fix; schema v2 (9672800) |
| ~~W3c~~ | ~~[Rhizome: Blast-Radius Simulation](rhizome/blast-radius-simulation.md)~~ | Done 2026-04-25 — rhizome_simulate_change MCP tool; BlastRadius/SymbolRef in rhizome-core; 40 tools total (a7ba43b) |

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
