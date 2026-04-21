# Cortina Session-End Stale Handoff Warning

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

Once handoff path extraction exists, the next smallest useful slice is a
session-end warning when the current session modified files that overlap with an
unchecked handoff.

## Depends on

- [handoff-path-extraction.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cortina/handoff-path-extraction.md)

## What needs doing

Add stop-hook detection in `cortina` that:

- scans active handoffs
- finds file overlap with the current session's modified files
- warns when overlapping handoffs still have unchecked items

Keep this handoff limited to Cortina session-end behavior and the policy flag
that enables or disables it.

## Files to modify

- `cortina/src/hooks/stop.rs`
- `cortina/src/policy.rs`
- `cortina/src/...` tests for stale handoff warnings

## Verification

```bash
cd cortina && cargo test staleness --quiet
bash .handoffs/cortina/verify-session-end-stale-handoff-warning.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] stop hook identifies overlapping active handoffs with unchecked items
- [ ] warning includes overlapping files
- [ ] warning includes unchecked checklist items or counts
- [ ] policy flag controls the check
- [ ] verify script passes with `Results: N passed, 0 failed`
