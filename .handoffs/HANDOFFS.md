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
| [Capability Ecosystem Control Plane](cross-project/capability-ecosystem-control-plane.md) | Complete | C0-C8 all done 2026-04-29 — typed endpoint schema, transport primitives, CLI audit, boundary policy |
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

Consumer contracts, stale cache, supply chain, docs drift, and feature work.

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| A12 | [Cap: Cross-Tool Consumer Contracts](cap/cross-tool-consumer-contracts.md) | Medium | Evidence source kind and Annulus status/statusline consumer drift |
| A37 | [Cap: Canopy Stale Cache Integrity](cap/canopy-stale-cache-integrity.md) | Medium | Stale snapshot fallback is global instead of project/filter keyed |
| A46 | [Cap: Node Supply Chain Script Policy](cap/node-supply-chain-script-policy.md) | Medium | `npx` scripts, release checks, install lifecycle policy |
| A50 | [Cap: Dashboard And API Docs Drift](cap/dashboard-api-docs-drift.md) | Medium | API docs, route inventory, internals docs, and UI behavior claims are stale |
| F2 | [Cap: Operator Console Scope Reset](cap/operator-console-scope-reset.md) | Medium | Scope reset doc — what cap is vs. is not; part of freeze roadmap |
| — | [Cap: Canopy Performance And Decomposition](cap/canopy-performance.md) | Low | Canopy query performance and decomposition for large handoffs |
| — | [Cap: Inline Diff-Comment Review Loops](cap/inline-diff-review.md) | Low | Inline diff-comment and review-loop surfaces in the dashboard |
| — | [Cap: Live Operator Views And Browser Review Surfaces](cap/live-operator-views-and-browser-review-surfaces.md) | Low | Live workflow/agent views and browser-side review integration |
| — | [Cap: Service Health Panel](cap/service-health-panel.md) | Low | Ecosystem service health panel in the operator console |
| — | [Cap: Status Preview And Customization Surface](cap/status-preview-and-customization-surface.md) | Low | Status segment preview and operator customization UI |

---

### Stipe

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| A9 | [Stipe: Control Plane Quality](stipe/control-plane-quality.md) | Medium | Backup partial-success semantics and boolean-heavy APIs |
| — | [Stipe: Rollback Self-Invocation → Library Call](stipe/rollback-library-call-migration.md) | Medium | Replace `Command::new("stipe").arg("doctor")` in rollback.rs with direct `doctor::run()` call |
| — | [Stipe: Skill Install Pack](stipe/skill-install-pack.md) | Low | Skill pack install and lifecycle management in the installer |

---

### Lamella

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| A40 | [Lamella: Manifest Sync Maintenance](lamella/manifest-sync-maintenance.md) | Medium | Manifest sync maintenance script points at obsolete paths |
| — | [Lamella: Council Role Bundles](lamella/council-role-bundles.md) | Low | Council role bundle packaging and skill grouping by role |
| — | [Lamella: Evolution Feedback Loop](lamella/evolution-feedback-loop.md) | Low | Feedback loop for skill and hook evolution based on usage signals |
| — | [Lamella: General And Ecosystem Skill Pack Split](lamella/general-and-ecosystem-skill-pack-split.md) | Low | Separate general-purpose skills from ecosystem-specific packs |
| — | [Lamella: Session-End Direct Hook Cutover](lamella/session-end-direct-hook-cutover.md) | Low | Migrate session-end hooks from adapter invocation to direct cortina call |
| — | [Lamella: Skill Progressive Disclosure Convention](lamella/skill-progressive-disclosure.md) | Low | Convention for progressive disclosure in skill prompts |
| — | [Lamella: Validator Plugin Architecture](lamella/validator-plugin-architecture.md) | Low | Plugin architecture for lamella content validators |

---

### Hyphae

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| — | [Hyphae: Rhizome CLI → MCP Migration](hyphae/rhizome-mcp-migration.md) | Medium | Replace `rhizome symbols <file>` CLI with rhizome MCP `get_symbols` via spore::McpClient |
| — | [Hyphae: Memoir Git Versioning](hyphae/memoir-git-versioning.md) | Low | Track memoir changes in git for diff and rollback |
| — | [Hyphae: Memory-Use Protocol](hyphae/memory-use-protocol.md) | Low | Shared protocol spec for how agents read and write hyphae memory |
| — | [Hyphae: Obsidian Second-Brain Export](hyphae/obsidian-second-brain-export.md) | Low | Export hyphae memoirs and memories to Obsidian-compatible vault |
| — | [Hyphae: Search Type Registry](hyphae/search-type-registry.md) | Low | Typed registry for search modes (semantic, keyword, memoir, etc.) |
| — | [Hyphae: Shared Cross-Agent Context](hyphae/shared-cross-agent-context.md) | Low | Shared context surface for multi-agent sessions via hyphae |
| — | [Hyphae: Structured Export And Archive](hyphae/structured-export-archive.md) | Low | Structured memory export and archive format for long-term storage |

---

