# External Audit Gap Map

Date: 2026-04-09
Purpose: map the current external-audit conclusions to the active `.handoffs` queue, identify what is already covered, and call out what is still missing enough to justify either a new handoff or a larger campaign

Related docs:

- [HANDOFFS.md](/Users/williamnewton/projects/basidiocarp/.handoffs/HANDOFFS.md)
- [project-examples-ecosystem-synthesis.md](/Users/williamnewton/projects/basidiocarp/.audit/external/synthesis/project-examples-ecosystem-synthesis.md)
- [ecosystem-synthesis-and-adoption-guide.md](/Users/williamnewton/projects/basidiocarp/.audit/external/synthesis/ecosystem-synthesis-and-adoption-guide.md)
- [skill-management-and-council-adoption-plan.md](/Users/williamnewton/projects/basidiocarp/.audit/external/synthesis/skill-management-and-council-adoption-plan.md)

Status:

- 2026-04-09: the missing handoff candidates in this note were converted into active handoffs in `.handoffs/`

## One-paragraph read

The active handoff set now covers most of the concrete external-audit follow-through. The strongest current coverage is in `stipe`, `lamella`, `hyphae`, `cortina`, `canopy`, `volva`, `septa`, and `rhizome`, and the sharp missing handoffs from the latest audit wave have been converted into active work. What remains is not another batch of obvious repo-owned handoffs. It is campaign-level coordination across the new handoffs, plus one still-deferred theme around layered guidance loading and override precedence.

## What is already covered well enough to stay as handoffs

These external-audit themes already have a clear active handoff:

- richer provider, MCP, plugin, and worktree health: [archive/stipe/provider-mcp-plugin-doctor-expansion.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/stipe/provider-mcp-plugin-doctor-expansion.md)
- skill validation and packaging discipline: [lamella/skill-package-validation.md](/Users/williamnewton/projects/basidiocarp/.handoffs/lamella/skill-package-validation.md)
- passive context resources and typed retrieval surfaces: [archive/hyphae/passive-context-resources.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/hyphae/passive-context-resources.md)
- scoped memory identity and export shape: [hyphae/scoped-memory-identity-and-export-contract.md](/Users/williamnewton/projects/basidiocarp/.handoffs/hyphae/scoped-memory-identity-and-export-contract.md)
- lifecycle normalization: [archive/cortina/normalized-lifecycle-event-contracts.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/cortina/normalized-lifecycle-event-contracts.md)
- task-linked council basics: [archive/cross-project/task-linked-council-sessions.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/cross-project/task-linked-council-sessions.md)
- queue, worktree, and review orchestration: [archive/canopy/queue-worktree-review-orchestration.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/canopy/queue-worktree-review-orchestration.md)
- execution-host identity: [archive/volva/execution-host-session-workspace-contract.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/volva/execution-host-session-workspace-contract.md)
- cross-tool participant identity: [archive/septa/workflow-participant-runtime-identity-contract.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/septa/workflow-participant-runtime-identity-contract.md)
- richer analyzer and understanding work: [archive/rhizome/richer-analyzer-plugins-and-incremental-understanding.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/rhizome/richer-analyzer-plugins-and-incremental-understanding.md)
- operator-facing browser and live views: [cap/live-operator-views-and-browser-review-surfaces.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/live-operator-views-and-browser-review-surfaces.md)

These do not need to be duplicated. They need to be finished.

## What is still incomplete after the new handoffs

These themes are no longer missing from the queue. They are active, but not closed:

### 1. Permission memory and runtime policy rollout

Active handoff:

- [archive/stipe/permission-memory-and-runtime-policy.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/stipe/permission-memory-and-runtime-policy.md)

Still needs:

- concrete persisted approval-memory semantics
- runtime policy surfaces that turn one-off approvals into explicit reusable rules
- operator-visible policy state

### 2. Portable status and customization rollout

Active handoffs:

- [archive/septa/resolved-status-and-customization-contract.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/septa/resolved-status-and-customization-contract.md)
- [cap/status-preview-and-customization-surface.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/status-preview-and-customization-surface.md)

Still needs:

- packaged presets against the shared contract
- per-host injection and repair flows against the same contract
- operator preview and editing over the portable shape rather than host-specific blobs

### 3. Usage-event normalization and deterministic telemetry rollout

Active handoffs:

