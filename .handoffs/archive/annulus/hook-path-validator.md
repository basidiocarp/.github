# Annulus Hook Path Validator

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** annulus/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

Hook validation is a separate feature slice from statusline extraction and can
be worked in parallel once the crate scaffold exists.

## Depends on

- [crate-scaffold.md](/Users/williamnewton/projects/basidiocarp/.handoffs/annulus/crate-scaffold.md)

## What needs doing

Implement `annulus validate-hooks` to:

- read host config files
- extract hook paths
- report missing, non-executable, or invalid targets
- return a non-zero exit when validation fails

Keep this handoff limited to Annulus validation behavior.

## Verification

```bash
cd annulus && cargo test validate_hooks
bash .handoffs/annulus/verify-hook-path-validator.sh
```

## Checklist

- [ ] hook path extraction and validation are implemented
- [ ] missing and non-executable hooks are reported clearly
- [ ] command exits non-zero on validation failure
- [ ] verify script passes with `Results: N passed, 0 failed`
