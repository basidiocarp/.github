# Annulus Contract Follow-Up

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** only the repos explicitly named in this handoff
- **Cross-repo edits:** allowed when this handoff names the touched repos explicitly
- **Non-goals:** unplanned umbrella decomposition or opportunistic adjacent repo edits
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

If Annulus introduces any new shared payload or machine-facing status surface,
that contract work should be isolated from the initial crate and wiring work.

## Depends on

- [statusline-extraction.md](/Users/williamnewton/projects/basidiocarp/.handoffs/annulus/statusline-extraction.md)

## What needs doing

Only if needed, add or refresh `septa` contracts and fixtures for new Annulus
payloads or machine-readable validation output.

## Verification

```bash
bash .handoffs/cross-project/verify-annulus-contract-followup.sh
```

## Checklist

- [ ] required contract changes are isolated to this follow-up
- [ ] `septa` fixtures or schemas are updated only if Annulus introduces a new contract
- [ ] verify script passes with `Results: N passed, 0 failed`
