# Mycelium: Hyphae Command Output Storage Bridge

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** `mycelium/...`
- **Cross-repo edits:** `none`
- **Non-goals:** redesigning `hyphae` storage APIs
- **Verification contract:** run the repo-local commands below and `bash .handoffs/mycelium/verify-hyphae-command-output-storage-bridge.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `mycelium` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Bridge `mycelium` summary mode to `hyphae` command-output storage so the full
output can be retrieved on demand.

## Verification

```bash
cd mycelium && cargo test 2>&1 | tail -10
bash .handoffs/mycelium/verify-hyphae-command-output-storage-bridge.sh
```

## Checklist

- [ ] full output is stored in `hyphae` when summary mode triggers
- [ ] storage remains non-blocking or degrades safely
- [ ] retrieval guidance is present in the emitted summary path
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `mycelium` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 3 of [Summary + Detail-on-Demand Pattern](../cross-project/summary-detail-on-demand.md).
