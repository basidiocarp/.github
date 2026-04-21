# Hyphae: Rhizome AST Chunking

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/...`
- **Cross-repo edits:** `none`
- **Non-goals:** changing `rhizome` parser internals
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hyphae/verify-rhizome-ast-chunking.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

`hyphae` code chunking still relies on heuristic `ByFunction` boundaries even
though `rhizome` can already provide AST-level symbol boundaries.

## What Needs Doing

Add a `ByAst` chunking strategy in `hyphae` that delegates to `rhizome` when
available and falls back to `ByFunction` when it is not.

## Files To Modify

- `hyphae/...` chunking strategy files
- `hyphae/...` ingest selection files
- tests as needed

## Verification

```bash
cd hyphae && cargo build --workspace 2>&1 | tail -5
cd hyphae && cargo test --workspace 2>&1 | tail -10
bash .handoffs/hyphae/verify-rhizome-ast-chunking.sh
```

## Checklist

- [ ] `ByAst` strategy exists
- [ ] `hyphae` falls back gracefully when `rhizome` is unavailable
- [ ] ingest metadata records the chunking strategy used
- [ ] repo build and tests pass
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsRe-homed from `cross-project/` because every implementation step lives in `hyphae`.
