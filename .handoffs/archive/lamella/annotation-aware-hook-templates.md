# Lamella: Annotation-Aware Hook Templates

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/...`
- **Cross-repo edits:** `none`
- **Non-goals:** changing runtime dispatch policy in `canopy` or provider annotations in `rhizome` and `hyphae`
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-annotation-aware-hook-templates.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `lamella` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

The ecosystem will have annotation-aware tool metadata, but `lamella` still needs
authoring patterns that inspect it in hooks.

## What Needs Doing

Add `lamella` hook templates and authoring docs that show how to inspect tool
annotation metadata for advisory or audit logging flows.

## Files To Modify

- `lamella/...` hook template files
- `lamella/docs/...` authoring docs

## Verification

```bash
cd lamella && make validate 2>&1 | tail -10
bash .handoffs/lamella/verify-annotation-aware-hook-templates.sh
```

## Checklist

- [ ] pre-tool-use template exists for annotation-aware advisory review
- [ ] post-tool-use template exists for annotation-aware logging
- [ ] lamella docs explain the annotation fields the templates inspect
- [ ] `make validate` passes
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `lamella` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 5 of [Tool Annotation Metadata](../cross-project/tool-annotation-metadata.md).
