# Hyphae Archive Import Command

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Import semantics are the second large seam in `structured-export-archive`. They
need their own handoff because conflict resolution and dry-run behavior are easy
to get wrong when mixed with export and validation work.

## What needs doing

Implement `hyphae import <input-file>` with:

- `--on-conflict skip|overwrite|merge`
- `--dry-run`

Required behavior:

- memories honor the selected conflict mode
- memoirs and sessions import without broad destructive replacement
- dry-run reports what would happen without writing
- the command prints a clear import summary

Keep this handoff limited to import behavior. Contract validation details belong
in `archive-import-validation`.

## Files to modify

- `hyphae/src/...` import command wiring
- `hyphae/src/...` conflict resolution logic
- `hyphae/src/...` import tests

## Verification

```bash
cd hyphae && cargo test import --quiet
bash .handoffs/hyphae/verify-archive-import-command.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] `skip`, `overwrite`, and `merge` modes are implemented
- [ ] `--dry-run` prints the same summary shape without writing
- [ ] summary reports imported, skipped, and overwritten counts
- [ ] memoir and session sections are handled safely when present
- [ ] at least 3 focused import tests exist
- [ ] verify script passes with `Results: N passed, 0 failed`
