# Canopy: Council Record Artifact Emission

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/...`
- **Cross-repo edits:** `none`
- **Non-goals:** adding the `hyphae` query surface in this handoff
- **Verification contract:** run the repo-local commands below and `bash .handoffs/canopy/verify-council-record-artifact-emission.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Emit closed Canopy council sessions as `council_record` typed artifacts or
artifact-ready payloads with the required linkage fields.

## Verification

```bash
cd canopy && cargo test 2>&1 | tail -10
bash .handoffs/canopy/verify-council-record-artifact-emission.sh
```

## Checklist

- [ ] council session close-out emits `council_record` data
- [ ] payload includes task linkage, roster, and outcome
- [ ] repo tests pass
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 1 of [Council Record Artifacts](../cross-project/council-record-artifacts.md).
