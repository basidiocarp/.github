# Cross-Project: Cache-Friendly Assembly Guidance

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** `docs/...`
- **Cross-repo edits:** `none`
- **Non-goals:** applying implementation changes in `lamella` or `cortina`
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-cache-friendly-assembly-guidance.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Document the cache-friendly context assembly order and its rationale in the
foundations docs.

## Verification

```bash
ls docs/foundations/cache-friendly-assembly.md
bash .handoffs/cross-project/verify-cache-friendly-assembly-guidance.sh
```

## Checklist

- [ ] assembly order is documented
- [ ] each layer includes cache behavior guidance
- [ ] anti-patterns are called out
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 1 of [Cache-Friendly Context Layout](cache-friendly-context-layout.md).
