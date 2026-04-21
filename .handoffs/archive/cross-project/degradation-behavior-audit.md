# Cross-Project Degradation Behavior Audit

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

The audit portion of `graceful-degradation-classification` is useful on its own
and should not be bundled together with `spore`, `annulus`, and `cap` changes.

## What needs doing

Audit current degradation behavior for the major ecosystem tools and record it in
`docs/foundations/graceful-degradation.md`:

- what fails open
- what returns hard errors
- what silently skips
- where behavior does not match the taxonomy

Keep this handoff audit-only. Do not make runtime code changes here unless the
existing document is impossible to update without a tiny supporting edit.

## Files to modify

- `docs/foundations/graceful-degradation.md`

## Verification

```bash
rg "Current Behavior" docs/foundations/graceful-degradation.md
bash .handoffs/cross-project/verify-degradation-behavior-audit.sh
```

## Checklist

- [x] all major tools are covered in a current-behavior section or table
- [x] mismatches against the taxonomy are flagged explicitly
- [x] no implementation code changed
- [x] verify script passes with `Results: 2 passed, 0 failed`

## Verification Output

<!-- PASTE START -->
PASS: current behavior section exists
PASS: tool coverage is broad
Results: 2 passed, 0 failed
<!-- PASTE END -->
