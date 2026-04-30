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
| [Ecosystem Health Audit](campaigns/ecosystem-health-audit/README.md) | Fix Phase In Progress | 16 issues tracked — 5 already fixed in codebase, 3 open (cortina session resilience, hyphae protocol schema, hook envelope schema); fix campaign: [ecosystem-health-audit-fix-2026-04-30](campaigns/ecosystem-health-audit-fix-2026-04-30/README.md) |
| [Sequential Audit Hardening Campaign](campaigns/sequential-audit-hardening-2026-04-26/README.md) | All Phases Complete | 53 issues tracked — fix phase ready |
| [Capability Ecosystem Control Plane](cross-project/capability-ecosystem-control-plane.md) | Complete | C0-C8 all done 2026-04-29 — typed endpoint schema, transport primitives, CLI audit, boundary policy |
| [Scope Freeze And Operator Console Reset](cross-project/core-hardening-freeze-roadmap.md) | Complete | F1 done 2026-04-29 — freeze roadmap; F2 done 2026-04-29 — cap scope reset |
| [Post-Execution Boundary Compliance Audit](campaigns/post-execution-boundary-audit-2026-04-29/README.md) | Complete | 22 findings closed 2026-04-29 — 3 blockers, 11 concerns, 4 nits + 36-item Low queue triage |
| [Ecosystem Drift Follow-Up Audit](campaigns/ecosystem-drift-followup-audit-2026-04-30/README.md) | Complete | 4 lanes done 2026-04-30 — 8 blockers, 9 concerns, 5 nits across smoke, producer-schema, version-pin, MCP-surface; fix phase complete 2026-04-30 (10 of 10 dispatchable handoffs landed; follow-up F3.1-followup also closed 2026-04-30) |

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
| ~~A12~~ | ~~[Cap: Cross-Tool Consumer Contracts](cap/cross-tool-consumer-contracts.md)~~ | ~~Medium~~ | Done 2026-04-29 — script_verification added, annulus fixture test, all septa kinds covered |
| ~~A37~~ | ~~[Cap: Canopy Stale Cache Integrity](cap/canopy-stale-cache-integrity.md)~~ | ~~Medium~~ | Done 2026-04-29 — per-request cache key, two-project and two-filter isolation tests |
| ~~A46~~ | ~~[Cap: Node Supply Chain Script Policy](cap/node-supply-chain-script-policy.md)~~ | ~~Medium~~ | Done 2026-04-29 — npx removed from package.json scripts and release.sh; supply chain policy doc added |
| ~~A50~~ | ~~[Cap: Dashboard And API Docs Drift](cap/dashboard-api-docs-drift.md)~~ | ~~Medium~~ | Done 2026-04-29 — 4 missing namespaces added to api.md; route count 9→13 in internals; 4 factual fixes in getting-started; 4 missing pages in README |
| ~~F2~~ | ~~[Cap: Operator Console Scope Reset](cap/operator-console-scope-reset.md)~~ | ~~Medium~~ | Done 2026-04-29 — decision report: partial rebuild, cut /code and /symbols, migrate CLI couplings, freeze new features |
| ~~F2.1+F2.3~~ | ~~[Cap: Stipe Validators Accept Null](cap/stipe-validators-accept-null.md)~~ | ~~Medium~~ | Done 2026-04-29 — `isRepairAction` accepts null description; `isInitStep` accepts null/missing detail; 6 contract tests added |
| ~~F2.2+F2.4~~ | ~~[Cap: Stipe Init Repair Action Shape](cap/stipe-init-repair-action-shape.md)~~ | ~~Medium~~ | Done 2026-04-29 — `isInitPlanRepairAction` predicate added; init repair_actions validate `action_key` and accept optional `args`/`tier`/`description` |
| ~~F2.5~~ | ~~[Cap: Mycelium Gain Validates Weekly/Monthly](cap/mycelium-gain-weekly-monthly.md)~~ | ~~Medium~~ | Done 2026-04-29 — `isGainCliOutput` validates weekly/monthly arrays via reused `isGainDailyStats` predicate (schemas identical); 7 tests added |
| ~~F2.6+F2.7+F2.9~~ | ~~[Cap: Canopy Consumer Tightening](cap/canopy-consumer-tightening.md)~~ | ~~Medium~~ | Done 2026-04-29 — snapshot validates `attention`/`sla_summary`/`drift_signals`; task-detail validates `attention`/`sla_summary`; notification `event_type` validated against septa enum, unknowns logged + skipped |
| — | [Cap: Canopy Performance And Decomposition](cap/canopy-performance.md) | Low | Canopy query performance and decomposition for large handoffs |
| — | [Cap: Inline Diff-Comment Review Loops](cap/inline-diff-review.md) | Low | Inline diff-comment and review-loop surfaces in the dashboard |
| — | [Cap: Live Operator Views And Browser Review Surfaces](cap/live-operator-views-and-browser-review-surfaces.md) | Low | Live workflow/agent views and browser-side review integration |
| — | [Cap: Status Preview And Customization Surface](cap/status-preview-and-customization-surface.md) | Low | Status segment preview and operator customization UI |
| — | [Cap: Operator Surface Socket Endpoints](cap/operator-surface-socket-endpoints.md) | Low | Migrate cap backend from CLI spawning to socket endpoints; blocked on sibling tool endpoint registration |

