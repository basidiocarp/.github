# Cross-Project: Core Hardening Freeze Roadmap

<!-- Save as: .handoffs/cross-project/core-hardening-freeze-roadmap.md -->
<!-- Create verify script: .handoffs/cross-project/verify-core-hardening-freeze-roadmap.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** `docs/foundations/`, `.handoffs/`, repo-local docs only where they need freeze notes
- **Cross-repo edits:** documentation and handoff dashboard only; implementation belongs in repo-owned hardening handoffs
- **Non-goals:** no source-code feature implementation and no repo deletion
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-core-hardening-freeze-roadmap.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** workspace docs and handoff dashboard
- **Likely files/modules:** `docs/foundations/`, `.handoffs/HANDOFFS.md`, active core hardening handoffs
- **Reference seams:** capability control plane handoffs, dogfood hardening handoffs, Cap operator-console scope reset, existing Rust ecosystem audit follow-ups
- **Spawn gate:** do not launch an implementer until the parent agent decides the exact freeze categories and exception process

## Problem

The ecosystem has enough moving parts that adding more features before the core loop is stable will make evaluation harder. The dogfood run showed the most valuable work is not more surface area; it is making the core tools and contracts reliable enough to improve real agent work.

The project needs an explicit freeze policy so "pause feature work" does not become vague or selectively ignored.

## Recommendation

Freeze new feature work across the ecosystem except for:

1. **Core hardening:** `mycelium`, `rhizome`, `hyphae`, and `septa`.
2. **Required communication substrate:** `spore` and `stipe` work needed for contracts, capability discovery, install health, and local service boundaries.
3. **Dogfood unblockers:** narrow `hymenium` and `canopy` fixes required to run and reconcile real dogfood tasks.
4. **Critical safety/security fixes:** any repo.
5. **Docs that clarify current behavior or freeze scope.**

Freeze or defer:

- Cap feature work except the operator-console scope reset and critical security fixes.
- New orchestration features in Hymenium/Canopy that are not required by the next dogfood run.
- Lamella/Annulus/Volva feature expansion unless it directly supports the core loop or fixes a critical boundary.
- New UI surfaces, dashboards, workflow templates, agents, or packaging features.

## What needs doing (intent)

Create a short freeze roadmap that names:

- repos in active hardening mode
- repos in maintenance/freeze mode
- exception process for emergency fixes or dogfood blockers
- current active handoffs that remain allowed
- handoffs that should be deferred until the core loop is proven
- exit criteria for lifting the freeze

## Scope

- **Primary seam:** ecosystem planning and handoff triage
- **Allowed files:** docs and dashboard only
- **Explicit non-goals:** no implementation, no archival sweep unless the user explicitly approves it

## Required Roadmap Structure

Create `docs/foundations/core-hardening-freeze-roadmap.md` with:

```markdown
# Core Hardening Freeze Roadmap

## Freeze Decision

## Active Hardening Repos

## Maintenance/Frozen Repos

## Allowed Work During Freeze

## Deferred Work

## Exception Process

## Exit Criteria

## Current Handoff Triage
```

## Verification

```bash
bash .handoffs/cross-project/verify-core-hardening-freeze-roadmap.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] roadmap exists at `docs/foundations/core-hardening-freeze-roadmap.md`
- [ ] roadmap names active hardening repos and frozen/maintenance repos
- [ ] roadmap defines allowed work and exception process
- [ ] roadmap defines exit criteria for lifting freeze
- [ ] handoff dashboard links this roadmap
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created after the CentralCommand dogfood run and Cap scope discussion. This keeps the ecosystem focused on proving the core loop before expanding optional surfaces.

