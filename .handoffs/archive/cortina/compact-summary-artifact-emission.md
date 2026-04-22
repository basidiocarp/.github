# Cortina: Compact Summary Artifact Emission

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/...`
- **Cross-repo edits:** `none`
- **Non-goals:** adding the `hyphae` retrieval surface in this handoff
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cortina/verify-compact-summary-artifact-emission.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Bridge Cortina pre-compact captures into typed `compact_summary` artifact
emission.

## Verification

```bash
cd cortina && cargo test --workspace 2>&1 | tail -10
bash .handoffs/cortina/verify-compact-summary-artifact-emission.sh
```

## Checklist

- [ ] pre-compact captures emit `compact_summary` artifacts or references
- [ ] existing capture behavior remains coherent
- [ ] repo tests pass
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 1 of [Compact Summary Artifacts](../cross-project/compact-summary-artifacts.md).