---

### Stipe

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~A9~~ | ~~[Stipe: Control Plane Quality](stipe/control-plane-quality.md)~~ | ~~Medium~~ | Done 2026-04-29 — BackupOutcome struct, InstallOptions/InitOptions, fn_params_excessive_bools removed |
| ~~—~~ | ~~[Stipe: Rollback Self-Invocation → Library Call](stipe/rollback-library-call-migration.md)~~ | ~~Medium~~ | Done 2026-04-29 — direct doctor::run() call; added check_health() to detect unhealthy state |
| ~~F2.16~~ | ~~[Stipe: Init-Plan Repair Action Producer Fix](stipe/init-plan-repair-action-producer-fix.md)~~ | ~~Tier A blocker~~ | Done 2026-04-30 — `RepairAction::manual` requires `action_key`; init-plan call sites use Primary/Secondary; doctor paths keep Manual |
| ~~F2.19~~ | ~~[Stipe: Capability-Registry Schema-Version Fix](stipe/capability-registry-schema-version-fix.md)~~ | ~~Tier C blocker~~ | Done 2026-04-30 — producer emits `"schema_version":"1.0"` via new `CAPABILITY_REGISTRY_SCHEMA_VERSION` constant; doctor fixture aligned |
| ~~Lane1~~ | ~~[Stipe: Doctor Cursor Host Gating](stipe/doctor-cursor-host-gating.md)~~ | ~~Tier D concern~~ | Done 2026-04-30 — Cursor gated by `STIPE_CURSOR_HOST` env var or `cursor` on PATH; refactored to pure helper for deterministic tests; 5 new tests cover the decision matrix |
| ~~Backup-path~~ | ~~[Stipe: Move package_repair Backups Out of Harness Load Tree](stipe/backup-path-out-of-harness-load-tree.md)~~ | ~~Medium~~ | Done 2026-04-30 — backups now under `~/.local/share/stipe/backups/<ts>-<idx>-pre-package-repair/<flattened>/`; pure helper API; `..`-segment guard; index-bucket collision-safe |
| — | [Stipe: Skill Install Pack](stipe/skill-install-pack.md) | Low | Skill pack install and lifecycle management in the installer |

---

### Lamella

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~A40~~ | ~~[Lamella: Manifest Sync Maintenance](lamella/manifest-sync-maintenance.md)~~ | ~~Medium~~ | Done 2026-04-29 — corrected paths to resources/skills/ and manifests/claude/, guard added |
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
| ~~—~~ | ~~[Hyphae: Rhizome CLI → MCP Migration](hyphae/rhizome-mcp-migration.md)~~ | ~~Medium~~ | Done 2026-04-29 — McpClient::spawn + get_symbols; 6 edge-case tests added |
| — | [Hyphae: Memoir Git Versioning](hyphae/memoir-git-versioning.md) | Low | Track memoir changes in git for diff and rollback |
| — | [Hyphae: Obsidian Second-Brain Export](hyphae/obsidian-second-brain-export.md) | Low | Export hyphae memoirs and memories to Obsidian-compatible vault |
| — | [Hyphae: Search Type Registry](hyphae/search-type-registry.md) | Low | Typed registry for search modes (semantic, keyword, memoir, etc.) |
| — | [Hyphae: Shared Cross-Agent Context](hyphae/shared-cross-agent-context.md) | Low | Shared context surface for multi-agent sessions via hyphae |

