# Cross-Project Canopy Notification Contract

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** only the repos explicitly named in this handoff
- **Cross-repo edits:** allowed when this handoff names the touched repos explicitly
- **Non-goals:** unplanned umbrella decomposition or opportunistic adjacent repo edits
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Cap and Annulus cannot consume Canopy notifications reliably until there is a
shared payload contract. That contract is smaller and more stable than the full
notification lifecycle rollout.

## What needs doing

Add the notification contract and fixture:

- `septa/canopy-notification-v1.schema.json`
- `septa/fixtures/canopy-notification-v1-example.json`
- `ecosystem-versions.toml` pin
- `septa/README.md` contract listing

Keep this handoff limited to the shared contract. Do not implement Canopy emission,
Cap UI, or Annulus delivery here.

## Files to modify

- `septa/canopy-notification-v1.schema.json`
- `septa/fixtures/canopy-notification-v1-example.json`
- `septa/README.md`
- `ecosystem-versions.toml`

## Verification

```bash
ls septa/canopy-notification-v1.schema.json
rg "canopy-notification" septa/README.md ecosystem-versions.toml
bash .handoffs/cross-project/verify-canopy-notification-contract.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] schema covers id, event_type, task_id, agent_id, payload, severity, created_at, and read_at
- [ ] fixture exists and matches the schema shape
- [ ] `ecosystem-versions.toml` pins `canopy-notification = "1.0"`
- [ ] `septa/README.md` lists the contract
- [ ] verify script passes with `Results: N passed, 0 failed`
