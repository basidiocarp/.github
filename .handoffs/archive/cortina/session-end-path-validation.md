# Cortina: Session-End Path Validation

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/...`
- **Cross-repo edits:** `none`
- **Non-goals:** modifying lamella hook registration or deleting the shim
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cortina/verify-session-end-path-validation.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Validate the `cortina` session-end path end to end while the lamella shim is
active, and document any output differences that matter to the migration.

## Verification

```bash
cd cortina && cargo test --workspace 2>&1 | tail -10
cortina status 2>&1
hyphae session list 2>&1 | head -10
bash .handoffs/cortina/verify-session-end-path-validation.sh
```

## Checklist

- [ ] recent session-end events are visible through `cortina`
- [ ] `hyphae` session records show the cortina-handled path working
- [ ] migration notes document any meaningful output differences
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 2 of [Lamella→Cortina Boundary Cleanup — Phase 2](../cross-project/lamella-cortina-boundary-phase2.md).