---

### Cortina

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~F2.17~~ | ~~[Cortina: tool-usage-event Skip-Serializing Fix](cortina/tool-usage-event-skip-serializing-fix.md)~~ | ~~Tier C blocker~~ | Done 2026-04-30 — `skip_serializing_if` removed from required fields; empty arrays now serialize as `[]` |
| #9+#15 | [Cortina: Session Resilience — Timeout and Cleanup](cortina/session-resilience-timeout-and-cleanup.md) | Medium | State file not removed on hyphae failure; no internal subprocess timeout on hyphae write |
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
| ~~—~~ | ~~[Mycelium: Rhizome CLI → MCP Migration](mycelium/rhizome-mcp-migration.md)~~ | ~~Medium~~ | Done 2026-04-29 — McpClient::spawn + get_structure; trim_end preserved |
| ~~F2.13~~ | ~~[Mycelium: Gain Weekly/Monthly Producer Fix](mycelium/gain-weekly-monthly-producer-fix.md)~~ | ~~Tier A blocker~~ | Done 2026-04-30 — WeekStats/MonthStats serialize canonical `date` (ISO-8601 week/month start); merge_monthly strips `-01` for ccusage key alignment |
| — | [Mycelium: Compressed Format Experiments](mycelium/compressed-format-experiments.md) | Low | Experiments with alternative compressed output formats |

---

### Septa

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~C5~~ | ~~[Septa: Local Service Endpoint Contracts](septa/local-service-endpoint-contracts.md)~~ | ~~Medium~~ | Done 2026-04-29 — schema, fixtures, CLI classification, foundation doc |
| ~~F2.10~~ | ~~[Septa: Orphan Schema Triage](septa/orphan-schema-triage.md)~~ | ~~Medium~~ | Done 2026-04-29 — 9 schemas moved to `septa/draft/`, 2 deleted, 1 kept (host-identifier-v1, `$ref` target); validate-all 60→48 |
| #11 | [Septa: Hyphae Protocol Schema](septa/hyphae-protocol-schema.md) | Medium | MemoryProtocolSurface is unseamed — hyphae emits it, volva consumes it, no septa schema |
| #13 | [Septa: Hook Envelope Schema](septa/hook-envelope-schema.md) | Low | Claude Code hook envelope format not schema-backed; low urgency |
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

---

### Hymenium

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| — | [Hymenium: Capability Dispatch Client](hymenium/capability-dispatch-client.md) | Low | Replace CLI dispatch with typed endpoint client via spore::LocalServiceClient; part of C8 |
| ~~F3.1-followup~~ | ~~[Hymenium: Migrate to Post-`0bc2e878` Spore Capability API](hymenium/spore-capability-api-migration.md)~~ | ~~Medium~~ | Done 2026-04-30 — inlined capability types + resolve_capability into capability_client.rs (both the module and path helpers absent from v0.4.11); Cargo.toml bumped to 0bc2e878; ecosystem-versions.toml pending cleared; 269 tests pass |

---

### Volva

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~—~~ | ~~[Volva: Canopy Availability → Spore Discovery](volva/canopy-discovery-migration.md)~~ | ~~Medium~~ | Done 2026-04-29 — spore::discover(Tool::Canopy).is_some() replaces subprocess probe |
| — | [Volva: Auth And Native API Backend](volva/auth-native-api.md) | Low | Native API backend and auth integration for volva runtime |
| — | [Volva: Orchestration Mode Definition](volva/orchestration-mode-definition.md) | Low | Define orchestration mode boundaries — **Decision Required before starting** |
| — | [Volva: Workspace-Session Route Models](volva/workspace-session-routes.md) | Low | Route model for workspace-scoped sessions in volva |

