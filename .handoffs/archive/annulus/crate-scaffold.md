# Annulus Crate Scaffold

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** annulus/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

The first unit of Annulus work should be only the crate scaffold. That keeps the
initial worker focused on bootstrapping the repo without mixing in statusline or
validation logic.

## What needs doing

Create the `annulus` crate with:

- `Cargo.toml`
- `src/main.rs`
- stub modules for `statusline` and `validate_hooks`
- a working CLI surface with `statusline` and `validate-hooks` subcommands

## Verification

```bash
cd annulus && cargo build
bash .handoffs/annulus/verify-crate-scaffold.sh
```

## Checklist

- [ ] `annulus` crate exists and builds
- [ ] `annulus --help` shows both subcommands
- [ ] stub modules compile cleanly
- [ ] verify script passes with `Results: N passed, 0 failed`
