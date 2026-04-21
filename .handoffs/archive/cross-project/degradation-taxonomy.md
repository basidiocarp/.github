# Cross-Project Degradation Taxonomy

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** only the repos explicitly named in this handoff
- **Cross-repo edits:** allowed when this handoff names the touched repos explicitly
- **Non-goals:** unplanned umbrella decomposition or opportunistic adjacent repo edits
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

The ecosystem cannot implement consistent graceful degradation until the tiers and
payload shape are defined. That contract work is smaller than the full rollout.

## What needs doing

Add the shared taxonomy and contract:

- `docs/foundations/graceful-degradation.md`
- `septa/degradation-tier-v1.schema.json`
- any README or index link needed from `docs/foundations/`

Keep this handoff limited to taxonomy and contract definition. Do not add runtime
probes or UI work here.

## Files to modify

- `docs/foundations/graceful-degradation.md`
- `docs/foundations/README.md` if needed
- `septa/degradation-tier-v1.schema.json`

## Verification

```bash
ls docs/foundations/graceful-degradation.md
ls septa/degradation-tier-v1.schema.json
bash .handoffs/cross-project/verify-degradation-taxonomy.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] the three tiers are defined clearly
- [ ] each major ecosystem tool is assigned a tier
- [ ] the septa schema covers tool, tier, available, reason, and degraded capabilities
- [ ] the foundations index links to the new doc if appropriate
- [ ] verify script passes with `Results: N passed, 0 failed`
