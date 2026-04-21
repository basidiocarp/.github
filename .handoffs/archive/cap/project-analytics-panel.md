# Cap Project Analytics Panel

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

## Depends on

- [project-gain-json.md](/Users/williamnewton/projects/basidiocarp/.handoffs/mycelium/project-gain-json.md)

## What needs doing

Consume the Mycelium project-analytics JSON surface in Cap and render a
per-project breakdown table or panel alongside the existing global analytics.

## Verification

```bash
cd cap && npm run build
cd cap && npm test
bash .handoffs/cap/verify-project-analytics-panel.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] Cap renders per-project analytics when present
- [ ] UI hides cleanly when project analytics are unavailable
- [ ] verify script passes with `Results: N passed, 0 failed`
