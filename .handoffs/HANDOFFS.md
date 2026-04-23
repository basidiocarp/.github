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

### Tier 0: Foundation — Audit Fix Backlog

Issues found during the Ecosystem Health Audit. Fix Critical/High first, then structural improvements.

**Critical / High (fix before new features):**

| # | Handoff | Severity | Repo |
|---|---------|----------|------|
| A1 | [Audit Fix: HandoffStatus Enum Drift](campaigns/ecosystem-health-audit/README.md) | Critical | septa + canopy |
| A2 | [Audit Fix: Snapshot additionalProperties Mismatch](campaigns/ecosystem-health-audit/README.md) | High | septa + canopy |
| A3 | [Audit Fix: cortina audit-handoff Unseamed](campaigns/ecosystem-health-audit/README.md) | High | septa + cortina + canopy |
| A4 | [Audit Fix: Spore Version Drift](campaigns/ecosystem-health-audit/README.md) | High | ecosystem |
| A5 | [Audit Fix: Cap→Canopy Single Point of Failure](campaigns/ecosystem-health-audit/README.md) | High | cap + canopy |

**Structural improvements (design decision required before starting):**

| # | Handoff | Priority | Note |
|---|---------|----------|------|
| S1 | [Cap: Canopy Resilience Layer](cap/canopy-resilience-layer.md) | High | ⚠ THINK FIRST — read and answer design questions |
| S2 | [Cortina: Session State Store](cortina/session-state-store.md) | Medium | ⚠ THINK FIRST — read and answer design questions |
| S3 | [Septa: Contract Governance Enforcement](septa/contract-governance-enforcement.md) | Medium | ⚠ THINK FIRST — read and answer design questions |

**Uncharted territory (new audit surface, not yet covered):**

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| U1 | [Cross-Project: CI Enforcement Gates](cross-project/ci-enforcement-gates.md) | High | Audit fix pass (clippy/fmt must be clean first) |
| U2 | [Cross-Project: Seam and Fix-Target Test Coverage](cross-project/seam-test-coverage.md) | Medium | Audit fix pass (tests cover fixed behavior) |
| U3 | [Cross-Project: Cross-Tool Observability](cross-project/cross-tool-observability.md) | Medium | — |
| U4 | [Cross-Project: Auth and Access Control Audit](cross-project/auth-access-control-audit.md) | Medium | — |

**Cohesion path (ecosystem tools actually used, tools wired together):**

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| C1 | [Cross-Project: Tool Preference Instructions](cross-project/tool-preference-instructions.md) | High | Nothing — CLAUDE.md edit only |
| C2 | [Cross-Project: Session-Start Context Injection](cross-project/session-start-context-injection.md) | High | Understand stipe hook deployment first |
| C3 | [Cross-Project: Ecosystem Smoke Test](cross-project/ecosystem-smoke-test.md) | Medium | Tools running locally |
| C4 | [Cap: Drift Signal Surface](cap/drift-signal-surface.md) | Medium | Cap→Canopy seam working (A5) |
| C5 | [Volva: Orchestration Mode Definition](volva/orchestration-mode-definition.md) | Medium | ⚠ THINK FIRST — read and answer design questions |

---

### Tier 5: Standalone or Lower Urgency

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 112 | [Mycelium: Compressed Format Experiments](mycelium/compressed-format-experiments.md) | Low | [Mycelium Structural Parser Hardening](archive/mycelium/structural-parser-hardening.md) |

### Tier 6: Cap

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 24 | [Cap: Live Operator Views And Browser Review Surfaces](cap/live-operator-views-and-browser-review-surfaces.md) | Medium | Volva Execution-Host Session Workspace Contract; Canopy Queue Worktree Review Orchestration; Hyphae Scoped Memory Identity And Export Contract |
| 60 | [Cap: Status Preview And Customization Surface](cap/status-preview-and-customization-surface.md) | Medium | Septa Resolved Status And Customization Contract; Cap Live Operator Views And Browser Review Surfaces |
| 30 | [Cap: Canopy Performance](cap/canopy-performance.md) | Medium | Deep Audit |
| — | [Cap: Service Health Panel](cap/service-health-panel.md) | Medium | Spore graceful-degradation-classification |
| C4 | [Cap: Drift Signal Surface](cap/drift-signal-surface.md) | Medium | Cap→Canopy seam working (A5) |

### Tier 7: Later Phases

| # | Handoff | Priority | Depends On |
|---|---------|----------|-----------|
| 81 | [Volva: Auth and Native API Backend](volva/auth-native-api.md) | Lower | — |
| 82 | [Cortina: Codex / Gemini Adapters](cortina/codex-gemini-adapters.md) | Lower | — |
| 105 | [Volva: Workspace-Session Route Models](volva/workspace-session-routes.md) | Lower | Volva Hyphae Recall Injection (#71) |
| C5 | [Volva: Orchestration Mode Definition](volva/orchestration-mode-definition.md) | Medium | ⚠ THINK FIRST |
| 106 | [Cap: Inline Diff-Comment Review Loops](cap/inline-diff-review.md) | Lower | Cap Live Operator Views (#24) |
| 107 | [Rhizome: Analyzer Plugin Extensibility](rhizome/analyzer-plugin-extensibility.md) | Lower | Shipped prerequisite: Rhizome Structural Fallback (v0.7.11) |
| — | [Lamella: Session-End Direct Hook Cutover](lamella/session-end-direct-hook-cutover.md) | Low | Lamella-Cortina Boundary Phase 2 |
