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
| [Capability Ecosystem Control Plane](cross-project/capability-ecosystem-control-plane.md) | Ready | C0-C8 tracked — registry, discovery, registration, typed local service APIs, and CLI-coupling audit |
| [Hymenium/Canopy Dogfood Hardening](cross-project/hymenium-canopy-dogfood-hardening.md) | Ready | H0-H7 tracked — parser intake, dispatch compatibility, runtime identity, reconciliation, and operator hardening |
| [Scope Freeze And Operator Console Reset](cross-project/core-hardening-freeze-roadmap.md) | Ready | F1-F2 tracked — freeze roadmap and Cap operator-console scope reset |

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

Work is organized by contract or tool boundary. Schema and contract items appear first within each group because they gate downstream code changes. Done items are shown in strikethrough for context.

### Contract & Schema Definitions

Septa schema work and the cross-project validation harness. Settle these before changing producer or consumer code.

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~A16~~ | ~~[Septa: Validation Tooling And Inventory](septa/validation-tooling-and-inventory.md)~~ | High | Done 2026-04-26 — validate-all.sh covers variant fixtures (55 pass), README primary workflow updated, CROSS-TOOL-PAYLOADS.md complete, workflow-template version fixed 1.0→1.1 (8d5ace4, 7adc3e9) |
| ~~A26~~ | ~~[Cross-Project: Producer Contract Validation Harness](cross-project/producer-contract-validation-harness.md)~~ | High | Done 2026-04-28 — validate-producer-output.py + contract-harness-demo.sh; 9 priority surfaces validated; README three-step pattern documented; septa 05a46cc |

---

### Capability Discovery & Dispatch

New capability registry contracts flowing through Septa → Spore → Stipe → Canopy endpoint → Hymenium client. C0 gates the rest.

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~C0~~ | ~~[Septa: Capability Registry Contracts](septa/capability-registry-contracts.md)~~ | Critical | Done 2026-04-28 — capability-registry-v1 + capability-runtime-lease-v1 schemas; fixtures; CROSS-TOOL-PAYLOADS.md + README inventory updated; verify 6/6; septa 0ba1de1 |
| ~~C1~~ | ~~[Spore: Capability Registry Discovery](spore/capability-registry-discovery.md)~~ | Critical | Done 2026-04-28 — capability.rs: CapabilityRegistry/RuntimeLease parse + load, resolve_capability lease-first fallback, 18 tests; path helpers in paths.rs; spore a3c7f5b; verify 7/7 |
| ~~C2~~ | ~~[Stipe: Capability Registration Manager](stipe/capability-registration-manager.md)~~ | High | Done 2026-04-28 — capability_ids+contract_ids on ToolSpec; write_capability_registry (serde_json::json!, spore pin constraint); capability registry doctor check; wired into stipe init; stipe 2d289ec; verify 8/8 |
| ~~C3~~ | ~~[Canopy: Dispatch Request Service Endpoint](canopy/dispatch-request-service-endpoint.md)~~ | High | Done 2026-04-28 — `dispatch.rs` intake/read_request; `DispatchPriority`/`DispatchAgentTier` → `TaskPriority`/`AgentRole`; `canopy dispatch submit`; `workflow.dispatch.v1` CAPABILITY_ID; verify 8/8; canopy 5cf7f35 |
| ~~C4~~ | ~~[Hymenium: Capability Dispatch Client](hymenium/capability-dispatch-client.md)~~ | High | Done 2026-04-28 — `CapabilityCanopyClient<C>` resolves `workflow.dispatch.v1` via Spore lease/registry, falls back to `CliCanopyClient`; wired into `commands/dispatch.rs`; `path = "../spore"` TODO for git pin; verify 8/8; hymenium 84f689a |

---

### Hymenium ↔ Canopy

