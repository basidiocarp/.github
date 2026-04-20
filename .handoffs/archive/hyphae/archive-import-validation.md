# Hyphae Archive Import Validation

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

Import validation is a separate seam from import behavior. The command needs to
reject malformed or version-mismatched archives cleanly instead of relying on
deserialization accidents.

## What needs doing

Add import-path validation against the Hyphae archive contract:

- reject missing required fields with clear errors
- reject unknown schema versions with clear mismatch messages
- reject malformed nested objects with descriptive validation errors

Keep this handoff limited to validation and error handling. Do not broaden it
into export behavior, backup, or new archive fields.

## Files to modify

- `hyphae/src/...` archive validation code
- `hyphae/src/...` import error mapping
- `hyphae/src/...` import validation tests

## Verification

```bash
cd hyphae && cargo test import_validation --quiet
bash .handoffs/hyphae/verify-archive-import-validation.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] missing `schema_version` fails cleanly
- [ ] unknown schema version fails cleanly
- [ ] malformed memory entries fail with descriptive validation errors
- [ ] validation happens before mutation logic runs
- [ ] at least 3 focused validation tests exist
- [ ] verify script passes with `Results: N passed, 0 failed`
