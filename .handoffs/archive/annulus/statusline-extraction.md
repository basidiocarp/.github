# Annulus Statusline Extraction

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** annulus/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

Once the crate exists, statusline migration is the next standalone slice. It is
too large to bundle with the initial scaffold or hook validation.

## Depends on

- [crate-scaffold.md](/Users/williamnewton/projects/basidiocarp/.handoffs/annulus/crate-scaffold.md)

## What needs doing

Move statusline logic from `cortina` into `annulus`, keeping the extraction
bounded to:

- porting the current statusline behavior
- introducing the segment structure
- documenting deprecation in `cortina`

Do not wire ecosystem install surfaces here.

## Verification

```bash
cd annulus && cargo test
cd cortina && cargo test statusline
bash .handoffs/annulus/verify-statusline-extraction.sh
```

## Checklist

- [ ] `annulus statusline` works with valid stdin JSON
- [ ] fallback terminal mode works
- [ ] missing tool segments fail open
- [ ] `cortina` keeps a deprecation note and still passes statusline tests
- [ ] verify script passes with `Results: N passed, 0 failed`
