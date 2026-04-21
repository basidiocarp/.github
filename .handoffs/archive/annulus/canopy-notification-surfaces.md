# Annulus Canopy Notification Surfaces

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** annulus/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `annulus`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `annulus` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Terminal delivery is a separate operational seam from Canopy emission and Cap UI.
Annulus needs its own bounded handoff for statusline unread counts and optional
polling or system notifications.

## What needs doing

Add Annulus notification surfaces:

- canopy unread indicator in the statusline
- `annulus notify --poll`
- optional `annulus notify --system`

Keep this handoff limited to Annulus behavior. It should consume existing Canopy
notification data, not redefine the model or add new Canopy events.

## Files to modify

- `annulus/src/...` statusline segments
- `annulus/src/...` notify subcommand
- `annulus/src/...` tests

## Verification

```bash
cd annulus && cargo test notify --quiet
bash .handoffs/annulus/verify-canopy-notification-surfaces.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `annulus`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `annulus` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] statusline canopy segment shows unread count when present
- [ ] `annulus notify --poll` prints and clears unread items
- [ ] `annulus notify --system` is opt-in
- [ ] missing Canopy degrades safely
- [ ] focused tests exist for polling or unread rendering
- [ ] verify script passes with `Results: N passed, 0 failed`
