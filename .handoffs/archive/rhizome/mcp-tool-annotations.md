# Rhizome: MCP Tool Annotations

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `rhizome`
- **Allowed write scope:** `rhizome/...`
- **Cross-repo edits:** `none`
- **Non-goals:** changing `hyphae`, `canopy`, or `lamella`
- **Verification contract:** run the repo-local commands below and `bash .handoffs/rhizome/verify-mcp-tool-annotations.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `rhizome`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `rhizome` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

`rhizome` MCP tools expose no annotation metadata, so consumers cannot
distinguish read-only operations from destructive edits.

## What Needs Doing

Add MCP `annotations` for every registered `rhizome` tool using the
classification table from
[mcp-tool-annotation-classification.md](../cross-project/mcp-tool-annotation-classification.md).

## Files To Modify

- `rhizome/...` tool registration files
- tests as needed

## Verification

```bash
cd rhizome && cargo build --workspace 2>&1 | tail -5
cd rhizome && cargo test tool_annotations 2>&1 | tail -10
bash .handoffs/rhizome/verify-mcp-tool-annotations.sh
```

## Checklist

- [ ] read-only tools carry `readOnlyHint`
- [ ] destructive edit tools carry `destructiveHint`
- [ ] annotations match the classification document
- [ ] repo build and tests pass
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `rhizome`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `rhizome` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 2 of [Tool Annotation Metadata](../cross-project/tool-annotation-metadata.md).