---

### Cross-Project & Workspace

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~A52~~ | ~~[Cross-Project: Workspace Docs Link Drift](cross-project/workspace-docs-link-drift.md)~~ | ~~Medium~~ | Done 2026-04-29 — absolute paths fixed, stale skill refs removed, verify script bug fixed |
| ~~C7~~ | ~~[Cross-Project: CLI Coupling Exemption Audit](cross-project/cli-coupling-exemption-audit.md)~~ | ~~Medium~~ | Done 2026-04-29 — 14-row CLI coupling table in septa, verify script 28/28 |
| ~~C8~~ | ~~[Cross-Project: System-To-System Communication Boundary](cross-project/system-to-system-communication-boundary.md)~~ | ~~Medium~~ | Done 2026-04-29 — AGENTS.md CLI boundary rule, 3-tier hierarchy, canopy/hymenium stub handoffs, verify 5/5 |
| ~~F2.8~~ | ~~[Cross-Project: Add `annulus-status-v1` Septa Schema](cross-project/annulus-status-v1-schema.md)~~ | ~~Medium~~ | Done 2026-04-29 — schema + fixture landed; cap parseAnnulusOutput validates schema/version consts and degrades soft; validate-all 60/60 |
| ~~F1.1+F1.2+F1.3~~ | ~~[Cross-Project: C7 CLI Coupling Table Refresh](cross-project/c7-cli-coupling-table-refresh.md)~~ | ~~Medium~~ | Done 2026-04-29 — added stipe→hyphae and stipe→lamella rows; reworded stipe→annulus row from `--version` to `validate-hooks --json` |
| ~~Lane3~~ | ~~[Cross-Project: Dashboard Low Queue Cleanup](cross-project/dashboard-low-queue-cleanup.md)~~ | ~~Medium~~ | Done 2026-04-29 — 7 stale umbrellas archived; misfiled cap row moved from Canopy to Cap section; Low queue 36→29 |
| ~~F3.1~~ | ~~[Cross-Project: Spore Rev Pin Decision](cross-project/spore-rev-pin-decision.md)~~ | ~~Tier B blocker~~ | Done 2026-04-30 — Option A applied: `ecosystem-versions.toml` rev bumped to `0bc2e878…`; hymenium held at `a3c7f5bf…` pending its capability API migration |
| ~~F3.2-F3.7~~ | ~~[Cross-Project: Tier B Pin Alignment Sweep](cross-project/tier-b-pin-alignment-sweep.md)~~ | ~~Tier B mixed~~ | Done 2026-04-30 — rusqlite/thiserror/which/toml aligned across volva/hymenium/cortina/mycelium/hyphae/rhizome/stipe/spore; clap_complete documented |
| ~~F2.14+F2.15~~ | ~~[Cross-Project: canopy-task-detail additionalProperties Decision](cross-project/canopy-task-detail-additional-properties-decision.md)~~ | ~~Tier C blocker~~ | Done 2026-04-30 — Option C applied: TaskDetailWire enforces 22 schema-declared fields, 6 internal fields dropped; schema extended with consumer-facing fields (events, heartbeats, ownership, etc.); additionalProperties:false now genuinely enforced |
| ~~F4.3+F4.4~~ | ~~[Cross-Project: Workspace CLAUDE.md MCP Tool Coverage](cross-project/workspace-claude-md-mcp-tool-coverage.md)~~ | ~~Tier D concern~~ | Done 2026-04-30 — workspace CLAUDE.md groups 23 hyphae + 21 rhizome MCP tools; per-repo files list all 40+40 callable surfaces |
| ~~Lane1~~ | ~~[Cross-Project: Hyphae recall→search Doc Fix](cross-project/hyphae-recall-vs-search-doc-fix.md)~~ | ~~Tier D concern~~ | Done 2026-04-30 — `hyphae memory recall` (nonexistent) replaced with `hyphae search --query …` across handoffs/templates/archives |
