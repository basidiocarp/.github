# Cross-Project: Summary Storage Contract

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** `septa/...`, `ecosystem-versions.toml`
- **Cross-repo edits:** allowed only in the named contract surfaces
- **Non-goals:** implementing `mycelium` runtime behavior
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-summary-storage-contract.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Define the summary payload and storage metadata contract for large command-output
summaries, using `septa` and the workspace contract pin.

## Verification

```bash
ls septa/mycelium-summary-v1.schema.json 2>/dev/null
bash .handoffs/cross-project/verify-summary-storage-contract.sh
```

## Checklist

- [ ] summary schema exists if the summary shape is treated as a cross-project contract
- [ ] storage metadata is documented
- [ ] contract pins are updated if required
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 1 of [Summary + Detail-on-Demand Pattern](summary-detail-on-demand.md).