### Cortina

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| — | [Cortina: Codex / Gemini Adapters](cortina/codex-gemini-adapters.md) | Low | Hook adapters for Codex and Gemini CLI lifecycles |
| — | [Cortina: Session State Store](cortina/session-state-store.md) | Low | Persistent session state store in cortina — **Decision Required before starting** |
| — | [Cortina: Hyphae Hook-Time CLI → Socket Endpoint](cortina/hyphae-hook-time-endpoint-registry.md) | Low | Replace CLI store calls with socket endpoint; blocked on hyphae endpoint registration |

---

### Rhizome

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| — | [Rhizome: Analyzer Plugin Extensibility](rhizome/analyzer-plugin-extensibility.md) | Low | Plugin interface for custom analyzer passes in rhizome |
| — | [Rhizome: Blast-Radius Simulation](rhizome/blast-radius-simulation.md) | Low | Simulate change blast radius from a symbol or file set |
| — | [Rhizome: Incremental Fingerprinting And Change Classification](rhizome/incremental-fingerprinting.md) | Low | Incremental file fingerprinting and semantic change classification |

---

### Mycelium

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| — | [Mycelium: Rhizome CLI → MCP Migration](mycelium/rhizome-mcp-migration.md) | Medium | Replace `rhizome structure <file>` CLI with rhizome MCP `get_structure` via spore::McpClient |
| — | [Mycelium: Compressed Format Experiments](mycelium/compressed-format-experiments.md) | Low | Experiments with alternative compressed output formats |

---

### Septa

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~C5~~ | ~~[Septa: Local Service Endpoint Contracts](septa/local-service-endpoint-contracts.md)~~ | ~~Medium~~ | Done 2026-04-29 — schema, fixtures, CLI classification, foundation doc |
| — | [Septa: Contract Governance Enforcement](septa/contract-governance-enforcement.md) | Low | Tooling to enforce contract ownership rules — **Decision Required before starting** |

---

### Spore

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~C6~~ | ~~[Spore: Local Service Transport Primitives](spore/local-service-transport-primitives.md)~~ | ~~Medium~~ | Done 2026-04-29 — transport client, schema_version validation, timeout mapping, write timeout, probe.method |

---

### Canopy

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| — | [Canopy: Dispatch Request Service Endpoint](canopy/dispatch-request-service-endpoint.md) | Low | Replace hymenium→canopy CLI dispatch with typed local service endpoint; part of C8 |
| — | [Cap: Operator Surface Socket Endpoints](cap/operator-surface-socket-endpoints.md) | Low | Migrate cap backend from CLI spawning to socket endpoints; blocked on sibling tool endpoint registration |

---

### Hymenium

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| — | [Hymenium: Capability Dispatch Client](hymenium/capability-dispatch-client.md) | Low | Replace CLI dispatch with typed endpoint client via spore::LocalServiceClient; part of C8 |

---

### Volva

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| — | [Volva: Canopy Availability → Spore Discovery](volva/canopy-discovery-migration.md) | Medium | Replace `Command::new("canopy").arg("--version")` with `spore::discover(Tool::Canopy).is_some()` |
| — | [Volva: Auth And Native API Backend](volva/auth-native-api.md) | Low | Native API backend and auth integration for volva runtime |
| — | [Volva: Orchestration Mode Definition](volva/orchestration-mode-definition.md) | Low | Define orchestration mode boundaries — **Decision Required before starting** |
| — | [Volva: Workspace-Session Route Models](volva/workspace-session-routes.md) | Low | Route model for workspace-scoped sessions in volva |

---

### Cross-Project & Workspace

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| A52 | [Cross-Project: Workspace Docs Link Drift](cross-project/workspace-docs-link-drift.md) | Medium | Broken docs links, archived handoff references, command rendering, unavailable skill refs |
| ~~C7~~ | ~~[Cross-Project: CLI Coupling Exemption Audit](cross-project/cli-coupling-exemption-audit.md)~~ | ~~Medium~~ | Done 2026-04-29 — 14-row CLI coupling table in septa, verify script 28/28 |
| ~~C8~~ | ~~[Cross-Project: System-To-System Communication Boundary](cross-project/system-to-system-communication-boundary.md)~~ | ~~Medium~~ | Done 2026-04-29 — AGENTS.md CLI boundary rule, 3-tier hierarchy, canopy/hymenium stub handoffs, verify 5/5 |
| — | [Cross-Project: Cache-Friendly Context Layout](cross-project/cache-friendly-context-layout.md) | Low | Prompt and context layout patterns that maximize cache hit rates |
| — | [Cross-Project: Graceful Degradation Classification](cross-project/graceful-degradation-classification.md) | Low | Classify ecosystem degradation modes and define fallback contracts |
| — | [Cross-Project: Lamella→Cortina Boundary Phase 2](cross-project/lamella-cortina-boundary-phase2.md) | Low | Phase 2 cleanup of the lamella/cortina hook dispatch boundary |
| — | [Cross-Project: Summary + Detail-on-Demand Pattern](cross-project/summary-detail-on-demand.md) | Low | Shared pattern for summary views with expandable detail surfaces |
