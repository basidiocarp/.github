# Cap Service Health Panel

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** cap/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

The Cap portion of graceful degradation is a separate UI seam from taxonomy,
Spore probing, and Annulus status rendering. It should not block those lower
layers from landing.

## What needs doing

Add a Cap service-health panel that consumes the availability report from Annulus
or `spore`-derived status:

- green when all Tier 1 and Tier 2 services are available
- amber when a Tier 2 service is unavailable
- red when a Tier 1 service is unavailable
- dismissible panel behavior

Keep this handoff limited to Cap consumption and rendering.

## Files to modify

- `cap/src/...` API route or proxy
- `cap/src/...` service-health UI
- `cap/src/...` tests

## Verification

```bash
cd cap && npm run build
bash .handoffs/cap/verify-service-health-panel.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] panel renders green, amber, and red states
- [ ] dismiss state is supported
- [ ] health data comes from Annulus or a shared availability source, not fresh ad-hoc probes in the component
- [ ] build and relevant tests pass
- [ ] verify script passes with `Results: N passed, 0 failed`
