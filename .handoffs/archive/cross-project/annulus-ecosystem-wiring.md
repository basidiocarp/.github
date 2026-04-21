# Annulus Ecosystem Wiring

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** only the repos explicitly named in this handoff
- **Cross-repo edits:** allowed when this handoff names the touched repos explicitly
- **Non-goals:** unplanned umbrella decomposition or opportunistic adjacent repo edits
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

After Annulus owns statusline and hook validation, the install and doctor
surfaces need explicit follow-up wiring. That is a separate cross-project task.

## Depends on

- [statusline-extraction.md](/Users/williamnewton/projects/basidiocarp/.handoffs/annulus/statusline-extraction.md)
- [hook-path-validator.md](/Users/williamnewton/projects/basidiocarp/.handoffs/annulus/hook-path-validator.md)

## What needs doing

Wire Annulus into the workspace:

- workspace root metadata as needed
- `stipe` install or doctor surfaces
- any deprecation routing needed from `cortina`

## Verification

```bash
cd stipe && cargo test
bash .handoffs/cross-project/verify-annulus-ecosystem-wiring.sh
```

## Checklist

- [ ] ecosystem metadata includes Annulus where needed
- [ ] `stipe` surfaces reference Annulus correctly
- [ ] legacy Cortina guidance points operators at Annulus
- [ ] verify script passes with `Results: N passed, 0 failed`
