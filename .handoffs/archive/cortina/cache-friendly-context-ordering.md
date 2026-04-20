# Cortina: Cache-Friendly Context Ordering

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/...`
- **Cross-repo edits:** `none`
- **Non-goals:** changing `lamella` ordering logic
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cortina/verify-cache-friendly-context-ordering.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Audit and reorder `cortina` context assembly so stable prefixes come first and
dynamic content moves later in the prompt.

## Verification

```bash
cd cortina && cargo test --workspace 2>&1 | tail -10
bash .handoffs/cortina/verify-cache-friendly-context-ordering.sh
```

## Checklist

- [ ] cortina context ordering follows the cache-friendly guidance
- [ ] stable content is emitted before dynamic content
- [ ] no functional regression in context delivery
- [ ] repo tests pass
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 3 of [Cache-Friendly Context Layout](../cross-project/cache-friendly-context-layout.md).