Workflow orchestration, dispatch compatibility, phase reconciliation, and runtime identity at the Hymenium–Canopy boundary. H2 → H3/H4 → H1/H5 → H6/H7 is the suggested order within the dogfood cluster.

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~A1~~ | ~~[Hymenium: Orchestration Dispatch Contracts](hymenium/orchestration-dispatch-contracts.md)~~ | Critical | Done 2026-04-25 — fixed --requested-by/--required-tier/assign flags; build_assign_task_args; 6 new tests (4e53d05) |
| H0 | [Hymenium/Canopy Dogfood Hardening](cross-project/hymenium-canopy-dogfood-hardening.md) | Critical | Umbrella for the 2026-04-26 dogfood findings |
| ~~H2~~ | ~~[Hymenium: Canopy Dispatch Compatibility](hymenium/canopy-dispatch-compatibility.md)~~ | Critical | Done 2026-04-26 — all 9 AgentRole variants covered; JSON task-id parse + raw fallback; verify script fixed (1be7dc0) |
| ~~H3~~ | ~~[Hymenium: Task Packet Runtime Identity](hymenium/task-packet-runtime-identity.md)~~ | Critical | Done 2026-04-26 — workflow_id/phase_id wired to Canopy task create; handoff_path fixed from owning_repo to real path; canopy_task_id surfaced in human status (ce11a87) |
| ~~H4~~ | ~~[Hymenium: Canopy Phase Reconciliation](hymenium/canopy-phase-reconciliation.md)~~ | Critical | Done 2026-04-26 — reconcile_phases(), PermissiveGateEvaluator, reconcile command; only "completed" = success, only "cancelled"/"canceled" = fail; 9 integration tests (b60ead7) |
| ~~H1~~ | ~~[Hymenium: Dogfood Handoff Intake Lint](hymenium/dogfood-handoff-intake-lint.md)~~ | High | Done 2026-04-26 — SectionType alias map, normalize_heading, extract_section_by_type, source_scope field, 4 parser tests + umbrella fixture; H4 residuals (engine/reconcile/main) also shipped (07978a2) |
| ~~H5~~ | ~~[Hymenium: Read-Only Audit Packet Quality](hymenium/read-only-audit-packet-quality.md)~~ | High | Done 2026-04-27 — titles include handoff title + em-dash; non-goals no longer comma-split; write capability gated on source patterns; artifact boundary constraint (4de36f3) |
| ~~A28~~ | ~~[Hymenium: Workflow Gate Integration Verification](hymenium/workflow-gate-integration-verification.md)~~ | High | Done 2026-04-26 — EvidenceGateEvaluator reads TaskDetail.has_code_diff/has_verification_passed; 5 non-ignored integration tests; partial evidence (diff-only) confirmed blocked (bcf8361) |
| ~~A36~~ | ~~[Hymenium: Terminal Workflow Idempotency](hymenium/terminal-workflow-idempotency.md)~~ | High | Done 2026-04-26 — complete/fail get already-terminal guard (Ok no-op with message); 6 new tests; cancel.rs unchanged (already had guard) (9565796) |
| A43 | [Hymenium: Dispatch Command Trust Boundary](hymenium/dispatch-command-trust-boundary.md) | Medium | Dispatch shells out to ambient `canopy` without timeout or trusted path |
| ~~A49~~ | ~~[Hymenium: Docs And CLI Surface Drift](hymenium/docs-and-cli-surface-drift.md)~~ | High | Done 2026-04-26 — positional args corrected, decompose marked stub, src/commands/ added to tree, MCP claim removed, mod.rs paths fixed (8b57fac) |
| ~~A18~~ | ~~[Canopy: MCP Handoff Runtime Boundaries](canopy/mcp-handoff-runtime-boundaries.md)~~ | Critical | Done 2026-04-26 — verify-script gated by flag; import rejects outside-.handoffs paths + traversal; ON DELETE CASCADE on file_locks; owner-scoped unlock; MCP schema updated (a8bbe5a) |
| ~~A35~~ | ~~[Canopy: Task Event And State Idempotency](canopy/task-event-and-state-idempotency.md)~~ | High | Done 2026-04-26 — scoped dedup (all 5 non-terminal statuses), terminal no-op guard, EvidenceAttached from store layer, migration drops old partial unique index (81a9db4) |
| H6 | [Canopy: Assigned Work Operator Surface](canopy/assigned-work-operator-surface.md) | Medium | Make current assigned work visible without manual task-id tracking |
| H7 | [Stipe: Installed Binary Freshness](stipe/installed-binary-freshness.md) | Medium | Doctor/update guidance catches stale installed Hymenium/Canopy binaries |

---

### Rhizome → Hyphae

