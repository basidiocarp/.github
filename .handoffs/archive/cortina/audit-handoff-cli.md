# Cortina Audit Handoff CLI

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** cortina/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

The next bounded surface after path parsing is a manual or automation-friendly
audit command. This should exist before any Canopy integration.

## Depends on

- [handoff-path-extraction.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cortina/handoff-path-extraction.md)

## What needs doing

Add `cortina audit-handoff <path>` plus supporting audit logic that reports:

- total checklist items
- likely implemented items
- evidence for each item

The command should be useful on its own and should not require Canopy changes.

## Files to modify

- `cortina/src/cli.rs`
- `cortina/src/handoff_audit.rs`
- wiring and tests in `cortina/src/...`

## Verification

```bash
cd cortina && cargo test audit --quiet
bash .handoffs/cortina/verify-audit-handoff-cli.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] `cortina audit-handoff` subcommand exists
- [ ] audit reports total vs likely implemented items
- [ ] evidence includes file existence plus at least one implementation signal
- [ ] command exits non-zero for stale handoff signal as designed
- [ ] verify script passes with `Results: N passed, 0 failed`
