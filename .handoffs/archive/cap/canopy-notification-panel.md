# Cap Canopy Notification Panel

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** cap/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Once Canopy can emit and list unread notifications, Cap needs a narrow UI handoff
that consumes them. That should stay separate from Canopy storage and Annulus
terminal delivery.

## What needs doing

Add the Cap notification panel and API route:

- `GET /api/canopy/notifications`
- header icon with unread badge
- notification drawer or panel
- mark-read and clear-all flows
- 10-second refresh while open

Keep this handoff limited to Cap’s proxy and UI behavior. Do not broaden it into
Canopy lifecycle logic or Annulus delivery.

## Files to modify

- `cap/src/...` API route
- `cap/src/...` header or notification UI
- `cap/src/...` tests

## Verification

```bash
cd cap && npm run build
bash .handoffs/cap/verify-canopy-notification-panel.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] notification API route exists
- [ ] header icon shows unread count
- [ ] panel renders severity and task context
- [ ] mark-read updates badge state
- [ ] open panel auto-refreshes
- [ ] verify script passes with `Results: N passed, 0 failed`