Code intelligence export from Rhizome and import into Hyphae. Also covers Rhizome's MCP write boundary and LSP verification.

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~A3~~ | ~~[Rhizome: Code Graph Contract And Install Boundary](rhizome/code-graph-contract-and-install-boundary.md)~~ | High | Done 2026-04-28 — metadata HashMap<String,Value> so line_start/end are JSON integers; file node zero-line metadata removed; backend_selector decoupled from installer; rhizome b02f4e9 |
| ~~A4~~ | ~~[Hyphae: Code Graph Import And Core Boundary](hyphae/code-graph-import-and-core-boundary.md)~~ | High | Done 2026-04-28 — edge weight range 0.0..=1.0 validated at import; out-of-range error with index+value; test for weight 2.5; hyphae b43c4f2 |
| ~~A17~~ | ~~[Rhizome: MCP Write Boundary And Runtime Timeouts](rhizome/mcp-write-boundary-and-runtime-timeouts.md)~~ | Critical | Done 2026-04-26 — caller root clamped to project_root; 300s installer timeouts; probe path read-only; hostile-root tests for all write families (febd669); follow-up: symbol_tools root param description is now misleading |
| ~~A29~~ | ~~[Rhizome: LSP And Export Verification](rhizome/lsp-and-export-verification.md)~~ | High | Done 2026-04-28 — deterministic.rs: 4 non-ignored LspClient/LspBackend error tests; live_lsp.rs stays optional; AGENTS.md documents --ignored commands; verify 3/3 |
| ~~A33~~ | ~~[Rhizome: Incremental Export Prune Integrity](rhizome/incremental-export-prune-integrity.md)~~ | High | Done 2026-04-28 — export_graph takes prune: bool; export_to_hyphae passes prune=files_skipped_cached==0; 2 regression tests (incremental→false, full→true); verify 3/3; rhizome e27508a |

---

### Volva → Cortina → Hyphae

Hook lifecycle capture chain: Volva emits hook envelopes, Cortina classifies and records them, Hyphae stores session signals.

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~A5~~ | ~~[Volva: Hook Runtime Contracts](volva/hook-runtime-contracts.md)~~ | High | Done 2026-04-25 — timeout clamped to [1,30000]; execution_session in septa schema; docs updated (49a2abb/a7971d3) |
| A23 | [Volva: Backend And Credential Runtime Safety](volva/backend-and-credential-runtime-safety.md) | Medium | Official backend timeout, project hook adapter trust/env, credential file permissions |
| ~~A6~~ | ~~[Cortina: Capture Policy Boundary](cortina/capture-policy-boundary.md)~~ | High | Done 2026-04-28 — GateGuard advisory default verified; verify 5/5 passed; no code changes needed |
| ~~A13~~ | ~~[Cortina: Session And Usage Event Contracts](cortina/session-usage-event-contracts.md)~~ | High | Done 2026-04-26 — SessionEventV1Dto wire DTO; wired into save paths; session-state fixture; cortina a3f6d46 |
| ~~A30~~ | ~~[Cortina: Hook Executor Verification](cortina/hook-executor-verification.md)~~ | Medium | Done 2026-04-28 — docs updated to accurate stub description; tests/ stub file created; verify 2/2; cortina 879dfe2 |
| ~~A34~~ | ~~[Cortina: Volva Event Replay Identity](cortina/volva-event-replay-identity.md)~~ | High | Done 2026-04-27 — VolvaExecutionSession; session_id wired into NormalizedLifecycleEvent; (session_id, phase) dedupe; cortina e985edf |
| ~~A38~~ | ~~[Cortina: Compact Summary Artifact Integrity](cortina/compact-summary-artifact-integrity.md)~~ | Medium | Done 2026-04-28 — artifact/compact_summary/{session_id} already implemented; verify script two-arg fix; verify 3/3 |
| ~~A41~~ | ~~[Cortina: Handoff Audit And Hook Secret Boundaries](cortina/handoff-audit-and-hook-secret-boundaries.md)~~ | High | Done 2026-04-27 — canonicalize_and_gate; secret_redaction.rs; safe_command all Hyphae paths; cortina 1e062ac |

---

### Mycelium → Hyphae

Command output compression (Mycelium) and storage into Hyphae. Includes Mycelium contract and boundary items.

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~A15~~ | ~~[Mycelium: Gain And Summary Contracts](mycelium/gain-summary-contracts.md)~~ | High | Done 2026-04-28 — telemetry_summary excluded from public JSON (skip_serializing); gain output now validates against mycelium-gain-v1 (additionalProperties:false); verify 4/4; mycelium 7321725 |
| ~~A10~~ | ~~[Mycelium: Output Cleanliness](mycelium/output-cleanliness.md)~~ | Medium | Done 2026-04-28 — Hyphae fallback uses tracing::warn! (not eprintln!); test_hyphae_fallback_stderr_not_polluted confirms clean output; verify 3/3; already implemented |
| ~~A24~~ | ~~[Mycelium: Input Size Boundaries](mycelium/input-size-boundaries.md)~~ | Medium | Done 2026-04-28 — 10MB limit on read/diff file+stdin; 1MB limit on json; reject_if_oversized helper; 3 named rejection tests; verify 6/6 |
| ~~A31~~ | ~~[Mycelium: Git Branch Regression Verification](mycelium/git-branch-regression-verification.md)~~ | Medium | Done 2026-04-28 — is_branch_write_op extracted; 7 non-ignored unit tests (branch_creation filter); 2 ignored integration tests kept; verify 2/2 |

