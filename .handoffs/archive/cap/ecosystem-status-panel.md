# Cap Ecosystem Status Panel

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

Once Annulus exposes structured status JSON, Cap needs one bounded consumer handoff
instead of directly re-reading ecosystem data from multiple tools.

## What needs doing

Add the Cap ecosystem-status consumer:

- `GET /api/ecosystem/status`
- dashboard panel fed by Annulus JSON
- 30-second refresh
- graceful empty or Annulus-not-installed state

Keep this handoff limited to Cap’s proxy and rendering path. Do not change
Annulus data-source logic here.

## Files to modify

- `cap/src/...` API route
- `cap/src/...` dashboard panel
- `cap/src/...` tests

## Verification

```bash
cd cap && npm run build
bash .handoffs/cap/verify-ecosystem-status-panel.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] ecosystem status API route exists
- [ ] dashboard panel renders segment cards from Annulus JSON
- [ ] refresh interval is implemented
- [ ] missing Annulus degrades cleanly
- [ ] verify script passes with `Results: N passed, 0 failed`
