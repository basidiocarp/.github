# Lamella: Session-End Shim

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/...`
- **Cross-repo edits:** `none`
- **Non-goals:** validating the runtime session-end path or deleting the shim
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-session-end-shim.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `lamella` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Replace the lamella `session-end.js` behavior with a thin shim that delegates to
the `cortina` session-end adapter and exits cleanly when `cortina` is missing.

## Verification

```bash
cd lamella && make validate 2>&1 | tail -10
bash .handoffs/lamella/verify-session-end-shim.sh
```

## Checklist

- [ ] the shim delegates stdin to `cortina`
- [ ] the shim exits cleanly when `cortina` is unavailable
- [ ] lamella cleanup docs mark the shim as transitional
- [ ] `make validate` passes
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `lamella` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 1 of [Lamella→Cortina Boundary Cleanup — Phase 2](../cross-project/lamella-cortina-boundary-phase2.md).
