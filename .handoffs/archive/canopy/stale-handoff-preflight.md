# Canopy: Stale Handoff Preflight

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/...`
- **Cross-repo edits:** `none`
- **Non-goals:** changing `cortina audit-handoff` itself
- **Verification contract:** run the repo-local commands below and `bash .handoffs/canopy/verify-stale-handoff-preflight.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

`canopy` should not dispatch a handoff blindly once `cortina` can audit a handoff
for staleness.

## Depends On

- [audit-handoff-cli.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cortina/audit-handoff-cli.md)

## What Needs Doing

Add a pre-dispatch check in `canopy` that runs `cortina audit-handoff` when a
task has a handoff path and flags stale handoffs for review instead of
dispatching them automatically.

## Files To Modify

- `canopy/src/runtime.rs`
- `canopy/src/...` tests for pre-dispatch decisions

## Verification

```bash
cd canopy && cargo test pre_dispatch --quiet
bash .handoffs/canopy/verify-stale-handoff-preflight.sh
```

## Checklist

- [ ] canopy runs Cortina handoff audit before dispatch when a handoff path exists
- [ ] stale handoffs are flagged for review instead of auto-dispatched
- [ ] a clear reason is returned in the dispatch decision
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsRe-homed from `cross-project/` because the actual implementation seam is `canopy` only.
