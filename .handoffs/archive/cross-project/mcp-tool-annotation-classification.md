# Cross-Project: MCP Tool Annotation Classification

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** `docs/...`
- **Cross-repo edits:** `none`
- **Non-goals:** adding runtime annotations in `rhizome`, `hyphae`, `canopy`, or `lamella`
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-mcp-tool-annotation-classification.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

The ecosystem needs one authoritative classification table for MCP tool
annotations before any provider or consumer code is updated.

## What Needs Doing

Create `docs/foundations/mcp-tool-annotations.md` with a classification table for
all `rhizome` and `hyphae` MCP tools, including `readOnlyHint`,
`destructiveHint`, and `idempotentHint`, plus short rationale for ambiguous
cases.

## Files To Modify

- `docs/foundations/mcp-tool-annotations.md`

## Verification

```bash
ls docs/foundations/mcp-tool-annotations.md
bash .handoffs/cross-project/verify-mcp-tool-annotation-classification.sh
```

## Checklist

- [ ] classification doc exists
- [ ] all `rhizome` MCP tools are classified
- [ ] all `hyphae` MCP tools are classified
- [ ] ambiguous cases include rationale
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 1 of [Tool Annotation Metadata](tool-annotation-metadata.md).
