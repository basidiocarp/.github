# Annulus: Tool Adoption Statusline

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** `annulus/...`
- **Cross-repo edits:** `none`
- **Non-goals:** adding the richer `cap` task panel
- **Verification contract:** run the repo-local commands below and `bash .handoffs/annulus/verify-tool-adoption-statusline.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `annulus`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `annulus` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

`annulus` has no compact tool-adoption indicator even though `canopy` can score
tool usage.

## What Needs Doing

Add a compact `tools:N/M` style indicator to `annulus` statusline output using
the tool-adoption data already computed upstream.

## Verification

```bash
cd annulus && cargo build 2>&1 | tail -5
cd annulus && cargo test 2>&1 | tail -10
bash .handoffs/annulus/verify-tool-adoption-statusline.sh
```

## Checklist

- [ ] statusline shows `tools:N/M` when adoption data exists
- [ ] color or severity thresholds match the agreed score bands
- [ ] indicator is absent when no data exists
- [ ] repo build and tests pass
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `annulus`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `annulus` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 2 of [Tool Usage Surfaces](../cross-project/tool-usage-surfaces.md).
