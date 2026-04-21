# Cap: Tool Adoption Panel

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/...`
- **Cross-repo edits:** `none`
- **Non-goals:** adding `annulus` statusline output
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cap/verify-tool-adoption-panel.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

`canopy` tool-adoption scoring exists, but operators cannot see it in the `cap`
task detail view.

## What Needs Doing

Add a task-detail panel in `cap` that renders the tool-adoption score, the used
tool list, and the relevant-but-unused tool list.

## Verification

```bash
cd cap && npm run build 2>&1 | tail -5
cd cap && npm test 2>&1 | tail -10
bash .handoffs/cap/verify-tool-adoption-panel.sh
```

## Checklist

- [ ] score badge is visible
- [ ] used tools are listed with counts
- [ ] relevant-but-unused tools are surfaced with reasons
- [ ] repo build and tests pass
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 1 of [Tool Usage Surfaces](../cross-project/tool-usage-surfaces.md).