---

### Hyphae Storage & Retrieval

Internal Hyphae integrity items not driven by a specific inbound producer.

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~A14~~ | ~~[Hyphae: Read Model And Archive Contracts](hyphae/read-model-and-archive-contracts.md)~~ | High | Done 2026-04-26 — hyphae-search-v1 expanded; archive filter `until` added to schema; import pre-validation atomicity; conflict strategy tests; septa e37da13, hyphae 5e2fd49 |
| ~~A19~~ | ~~[Hyphae: Storage And Ingest Runtime Safety](hyphae/storage-and-ingest-runtime-safety.md)~~ | High | Done 2026-04-27 — VACUUM INTO WAL-safe backup, atomic restore via rename, OsString sidecars, 10MB ingest cap, case-split secret detection, UTF-8 lossy stdin; hyphae f82c46b bd94de7 |
| ~~A32~~ | ~~[Hyphae: Memory And Document Integrity](hyphae/memory-document-integrity.md)~~ | High | Done 2026-04-27 — unchecked_transaction wraps memory+embedding writes, project-scoped UNIQUE(project,source_path) with inline migration, NULL-semantics documented; hyphae c6446e3 |
| ~~A45~~ | ~~[Hyphae: Embedding Supply Chain Profile](hyphae/embedding-supply-chain-profile.md)~~ | High | Done 2026-04-27 — supply chain documented in README+AGENTS.md; CI split into ci-embeddings/ci-no-embeddings; verify script 4/4 passed; hyphae edc0c49 |

---

### Canopy / Hyphae → Cap

Read models consumed by Cap and Annulus operator surfaces.

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~A2~~ | ~~[Canopy: Septa Read Model Contracts](canopy/septa-read-model-contracts.md)~~ | High | Done 2026-04-26 — allowed_actions.level enum fixed; needs_verification_count added to snapshot; schema_version validation in outcomes; contract tests; septa e37da13, canopy 447b491 |
| ~~A11~~ | ~~[Canopy: Notification Contract Alignment](canopy/canopy-notification-contract-alignment.md)~~ | High | Done 2026-04-26 — notification_id/seen in schema+fixture+tests; septa c5520e3, canopy 958d3b6 |
| ~~A7~~ | ~~[Annulus: Operator Boundary And Statusline Contracts](annulus/operator-boundary-statusline-contracts.md)~~ | High | Done 2026-04-28 — notify write boundary documented (notification acknowledgement); degradation+hyphae segments added to septa schema; annulus b9ed99c, septa 70e3867; verify 5/5 |
| A12 | [Cap: Cross-Tool Consumer Contracts](cap/cross-tool-consumer-contracts.md) | Medium | Evidence source kind and Annulus status/statusline consumer drift |
| ~~A21~~ | ~~[Cap: API Auth And Webhook Defaults](cap/api-auth-and-webhook-defaults.md)~~ | High | Done 2026-04-26 — non-loopback + no API key → 503; startup host closed over not re-read; webhook validate() pure HMAC; bypass at route layer; localStorage documented (ed61c88) |
| ~~A27~~ | ~~[Cap: Server And UI Verification Hardening](cap/server-and-ui-verification-hardening.md)~~ | High | Done 2026-04-28 — null/array/scalar body guard in validators; whitespace-only changed_by rejected; 8 validator tests + 8 route tests + observable UI error test; beforeEach mockImplementation reset; verify 4/4; cap 98fa6cd |
| A37 | [Cap: Canopy Stale Cache Integrity](cap/canopy-stale-cache-integrity.md) | Medium | Stale snapshot fallback is global instead of project/filter keyed |
| A46 | [Cap: Node Supply Chain Script Policy](cap/node-supply-chain-script-policy.md) | Medium | `npx` scripts, release checks, install lifecycle policy |
| A50 | [Cap: Dashboard And API Docs Drift](cap/dashboard-api-docs-drift.md) | Medium | API docs, route inventory, internals docs, and UI behavior claims are stale |

---