- [archive/cross-project/usage-event-contract.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/cross-project/usage-event-contract.md)
- [mycelium/deterministic-telemetry-summary-surfaces.md](/Users/williamnewton/projects/basidiocarp/.handoffs/mycelium/deterministic-telemetry-summary-surfaces.md)

Still needs:

- a clean producer path in `cortina`
- deterministic summaries in `mycelium`
- operator views that consume summaries instead of reverse-engineering raw host output

### 4. Layered guidance loading as a product surface

Covered indirectly by:

- workspace docs and current AGENTS practices
- `lamella` packaging and validation work

Still missing:

- a deliberate runtime model for global, repo, and local guidance loading where tools need it
- clear source-of-truth rules around override precedence

Audit pressure:

- `forgecode`

This is still real, but it is not yet obviously a standalone repo-owned handoff.

## Active handoffs added from the latest audit wave

These are the concrete handoffs that were added from the most recent external-audit pass:

- [archive/stipe/permission-memory-and-runtime-policy.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/stipe/permission-memory-and-runtime-policy.md)
  Pressure: `forgecode`, `rtk`
- [archive/septa/resolved-status-and-customization-contract.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/septa/resolved-status-and-customization-contract.md)
  Pressure: `ccstatusline`, `ccusage`, `1code`
- [archive/cross-project/usage-event-contract.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/cross-project/usage-event-contract.md)
  Pressure: `ccusage`, `rtk`
- [mycelium/deterministic-telemetry-summary-surfaces.md](/Users/williamnewton/projects/basidiocarp/.handoffs/mycelium/deterministic-telemetry-summary-surfaces.md)
  Pressure: `ccusage`, `rtk`, `context-keeper`
- [cap/status-preview-and-customization-surface.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/status-preview-and-customization-surface.md)
  Pressure: `ccstatusline`

## Campaign candidates

These gaps cluster tightly enough that it makes more sense to treat them as campaigns first, then split them into handoffs when execution starts.

### Campaign A: Host Operator Surface

Use this campaign if you want to land the host-facing operator improvements as one coordinated wave.

Scope:

- `stipe` permission memory and runtime policy
- `stipe` provider or MCP operator UX follow-through
- `septa` resolved status/customization contract
- `lamella` packaged presets and capability metadata for status/customization
- `cap` preview and editing surface for the same contract

Why it is a campaign:

- the pieces are strongly related, but they do not belong in one repo
- sequencing matters: contract first, host adapter second, UI third

### Campaign B: Telemetry Contract And Reporting

Use this campaign if you want to land the `ccusage` and `rtk` lessons as one coordinated wave.

Scope:

- `septa` or cross-project usage-event contract
- `cortina` normalized edge capture
- `mycelium` deterministic summary surfaces
- `cap` usage and cost views over the same summaries
- `stipe` host discovery and doctor surfaces for telemetry inputs

Why it is a campaign:

- this is one end-to-end pipeline, not one repo feature
- doing it piecemeal risks more host-specific heuristics before the contract exists

### Campaign C: Guidance And Policy Surface

Use this campaign only if the ecosystem decides layered guidance loading needs to become a real runtime feature instead of staying mostly a workspace convention.

Scope:

- explicit global, workspace, repo, and local guidance precedence
- source-of-truth rules
- packaging and runtime integration where needed

Likely repos:

- `lamella`
- `volva`
- `spore`
- `stipe`

Why it is a campaign, not a handoff yet:

- the owning runtime seam is still not crisp enough to start coding one repo in isolation

## Recommended next move

If the goal is the highest-value remaining work from the recent audits, do this:

1. execute the new `stipe`, `septa`, `cross-project`, and `mycelium` handoffs
2. use `Host Operator Surface` as the sequencing wrapper for the `stipe` + `septa` + `lamella` + `cap` work
3. use `Telemetry Contract And Reporting` as the sequencing wrapper for the `cortina` + `septa` + `mycelium` + `cap` work
4. leave `Guidance And Policy Surface` deferred until the owning runtime seam is clearer

That preserves concrete repo-owned execution while still keeping the larger program shape visible.

## Final read

The audits do not mainly reveal another batch of random handoffs. They reveal two rollout programs.

The first program is host operator surface work.

The second program is telemetry contract and reporting work.

Everything else still open is either part of one of those programs or still too blurry to justify a new handoff yet.
