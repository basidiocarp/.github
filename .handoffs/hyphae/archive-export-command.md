# Hyphae Archive Export Command

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

The export half of `structured-export-archive` is large enough on its own. It
needs to land as a clean CLI surface before import and backup work build on top.

## What needs doing

Implement `hyphae export <output-file>` with the filter and formatting flags from
the umbrella handoff:

- `--topic`
- `--since`
- `--until`
- `--include-memoirs`
- `--include-sessions`
- `--min-weight`
- `--pretty`
- `--overwrite`

Export should produce valid JSON conforming to the Hyphae archive contract and
print a summary of the exported counts.

Keep this handoff limited to export. Do not implement import or `stipe` backup
logic here.

## Files to modify

- `hyphae/src/...` export command wiring
- `hyphae/src/...` export query or serialization code
- `hyphae/src/...` export tests

## Verification

```bash
cd hyphae && cargo test export --quiet
bash .handoffs/hyphae/verify-archive-export-command.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] `hyphae export` writes valid JSON
- [ ] topic and date filters work
- [ ] memoir and session inclusion is opt-in
- [ ] existing output path fails without `--overwrite`
- [ ] stdout summary includes exported counts
- [ ] at least 3 focused export tests exist
- [ ] verify script passes with `Results: N passed, 0 failed`
