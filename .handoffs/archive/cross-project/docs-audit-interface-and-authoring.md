# Cross-Project: Docs Audit Interface And Authoring

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** `cortina/...`, `cap/...`, `lamella/...`
- **Cross-repo edits:** allowed only in the named repos
- **Non-goals:** auditing other repos in this handoff
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-docs-audit-interface-and-authoring.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Audit and fix user-facing docs in `cortina`, `cap`, and `lamella` against the
actual hook, UI, and authoring surfaces.

## Verification

```bash
cd lamella && make validate 2>&1 | tail -10
bash .handoffs/cross-project/verify-docs-audit-interface-and-authoring.sh
```

## Checklist

- [ ] `cortina` docs match actual hook event types and CLI
- [ ] `cap` docs match actual routes or UI tabs
- [ ] `lamella` docs match actual skill and hook authoring surfaces
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 3 of [Documentation Audit](docs-audit.md).
