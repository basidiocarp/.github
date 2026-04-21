# Operator And Runtime Follow-Ons

Date: 2026-04-15
Purpose: capture the worthwhile secondary patterns from the external audit wave without mixing them into the orchestration reset authority work

Related docs:

- [Active dashboard](../../HANDOFFS.md)
- [Orchestration reset campaign](../orchestration-reset/README.md)
- [External synthesis](../../../.audit/external/synthesis/project-examples-ecosystem-synthesis.md)

## One-paragraph read

This campaign is the follow-on program for the secondary audit insights that are useful but not core to the orchestration reset itself. The reset still defines authority and contracts. This campaign picks up the next layer: runtime hardening, worktree and session persistence, operator read models, doctor and availability surfaces, and local-first usage visibility. The goal is not to imitate outside products. It is to land the good seams in the repo that already owns each concern.

## What belongs here

- explicit runtime hardening and claim safety
- execution-host worktree, session, and restore state
- task-anchored council or review session visibility
- local-first operator surfaces and real-time invalidation patterns
- host doctor, provider health, and per-provider usage reporting

## What does not belong here

- changing the core orchestration authority split
- widening the workflow template surface before the reset lands
- introducing UI-owned configuration truth
- recreating vendor or model brand matrices as first-class architecture

## Track 1: Runtime Hardening — DONE 2026-04-15

All five handoffs shipped and released:

- canopy v0.5.12 — task duplicate prevention (partial unique index, atomic claim, concurrency cap)
- hymenium v0.4.0 — runtime sweeper (SWEEP_INTERVAL 30s, HEARTBEAT_TIMEOUT 45s, GC_RETENTION 7d, background OS thread)
- volva v0.2.0 — ExecEnv module (directory setup, provider/skill injection, worktree, gc metadata)
- stipe v0.5.16 — doctor expansion (MCP health, provider keys, plugin inventory)
- annulus v0.5.3 — per-provider usage scanner (UsageRow, UsageScanner trait, Claude/Codex/Gemini scanners)

1. [Canopy: Task Duplicate Prevention](../../canopy/task-duplicate-prevention.md) ✓
2. [Hymenium: Runtime Sweeper](../../hymenium/runtime-sweeper.md) ✓
3. [Volva: Execution Environment Isolation](../../volva/execution-environment-isolation.md) ✓

Primary external value:

- `multica`: duplicate prevention, atomic claim, watchdog sweepers, isolated execution environments

## Track 2: Session And Route Identity

1. [Volva: Workspace-Session Route Models](../../volva/workspace-session-routes.md)
2. [Volva: Execution Session Instance Records](../../volva/execution-session-instance-records.md)
3. [Canopy: Council Session Lifecycle](../../canopy/council-session-lifecycle.md)
4. [Canopy: Council Record Artifact Emission](../../canopy/council-record-artifact-emission.md)

Primary external value:

- `vibe-kanban`: workspace and session route identity
- `council`: explicit session records, rosters, and timelines
- `claude-squad`: persisted task, worktree, and restore state

## Track 3: Operator Surfaces

1. [Cap: Live Operator Views And Browser Review Surfaces](../../cap/live-operator-views-and-browser-review-surfaces.md)
2. [Cap: Realtime Invalidation Read Models](../../cap/realtime-invalidation-read-models.md)
3. [Cap: Inline Diff-Comment Review Loops](../../cap/inline-diff-review.md)

Primary external value:

- `vibe-kanban`: explicit review loop and preview flow
- `multica`: WebSocket-as-invalidation over query-backed read models

## Track 4: Host Readiness And Usage

1. [Stipe: Doctor Expansion](../../stipe/doctor-expansion.md)
2. [Stipe: Permission Memory And Provider UX](../../stipe/permission-memory-provider-ux.md)
3. [Annulus: Per-Provider Usage Scanner](../../annulus/per-provider-usage-scanner.md)

Primary external value:

- `vibe-kanban`: agent and MCP availability checks
- `multica`: per-provider usage scanner shape
- `council`: summon prerequisite visibility
- `claude-squad`: operator-friendly session and daemon readiness expectations

## Sequencing

Run this campaign after the orchestration reset has a believable runtime and ledger core, or in carefully isolated parallel where the seam is already independent.

Recommended order:

1. runtime hardening
2. session and route identity
3. host readiness and usage
4. operator surfaces

## Done means

This campaign is only done when:

- runtime and claim safety are explicit rather than implied
- worktree, workspace, and session restore facts are durable
- operator surfaces read from stable backend ownership
- doctor and usage views expose local truth without inventing backend authority
