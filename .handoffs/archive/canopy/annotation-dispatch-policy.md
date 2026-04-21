# Canopy: Annotation Dispatch Policy

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/...`
- **Cross-repo edits:** `none`
- **Non-goals:** adding annotations in provider repos or changing `lamella`
- **Verification contract:** run the repo-local commands below and `bash .handoffs/canopy/verify-annotation-dispatch-policy.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

`canopy` cannot enforce a principled autonomous-dispatch policy until it reads
MCP annotation metadata from tool definitions.

## What Needs Doing

Wire `canopy` dispatch policy to respect `readOnlyHint`,
`destructiveHint`, and related annotation fields, and expose the active policy
through a narrow operator surface.

## Files To Modify

- `canopy/...` dispatch policy files
- `canopy/...` CLI or policy output files
- tests as needed

## Verification

```bash
cd canopy && cargo test dispatch_policy 2>&1 | tail -20
cd canopy && cargo test --workspace 2>&1 | tail -10
bash .handoffs/canopy/verify-annotation-dispatch-policy.sh
```

## Checklist

- [ ] dispatch policy reads annotation metadata before autonomous tool dispatch
- [ ] destructive tools require confirmation by default
- [ ] the active policy is visible to operators
- [ ] repo tests pass
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 4 of [Tool Annotation Metadata](../cross-project/tool-annotation-metadata.md).
