# Lamella: Manifest Sync Maintenance

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/scripts/maintenance/sync-manifests-with-folders.py`, `lamella/scripts/maintenance/README.md`, `lamella/scripts/ci/`, `lamella/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no marketplace catalog redesign and no generated `dist/` edits
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-manifest-sync-maintenance.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** maintenance sync script, maintenance README, CI manifest validator
- **Reference seams:** `scripts/ci/validate-manifests.js`, `resources/skills`, `manifests/claude`
- **Spawn gate:** do not launch an implementer until the parent agent decides whether the maintenance sync script should be fixed or retired

## Problem

Lamella's documented manifest sync maintenance script points at obsolete `scripts/skills` and `scripts/plugin-manifests` paths rather than the real `resources/skills` and `manifests/claude` source-of-truth paths. A maintainer can run the documented command and get no useful manifest alignment.

## What needs doing

1. Either retire the obsolete sync script or update it to use the same roots as CI validation.
2. Update maintenance docs to point to the supported manifest validation/sync path.
3. Add a smoke test or validation guard so obsolete paths cannot silently pass.

## Verification

```bash
cd lamella && node scripts/ci/validate-manifests.js
cd lamella && make validate
bash .handoffs/lamella/verify-manifest-sync-maintenance.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] manifest sync docs no longer point to obsolete paths
- [ ] sync script is fixed or clearly retired
- [ ] CI manifest validator remains the authoritative validation path
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 4 data integrity audit. Severity: medium.
