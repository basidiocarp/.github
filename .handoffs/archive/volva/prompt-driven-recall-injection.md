# Volva: Prompt-Driven Recall Injection

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `volva`
- **Allowed write scope:** `volva/...`
- **Cross-repo edits:** `none`
- **Non-goals:** changing Cortina’s injection path in this handoff
- **Verification contract:** run the repo-local commands below and `bash .handoffs/volva/verify-prompt-driven-recall-injection.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `volva` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Make `volva` recall injection prompt-aware, token-budgeted, and deduplicated
using the existing `hyphae` query surfaces.

## Verification

```bash
cd volva && cargo test 2>&1 | tail -10
bash .handoffs/volva/verify-prompt-driven-recall-injection.sh
```

## Checklist

- [ ] prompt excerpts drive recall queries
- [ ] recall respects a token budget
- [ ] duplicate recalled memories are skipped within the dedup window
- [ ] repo tests pass
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `volva` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 1 of [Prompt-Driven Proactive Recall](../cross-project/prompt-driven-proactive-recall.md).
