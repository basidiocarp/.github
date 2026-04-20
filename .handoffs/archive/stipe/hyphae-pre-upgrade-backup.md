# Stipe Hyphae Pre-Upgrade Backup

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** stipe/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `stipe` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

The last step of `structured-export-archive` is operational, not archival: `stipe`
needs a narrow backup hook before upgrading Hyphae. That should be its own unit
instead of being buried under export and import work.

## What needs doing

Add two operator surfaces:

- a pre-upgrade backup hook for `stipe upgrade hyphae`
- a manual `stipe backup hyphae` command

Required behavior:

- backup runs only for Hyphae upgrades when a database exists
- backup path includes version and timestamp
- export failures warn but do not block the upgrade
- manual backup reuses the same archive path convention

Keep this handoff limited to `stipe`. Do not extend the archive format or Hyphae
CLI here.

## Files to modify

- `stipe/src/...` upgrade flow
- `stipe/src/...` backup command wiring
- `stipe/src/...` tests for warning and backup path behavior

## Verification

```bash
cd stipe && cargo test backup --quiet
bash .handoffs/stipe/verify-hyphae-pre-upgrade-backup.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `stipe` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] `stipe upgrade hyphae` attempts a backup before upgrade work
- [ ] backup filenames include version and timestamp
- [ ] backup failure warns and continues
- [ ] `stipe backup hyphae` exists
- [ ] focused tests cover at least manual and pre-upgrade paths
- [ ] verify script passes with `Results: N passed, 0 failed`
