# Lamella: Session-End Direct Hook Cutover

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/...`
- **Cross-repo edits:** `none`
- **Non-goals:** revalidating the cortina runtime path
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-session-end-direct-hook-cutover.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `lamella` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Delete the transitional shim, point lamella hook registration directly at
`cortina`, and update the boundary cleanup doc to mark the migration complete.

## Verification

```bash
cd lamella && make validate 2>&1 | tail -10
bash .handoffs/lamella/verify-session-end-direct-hook-cutover.sh
```

## Checklist

- [ ] the shim file is deleted
- [ ] `hooks.json` points directly at `cortina`
- [ ] cleanup docs mark the boundary complete
- [ ] `make validate` passes
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `lamella` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 3 of [Lamella→Cortina Boundary Cleanup — Phase 2](../cross-project/lamella-cortina-boundary-phase2.md).
