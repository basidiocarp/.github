# Lamella: Cache-Friendly Context Ordering

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/...`
- **Cross-repo edits:** `none`
- **Non-goals:** changing `cortina` ordering logic
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-cache-friendly-context-ordering.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `lamella` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Audit and reorder `lamella` context assembly so stable prefixes come first and
dynamic content moves later in the prompt.

## Verification

```bash
cd lamella && make validate 2>&1 | tail -10
bash .handoffs/lamella/verify-cache-friendly-context-ordering.sh
```

## Checklist

- [ ] lamella context ordering follows the cache-friendly guidance
- [ ] stable content is emitted before dynamic content
- [ ] no functional regression in context delivery
- [ ] `make validate` passes
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `lamella` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 2 of [Cache-Friendly Context Layout](../cross-project/cache-friendly-context-layout.md).
