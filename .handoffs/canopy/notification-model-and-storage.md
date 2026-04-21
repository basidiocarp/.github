# Canopy Notification Model and Storage

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

`notification-lifecycle` is too broad to hand to one worker. The first bounded
unit is just the Canopy-side data model: migration, enum, and storage surface.

## What needs doing

Add the notification storage seam in `canopy`:

- `notifications` table migration
- `NotificationEventType` enum
- minimal model and store wiring for notification rows

Keep this handoff limited to storage and model definition. Do not add emission
triggers, Cap UI, or Annulus delivery here.

## Files to modify

- `canopy/src/store/...`
- `canopy/src/models.rs`
- `canopy/src/...` tests for migration and model serialization

## Verification

```bash
cd canopy && cargo test notification --quiet
bash .handoffs/canopy/verify-notification-model-and-storage.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] `notifications` table migration exists
- [ ] event-type enum includes the initial lifecycle events
- [ ] model or store code can read and write notification rows
- [ ] at least 2 focused migration or model tests exist
- [ ] verify script passes with `Results: N passed, 0 failed`
