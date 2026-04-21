# Canopy Task Lifecycle Notification Emission

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** canopy/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

After the storage seam exists, the next bounded unit is the actual Canopy
emission path. That deserves its own handoff because lifecycle transitions, CLI
read APIs, and mark-read semantics are tightly coupled.

## What needs doing

Add Canopy emission and operator-facing notification commands:

- emit notifications on task completion and failure
- emit on evidence receipt and claim conflicts
- add `canopy notification list`
- add `canopy notification mark-read`
- add `canopy notification mark-all-read`

Keep this handoff limited to Canopy emission and CLI behavior. Do not add Cap UI
or Annulus delivery here.

## Files to modify

- `canopy/src/...` lifecycle store or service code
- `canopy/src/...` CLI wiring
- `canopy/src/...` tests for emission and mark-read flows

## Verification

```bash
cd canopy && cargo test lifecycle --quiet
bash .handoffs/canopy/verify-task-lifecycle-notification-emission.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] completion and failure transitions emit notifications
- [ ] evidence receipt emits notifications
- [ ] unread list command renders recent notifications
- [ ] mark-read and mark-all-read work
- [ ] persistence survives process restart because it is stored in SQLite
- [ ] verify script passes with `Results: N passed, 0 failed`
