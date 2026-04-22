# Hyphae: Council Record Artifact Query Surface

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/...`
- **Cross-repo edits:** `none`
- **Non-goals:** changing Canopy’s council-session lifecycle in this handoff
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hyphae/verify-council-record-artifact-query-surface.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Add or tighten the `hyphae` query surface for `council_record` artifacts by type
and project.

## Verification

```bash
cd hyphae && cargo test --workspace 2>&1 | tail -10
bash .handoffs/hyphae/verify-council-record-artifact-query-surface.sh
```

## Checklist

- [ ] `council_record` artifacts are queryable by type and project
- [ ] returned payload keeps linkage fields intact
- [ ] repo tests pass
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 2 of [Council Record Artifacts](../cross-project/council-record-artifacts.md).