### Stipe (Install, Registration & Updates)

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| A9 | [Stipe: Control Plane Quality](stipe/control-plane-quality.md) | Medium | Backup partial-success semantics and boolean-heavy APIs |
| ~~A20~~ | ~~[Stipe: Install Hooks And Secret Safety](stipe/install-hooks-and-secret-safety.md)~~ | High | Done 2026-04-27 — validate_key_for_shell_export; quoted export; 0600 perms; gitignore check; stipe 8acd92b |
| ~~A47~~ | ~~[Stipe: Release Artifact Provenance](stipe/release-artifact-provenance.md)~~ | High | Done 2026-04-27 — SHA-256 verify, 100MB cap, TempDir extraction, version match; stipe 9905deb |
| ~~A53~~ | ~~[Stipe: Install And Release Docs Drift](stipe/install-release-docs-drift.md)~~ | High | Done 2026-04-27 — matrix/scope/README updated; validate-docs.py fixed; stipe 8acd92b, root 0b37df9 |

---

### Lamella (Hooks & Skills Packaging)

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~A22~~ | ~~[Lamella: Session Logger Secret Redaction](lamella/session-logger-secret-redaction.md)~~ | Medium | Done 2026-04-28 — redactSecrets() in JS + redact_secrets() in shell; 0600 permissions (chmodSync + chmod); console.log(d) removed from PostToolUse inline hooks; lamella fbb6013 |
| ~~A42~~ | ~~[Lamella: Hook Trust And Manifest Path Security](lamella/hook-trust-and-manifest-path-security.md)~~ | High | Done 2026-04-27 — scrubEnv() in post-edit-format/typecheck/auto-format; path containment check in validate-manifests; lamella 64a661c |
| ~~A48~~ | ~~[Lamella: Package Provenance And Runtime Pins](lamella/package-provenance-and-runtime-pins.md)~~ | High | Done 2026-04-27 — @latest and -y removed from mcp-configs; ccstatusline pinned @1.0; provenance doc added; lamella 143d4eb |
| A40 | [Lamella: Manifest Sync Maintenance](lamella/manifest-sync-maintenance.md) | Medium | Manifest sync maintenance script points at obsolete paths |
| ~~A51~~ | ~~[Lamella: Docs And Authoring Drift](lamella/docs-and-authoring-drift.md)~~ | High | Done 2026-04-27 — make build PLUGIN= removed; marketplace builder separated from plugin builder; hook path vars clarified; skill counts 286/292→301; lamella 72ba946 |

---

### Cross-Project & Workspace

| # | Handoff | Priority | Notes |
|---|---------|----------|-------|
| ~~A8~~ | ~~[Spore: Shared Primitive Quality](spore/shared-primitive-quality.md)~~ | High | Done 2026-04-25 — logging API preserved, wait() after kill() in 3 paths, discovery 5s timeout, README v0.4.11/CI (e4cd04b) |
| ~~A25~~ | ~~[Cross-Project: Verification Command And Script Hardening](cross-project/verification-command-and-script-hardening.md)~~ | High | Done 2026-04-27 — A19/A23/A24 scripts hardened with check_test_count guards; A18/A21 orphan scripts archived; template updated for cwd-safe subshells (4824ff1) |
| ~~A39~~ | ~~[Cross-Project: Version Ledger Authority](cross-project/version-ledger-authority.md)~~ | High | Done 2026-04-27 — ecosystem-versions.toml is authority; Stipe pins aligned (hyphae/canopy/stipe/spore/annulus/cap); lamella/annulus/cap ledger corrected; hyphae-ingest added to release.sh; check-version-drift.sh (1d3bd90) |
| ~~A44~~ | ~~[Cross-Project: Rust Supply Chain Policy](cross-project/rust-supply-chain-policy.md)~~ | High | Done 2026-04-27 — deny.toml + [licenses]; Dependabot Cargo coverage for all 10 repos (subrepo-local configs for volva/annulus/hymenium); Spore pinned by rev= across all 9 consumers; check-spore-pins.sh (4fbfc6b) |
| A52 | [Cross-Project: Workspace Docs Link Drift](cross-project/workspace-docs-link-drift.md) | Medium | Broken docs links, archived handoff references, command rendering, unavailable skill refs |
| ~~A54~~ | ~~[Cross-Project: Release Smoke Tests](cross-project/release-smoke-tests.md)~~ | Medium | Done 2026-04-28 — Smoke test step added to canopy, stipe, hymenium, cortina, annulus, volva release.yml; L0 `--version` + per-repo L1; cross-skip guard; verify 36/36 |

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
| — | [Hyphae: Obsidian Second-Brain Export](hyphae/obsidian-second-brain-export.md) | Low | Deferred until core hardening freeze lifts; export-first, no Cap-owned second-brain UI |
